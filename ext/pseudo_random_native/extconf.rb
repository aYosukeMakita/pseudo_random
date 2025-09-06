require 'mkmf'

# Use C++ compiler
$CPPFLAGS += ' -std=c++17'
$CXXFLAGS += ' -std=c++17'

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
$LIBS += ' -lstdc++'

# Create Makefile
create_makefile(extension_name)
