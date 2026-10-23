#!/usr/bin/env bats

# Tests for the OpenSSL 3 pin in the install script. PHP 8.3.29 fails to compile against the openssl@4
# headers that Homebrew links on macOS, so the pin points the build at openssl@3 when it is installed.

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS PHP_CONFIGURE_OPTIONS PKG_CONFIG_PATH LDFLAGS

  # Mock brew: openssl@3 lives under TEST_TEMP_DIR/opt, and every other prefix is the opt directory
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/brew" <<EOF
#!/bin/bash
if [ "\$1" = "--prefix" ] && [ "\$2" = "openssl@3" ]; then
  echo "${TEST_TEMP_DIR}/opt/openssl@3"
elif [ "\$1" = "--prefix" ]; then
  echo "${TEST_TEMP_DIR}/opt"
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/brew"
  export PATH="${TEST_TEMP_DIR}/bin:$PATH"

  sed -n '/^setup_openssl_pin()/,/^}$/p' "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/function.sh"
  source "${TEST_TEMP_DIR}/function.sh"
}

teardown() {
  rm -rf "${TEST_TEMP_DIR}"
}

# Creates the openssl@3 directory the pin looks for
install_fake_openssl3() {
  mkdir -p "${TEST_TEMP_DIR}/opt/openssl@3/lib/pkgconfig"
}

# Links openssl@4 headers into the Homebrew include directory, as Homebrew does for a linked formula
link_openssl4() {
  mkdir -p "${TEST_TEMP_DIR}/opt/openssl@4/include/openssl" "${TEST_TEMP_DIR}/include"
  ln -sfn "../opt/openssl@4/include/openssl" "${TEST_TEMP_DIR}/include/openssl"
}

@test "should point PKG_CONFIG_PATH, LDFLAGS and --with-openssl at openssl@3 on macOS" {
  install_fake_openssl3
  link_openssl4

  setup_openssl_pin

  [[ "${PKG_CONFIG_PATH}" == "${TEST_TEMP_DIR}/opt/openssl@3/lib/pkgconfig"* ]]
  [[ "${LDFLAGS}" == "-L${TEST_TEMP_DIR}/opt/openssl@3/lib"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-openssl=${TEST_TEMP_DIR}/opt/openssl@3"* ]]
}

@test "should put openssl@3 first and keep the existing PKG_CONFIG_PATH and LDFLAGS" {
  install_fake_openssl3
  export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c@78/lib/pkgconfig"
  export LDFLAGS="-L/opt/homebrew/lib"

  setup_openssl_pin

  [ "${PKG_CONFIG_PATH}" = "${TEST_TEMP_DIR}/opt/openssl@3/lib/pkgconfig:/opt/homebrew/opt/icu4c@78/lib/pkgconfig" ]
  [ "${LDFLAGS}" = "-L${TEST_TEMP_DIR}/opt/openssl@3/lib -L/opt/homebrew/lib" ]
}

@test "should leave the build alone when --with-openssl is already configured" {
  install_fake_openssl3
  export PHP_CONFIGURE_OPTIONS="--with-openssl=/custom/openssl"

  setup_openssl_pin

  [ -z "${PHP_BUILD_CONFIGURE_OPTS:-}" ]
  [ -z "${PKG_CONFIG_PATH:-}" ]
  [ -z "${LDFLAGS:-}" ]
}

@test "should leave the build alone when PKG_CONFIG_PATH already starts with an openssl directory" {
  install_fake_openssl3
  export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@4/lib/pkgconfig"

  setup_openssl_pin

  [ "${PKG_CONFIG_PATH}" = "/opt/homebrew/opt/openssl@4/lib/pkgconfig" ]
  [ -z "${PHP_BUILD_CONFIGURE_OPTS:-}" ]
  [ -z "${LDFLAGS:-}" ]
}

@test "should do nothing on Linux" {
  install_fake_openssl3
  export OSTYPE="linux-gnu"

  setup_openssl_pin

  [ -z "${PHP_BUILD_CONFIGURE_OPTS:-}" ]
  [ -z "${LDFLAGS:-}" ]
}

@test "should do nothing when openssl@3 is not installed" {
  setup_openssl_pin

  [ -z "${PHP_BUILD_CONFIGURE_OPTS:-}" ]
  [ -z "${PKG_CONFIG_PATH:-}" ]
}

@test "should do nothing when brew is not installed" {
  install_fake_openssl3
  export PATH="/usr/bin:/bin"

  setup_openssl_pin

  [ -z "${PHP_BUILD_CONFIGURE_OPTS:-}" ]
  [ -z "${PKG_CONFIG_PATH:-}" ]
}

@test "should leave an OpenSSL 1.1 path from check_openssl_compatibility alone" {
  install_fake_openssl3
  export PHP_BUILD_CONFIGURE_OPTS="--with-openssl=/usr/local/openssl-1.1"

  setup_openssl_pin

  [ "${PHP_BUILD_CONFIGURE_OPTS}" = "--with-openssl=/usr/local/openssl-1.1" ]
  [ -z "${PKG_CONFIG_PATH:-}" ]
  [ -z "${LDFLAGS:-}" ]
}

@test "should add --with-openssl only once when the pin runs twice" {
  install_fake_openssl3

  setup_openssl_pin
  setup_openssl_pin

  [ "${PHP_BUILD_CONFIGURE_OPTS}" = "--with-openssl=${TEST_TEMP_DIR}/opt/openssl@3" ]
}
