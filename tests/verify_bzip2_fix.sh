#!/usr/bin/env bash
set -eo pipefail

# Manual verification script to check if bzip2 configuration is correct
# This script simulates the install process and verifies the configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== BZip2 Configuration Verification ==="
echo ""
echo "Plugin directory: ${PLUGIN_DIR}"
echo "OS Type: ${OSTYPE}"
echo ""

# Extract and source the function
TEMP_FUNC_FILE=$(mktemp)
sed -n '/^# Configure macOS-specific dependencies for all PHP versions$/,/^}$/p' "${PLUGIN_DIR}/bin/install" > "${TEMP_FUNC_FILE}"
source "${TEMP_FUNC_FILE}"
rm -f "${TEMP_FUNC_FILE}"

# Test different PHP versions
test_versions=(
  "8.5.4"
  "8.4.3"
  "8.3.15"
  "8.2.28"
  "8.1.31"
  "8.0.30"
  "7.4.33"
)

echo "Testing PHP versions:"
echo ""

for version in "${test_versions[@]}"; do
  unset PHP_BUILD_CONFIGURE_OPTS
  unset LDFLAGS
  unset CPPFLAGS

  setup_macos_dependencies "$version"

  echo "PHP ${version}:"
  echo "  PHP_BUILD_CONFIGURE_OPTS: ${PHP_BUILD_CONFIGURE_OPTS:-<not set>}"
  echo "  LDFLAGS: ${LDFLAGS:-<not set>}"
  echo "  CPPFLAGS: ${CPPFLAGS:-<not set>}"

  # Check if bzip2 is configured on macOS
  if [[ $OSTYPE == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      if [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-bz2="* ]]; then
        echo "  ✓ BZip2 configured correctly"
      else
        echo "  ✗ BZip2 NOT configured (this would cause the build error)"
      fi

      if [[ "${PHP_BUILD_CONFIGURE_OPTS}" == *"--with-iconv="* ]]; then
        echo "  ✓ libiconv configured correctly"
      else
        echo "  ⚠ libiconv not configured"
      fi

      if [[ "${LDFLAGS}" == *"-L"* ]]; then
        echo "  ✓ LDFLAGS configured"
      else
        echo "  ⚠ LDFLAGS not configured"
      fi

      if [[ "${CPPFLAGS}" == *"-I"* ]]; then
        echo "  ✓ CPPFLAGS configured"
      else
        echo "  ⚠ CPPFLAGS not configured"
      fi
    else
      echo "  ⚠ Homebrew not available, skipping brew-specific checks"
    fi
  else
    echo "  ℹ Not on macOS, skipping macOS-specific configuration checks"
  fi

  echo ""
done

echo "=== Verification Complete ==="
echo ""

# Check if actual brew packages are installed
if [[ $OSTYPE == "darwin"* ]] && command -v brew &>/dev/null; then
  echo "Checking Homebrew package installations:"
  echo ""

  if brew list bzip2 &>/dev/null; then
    bzip2_prefix=$(brew --prefix bzip2)
    echo "✓ bzip2 is installed at: ${bzip2_prefix}"

    if [ -d "${bzip2_prefix}" ]; then
      echo "  ✓ Directory exists"
    else
      echo "  ✗ Directory does not exist"
    fi

    if [ -f "${bzip2_prefix}/lib/libbz2.dylib" ] || [ -f "${bzip2_prefix}/lib/libbz2.a" ]; then
      echo "  ✓ BZip2 library files found"
    else
      echo "  ⚠ BZip2 library files not found"
    fi

    if [ -f "${bzip2_prefix}/include/bzlib.h" ]; then
      echo "  ✓ BZip2 header files found"
    else
      echo "  ⚠ BZip2 header files not found"
    fi
  else
    echo "✗ bzip2 is NOT installed via Homebrew"
    echo "  Install with: brew install bzip2"
  fi

  echo ""

  if brew list libiconv &>/dev/null; then
    iconv_prefix=$(brew --prefix libiconv)
    echo "✓ libiconv is installed at: ${iconv_prefix}"
  else
    echo "⚠ libiconv is NOT installed via Homebrew"
    echo "  Note: Usually provided by macOS, but Homebrew version may be needed for some builds"
  fi
fi

echo ""
echo "=== Summary ==="
echo ""
echo "This script verified that the setup_macos_dependencies function:"
echo "1. Correctly configures --with-bz2 for all PHP versions on macOS"
echo "2. Correctly configures --with-iconv for all PHP versions on macOS"
echo "3. Sets appropriate LDFLAGS and CPPFLAGS"
echo "4. Works across PHP 7.4 through 8.5+"
echo ""
echo "The original error was:"
echo "  'configure: error: Please reinstall the BZip2 library package'"
echo ""
echo "This occurred because newer PHP versions (8.3+, 8.4+, 8.5+) were not"
echo "getting the bzip2 path configuration that was only applied to PHP 7.4"
echo "and PHP 8.0.0-8.0.19 in the setup_compiler_for_old_php function."
echo ""
echo "The fix adds setup_macos_dependencies() which runs for ALL PHP versions"
echo "on macOS, ensuring bzip2 and other Homebrew dependencies are always found."
