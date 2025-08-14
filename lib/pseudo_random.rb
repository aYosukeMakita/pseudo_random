# frozen_string_literal: true

require_relative 'pseudo_random/version'

module PseudoRandom
  class Error < StandardError; end

  # Internal seed canonicalization & hashing (FNV-1a 64-bit, pure Ruby)
  module Seed
    FNV_OFFSET = 0xcbf29ce484222325
    FNV_PRIME  = 0x100000001b3
    MASK64     = 0xffff_ffff_ffff_ffff

    module_function

    # Public: Convert arbitrary Ruby object to a deterministic 31-bit Integer for Random.new
    def to_seed_int(obj)
      h = FNV_OFFSET
      canonical_each_byte(obj) do |byte|
        h ^= byte
        h = (h * FNV_PRIME) & MASK64
      end
      s = h ^ (h >> 32)
      s & 0x7fff_ffff
    end

    # Depth-first canonical serialization streamed as bytes
    def canonical_each_byte(obj, &blk)
      case obj
      when NilClass
        yield 'n'.ord
      when TrueClass
        yield 't'.ord
      when FalseClass
        yield 'f'.ord
      when Integer
        yield 'i'.ord
        encode_varint(zigzag(obj), &blk)
      when Float
        yield 'd'.ord
        [obj].pack('G').each_byte(&blk) # big-endian IEEE 754
      when String
        str = obj.encode(Encoding::UTF_8)
        yield 's'.ord
        encode_varint(str.bytesize, &blk)
        str.each_byte(&blk)
      when Symbol
        str = obj.to_s.encode(Encoding::UTF_8)
        yield 'y'.ord
        encode_varint(str.bytesize, &blk)
        str.each_byte(&blk)
      when Array
        yield 'a'.ord
        encode_varint(obj.length, &blk)
        obj.each { |e| canonical_each_byte(e, &blk) }
      when Hash
        yield 'h'.ord
        encode_varint(obj.length, &blk)
        # Canonical order by key string representation to avoid insertion order dependence
        obj.keys.map(&:to_s).sort.each do |ks|
          canonical_each_byte(ks, &blk)
          original_key = if obj.key?(ks)
                           ks
                         elsif obj.key?(ks.to_sym)
                           ks.to_sym
                         else
                           # Fallback (should not usually happen)
                           obj.keys.find { |k| k.to_s == ks }
                         end
          canonical_each_byte(obj[original_key], &blk)
        end
      when Time
        yield 'T'.ord
        encode_varint(obj.to_i, &blk)
        encode_varint(obj.nsec, &blk)
      else
        # Fallback: class name + ':' + to_s (could cause collisions if to_s not stable)
        rep = "#{obj.class.name}:#{obj}"
        rep = rep.encode(Encoding::UTF_8)
        yield 'o'.ord
        encode_varint(rep.bytesize, &blk)
        rep.each_byte(&blk)
      end
    end

    # ZigZag encode signed -> unsigned integer
    def zigzag(n)
      n >= 0 ? (n << 1) : ((-n << 1) - 1)
    end

    # Varint (7-bit continuation) encoding
    def encode_varint(num)
      raise ArgumentError, 'negative varint' if num < 0

      loop do
        byte = num & 0x7f
        num >>= 7
        if num.zero?
          yield byte
          break
        else
          yield(byte | 0x80)
        end
      end
    end
  end

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
end
