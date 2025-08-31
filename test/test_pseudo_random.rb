# frozen_string_literal: true

require 'test_helper'
require 'date'

# rubocop:disable Metrics/ClassLength

class TestPseudoRandom < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PseudoRandom::VERSION
  end

  def test_integer_seed
    generator = PseudoRandom::Generator.new(42)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_string_seed
    generator = PseudoRandom::Generator.new('hello')
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_float_seed
    generator = PseudoRandom::Generator.new(3.14)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_boolean_seed_true
    generator = PseudoRandom::Generator.new(true)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_boolean_seed_false
    generator = PseudoRandom::Generator.new(false)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_hash_seed
    generator = PseudoRandom::Generator.new({ a: 1, b: 2 })
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_array_seed
    generator = PseudoRandom::Generator.new([1, 2, 3])
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_datetime_seed
    generator = PseudoRandom::Generator.new(DateTime.now)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_date_seed
    generator = PseudoRandom::Generator.new(Date.today)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_time_seed
    generator = PseudoRandom::Generator.new(Time.now)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_symbol_seed
    generator = PseudoRandom::Generator.new(:test_symbol)
    result = generator.rand
    assert result.is_a?(Float)
    assert result >= 0.0 && result < 1.0
  end

  def test_same_seed_same_result
    # Verify that the same seed produces the same sequence of results
    generator1 = PseudoRandom::Generator.new('test')
    generator2 = PseudoRandom::Generator.new('test')

    100.times do
      assert_equal generator1.rand, generator2.rand
    end
  end

  def test_nil_seed_same_result
    # Verify that nil seed yields a consistent deterministic sequence
    # Even with nil, a deterministic derived seed is used so sequences match across instances
    generator1 = PseudoRandom::Generator.new(nil)
    generator2 = PseudoRandom::Generator.new(nil)

    # 複数回実行して同じ結果が返されることを確認
    100.times do
      assert_equal generator1.rand, generator2.rand, 'nil seed should produce consistent results'
    end
  end

  def test_rand_with_integer
    # rand(10) should return integers in [0, 10)
    generator = PseudoRandom::Generator.new(42)

    100.times do
      result = generator.rand(10)
      assert result.is_a?(Integer), "Expected Integer, got #{result.class}"
      assert result >= 0, "Expected result >= 0, got #{result}"
      assert result < 10, "Expected result < 10, got #{result}"
    end
  end

  def test_rand_with_float
    # rand(10.0) should return floats in [0.0, 10.0)
    generator = PseudoRandom::Generator.new(42)

    100.times do
      result = generator.rand(10.0)
      assert result.is_a?(Float), "Expected Float, got #{result.class}"
      assert result >= 0.0, "Expected result >= 0.0, got #{result}"
      assert result < 10.0, "Expected result < 10.0, got #{result}"
    end
  end

  def test_hex_with_length_10
    # hex(10) should return a 10-character lowercase hexadecimal string
    generator = PseudoRandom::Generator.new(42)

    result = generator.hex(10)
    assert result.is_a?(String), "Expected String, got #{result.class}"
    assert_equal 10, result.length, "Expected length 10, got #{result.length}"
    assert_match(/\A[0-9a-f]{10}\z/, result, "Expected hexadecimal string (lowercase), got #{result}")
  end

  def test_hex_with_length_0
    generator = PseudoRandom::Generator.new(42)
    result = generator.hex(0)
    assert_equal '', result
  end

  def test_hex_with_length_1
    generator = PseudoRandom::Generator.new(42)
    result = generator.hex(1)
    assert_equal 1, result.length
    assert_match(/\A[0-9a-f]\z/, result)
  end

  def test_hex_with_large_length
    generator = PseudoRandom::Generator.new(42)
    len = 100
    result = generator.hex(len)
    assert_equal len, result.length
    assert_match(/\A[0-9a-f]{100}\z/, result)
  end

  def test_hex_deterministic
    g1 = PseudoRandom::Generator.new('hex_seed')
    g2 = PseudoRandom::Generator.new('hex_seed')
    assert_equal g1.hex(32), g2.hex(32)
  end

  def test_hex_different_seeds
    g1 = PseudoRandom::Generator.new('hex_seed1')
    g2 = PseudoRandom::Generator.new('hex_seed2')
    refute_equal g1.hex(32), g2.hex(32)
  end

  def test_alphanumeric_with_length_10
    # alphanumeric(10) should return a 10-character alphanumeric string
    generator = PseudoRandom::Generator.new(42)

    result = generator.alphanumeric(10)
    assert result.is_a?(String), "Expected String, got #{result.class}"
    assert_equal 10, result.length, "Expected length 10, got #{result.length}"
    assert_match(/\A[A-Za-z0-9]{10}\z/, result, "Expected alphanumeric string, got #{result}")
  end

  def test_alphanumeric_with_length_0
    # When length is 0 it should return an empty string
    generator = PseudoRandom::Generator.new(42)

    result = generator.alphanumeric(0)
    assert result.is_a?(String), "Expected String, got #{result.class}"
    assert_equal 0, result.length, "Expected empty string, got #{result}"
    assert_equal '', result, "Expected empty string, got #{result}"
  end

  def test_alphanumeric_with_length_1
    # When length is 1 it should return a single alphanumeric character
    generator = PseudoRandom::Generator.new(42)

    result = generator.alphanumeric(1)
    assert result.is_a?(String), "Expected String, got #{result.class}"
    assert_equal 1, result.length, "Expected length 1, got #{result.length}"
    assert_match(/\A[A-Za-z0-9]\z/, result, "Expected single alphanumeric character, got #{result}")
  end

  def test_alphanumeric_with_large_length
    # Works correctly with a large length
    generator = PseudoRandom::Generator.new(42)

    result = generator.alphanumeric(100)
    assert result.is_a?(String), "Expected String, got #{result.class}"
    assert_equal 100, result.length, "Expected length 100, got #{result.length}"
    assert_match(/\A[A-Za-z0-9]{100}\z/, result, "Expected alphanumeric string, got #{result}")
  end

  def test_alphanumeric_character_distribution
    # Ensure the character set covers uppercase, lowercase, and digits
    generator = PseudoRandom::Generator.new(42)

    # Generate a sufficiently long string to observe all character classes
    result = generator.alphanumeric(1000)

    has_uppercase = result.match?(/[A-Z]/)
    has_lowercase = result.match?(/[a-z]/)
    has_digits = result.match?(/[0-9]/)

    assert has_uppercase, 'Expected uppercase letters in result'
    assert has_lowercase, 'Expected lowercase letters in result'
    assert has_digits, 'Expected digits in result'
  end

  def test_alphanumeric_with_invalid_length_negative
    # Negative length should raise ArgumentError
    generator = PseudoRandom::Generator.new(42)

    error = assert_raises(ArgumentError) do
      generator.alphanumeric(-1)
    end
    assert_equal 'Length must be a non-negative integer', error.message
  end

  def test_alphanumeric_with_invalid_length_non_integer
    # Non-integer length should raise ArgumentError
    generator = PseudoRandom::Generator.new(42)

    error = assert_raises(ArgumentError) do
      generator.alphanumeric(10.5)
    end
    assert_equal 'Length must be a non-negative integer', error.message
  end

  def test_alphanumeric_deterministic
    # Same seed should produce identical alphanumeric output
    generator1 = PseudoRandom::Generator.new('test_seed')
    generator2 = PseudoRandom::Generator.new('test_seed')

    result1 = generator1.alphanumeric(20)
    result2 = generator2.alphanumeric(20)

    assert_equal result1, result2, 'Same seed should produce same alphanumeric result'
  end

  def test_alphanumeric_different_seeds_different_results
    # Different seeds should produce different alphanumeric output
    generator1 = PseudoRandom::Generator.new('seed1')
    generator2 = PseudoRandom::Generator.new('seed2')

    result1 = generator1.alphanumeric(20)
    result2 = generator2.alphanumeric(20)

    refute_equal result1, result2, 'Different seeds should produce different results'
  end

  # --- alphabetic ---
  def test_alphabetic_with_length_0
    generator = PseudoRandom::Generator.new(42)
    result = generator.alphabetic(0)
    assert_equal '', result
  end

  def test_alphabetic_with_length_1
    generator = PseudoRandom::Generator.new(42)
    result = generator.alphabetic(1)
    assert_equal 1, result.length
    assert_match(/\A[A-Za-z]\z/, result)
  end

  def test_alphabetic_with_large_length
    generator = PseudoRandom::Generator.new(42)
    result = generator.alphabetic(100)
    assert_equal 100, result.length
    assert_match(/\A[A-Za-z]{100}\z/, result)
  end

  def test_alphabetic_deterministic
    g1 = PseudoRandom::Generator.new('alpha_seed')
    g2 = PseudoRandom::Generator.new('alpha_seed')
    assert_equal g1.alphabetic(50), g2.alphabetic(50)
  end

  def test_alphabetic_different_seeds
    g1 = PseudoRandom::Generator.new('alpha_seed1')
    g2 = PseudoRandom::Generator.new('alpha_seed2')
    refute_equal g1.alphabetic(50), g2.alphabetic(50)
  end

  # --- rand(range) ---
  def test_rand_with_inclusive_integer_range
    generator = PseudoRandom::Generator.new(42)
    200.times do
      v = generator.rand(1..6)
      assert v.is_a?(Integer)
      assert v.between?(1, 6), "Expected 1..6 got #{v}"
    end
  end

  def test_rand_range_deterministic
    g1 = PseudoRandom::Generator.new('range_seed')
    g2 = PseudoRandom::Generator.new('range_seed')
    seq1 = Array.new(20) { g1.rand(1..6) }
    seq2 = Array.new(20) { g2.rand(1..6) }
    assert_equal seq1, seq2
  end

  def test_rand_range_different_seeds
    g1 = PseudoRandom::Generator.new('range_seed1')
    g2 = PseudoRandom::Generator.new('range_seed2')
    seq1 = Array.new(20) { g1.rand(1..6) }
    seq2 = Array.new(20) { g2.rand(1..6) }
    refute_equal seq1, seq2
  end
end

# rubocop:enable Metrics/ClassLength
