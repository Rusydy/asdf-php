#!/usr/bin/env bats

# Tests for macOS dependency configuration in the install script

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"
  export ASDF_INSTALL_VERSION="8.5.4"
  export ASDF_INSTALL_PATH="${TEST_TEMP_DIR}/install"

  # Mock brew command for macOS testing
  export MOCK_BREW_PREFIX="/usr/local/opt"
  mkdir -p "${TEST_TEMP_DIR}/bin"
  mkdir -p "/usr/local/opt/bzip2"
  mkdir -p "/usr/local/opt/libiconv"

  cat > "${TEST_TEMP_DIR}/bin/brew" <<'EOF'
#!/bin/bash
if [ "$1" = "--prefix" ]; then
  if [ "$2" = "bzip2" ]; then
    echo "/usr/local/opt/bzip2"
  elif [ "$2" = "libiconv" ]; then
    echo "/usr/local/opt/libiconv"
  else
    echo "/usr/local"
  fi
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/brew"
  export PATH="${TEST_TEMP_DIR}/bin:$PATH"

  # Extract and source the function
  sed -n '/^# Configure macOS-specific dependencies for all PHP versions$/,/^}$/p' "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/function.sh"
  source "${TEST_TEMP_DIR}/function.sh"
}

teardown() {
  rm -rf "${TEST_TEMP_DIR}"
}

@test "should configure bzip2 paths on macOS for PHP 8.5.4" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should configure bzip2 paths on macOS for PHP 8.4.0" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.4.0"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should configure bzip2 paths on macOS for PHP 8.3.0" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.3.0"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should configure libiconv paths on macOS for all PHP versions" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-iconv=/usr/local/opt/libiconv"* ]]
}

@test "should set LDFLAGS on macOS when brew is available" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.5.4"

  [[ "${LDFLAGS}" == *"-L/usr/local/lib"* ]]
}

@test "should set CPPFLAGS on macOS when brew is available" {
  export OSTYPE="darwin23.0"

  setup_macos_dependencies "8.5.4"

  [[ "${CPPFLAGS}" == *"-I/usr/local/include"* ]]
}

@test "should not configure brew dependencies on Linux" {
  export OSTYPE="linux-gnu"

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"--with-bz2=/usr/local"* ]]
}

@test "should handle missing brew command gracefully on macOS" {
  export OSTYPE="darwin23.0"
  export PATH="/usr/bin:/bin"

  setup_macos_dependencies "8.5.4"

  [ $? -eq 0 ]
}

@test "should preserve existing PHP_BUILD_CONFIGURE_OPTS when adding bzip2" {
  export OSTYPE="darwin23.0"
  export PHP_BUILD_CONFIGURE_OPTS="--enable-mbstring --with-curl"

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--enable-mbstring"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-curl"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should preserve existing LDFLAGS when adding brew lib path" {
  export OSTYPE="darwin23.0"
  export LDFLAGS="-L/custom/path"

  setup_macos_dependencies "8.5.4"

  [[ "${LDFLAGS}" == *"-L/custom/path"* ]]
  [[ "${LDFLAGS}" == *"-L/usr/local/lib"* ]]
}

@test "should preserve existing CPPFLAGS when adding brew include path" {
  export OSTYPE="darwin23.0"
  export CPPFLAGS="-I/custom/include"

  setup_macos_dependencies "8.5.4"

  [[ "${CPPFLAGS}" == *"-I/custom/include"* ]]
  [[ "${CPPFLAGS}" == *"-I/usr/local/include"* ]]
}
