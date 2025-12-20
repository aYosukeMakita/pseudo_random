# PseudoRandom

PseudoRandom is a Ruby library that generates deterministic, reproducible pseudo-random numbers from a seed. Given the same seed, it always produces the same sequence, making it ideal for tests, simulations, and any scenario where repeatability matters.

## Features

- Deterministic & reproducible sequences from identical seeds
- Flexible seeding: numbers, strings, arrays, hashes, Time objects, and more
- Floating point values in [0.0, 1.0) and integers within given ranges
- Hexadecimal string generation of arbitrary length
- API surface broadly compatible with Ruby's built-in `Random`

## String generation methods (alphabetic / alphanumeric / hex)

This section documents the specs, boundary conditions, and determinism guarantees for the string helpers.

### Common rules

- Covered methods: `generator.hex(length)`, `generator.alphabetic(length)`, `generator.alphanumeric(length)`
- Argument `length` MUST be an Integer >= 0.
  - Negative or non-integer (e.g. Float) raises: `ArgumentError: "Length must be a non-negative integer"`.
- When `length == 0` an empty string (`""`) is returned.
- The returned string length always equals `length`.
- Output is deterministic w.r.t. the seed AND the exact call order of all generator methods.
  - Same seed + identical sequence of method calls + identical `length` values => identical sequence of outputs.
  - Different seeds produce statistically different outputs.
- Implementation wraps Ruby's `Random`. Characters are produced in fixed-size chunks by drawing a uniformly distributed integer and converting it to a mixed‑radix representation. Chunk sizing is part of the public deterministic algorithm; changing it is a breaking (MAJOR) change (see Determinism Policy below).

### Per-method specifics

| Method                 | Character set / Output                    | Notes                                                                                                                                                                                                                                                                               |
| ---------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rand([limit])`        | Float [0.0, 1.0), Integer, Range, etc.    | No argument: float in [0.0, 1.0). Integer: integer in [0, n). Float: float in [0.0, n). Range (integer or float): value in the given range. Supports both integer and floating-point ranges, e.g., `rand(1..10)` or `rand(1.0..2.0)`. Compatible with Ruby's Random. Deterministic. |
| `hex(length)`          | `0-9a-f` (16 chars, lowercase)            | Uses 32‑bit integers -> 8 hex chars at a time; remainder (1–7) from another 32‑bit block prefix. Uniform over all hex strings of the requested length.                                                                                                                              |
| `alphabetic(length)`   | `A-Z` (26) + `a-z` (26) = 52              | 3-char chunks (since 52^3 < 2^32) plus remainder (1–2 chars). Uniform.                                                                                                                                                                                                              |
| `alphanumeric(length)` | `A-Z` (26) + `a-z` (26) + `0-9` (10) = 62 | 5-char chunks (62^5 < 2^32) plus remainder (1–4 chars). Uniform.                                                                                                                                                                                                                    |

### Uniformity

Each chunk uses `Random#rand(base^k)` for an integer in `0...(base^k)` which is then expanded via repeated mod/div to `k` characters. This yields a uniform distribution over all `base^k` length-`k` strings. Remainder segments use the same approach. Thus (subject to the statistical quality of Ruby's underlying PRNG) each character position is unbiased and independent across chunks.

For `rand`, the output is uniformly distributed over the specified range or interval, matching the behavior of Ruby's built-in `Random`. The statistical quality depends on the underlying PRNG.

### Performance / limits

- Time complexity: O(length). Memory: O(length) for the resulting string.
- Very large values (millions of characters) imply higher allocation cost; consider generating in smaller segments if required.

For `rand`, each call is O(1) in time and memory. Extremely large integer ranges or high-precision floats may be limited by Ruby's internal implementation.

### Determinism Policy

As stated in Versioning: the mapping `(seed, call order) -> output sequence` is a public contract.

- PATCH / MINOR: Existing deterministic sequences are preserved (unless fixing clearly incorrect behavior as per docs).
- MAJOR: We may alter internal chunk sizing / conversion strategy. Any such change will be called out in the CHANGELOG.
- The seed normalization algorithm (FNV‑1a based canonicalization) is also part of the deterministic surface; modifying it (outside critical bug fixes) is MAJOR.

### Exceptions (current)

| Condition                  | Exception       |
| -------------------------- | --------------- |
| `length < 0`               | `ArgumentError` |
| `length` not an Integer    | `ArgumentError` |
| invalid argument to `rand` | `ArgumentError` |

### Examples

```ruby
g = PseudoRandom.new("seed")
g.rand           # => float in [0.0, 1.0)
g.rand(10)       # => integer in [0, 10)
g.rand(1..100)   # => integer in [1, 100]
g.rand(10.0)     # => float in [0.0, 10.0)
g.rand(1.0..2.0) # => float in [1.0, 2.0)
g.hex(10)         # => 10 hex chars (0-9a-f)
g.alphabetic(12)  # => 12 alphabetic chars (A-Za-z)
g.alphanumeric(8) # => 8 alphanumeric chars (A-Za-z0-9)
```

See `CHANGELOG.md` for detailed release notes.

## ⚠️ Security / Cryptographic Use Disclaimer

The random values produced by this library prioritize determinism and reproducibility. They are NOT cryptographically secure. Do NOT use this library for any of the following:

- Password or passphrase generation
- API keys, access tokens, session IDs, CSRF tokens
- Cryptographic keys, IVs, nonces, salts
- Lotteries, drawings, or any fairness-critical public process exposed to adversaries

For those purposes use Ruby's standard `SecureRandom`, or a cryptographically secure source via OpenSSL / libsodium. Always use a CSPRNG for any security-sensitive or fairness‑critical context (passwords, keys, tokens, lotteries, audits, public selections, etc.).

Example (when you need secure randomness):

```ruby
require 'securerandom'
token = SecureRandom.hex(32) # 64 hex characters
```

Use PseudoRandom only in contexts where determinism is valuable: tests, simulations, reproducible data generation, behavior snapshots with fixed seeds, etc.

## Installation

Add this line to your Gemfile:

```ruby
gem 'pseudo_random'
```

Then execute:

```bash
bundle install
```

Or install directly:

```bash
gem install pseudo_random
```

## Usage

### Basic usage

```ruby
require 'pseudo_random'

# Create a generator with seed 42
generator = PseudoRandom.new(42)

# Float in [0.0, 1.0)
random_float = generator.rand
puts random_float  # => 0.8731369804701281

# Integer in [0, 9]
random_int = generator.rand(10)
puts random_int  # => 9

# Float in [0.0, 10.0)
random_float_range = generator.rand(10.0)
puts random_float_range  # => 3.440017825456998

# Integer in [1, 100]
random_range = generator.rand(1..100)
puts random_range  # => 41
```

### Convenience one-off methods

```ruby
# One-off random number
result = PseudoRandom.rand(seed: 42)
puts result  # => 0.8731369804701281

# One-off hex string
hex = PseudoRandom.hex(seed: 'my_seed', length: 16)
puts hex  # => "cee117d6757980b7"

# One-off alphabetic string
alpha = PseudoRandom.alphabetic(seed: 'my_seed', length: 12)
puts alpha  # => "aZikVznxlLXj"

# One-off alphanumeric string
alnum = PseudoRandom.alphanumeric(seed: 'my_seed', length: 10)
puts alnum  # => "Q3a2S8sXED"

# These are equivalent to creating a generator and calling the method once:
# PseudoRandom.hex(seed: 'my_seed', length: 16) == PseudoRandom.new('my_seed').hex(16)
```

### Diverse seed types

You can pass any Ruby object as a seed to `PseudoRandom.new`. The object will be normalized into a deterministic hash value using a canonicalization algorithm (based on FNV-1a). This ensures that objects with the same content (even if of different types, e.g., a string `"42"` and an integer `42`) will produce different random sequences, while identical objects always yield the same sequence. Supported seed types include numbers, strings, arrays, hashes, symbols, Time objects, and any other Ruby object.

```ruby
# String seed
generator1 = PseudoRandom.new("hello")
puts generator1.rand  # => 0.37097030662852004

# Array seed
generator2 = PseudoRandom.new([1, 2, 3])
puts generator2.rand  # => 0.41837699041143994

# Hash seed
generator3 = PseudoRandom.new({ name: "John", age: 30 })
puts generator3.rand  # => 0.5869273234945404

# Time seed
generator4 = PseudoRandom.new(Time.new(2023, 1, 1))
puts generator4.rand  # => 0.6345803634459501

# Omitted seed (uses hash of nil)
generator5 = PseudoRandom.new
puts generator5.rand  # => 0.9527695090684619
```

### Hex string generation

```ruby
generator = PseudoRandom.new("secret")

# 8 hex characters
hex_string = generator.hex(8)
puts hex_string  # => "0b628b64"

# 10 hex characters
hex_string_10 = generator.hex(10)
puts hex_string_10  # => "6f291838f3"

# 16 hex characters
long_hex = generator.hex(16)
puts long_hex  # => "afef24ef63f4e104"

# Empty string (length 0)
empty_hex = generator.hex(0)
puts empty_hex  # => ""
```

### Reproducibility demonstration

```ruby
# Two generators with the same seed
gen1 = PseudoRandom.new("test")
gen2 = PseudoRandom.new("test")

# Produces identical sequences
5.times do
  puts "gen1: #{gen1.rand}, gen2: #{gen2.rand}"
end

# Example output:
# gen1: 0.7714906738735868, gen2: 0.7714906738735868
# gen1: 0.9245604822851962, gen2: 0.9245604822851962
# gen1: 0.4030548732252476, gen2: 0.4030548732252476
# gen1: 0.07008281657880167, gen2: 0.07008281657880167
# gen1: 0.8898582626604018, gen2: 0.8898582626604018
```

### Practical examples

#### Generating test data

```ruby
# Consistent user test data
def generate_test_user(seed)
  generator = PseudoRandom.new(seed)

  {
    id: generator.rand(1_000_000),
    name: "User#{generator.hex(6)}",
    score: generator.rand(100),
    active: generator.rand(2) == 1
  }
end

user1 = generate_test_user("user1")
user2 = generate_test_user("user1")  # Same data
puts user1 == user2  # => true
```

#### Simulation

```ruby
# Dice roll simulation
def simulate_dice_rolls(seed, count)
  generator = PseudoRandom.new(seed)
  results = Array.new(6, 0)

  count.times do
    roll = generator.rand(1..6)
    results[roll - 1] += 1
  end

  results
end

# Identical results with identical seed
results1 = simulate_dice_rolls("dice_sim", 1000)
results2 = simulate_dice_rolls("dice_sim", 1000)
puts results1 == results2  # => true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake test` to run the test suite. You can also run `bin/console` for an interactive prompt to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version: update the version in `version.rb`, then run `bundle exec rake release` (this creates a git tag, pushes commits and the tag, and publishes the `.gem` to [rubygems.org](https://rubygems.org)).

## Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

Version numbers use the format MAJOR.MINOR.PATCH (e.g. `1.2.3`).

- MAJOR: Incremented for any backward-incompatible change to the public API. A change is considered breaking if it alters method names, argument semantics, return types, raises new errors in previously valid use, or changes the deterministic output sequence for the same seed in a way not explicitly documented as a bug fix.
- MINOR: Backward-compatible feature additions or expansions. May introduce new methods or optional arguments. Deterministic sequences for existing seeds remain unchanged (except where a PATCH-level bug fix applies).
- PATCH: Backward-compatible bug fixes and internal improvements that do not modify the documented behavior or output streams for existing seeds, unless the prior output was clearly incorrect per documentation (in which case the CHANGELOG will call it out explicitly).

Deprecations: A feature marked as deprecated will remain available for at least one MINOR release before removal in the next MAJOR. Deprecations are announced in the CHANGELOG under an "Deprecated" heading.

Deterministic Output Contract: The algorithm's mapping from (seed, call order) to values is part of the observable API. Altering it counts as a breaking change unless correcting a documented bug.

Pre-release tags (e.g. `1.1.0-alpha.1`) may be used for experimentation; they do not guarantee output stability until the final release.

The current version is defined in `lib/pseudo_random/version.rb` (`PseudoRandom::VERSION`).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aYosukeMakita/pseudo_random.

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
