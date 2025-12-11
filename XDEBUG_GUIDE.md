# Xdebug Installation Guide for asdf-php

This guide explains how to install and configure Xdebug with asdf-php.

## Why is Xdebug Disabled by Default?

Starting with the php-build integration, **Xdebug is disabled during PHP installation by default** because:

1. **Prevents build failures**: Xdebug compilation can fail on some systems (especially AlmaLinux, RHEL)
2. **Faster builds**: Skipping Xdebug makes PHP installation faster
3. **Not always needed**: Many users don't need Xdebug for production environments
4. **Easy to install later**: You can install Xdebug anytime via PECL

## Installation Options

### Option 1: Automatic Installation (Recommended)

Install PHP with Xdebug in one command:

```bash
PHP_WITH_XDEBUG=yes asdf install php 8.5.0
```

This will:
1. Build PHP successfully
2. Install Xdebug via PECL after PHP is built
3. Configure Xdebug automatically
4. Enable debug mode by default

### Option 2: Manual Installation via PECL

Install PHP first, then add Xdebug:

```bash
# Install PHP without Xdebug
asdf install php 8.5.0

# Install Xdebug via PECL
pecl install xdebug

# Enable Xdebug
echo "zend_extension=xdebug.so" >> $(asdf where php)/conf.d/xdebug.ini

# Verify
php -v | grep Xdebug
```

### Option 3: Use php-build's Xdebug Plugin (Advanced)

Enable php-build's automatic Xdebug installation:

```bash
# This may fail on some systems!
PHP_BUILD_XDEBUG_ENABLE=on asdf install php 8.5.0
```

**Warning**: This uses php-build's built-in Xdebug plugin which may fail with:
```
fatal error: php.h: No such file or directory
```

We recommend Option 1 or 2 instead.

## Configuration

### Basic Xdebug Configuration

After installation, configure Xdebug for your needs:

```bash
# Edit Xdebug config
cat >> $(asdf where php)/conf.d/xdebug.ini << 'EOF'
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=localhost
xdebug.client_port=9003
xdebug.log=/tmp/xdebug.log
EOF
```

### Xdebug Modes

Xdebug 3.x supports different modes:

```ini
# Development mode (step debugging)
xdebug.mode=debug

# Profiling mode
xdebug.mode=profile

# Code coverage mode
xdebug.mode=coverage

# Multiple modes
xdebug.mode=debug,profile

# Disable (for production)
xdebug.mode=off
```

### IDE Configuration

#### VSCode

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/path/to/project": "${workspaceFolder}"
      }
    }
  ]
}
```

#### PhpStorm

1. Go to **Settings → PHP → Debug**
2. Set Xdebug port to `9003`
3. Enable "Can accept external connections"
4. Click "Start Listening for PHP Debug Connections"

## Verification

### Check if Xdebug is Loaded

```bash
# Method 1: Check PHP version output
php -v
# Should show: "with Xdebug v3.x.x"

# Method 2: Check loaded extensions
php -m | grep xdebug

# Method 3: Check phpinfo
php -i | grep xdebug

# Method 4: Get Xdebug info
php -r "xdebug_info();"
```

### Test Xdebug

Create a test file:

```php
<?php
// test_xdebug.php
var_dump(xdebug_info());
```

Run it:

```bash
php test_xdebug.php
```

## Troubleshooting

### Xdebug Not Loaded After Installation

**Check if extension file exists:**
```bash
ls $(asdf where php)/lib/php/extensions/*/xdebug.so
```

**If missing, reinstall:**
```bash
pecl install xdebug
```

**Check configuration:**
```bash
cat $(asdf where php)/conf.d/xdebug.ini
```

**Verify it's enabled:**
```bash
php --ini
php -m | grep xdebug
```

### PECL Install Fails

**Error: `phpize: command not found`**

This shouldn't happen with asdf-php, but if it does:

```bash
# Check PHP installation
asdf where php

# Verify phpize exists
ls -la $(asdf where php)/bin/phpize

# Reshim
asdf reshim php
```

### Xdebug Installed but Not Working

**Check if it's in the right location:**
```bash
php -i | grep "extension_dir"
ls $(php -r "echo ini_get('extension_dir');")/xdebug.so
```

**Check configuration syntax:**
```bash
php --ini
php -r "phpinfo();" | grep xdebug
```

**Enable logging:**
```bash
echo "xdebug.log=/tmp/xdebug.log" >> $(asdf where php)/conf.d/xdebug.ini
php -v
cat /tmp/xdebug.log
```

### Port Already in Use

**Error: Xdebug can't connect to port 9003**

Check what's using the port:
```bash
# Linux
sudo lsof -i :9003

# macOS
lsof -i :9003
```

Change the port:
```bash
echo "xdebug.client_port=9004" >> $(asdf where php)/conf.d/xdebug.ini
```

## Performance Considerations

### Disable Xdebug in Production

Xdebug significantly slows down PHP. Disable it for production:

```bash
# Remove or rename the config file
mv $(asdf where php)/conf.d/xdebug.ini $(asdf where php)/conf.d/xdebug.ini.disabled

# Or set mode to off
echo "xdebug.mode=off" >> $(asdf where php)/conf.d/xdebug.ini
```

### Conditional Xdebug Loading

Only load Xdebug when needed:

```bash
# Create a script to toggle Xdebug
cat > ~/bin/xdebug-toggle << 'EOF'
#!/bin/bash
XDEBUG_INI="$(asdf where php)/conf.d/xdebug.ini"
if [ -f "$XDEBUG_INI" ]; then
  mv "$XDEBUG_INI" "$XDEBUG_INI.disabled"
  echo "Xdebug disabled"
else
  mv "$XDEBUG_INI.disabled" "$XDEBUG_INI"
  echo "Xdebug enabled"
fi
EOF

chmod +x ~/bin/xdebug-toggle

# Use it
xdebug-toggle
```

## Multiple PHP Versions

If you have multiple PHP versions, install Xdebug for each:

```bash
# Install PHP 8.5.0 with Xdebug
PHP_WITH_XDEBUG=yes asdf install php 8.5.0

# Install PHP 8.3.14 with Xdebug
PHP_WITH_XDEBUG=yes asdf install php 8.3.14

# Switch between versions
asdf global php 8.5.0
php -v | grep Xdebug

asdf global php 8.3.14
php -v | grep Xdebug
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_WITH_XDEBUG` | `no` | Set to `yes` to auto-install Xdebug after PHP |
| `PHP_BUILD_XDEBUG_ENABLE` | `off` | php-build's Xdebug plugin (not recommended) |

## Examples

### Install PHP with Xdebug for Development

```bash
# Set environment variables
export PHP_WITH_XDEBUG=yes
export ASDF_CONCURRENCY=$(nproc)

# Install PHP
asdf install php 8.5.0

# Set as global version
asdf global php 8.5.0

# Verify
php -v
composer --version
php -m | grep xdebug
```

### Install PHP without Xdebug for Production

```bash
# Default behavior (Xdebug disabled)
asdf install php 8.5.0

# Or explicitly disable
PHP_WITH_XDEBUG=no asdf install php 8.5.0
```

### Install Xdebug on Already Installed PHP

```bash
# If you already installed PHP without Xdebug
pecl install xdebug

# Configure it
cat >> $(asdf where php)/conf.d/xdebug.ini << 'EOF'
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_port=9003
EOF

# Verify
php -m | grep xdebug
```

## Best Practices

1. **Development**: Install Xdebug with `PHP_WITH_XDEBUG=yes`
2. **Production**: Never install Xdebug (default behavior)
3. **CI/CD**: Install without Xdebug for faster builds
4. **Testing**: Use `xdebug.mode=coverage` for code coverage
5. **Profiling**: Use `xdebug.mode=profile` temporarily, then disable

## Resources

- [Xdebug Documentation](https://xdebug.org/docs/)
- [Xdebug 3 Upgrade Guide](https://xdebug.org/docs/upgrade_guide)
- [VSCode PHP Debug Extension](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug)
- [PhpStorm Xdebug Guide](https://www.jetbrains.com/help/phpstorm/configuring-xdebug.html)

## Support

- **asdf-php issues**: https://github.com/asdf-community/asdf-php/issues
- **Xdebug issues**: https://bugs.xdebug.org/
- **PECL issues**: https://bugs.php.net/

---

**Last Updated**: December 2024  
**Plugin Version**: refactor-with-php-build  
**Xdebug Version**: 3.x