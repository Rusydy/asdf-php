#!/usr/bin/env bats

# Tests for optional extension configuration in the install script

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"
  unset PHP_BUILD_CONFIGURE_OPTS PHP_CONFIGURE_OPTIONS

  # Mock pkg-config so the tests don't depend on what the host has installed;
  # MOCK_PKG_CONFIG_PACKAGES lists the packages it reports as present
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/pkg-config" <<'EOF'
#!/bin/bash
[ "$1" = "--exists" ] && [[ " ${MOCK_PKG_CONFIG_PACKAGES:-} " == *" $2 "* ]]
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/pkg-config"
  export PATH="${TEST_TEMP_DIR}/bin:$PATH"

  sed -n "/^# php-build's default configure options leave out sodium and gmp/,/^}$/p" "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/function.sh"
  source "${TEST_TEMP_DIR}/function.sh"
}

teardown() {
  rm -rf "${TEST_TEMP_DIR}"
}

@test "should enable sodium and gmp when both libraries are installed" {
  export MOCK_PKG_CONFIG_PACKAGES="libsodium gmp"

  setup_optional_extensions

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-sodium"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-gmp"* ]]
}

@test "should pass gmp without a directory so Debian's multiarch gmp.h is found" {
  export MOCK_PKG_CONFIG_PACKAGES="gmp"

  setup_optional_extensions

  [[ " ${PHP_BUILD_CONFIGURE_OPTS} " == *" --with-gmp "* ]]
}

@test "should enable only the extensions whose libraries are installed" {
  export MOCK_PKG_CONFIG_PACKAGES="libsodium"

  setup_optional_extensions

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-sodium"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"gmp"* ]]
}

@test "should report missing libraries and add no flags" {
  export MOCK_PKG_CONFIG_PACKAGES=""

  run setup_optional_extensions

  [[ "$output" == *"libsodium not found"* ]]
  [[ "$output" == *"gmp not found"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS:-}" != *"--with-"* ]]
}

@test "should not duplicate sodium already in PHP_BUILD_CONFIGURE_OPTS" {
  export MOCK_PKG_CONFIG_PACKAGES="libsodium"
  export PHP_BUILD_CONFIGURE_OPTS="--with-sodium=/opt/sodium"

  setup_optional_extensions

  [ "${PHP_BUILD_CONFIGURE_OPTS}" = "--with-sodium=/opt/sodium" ]
}

@test "should leave an extension to the user when PHP_CONFIGURE_OPTIONS mentions it" {
  export MOCK_PKG_CONFIG_PACKAGES="libsodium gmp"
  export PHP_CONFIGURE_OPTIONS="--without-sodium"

  setup_optional_extensions

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"--with-sodium"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-gmp"* ]]
}
