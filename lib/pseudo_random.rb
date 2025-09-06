# frozen_string_literal: true

require_relative 'pseudo_random/version'
require_relative 'pseudo_random/seed'

# Try to load native C++ extension first, fall back to Ruby implementation
begin
  require 'pseudo_random_native'
  NATIVE_EXTENSION_LOADED = true
rescue LoadError
  NATIVE_EXTENSION_LOADED = false
end

module PseudoRandom
  class Error < StandardError; end

  class Generator
    # Character set for alphabetic generation: A-Z (26) + a-z (26) = 52 characters
    ALPHABETIC_CHARS = ('A'..'Z').to_a + ('a'..'z').to_a
    # Character set for alphanumeric generation: A-Z (26) + a-z (26) + 0-9 (10) = 62 characters
    ALPHANUMERIC_CHARS = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a

    def initialize(seed = nil)
      @random = Random.new(normalize_seed(seed))
    end

    # Generates the next pseudo-random number in the sequence
    # If max is provided, returns a value between 0 and max-1 (or 0.0 to max for floats)
    # If a Range is provided, returns a value within that range
    # If no arguments, returns a float between 0.0 and 1.0 (like Ruby's Kernel.#rand)
    def rand(max = nil)
      if max.nil?
        @random.rand # Returns float between 0.0 and 1.0
      else
        @random.rand(max)
      end
    end

    # Generates a hexadecimal string with the specified number of characters
    # @param length [Integer] the number of hexadecimal characters to generate (must be >= 0)
    # @return [String] a hexadecimal string with lowercase a-f
    def hex(length)
      raise ArgumentError, 'Length must be a non-negative integer' unless length.is_a?(Integer) && length >= 0

      return '' if length == 0

      result = ''
      remaining = length

      # Process 8 characters at a time for efficiency (32-bit random number = 8 hex chars)
      while remaining >= 8
        # Generate a 32-bit random number and convert to 8-character hex string
        random_value = @random.rand(2**32)
        hex_chunk = format('%08x', random_value)
        result += hex_chunk
        remaining -= 8
      end

      # Process remaining characters (1-7) by generating 8 chars and taking what we need
      if remaining > 0
        random_value = @random.rand(2**32)
        hex_chunk = format('%08x', random_value)
        result += hex_chunk[0, remaining] # Take only the first 'remaining' characters
      end

      result
    end

    # Generates an alphabetic string with the specified number of characters
    # @param length [Integer] the number of alphabetic characters to generate (must be >= 0)
    # @return [String] a string containing uppercase letters (A-Z) and lowercase letters (a-z)
    def alphabetic(length)
      raise ArgumentError, 'Length must be a non-negative integer' unless length.is_a?(Integer) && length >= 0

      return '' if length == 0

      result = ''
      remaining = length

      # Process multiple characters at once for efficiency
      # We can generate about 3 characters from a 32-bit random number (52^3 = 140,608 < 2^32)
      chunk_size = 3

      while remaining >= chunk_size
        # Generate a random number and convert to base-52 representation
        random_value = @random.rand(52**chunk_size)
        chunk = ''

        chunk_size.times do
          chunk = ALPHABETIC_CHARS[random_value % 52] + chunk
          random_value /= 52
        end

        result += chunk
        remaining -= chunk_size
      end

      # Process remaining characters (1-2)
      if remaining > 0
        random_value = @random.rand(52**remaining)
        chunk = ''

        remaining.times do
          chunk = ALPHABETIC_CHARS[random_value % 52] + chunk
          random_value /= 52
        end

        result += chunk
      end

      result
    end

    # Generates an alphanumeric string with the specified number of characters
    # @param length [Integer] the number of alphanumeric characters to generate (must be >= 0)
    # @return [String] a string containing uppercase letters (A-Z), lowercase letters (a-z), and digits (0-9)
    def alphanumeric(length)
      raise ArgumentError, 'Length must be a non-negative integer' unless length.is_a?(Integer) && length >= 0

      return '' if length == 0

      result = ''
      remaining = length

      # Process multiple characters at once for efficiency
      # We can generate about 5 characters from a 32-bit random number (62^5 = 916,132,832 < 2^32)
      chunk_size = 5

      while remaining >= chunk_size
        # Generate a random number and convert to base-62 representation
        random_value = @random.rand(62**chunk_size)
        chunk = ''

        chunk_size.times do
          chunk = ALPHANUMERIC_CHARS[random_value % 62] + chunk
          random_value /= 62
        end

        result += chunk
        remaining -= chunk_size
      end

      # Process remaining characters (1-4)
      if remaining > 0
        random_value = @random.rand(62**remaining)
        chunk = ''

        remaining.times do
          chunk = ALPHANUMERIC_CHARS[random_value % 62] + chunk
          random_value /= 62
        end

        result += chunk
      end

      result
    end

    private

    # Deterministic, process-independent reduction of arbitrary object to Integer seed.
    def normalize_seed(seed)
      Seed.to_seed_int(seed)
    end
  end

  # Creates a new generator with the given seed
  def self.new(seed = nil)
    Generator.new(seed)
  end

  # Generates a single pseudo-random number based on the given seed (backward compatibility)
  def self.rand(seed)
    generator = new(seed)
    generator.rand
  end

  # Returns true if native C++ extension is loaded and available
  def self.native_extension_loaded?
    NATIVE_EXTENSION_LOADED
  end
end
