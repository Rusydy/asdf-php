#!/usr/bin/env bats

# Tests for CXXFLAGS sanitization to prevent old C++ standard flags inherited
# from prior ICU-based PHP installations from blocking the C++17 configure check that
# ext/intl applies once icu-uc >= 74 (PHP 8.1.33+, 8.2.19+, 8.3.7+, 8.4+)

setup() {
  export PLUGIN_DIR="${BATS_TEST_DIRNAME}/.."
  export TEST_TEMP_DIR="$(mktemp -d)"

  # Extract only the target function to avoid executing the rest of the install
  # script which has side effects (php-build setup, version resolution, etc.)
  sed -n '/^sanitize_cxxflags_for_modern_php()/,/^}$/p' \
    "${PLUGIN_DIR}/bin/install" > "${TEST_TEMP_DIR}/function.sh"
  source "${TEST_TEMP_DIR}/function.sh"
}

teardown() {
  unset CXXFLAGS
  rm -rf "${TEST_TEMP_DIR}"
}

@test "should replace -std=c++11 with -std=c++17 for PHP 8.5.4" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
  [[ "${CXXFLAGS}" != *"-std=c++11"* ]]
}

@test "should replace -std=c++14 with -std=c++17 for PHP 8.5.4" {
  export CXXFLAGS="-std=c++14"

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
  [[ "${CXXFLAGS}" != *"-std=c++14"* ]]
}

@test "should preserve -std=c++17 as it already satisfies the C++17 requirement for PHP 8.5.4" {
  export CXXFLAGS="-std=c++17"

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should set -std=c++17 when CXXFLAGS is unset for PHP 8.5.4" {
  unset CXXFLAGS

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should set -std=c++17 when CXXFLAGS is empty for PHP 8.5.4" {
  export CXXFLAGS=""

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should strip -std=c++11 and preserve all other flags matching the exact production failure scenario" {
  # The production failure: old ICU pkg-config sets CXXFLAGS=-std=c++11 -stdlib=libc++
  # -DU_USING_ICU_NAMESPACE=1, which prevents PHP 8.5.4's C++17 configure check from passing
  export CXXFLAGS="-std=c++11 -stdlib=libc++ -DU_USING_ICU_NAMESPACE=1"

  sanitize_cxxflags_for_modern_php "8.5.4"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
  [[ "${CXXFLAGS}" == *"-stdlib=libc++"* ]]
  [[ "${CXXFLAGS}" == *"-DU_USING_ICU_NAMESPACE=1"* ]]
  [[ "${CXXFLAGS}" != *"-std=c++11"* ]]
}

@test "should apply -std=c++17 to PHP 8.4.0, the first 8.4 release with the icu-uc >= 74 check" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.4.0"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
  [[ "${CXXFLAGS}" != *"-std=c++11"* ]]
}

@test "should leave PHP 8.3.6 alone and apply -std=c++17 from PHP 8.3.7" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.3.6"
  [[ "${CXXFLAGS}" == "-std=c++11" ]]

  sanitize_cxxflags_for_modern_php "8.3.7"
  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should leave PHP 8.2.18 alone and apply -std=c++17 from PHP 8.2.19" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.2.18"
  [[ "${CXXFLAGS}" == "-std=c++11" ]]

  sanitize_cxxflags_for_modern_php "8.2.19"
  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should leave PHP 8.1.32 alone and apply -std=c++17 from PHP 8.1.33" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.1.32"
  [[ "${CXXFLAGS}" == "-std=c++11" ]]

  sanitize_cxxflags_for_modern_php "8.1.33"
  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
}

@test "should not modify CXXFLAGS for PHP 8.0.30 because its ext/intl still hardcodes C++11" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "8.0.30"

  [[ "${CXXFLAGS}" == "-std=c++11" ]]
}

@test "should not modify CXXFLAGS for PHP 7.4.x because it does not require C++17" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "7.4.33"

  [[ "${CXXFLAGS}" == "-std=c++11" ]]
}

@test "should apply to PHP 9.x to guard against future major versions that also require C++17 or higher" {
  export CXXFLAGS="-std=c++11"

  sanitize_cxxflags_for_modern_php "9.0.0"

  [[ "${CXXFLAGS}" == *"-std=c++17"* ]]
  [[ "${CXXFLAGS}" != *"-std=c++11"* ]]
}
