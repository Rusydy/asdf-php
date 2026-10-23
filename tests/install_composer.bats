#!/usr/bin/env bats

# Tests for the extension checks at the top of install_composer(). Under pipefail, `php -m | grep -q`
# reported a loaded extension as missing whenever php was still writing after grep had matched.

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"
  export install_path="${TEST_TEMP_DIR}/install"
  mkdir -p "${install_path}/bin"

  # Extract only the functions under test, so the rest of the installer does not run
  sed -n '/^php_has_extension()/,/^}$/p; /^install_composer()/,/^}$/p' \
    "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/functions.sh"
  source "${TEST_TEMP_DIR}/functions.sh"

  # Keep the tests offline: the signature fetch and every download method fail
  curl() { return 1; }
  wget() { return 1; }

  make_mock_php
}

teardown() {
  unset MOCK_PHP_MODULES MOCK_PHP_PAD
  rm -rf "${TEST_TEMP_DIR}"
}

# Mock php. `-m` prints MOCK_PHP_MODULES and, when MOCK_PHP_PAD is set, keeps writing past the pipe
# buffer. A failed write exits 255, as php does once grep has closed the pipe. `-r` answers only
# extension_loaded() checks, and any other `php -r` call fails.
make_mock_php() {
  cat > "${install_path}/bin/php" <<'EOF'
#!/bin/bash
if [ "$1" = "-m" ]; then
  echo "[PHP Modules]" || exit 255
  for module in ${MOCK_PHP_MODULES}; do echo "${module}" || exit 255; done
  if [ -n "${MOCK_PHP_PAD:-}" ]; then
    for ((i = 1; i <= 100000; i++)); do echo "padding_${i}" || exit 255; done
  fi
  exit 0
fi
if [ "$1" = "-r" ] && [[ "$2" == *extension_loaded* ]]; then
  [[ " ${MOCK_PHP_MODULES} " == *" $3 "* ]]
  exit $?
fi
exit 1
EOF
  chmod +x "${install_path}/bin/php"
}

@test "should not report openssl as missing when php -m keeps writing after grep matches under pipefail" {
  export MOCK_PHP_MODULES="curl openssl"
  export MOCK_PHP_PAD=1
  set -o pipefail

  run install_composer

  [[ "${output}" != *"OpenSSL extension not available"* ]]
  [[ "${output}" == *"Downloading Composer installer"* ]]
}

@test "should still report openssl as missing when php does not load it" {
  export MOCK_PHP_MODULES="curl"
  set -o pipefail

  run install_composer

  [ "${status}" -eq 1 ]
  [[ "${output}" == *"OpenSSL extension not available"* ]]
  [[ "${output}" != *"Downloading Composer installer"* ]]
}

@test "should still report curl as missing without stopping the install" {
  export MOCK_PHP_MODULES="openssl"
  set -o pipefail

  run install_composer

  [[ "${output}" == *"PHP curl extension not available"* ]]
  [[ "${output}" == *"Downloading Composer installer"* ]]
}

@test "should not leave a php -m | grep -q pipeline in bin/ or lib/" {
  run grep -rn '| *grep -q' "${PLUGIN_DIR}/bin" "${PLUGIN_DIR}/lib"

  [ "${status}" -eq 1 ]
}
