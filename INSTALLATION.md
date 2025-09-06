# Gem Installation and Usage

## Installation

### Standard Installation (with C++ Extension)

```bash
# Prepare development environment (first time only)
# Ubuntu/Debian:
sudo apt-get install build-essential ruby-dev

# CentOS/RHEL:
sudo yum install gcc-c++ ruby-devel

# macOS:
xcode-select --install

# Install the gem
gem install pseudo_random
# or
bundle add pseudo_random
```

### Troubleshooting

If C++ extension compilation fails:

1. **When compilation errors occur**:

   ```bash
   # Display detailed error information
   gem install pseudo_random --verbose
   ```

2. **Avoiding environment-dependent issues**:
   ```bash
   # Install with Ruby implementation only (reduced performance)
   PSEUDO_RANDOM_DISABLE_NATIVE=1 gem install pseudo_random
   ```

## Usage

```ruby
require 'pseudo_random'

# Basic usage (C++ extension is used automatically)
generator = PseudoRandom.new("my_seed")
puts generator.rand           # => 0.123456789
puts generator.hex(8)         # => "1a2b3c4d"
puts generator.alphabetic(10) # => "AbCdEfGhIj"

# Arrays and hashes can also be used as seeds
complex_seed = { user: "alice", timestamp: 1234567890 }
generator2 = PseudoRandom.new(complex_seed)
puts generator2.rand
```

## Performance

- **With C++ extension**: High speed (20-50x faster than Ruby implementation)
- **Ruby implementation only**: Standard speed

When the C++ extension is not available, it automatically falls back to the Ruby implementation,
ensuring it works in any environment.

## Compatibility

- Ruby 3.1.0 or higher
- C++17 compatible compiler (only when using C++ extension)
- Linux, macOS, Windows supported
