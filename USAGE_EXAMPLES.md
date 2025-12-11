# Usage Examples for asdf-php

Quick reference for common use cases.

## Basic Installation

```bash
# Install specific version
asdf install php 8.5.0

# Install latest stable
asdf install php latest

# Set global version
asdf global php 8.5.0

# Verify
php --version
composer --version
```

## Install with Xdebug (Automatic)

```bash
# Install PHP with Xdebug in one command
PHP_WITH_XDEBUG=yes asdf install php 8.5.0

# Verify Xdebug is loaded
php -v | grep Xdebug
php -m | grep xdebug
```

## Install without Xdebug (Default)

```bash
# Default behavior - no Xdebug
asdf install php 8.5.0

# Install Xdebug later if needed
pecl install xdebug
echo "zend_extension=xdebug.so" >> $(asdf where php)/conf.d/xdebug.ini
```

## Faster Builds with Parallel Compilation

```bash
# Use all CPU cores
export ASDF_CONCURRENCY=$(nproc)  # Linux
export ASDF_CONCURRENCY=$(sysctl -n hw.ncpu)  # macOS

asdf install php 8.5.0
```

## Custom Build Options

```bash
# Add specific extensions
export PHP_BUILD_CONFIGURE_OPTS="--with-gmp --with-sodium"
asdf install php 8.5.0

# Skip PEAR
export PHP_WITHOUT_PEAR=yes
asdf install php 8.5.0

# Combine options
export PHP_BUILD_CONFIGURE_OPTS="--with-gmp"
export PHP_WITHOUT_PEAR=yes
export ASDF_CONCURRENCY=8
asdf install php 8.5.0
```

## Multiple PHP Versions

```bash
# Install multiple versions
asdf install php 8.5.0
asdf install php 8.3.14
asdf install php 8.2.27

# List installed versions
asdf list php

# Set global version
asdf global php 8.5.0

# Set project-specific version
cd ~/my-project
asdf local php 8.3.14

# Set shell-specific version
asdf shell php 8.2.27
```

## Development Setup

```bash
# Complete development setup
export PHP_WITH_XDEBUG=yes
export ASDF_CONCURRENCY=$(nproc)
asdf install php 8.5.0
asdf global php 8.5.0

# Install common tools
composer global require phpunit/phpunit
composer global require friendsofphp/php-cs-fixer
composer global require vimeo/psalm

# Reshim to make them available
asdf reshim php

# Verify
phpunit --version
php-cs-fixer --version
psalm --version
```

## Production Setup

```bash
# Production setup (no Xdebug, optimized)
export PHP_WITHOUT_PEAR=yes
export ASDF_CONCURRENCY=8
asdf install php 8.5.0
asdf global php 8.5.0

# Configure for production
cat >> $(asdf where php)/conf.d/production.ini << 'EOCONFIG'
memory_limit = 256M
max_execution_time = 30
display_errors = Off
error_reporting = E_ALL & ~E_DEPRECATED
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
EOCONFIG
```

## Clean Build (Fix Corrupted Cache)

```bash
# Remove build cache
rm -rf /tmp/php-build

# Install fresh
asdf install php 8.5.0
```

## Install Specific Extensions

```bash
# Install via PECL
pecl install redis
pecl install imagick
pecl install mongodb

# Enable them
cat >> $(asdf where php)/conf.d/extensions.ini << 'EOCONFIG'
extension=redis.so
extension=imagick.so
extension=mongodb.so
EOCONFIG

# Verify
php -m | grep -E "(redis|imagick|mongodb)"
```

## All-in-One Development Install

Save this as `setup-php-dev.sh`:

```bash
#!/bin/bash
# Complete PHP development setup

# Configuration
PHP_VERSION="8.5.0"
export PHP_WITH_XDEBUG=yes
export ASDF_CONCURRENCY=$(nproc)

# Install PHP
echo "Installing PHP $PHP_VERSION with Xdebug..."
asdf install php $PHP_VERSION
asdf global php $PHP_VERSION

# Install development tools
echo "Installing development tools..."
composer global require phpunit/phpunit
composer global require friendsofphp/php-cs-fixer
composer global require vimeo/psalm
composer global require laravel/installer

# Install common extensions
echo "Installing extensions..."
pecl install redis
pecl install imagick

# Configure
echo "Configuring PHP..."
cat >> $(asdf where php)/conf.d/development.ini << 'EOCONFIG'
memory_limit = 512M
max_execution_time = 300
display_errors = On
error_reporting = E_ALL
extension=redis.so
extension=imagick.so
EOCONFIG

# Reshim
asdf reshim php

# Verify
echo ""
echo "Installation complete!"
php -v
composer --version
phpunit --version
php -m | grep -E "(xdebug|redis|imagick)"
```

Make it executable and run:

```bash
chmod +x setup-php-dev.sh
./setup-php-dev.sh
```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_WITH_XDEBUG` | `no` | Set to `yes` to auto-install Xdebug |
| `PHP_BUILD_XDEBUG_ENABLE` | `off` | php-build's Xdebug plugin (not recommended) |
| `PHP_BUILD_CONFIGURE_OPTS` | - | Custom configure options |
| `PHP_CONFIGURE_OPTIONS` | - | Alternative to PHP_BUILD_CONFIGURE_OPTS |
| `PHP_WITHOUT_PEAR` | `no` | Set to `yes` to skip PEAR |
| `ASDF_CONCURRENCY` | `1` | Number of parallel make jobs |

## Quick Tips

```bash
# Where is PHP installed?
asdf where php

# What version am I using?
asdf current php

# List all available versions
asdf list all php

# List installed versions
asdf list php

# Uninstall a version
asdf uninstall php 8.3.0

# Reshim after installing global packages
asdf reshim php

# View PHP configuration
php --ini
php -i

# Check loaded extensions
php -m

# View PHP info
php -r "phpinfo();"
```

---

## See Also

- [XDEBUG_GUIDE.md](XDEBUG_GUIDE.md) - Complete Xdebug documentation
- [INSTALL_DEPENDENCIES.md](INSTALL_DEPENDENCIES.md) - System dependencies
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [QUICK_START.md](QUICK_START.md) - Quick start guide

---

**Last Updated**: December 2024
**Plugin Version**: refactor-with-php-build