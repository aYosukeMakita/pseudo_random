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

# Check C++17 support
unless have_macro('__cplusplus', 'iostream')
  puts 'Warning: C++ compiler not found. Ruby implementation will be used.'
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
