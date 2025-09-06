# frozen_string_literal: true

module PseudoRandom
  # Internal seed canonicalization & hashing (FNV-1a 64-bit)
  # Uses C++ implementation if available, otherwise pure Ruby
  module Seed
    FNV_OFFSET = 0xcbf29ce484222325
    FNV_PRIME  = 0x100000001b3
    MASK64     = 0xffff_ffff_ffff_ffff

    module_function

    # Public: Convert arbitrary Ruby object to a deterministic 31-bit Integer for Random.new
    def to_seed_int(obj)
      if NATIVE_EXTENSION_LOADED
        # Use C++ implementation for better performance
        PseudoRandom::SeedNative.to_seed_int(obj)
      else
        # Fall back to Ruby implementation
        h = FNV_OFFSET
        canonical_each_byte(obj) do |byte|
          h ^= byte
          h = (h * FNV_PRIME) & MASK64
        end
        s = h ^ (h >> 32)
        s & 0x7fff_ffff
      end
    end

    private

    # Ruby fallback implementations (used when native extension is not available)

    # Depth-first canonical serialization streamed as bytes
    def canonical_each_byte(obj, ...)
      case obj
      when NilClass
        yield 'n'.ord
      when TrueClass
        yield 't'.ord
      when FalseClass
        yield 'f'.ord
      when Integer
        yield 'i'.ord
        encode_varint(zigzag(obj), ...)
      when Float
        yield 'd'.ord
        [obj].pack('G').each_byte(...)
      when String
        str = obj.encode(Encoding::UTF_8)
        yield 's'.ord
        encode_varint(str.bytesize, ...)
        str.each_byte(...)
      when Symbol
        str = obj.to_s.encode(Encoding::UTF_8)
        yield 'y'.ord
        encode_varint(str.bytesize, ...)
        str.each_byte(...)
      when Array
        yield 'a'.ord
        encode_varint(obj.length, ...)
        obj.each { |e| canonical_each_byte(e, ...) }
      when Hash
        yield 'h'.ord
        encode_varint(obj.length, ...)
        # Canonical order by key string representation to avoid insertion order dependence
        obj.keys.map(&:to_s).sort.each do |ks|
          canonical_each_byte(ks, ...)
          original_key = if obj.key?(ks)
                           ks
                         elsif obj.key?(ks.to_sym)
                           ks.to_sym
                         else
                           # Fallback (should not usually happen)
                           obj.keys.find { |k| k.to_s == ks }
                         end
          canonical_each_byte(obj[original_key], ...)
        end
      when Time
        yield 'T'.ord
        encode_varint(obj.to_i, ...)
        encode_varint(obj.nsec, ...)
      else
        # Fallback: class name + ':' + to_s (could cause collisions if to_s not stable)
        rep = "#{obj.class.name}:#{obj}"
        rep = rep.encode(Encoding::UTF_8)
        yield 'o'.ord
        encode_varint(rep.bytesize, ...)
        rep.each_byte(...)
      end
    end

    # ZigZag encode signed -> unsigned integer
    def zigzag(num)
      num >= 0 ? (num << 1) : ((-num << 1) - 1)
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
end
