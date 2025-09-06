#include <ruby.h>
#include <ruby/encoding.h>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>

// FNV-1a 64-bit constants
constexpr uint64_t FNV_OFFSET = 0xcbf29ce484222325ULL;
constexpr uint64_t FNV_PRIME = 0x100000001b3ULL;
constexpr uint64_t MASK64 = 0xffffffffffffffffULL;

class SeedCalculator {
private:
    std::vector<uint8_t> bytes;
    
    // ZigZag encode signed -> unsigned integer
    uint64_t zigzag(int64_t num) const {
        return num >= 0 ? (static_cast<uint64_t>(num) << 1) : 
                         ((static_cast<uint64_t>(-num) << 1) - 1);
    }
    
    // Varint (7-bit continuation) encoding
    void encode_varint(uint64_t num) {
        do {
            uint8_t byte = num & 0x7f;
            num >>= 7;
            if (num == 0) {
                bytes.push_back(byte);
                break;
            } else {
                bytes.push_back(byte | 0x80);
            }
        } while (true);
    }
    
    // Canonical serialization of Ruby objects
    void canonical_serialize(VALUE obj) {
        switch (TYPE(obj)) {
            case T_NIL:
                bytes.push_back('n');
                break;
                
            case T_TRUE:
                bytes.push_back('t');
                break;
                
            case T_FALSE:
                bytes.push_back('f');
                break;
                
            case T_FIXNUM:
            case T_BIGNUM:
                bytes.push_back('i');
                encode_varint(zigzag(NUM2LL(obj)));
                break;
                
            case T_FLOAT:
                bytes.push_back('d');
                {
                    double d = RFLOAT_VALUE(obj);
                    uint64_t bits;
                    std::memcpy(&bits, &d, sizeof(double));
                    // Convert to big-endian (network byte order)
                    for (int i = 7; i >= 0; i--) {
                        bytes.push_back((bits >> (i * 8)) & 0xff);
                    }
                }
                break;
                
            case T_STRING:
                bytes.push_back('s');
                {
                    // Use the string as-is, assume it's already properly encoded
                    const char* str_ptr = RSTRING_PTR(obj);
                    long str_len = RSTRING_LEN(obj);
                    encode_varint(str_len);
                    for (long i = 0; i < str_len; i++) {
                        bytes.push_back(static_cast<uint8_t>(str_ptr[i]));
                    }
                }
                break;
                
            case T_SYMBOL:
                bytes.push_back('y');
                {
                    VALUE str = rb_sym2str(obj);
                    const char* str_ptr = RSTRING_PTR(str);
                    long str_len = RSTRING_LEN(str);
                    encode_varint(str_len);
                    for (long i = 0; i < str_len; i++) {
                        bytes.push_back(static_cast<uint8_t>(str_ptr[i]));
                    }
                }
                break;
                
            case T_ARRAY:
                bytes.push_back('a');
                {
                    long len = RARRAY_LEN(obj);
                    encode_varint(len);
                    for (long i = 0; i < len; i++) {
                        canonical_serialize(RARRAY_AREF(obj, i));
                    }
                }
                break;
                
            case T_HASH:
                bytes.push_back('h');
                {
                    VALUE keys = rb_funcall(obj, rb_intern("keys"), 0);
                    long len = RARRAY_LEN(keys);
                    encode_varint(len);
                    
                    // Sort keys by string representation for canonical order
                    std::vector<std::pair<std::string, VALUE>> sorted_keys;
                    for (long i = 0; i < len; i++) {
                        VALUE key = RARRAY_AREF(keys, i);
                        VALUE key_str = rb_funcall(key, rb_intern("to_s"), 0);
                        std::string key_string(RSTRING_PTR(key_str), RSTRING_LEN(key_str));
                        sorted_keys.push_back({key_string, key});
                    }
                    
                    std::sort(sorted_keys.begin(), sorted_keys.end(),
                             [](const auto& a, const auto& b) { return a.first < b.first; });
                    
                    for (const auto& key_pair : sorted_keys) {
                        canonical_serialize(rb_str_new(key_pair.first.c_str(), key_pair.first.length()));
                        VALUE original_key = key_pair.second;
                        VALUE value = rb_hash_aref(obj, original_key);
                        canonical_serialize(value);
                    }
                }
                break;
                
            case T_DATA:
                // Check if it's a Time object
                if (rb_obj_is_kind_of(obj, rb_cTime)) {
                    bytes.push_back('T');
                    VALUE to_i = rb_funcall(obj, rb_intern("to_i"), 0);
                    VALUE nsec = rb_funcall(obj, rb_intern("nsec"), 0);
                    encode_varint(NUM2ULL(to_i));
                    encode_varint(NUM2ULL(nsec));
                    break;
                }
            // Fall through to default case: intentionally handle non-Time T_DATA objects as generic objects
            [[fallthrough]];
            default:
                // Fallback: class name + ':' + to_s
                bytes.push_back('o');
                {
                    VALUE klass = rb_obj_class(obj);
                    VALUE class_name = rb_funcall(klass, rb_intern("name"), 0);
                    VALUE obj_str = rb_funcall(obj, rb_intern("to_s"), 0);
                    
                    std::string rep = std::string(RSTRING_PTR(class_name), RSTRING_LEN(class_name)) + 
                                     ":" + 
                                     std::string(RSTRING_PTR(obj_str), RSTRING_LEN(obj_str));
                    
                    encode_varint(rep.length());
                    for (char c : rep) {
                        bytes.push_back(static_cast<uint8_t>(c));
                    }
                }
                break;
        }
    }
    
public:
    // Convert arbitrary Ruby object to a deterministic 31-bit Integer
    uint32_t to_seed_int(VALUE obj) {
        bytes.clear();
        canonical_serialize(obj);
        
        // FNV-1a hash calculation
        uint64_t h = FNV_OFFSET;
        for (uint8_t byte : bytes) {
            h ^= byte;
            h = (h * FNV_PRIME) & MASK64;
        }
        
        uint32_t s = static_cast<uint32_t>(h ^ (h >> 32));
        return s & 0x7fffffff; // 31-bit mask
    }
};

// Ruby C API wrapper functions
extern "C" {
    static VALUE seed_to_seed_int(VALUE /* self */, VALUE obj) {
        try {
            SeedCalculator calculator;
            uint32_t result = calculator.to_seed_int(obj);
            return UINT2NUM(result);
        } catch (const std::exception& e) {
            rb_raise(rb_eRuntimeError, "Error in seed calculation: %s", e.what());
            return Qnil;
        }
    }
    
    void Init_pseudo_random_native() {
        VALUE mPseudoRandom = rb_define_module("PseudoRandom");
        VALUE mSeedNative = rb_define_module_under(mPseudoRandom, "SeedNative");
        
        rb_define_module_function(mSeedNative, "to_seed_int", RUBY_METHOD_FUNC(seed_to_seed_int), 1);
    }
}
