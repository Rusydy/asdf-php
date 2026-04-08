#!/usr/bin/env bats

# Integration tests for PHP installation with real-world scenarios

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"
  export ASDF_INSTALL_VERSION="8.5.4"
  export ASDF_INSTALL_PATH="${TEST_TEMP_DIR}/install"

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

  sed -n '/^# Configure macOS-specific dependencies for all PHP versions$/,/^}$/p' "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/function.sh"
  source "${TEST_TEMP_DIR}/function.sh"
}

teardown() {
  rm -rf "${TEST_TEMP_DIR}"
}

@test "PHP 8.5.4 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 8.4.3 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.4.3"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 8.3.15 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.3.15"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 8.2.28 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.2.28"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 8.1.31 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.1.31"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 8.0.30 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.0.30"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "PHP 7.4.33 installation should include bzip2 configuration on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "7.4.33"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "configuration should include both LDFLAGS and CPPFLAGS for Homebrew libraries" {
  export OSTYPE="darwin23.0"
  unset LDFLAGS
  unset CPPFLAGS

  setup_macos_dependencies "8.5.4"

  [[ "${LDFLAGS}" == *"-L/usr/local/lib"* ]]
  [[ "${CPPFLAGS}" == *"-I/usr/local/include"* ]]
}

@test "should configure both bzip2 and libiconv on macOS" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-iconv=/usr/local/opt/libiconv"* ]]
}

@test "should not configure brew paths on Linux" {
  export OSTYPE="linux-gnu"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.5.4"

  [[ -z "${PHP_BUILD_CONFIGURE_OPTS}" ]] || [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"--with-bz2="* ]]
}

@test "should not fail when brew is not available on macOS" {
  export OSTYPE="darwin23.0"
  export PATH="/usr/bin:/bin"
  unset PHP_BUILD_CONFIGURE_OPTS

  run setup_macos_dependencies "8.5.4"

  [ "$status" -eq 0 ]
}

@test "should append to existing configuration options" {
  export OSTYPE="darwin23.0"
  export PHP_BUILD_CONFIGURE_OPTS="--enable-mbstring --with-curl"

  setup_macos_dependencies "8.5.4"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--enable-mbstring"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-curl"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-iconv=/usr/local/opt/libiconv"* ]]
}

@test "should append to existing LDFLAGS" {
  export OSTYPE="darwin23.0"
  export LDFLAGS="-L/custom/lib -lz"

  setup_macos_dependencies "8.5.4"

  [[ "${LDFLAGS}" == *"-L/custom/lib"* ]]
  [[ "${LDFLAGS}" == *"-lz"* ]]
  [[ "${LDFLAGS}" == *"-L/usr/local/lib"* ]]
}

@test "should append to existing CPPFLAGS" {
  export OSTYPE="darwin23.0"
  export CPPFLAGS="-I/custom/include -DCUSTOM_FLAG"

  setup_macos_dependencies "8.5.4"

  [[ "${CPPFLAGS}" == *"-I/custom/include"* ]]
  [[ "${CPPFLAGS}" == *"-DCUSTOM_FLAG"* ]]
  [[ "${CPPFLAGS}" == *"-I/usr/local/include"* ]]
}

@test "should skip bzip2 configuration if directory does not exist" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  rm -rf "/usr/local/opt/bzip2"

  setup_macos_dependencies "8.5.4"

  [[ -z "${PHP_BUILD_CONFIGURE_OPTS}" ]] || [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"--with-bz2="* ]]
}

@test "should skip libiconv configuration if directory does not exist" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  rm -rf "/usr/local/opt/libiconv"

  setup_macos_dependencies "8.5.4"

  [[ -z "${PHP_BUILD_CONFIGURE_OPTS}" ]] || [[ "${PHP_BUILD_CONFIGURE_OPTS}" != *"--with-iconv="* ]]
}

@test "should handle version with RC suffix" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.5.0RC1"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should handle version with beta suffix" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.5.0beta2"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}

@test "should handle version with alpha suffix" {
  export OSTYPE="darwin23.0"
  unset PHP_BUILD_CONFIGURE_OPTS

  setup_macos_dependencies "8.6.0alpha1"

  [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2=/usr/local/opt/bzip2"* ]]
}
