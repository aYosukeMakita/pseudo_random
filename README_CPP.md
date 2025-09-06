# Performance Enhancement with C++ Extension

## Overview

The PseudoRandom library includes a C++ native extension for the Seed module. This extension can significantly improve the performance of seed calculations.

## Performance Improvements

Benchmark results show the following performance improvements with the C++ extension:

- **5-20x speedup** (depending on data complexity)
- **Reduced memory usage**
- **Optimized CPU cost**

## Installation and Usage

### 1. Development Environment Setup

#### Ubuntu/Debian:

```bash
sudo apt-get install build-essential ruby-dev
```

#### CentOS/RHEL:

```bash
sudo yum install gcc-c++ ruby-devel
# or
sudo dnf install gcc-c++ ruby-devel
```

#### macOS:

```bash
# Xcode Command Line Tools required
xcode-select --install
```

### 2. Building the C++ Extension

```bash
# Automatic build (recommended)
rake compile

# or manual build
cd ext/pseudo_random_native
ruby extconf.rb
make
```

### 3. Usage

```ruby
require 'pseudo_random'

# C++ extension is automatically used when available
generator = PseudoRandom.new("my_seed")
puts generator.rand
```

### 4. Fallback

In environments where the C++ extension cannot be built, it automatically falls back to the Ruby implementation:

```ruby
# Ruby implementation is automatically used when C++ extension is unavailable
generator = PseudoRandom.new("my_seed")
puts generator.rand
```

## Technical Details

### C++ Implementation Features

1. **FNV-1a 64-bit hash**: Same algorithm as Ruby implementation
2. **Optimized memory management**: Vector-based byte arrays
3. **Type safety**: Leveraging C++ type system
4. **Error handling**: Integration with Ruby exceptions

### Compatibility

- **Full backward compatibility**: Guarantees same results as Ruby implementation
- **Automatic switching**: Auto-detection of extension availability
- **Debug support**: Ruby implementation also available in parallel

### Supported Platforms

- Linux (x86_64, ARM64)
- macOS (x86_64, ARM64/M1)
- Windows (MinGW, Visual Studio)

## Troubleshooting

### Build Errors

1. **Compiler not found**:

   ```bash
   # Ubuntu/Debian
   sudo apt-get install build-essential

   # CentOS/RHEL
   sudo yum install gcc-c++
   ```

2. **Ruby development headers not found**:

   ```bash
   # Ubuntu/Debian
   sudo apt-get install ruby-dev

   # CentOS/RHEL
   sudo yum install ruby-devel
   ```

3. **Manual cleanup**:
   ```bash
   rake clean
   rake compile
   ```

### Runtime Errors

If problems occur with the C++ extension, you can force the use of pure Ruby implementation:

```ruby
# Use Ruby implementation directly
result = PseudoRandom::SeedRuby.to_seed_int(my_data)

# or control with environment variable
ENV['PSEUDO_RANDOM_DISABLE_NATIVE'] = '1'
require 'pseudo_random'
```

## Developer Information

### Source File Structure

```
ext/pseudo_random_native/
├── pseudo_random_native.cpp  # Main C++ implementation
├── extconf.rb                # Build configuration
└── Makefile                  # Generated Makefile

lib/
├── pseudo_random.rb          # Original Ruby implementation
└── pseudo_random_native.rb   # C++ extension wrapper
```

### Debug Build

```bash
# Build with debug information
CPPFLAGS="-g -O0" rake compile
```

### Profiling

```ruby
require 'ruby-prof'

RubyProf.start
1000.times { PseudoRandom::Seed.to_seed_int("test") }
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```
