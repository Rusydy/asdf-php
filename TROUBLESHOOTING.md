# Troubleshooting Guide: asdf-php with php-build

This guide covers common issues you may encounter when using asdf-php with php-build integration.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Build Errors](#build-errors)
- [Extension Issues](#extension-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Debug Information](#debug-information)

---

## Installation Issues

### Issue: php-build command not found

**Error:**
```
/home/dev/.asdf/plugins/php/bin/install: line 40: php-build: command not found
✗ PHP build failed
```

**Cause:** The php-build submodule wasn't initialized when the plugin was installed.

**Solution:**
```bash
# Method 1: Reinitialize the plugin
asdf plugin remove php
asdf plugin add php https://github.com/asdf-community/asdf-php.git

# Method 2: Manually clone php-build
mkdir -p ~/.asdf/plugins/php/vendor
git clone https://github.com/php-build/php-build.git ~/.asdf/plugins/php/vendor/php-build

# Method 3: Initialize submodule
cd ~/.asdf/plugins/php
git submodule update --init --recursive
```

---

### Issue: post-plugin-add hook not running

**Symptom:** php-build isn't automatically initialized after `asdf plugin add`.

**Cause:** The hook file wasn't committed to git or asdf version doesn't support it.

**Solution:**
```bash
# Check asdf version (needs 0.8.0+)
asdf --version

# If version is old, update asdf
asdf update

# Then reinstall plugin
asdf plugin remove php
asdf plugin add php https://github.com/asdf-community/asdf-php.git
```

---

## Build Errors

### Issue: Xdebug build fails with "php.h: No such file or directory"

**Error:**
```
[xdebug]: Compiling xdebug in /tmp/php-build/source/xdebug-3.5.0
fatal error: php.h: No such file or directory
   21 | #include "php.h"
compilation terminated.
```

**Cause:** php-build tries to automatically install Xdebug, but it can't find PHP headers after installation.

**Solution 1: Disable Xdebug auto-install (Recommended)**
```bash
# Disable Xdebug during PHP installation
export PHP_BUILD_XDEBUG_ENABLE=off
asdf install php 8.5.0

# Install Xdebug manually later via PECL
pecl install xdebug
echo "zend_extension=xdebug.so" >> $(asdf where php)/conf.d/xdebug.ini
```

**Solution 2: Disable all php-build plugins**
```bash
# Create custom definition without plugins
export PHP_BUILD_INSTALL_EXTENSION=""
asdf install php 8.5.0
```

**Solution 3: Skip Xdebug specifically**
```bash
# Edit php-build configuration
mkdir -p ~/.php-build
echo "export PHP_BUILD_XDEBUG_ENABLE=off" >> ~/.php-build/default_configure_options
asdf install php 8.5.0
```

---

### Issue: PHP 8.0.0 fails with OpenSSL 3.x compatibility errors

**Error:**
```
warning: passing argument 4 of 'RSA_public_decrypt' discards 'const' qualifier from pointer target type
/usr/include/openssl/rsa.h:300:29: note: expected 'RSA *' but argument is of type 'const struct rsa_st *'
```

**Cause:** PHP 8.0.0 (and other old PHP versions) were built for OpenSSL 1.x. AlmaLinux 10 and other modern distributions use OpenSSL 3.x, which has breaking API changes.

**Solution 1: Use Latest Patch Version (Recommended)**
```bash
# Instead of 8.0.0, use the latest 8.0.x which has OpenSSL 3 support
asdf install php 8.0.30

# Or get latest 8.0 automatically
asdf install php latest:8.0
```

**Solution 2: Use Supported PHP Versions**
```bash
# PHP 8.0 reached End of Life on November 26, 2023
# Use actively supported versions:

asdf install php 8.5.0   # Latest stable
asdf install php 8.3.14  # Active support
asdf install php 8.2.27  # Security fixes only
```

**Why This Happens:**
- PHP 8.0.0 released: December 2020 (OpenSSL 1.x era)
- OpenSSL 3.0 released: September 2021 (breaking changes)
- PHP 8.0.30 released: August 2023 (with OpenSSL 3 fixes)
- AlmaLinux 10 uses: OpenSSL 3.x (incompatible with old PHP)

**PHP Version Support Status:**

| Version | Status | End of Life | Recommendation |
|---------|--------|-------------|----------------|
| PHP 8.5.x | ✅ Active | Nov 2027 | Use for new projects |
| PHP 8.3.x | ✅ Active | Nov 2026 | Current stable |
| PHP 8.2.x | ⚠️ Security | Dec 2025 | Upgrade soon |
| PHP 8.1.x | ⚠️ Security | Nov 2025 | Upgrade soon |
| PHP 8.0.x | ❌ EOL | Nov 2023 | Do not use |
| PHP 7.4.x | ❌ EOL | Nov 2022 | Do not use |

---

### Issue: Cannot find libtidy

**Error:**
```
configure: error: Cannot find libtidy
```

**Solution:**

**AlmaLinux/RHEL/CentOS:**
```bash
sudo yum install -y libtidy-devel
asdf install php 8.5.0
```

**macOS:**
```bash
brew install libtidy-html5
asdf install php 8.5.0
```

**Ubuntu/Debian:**
```bash
sudo apt-get install -y libtidy-dev
asdf install php 8.5.0
```

---

### Issue: Cannot find libzip

**Error:**
```
configure: error: Please reinstall the libzip distribution
```

**Solution:**

**AlmaLinux/RHEL/CentOS:**
```bash
sudo yum install -y libzip-devel
asdf install php 8.5.0
```

**macOS:**
```bash
brew install libzip
asdf install php 8.5.0
```

**Ubuntu/Debian:**
```bash
sudo apt-get install -y libzip-dev
asdf install php 8.5.0
```

---

### Issue: Cannot find openssl

**Error:**
```
configure: error: Cannot find OpenSSL's <evp.h>
```

**Solution:**

**AlmaLinux/RHEL/CentOS:**
```bash
sudo yum install -y openssl-devel
asdf install php 8.5.0
```

**macOS:**
```bash
brew install openssl@1.1
export PKG_CONFIG_PATH="$(brew --prefix openssl@1.1)/lib/pkgconfig:$PKG_CONFIG_PATH"
asdf install php 8.5.0
```

**Ubuntu/Debian:**
```bash
sudo apt-get install -y libssl-dev
asdf install php 8.5.0
```

---

### Issue: bison not found on macOS

**Error:**
```
configure: error: bison is required to build PHP/Zend
```

**Solution:**
```bash
brew install bison
export PATH="$(brew --prefix bison)/bin:$PATH"
asdf install php 8.5.0

# Add to ~/.zshrc or ~/.bash_profile permanently
echo 'export PATH="$(brew --prefix bison)/bin:$PATH"' >> ~/.zshrc
```

---

### Issue: Build takes too long

**Symptom:** PHP compilation is very slow.

**Solution:** Enable parallel compilation
```bash
# Use all CPU cores
export ASDF_CONCURRENCY=$(nproc)  # Linux
export ASDF_CONCURRENCY=$(sysctl -n hw.ncpu)  # macOS

asdf install php 8.5.0
```

---

### Issue: Build fails with "configure: WARNING: unrecognized options"

**Warning:**
```
configure: WARNING: unrecognized options: --with-zlib-dir, --with-gd-native-ttf
```

**Cause:** php-build's default configure options include legacy flags that newer PHP versions don't support.

**Impact:** This is usually just a warning and doesn't cause build failure. You can safely ignore it.

**Solution (if it bothers you):**
```bash
# Create custom definition without legacy options
mkdir -p ~/.php-build/definitions
cat > ~/.php-build/definitions/8.5.0 << 'EOF'
install_package "https://www.php.net/distributions/php-8.5.0.tar.bz2"
configure_option "--with-openssl"
configure_option "--with-curl"
configure_option "--with-zlib"
configure_option "--enable-mbstring"
EOF

asdf install php 8.5.0
```

---

## Extension Issues

### Issue: PECL extension installation fails

**Error:**
```
pecl install redis
ERROR: `phpize' failed
```

**Cause:** PHP development headers not in PATH.

**Solution:**
```bash
# Ensure PHP is in PATH
asdf reshim php

# Try again
pecl install redis

# If still fails, use full path
$(asdf where php)/bin/pecl install redis
```

---

### Issue: Extension installed but not loaded

**Symptom:** Extension appears in `pecl list` but not in `php -m`.

**Solution:**
```bash
# Find where PHP is installed
asdf where php

# Add extension to configuration
echo "extension=redis.so" >> $(asdf where php)/conf.d/php.ini

# Verify
php -m | grep redis
```

---

### Issue: Composer not found after installation

**Symptom:** `composer: command not found` after PHP installation.

**Solution:**
```bash
# Regenerate shims
asdf reshim php

# Verify composer is installed
ls $(asdf where php)/bin/composer

# If missing, reinstall manually
cd $(asdf where php)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=bin --filename=composer
rm composer-setup.php

# Regenerate shims
asdf reshim php

# Verify
composer --version
```

---

## Platform-Specific Issues

### AlmaLinux/RHEL 10

#### Issue: Missing development tools

**Solution:**
```bash
# Install all required build dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y \
  autoconf automake bison gcc gcc-c++ make \
  openssl-devel libcurl-devel libxml2-devel \
  readline-devel libzip-devel oniguruma-devel \
  sqlite-devel bzip2-devel libpng-devel \
  libjpeg-devel libwebp-devel freetype-devel \
  libicu-devel gmp-devel libsodium-devel \
  libtidy-devel libxslt-devel pkg-config re2c
```

#### Issue: SELinux blocking compilation

**Symptom:** Build fails with permission errors.

**Solution:**
```bash
# Temporarily disable SELinux (not recommended for production)
sudo setenforce 0

# Or add proper SELinux context
sudo chcon -R -t bin_t ~/.asdf/installs/php/

# Check SELinux logs
sudo ausearch -m avc -ts recent
```

---

### macOS

#### Issue: Homebrew packages not found

**Symptom:** Configure can't find libraries installed with Homebrew.

**Solution:**
```bash
# Set PKG_CONFIG_PATH for Homebrew libraries
export PKG_CONFIG_PATH="$(brew --prefix)/opt/icu4c/lib/pkgconfig:$(brew --prefix)/opt/krb5/lib/pkgconfig:$(brew --prefix)/opt/libedit/lib/pkgconfig:$(brew --prefix)/opt/libxml2/lib/pkgconfig:$(brew --prefix)/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"

# Add to ~/.zshrc permanently
echo 'export PKG_CONFIG_PATH="$(brew --prefix)/opt/icu4c/lib/pkgconfig:$(brew --prefix)/opt/krb5/lib/pkgconfig:$(brew --prefix)/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.zshrc

# Try installation again
asdf install php 8.5.0
```

#### Issue: Apple Silicon (M1/M2) architecture issues

**Solution:**
```bash
# Ensure Homebrew is for ARM64
which brew  # Should be /opt/homebrew/bin/brew

# If using Rosetta, use x86_64 explicitly
arch -x86_64 asdf install php 8.5.0
```

---

### Ubuntu/Debian

#### Issue: libonig not found

**Error:**
```
configure: error: Package requirements (oniguruma) were not met
```

**Solution:**
```bash
sudo apt-get update
sudo apt-get install -y libonig-dev
asdf install php 8.5.0
```

---

## Debug Information

### View Full Build Log

```bash
# Find the latest build log
ls -lt /tmp/php-build.*.log | head -1

# View it
cat /tmp/php-build.*.log

# Or use less for scrolling
less /tmp/php-build.*.log

# Search for errors
grep -i error /tmp/php-build.*.log
grep -i "cannot find" /tmp/php-build.*.log
```

---

### Enable Verbose Build Output

```bash
# Enable php-build debug mode
export PHP_BUILD_DEBUG=yes
asdf install php 8.5.0

# This will show all build commands
```

---

### Check PHP Installation

```bash
# Where is PHP installed?
asdf where php

# What version is active?
asdf current php

# List all installed versions
asdf list php

# Check PHP info
php -v
php -m  # List loaded extensions
php -i  # Full PHP info
php --ini  # Config file locations
```

---

### Verify Dependencies

**AlmaLinux/RHEL:**
```bash
rpm -qa | grep -E "(openssl-devel|libxml2-devel|libzip-devel|libtidy-devel)"
```

**macOS:**
```bash
brew list | grep -E "(openssl|libxml2|libzip|libtidy)"
```

**Ubuntu/Debian:**
```bash
dpkg -l | grep -E "(libssl-dev|libxml2-dev|libzip-dev|libtidy-dev)"
```

---

### Test PHP Build Manually

```bash
# Test if php-build works directly
~/.asdf/plugins/php/vendor/php-build/bin/php-build --definitions

# List available versions
~/.asdf/plugins/php/vendor/php-build/bin/php-build --definitions | grep 8.5

# Try building to a temporary directory
mkdir -p /tmp/php-test
~/.asdf/plugins/php/vendor/php-build/bin/php-build 8.5.0 /tmp/php-test
```

---

## Common Environment Variables

### Disable Specific Features

```bash
# Skip PEAR
export PHP_WITHOUT_PEAR=yes

# Skip specific configure options
export PHP_BUILD_CONFIGURE_OPTS="--without-pear --without-xdebug"

# Disable all plugins
export PHP_BUILD_INSTALL_EXTENSION=""
```

---

### Enable Debugging

```bash
# Debug php-build
export PHP_BUILD_DEBUG=yes

# Verbose asdf output
export ASDF_FORCE_PREPEND=yes
```

---

## Getting More Help

### Check php-build Documentation

```bash
# View php-build help
~/.asdf/plugins/php/vendor/php-build/bin/php-build --help

# Check available definitions
~/.asdf/plugins/php/vendor/php-build/bin/php-build --definitions
```

---

### Report Issues

**For asdf-php issues:**
- GitHub: https://github.com/asdf-community/asdf-php/issues
- Include: PHP version, OS, error message, build log

**For php-build issues:**
- GitHub: https://github.com/php-build/php-build/issues
- Include: Build log from `/tmp/php-build.*.log`

**For PHP core issues:**
- PHP Bugs: https://bugs.php.net/

---

## Quick Reference: Common Fixes

| Problem | Quick Fix |
|---------|-----------|
| php-build not found | `mkdir -p ~/.asdf/plugins/php/vendor && git clone https://github.com/php-build/php-build.git ~/.asdf/plugins/php/vendor/php-build` |
| Xdebug fails | `export PHP_BUILD_XDEBUG_ENABLE=off` |
| Missing library | Install dev package for your OS |
| Build too slow | `export ASDF_CONCURRENCY=$(nproc)` |
| Composer missing | `asdf reshim php` |
| Extension not loaded | `echo "extension=name.so" >> $(asdf where php)/conf.d/php.ini` |

---

**Last Updated:** December 2024
**Plugin Version:** refactor-with-php-build
**Tested on:** AlmaLinux 10, macOS 14, Ubuntu 22.04
