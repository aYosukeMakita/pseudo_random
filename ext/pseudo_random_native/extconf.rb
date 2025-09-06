require 'mkmf'

# Use C++ compiler
$CPPFLAGS += ' -std=c++17'

# Extension name
extension_name = 'pseudo_random_native'

# Source file specification
$srcs = ['pseudo_random_native.cpp']

# Add debug information (for development)
# $CPPFLAGS += " -g -O0"

# Release optimization
$CPPFLAGS += ' -O3 -DNDEBUG'

# Compiler warning level
$CPPFLAGS += ' -Wall -Wextra'

# Link C++ standard library
have_library('stdc++')

# Check C++17 support using try_compile
cxx17_test = <<~CPP
  #include <optional>
  int main() {
    std::optional<int> x = 42;
    return x.value_or(0);
  }
CPP
unless try_compile('C++17 support', cxx17_test, '-std=c++17')
  puts 'Warning: C++17 compiler not found. Ruby implementation will be used.'
  makefile_content = <<~MAKEFILE
    all:
    	echo 'Skipping C++ extension compilation'

    install:
    	echo 'C++ extension not available'

    clean:
    	echo 'Nothing to clean'
  MAKEFILE
  File.write('Makefile', makefile_content)
  exit 0
end

# Create Makefile
create_makefile(extension_name)
