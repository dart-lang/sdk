// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CANONICAL_TABLES_H_
#define RUNTIME_VM_CANONICAL_TABLES_H_

#include "platform/assert.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {

template <typename CharType>
class CharArray {
 public:
  CharArray(const CharType* data, intptr_t len) : data_(data), len_(len) {
    hash_ = String::Hash(data, len);
  }
  StringPtr ToSymbol() const {
    String& result = String::Handle(StringFrom(data_, len_, Heap::kOld));
    result.SetCanonical();
    result.SetHash(hash_);
    return result.raw();
  }
  bool Equals(const String& other) const {
    ASSERT(other.HasHash());
    if (other.Hash() != hash_) {
      return false;
    }
    return other.Equals(data_, len_);
  }
  intptr_t Hash() const { return hash_; }

 private:
  const CharType* data_;
  intptr_t len_;
  intptr_t hash_;
};
typedef CharArray<uint8_t> Latin1Array;
typedef CharArray<uint16_t> UTF16Array;
typedef CharArray<int32_t> UTF32Array;

class StringSlice {
 public:
  StringSlice(const String& str, intptr_t begin_index, intptr_t length)
      : str_(str), begin_index_(begin_index), len_(length) {
    hash_ = is_all() ? str.Hash() : String::Hash(str, begin_index, length);
  }
  StringPtr ToSymbol() const;
  bool Equals(const String& other) const {
    ASSERT(other.HasHash());
    if (other.Hash() != hash_) {
      return false;
    }
    return other.Equals(str_, begin_index_, len_);
  }
  intptr_t Hash() const { return hash_; }

 private:
  bool is_all() const { return begin_index_ == 0 && len_ == str_.Length(); }
  const String& str_;
  intptr_t begin_index_;
  intptr_t len_;
  intptr_t hash_;
};

class ConcatString {
 public:
  ConcatString(const String& str1, const String& str2)
      : str1_(str1), str2_(str2), hash_(String::HashConcat(str1, str2)) {}
  StringPtr ToSymbol() const;
  bool Equals(const String& other) const {
    ASSERT(other.HasHash());
    if (other.Hash() != hash_) {
      return false;
    }
    return other.EqualsConcat(str1_, str2_);
  }
  intptr_t Hash() const { return hash_; }

 private:
  const String& str1_;
  const String& str2_;
  intptr_t hash_;
};

class SymbolTraits {
 public:
  static const char* Name() { return "SymbolTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const String& a_str = String::Cast(a);
    const String& b_str = String::Cast(b);
    ASSERT(a_str.HasHash());
    ASSERT(b_str.HasHash());
    if (a_str.Hash() != b_str.Hash()) {
      return false;
    }
    intptr_t a_len = a_str.Length();
    if (a_len != b_str.Length()) {
      return false;
    }
    // Use a comparison which does not consider the state of the canonical bit.
    return a_str.Equals(b_str, 0, a_len);
  }
  template <typename CharType>
  static bool IsMatch(const CharArray<CharType>& array, const Object& obj) {
    return array.Equals(String::Cast(obj));
  }
  static bool IsMatch(const StringSlice& slice, const Object& obj) {
    return slice.Equals(String::Cast(obj));
  }
  static bool IsMatch(const ConcatString& concat, const Object& obj) {
    return concat.Equals(String::Cast(obj));
  }
  static uword Hash(const Object& key) { return String::Cast(key).Hash(); }
  template <typename CharType>
  static uword Hash(const CharArray<CharType>& array) {
    return array.Hash();
  }
  static uword Hash(const StringSlice& slice) { return slice.Hash(); }
  static uword Hash(const ConcatString& concat) { return concat.Hash(); }
  template <typename CharType>
  static ObjectPtr NewKey(const CharArray<CharType>& array) {
    return array.ToSymbol();
  }
  static ObjectPtr NewKey(const StringSlice& slice) { return slice.ToSymbol(); }
  static ObjectPtr NewKey(const ConcatString& concat) {
    return concat.ToSymbol();
  }
};
typedef UnorderedHashSet<SymbolTraits> CanonicalStringSet;

class CanonicalTypeKey {
 public:
  explicit CanonicalTypeKey(const Type& key) : key_(key) {}
  bool Matches(const Type& arg) const { return key_.Equals(arg); }
  uword Hash() const { return key_.Hash(); }
  const Type& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical Type based on its hash.
class CanonicalTypeTraits {
 public:
  static const char* Name() { return "CanonicalTypeTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsType() && b.IsType());
    const Type& arg1 = Type::Cast(a);
    const Type& arg2 = Type::Cast(b);
    return arg1.Equals(arg2) && (arg1.Hash() == arg2.Hash());
  }
  static bool IsMatch(const CanonicalTypeKey& a, const Object& b) {
    ASSERT(b.IsType());
    return a.Matches(Type::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(key.IsType());
    return Type::Cast(key).Hash();
  }
  static uword Hash(const CanonicalTypeKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalTypeKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalTypeTraits> CanonicalTypeSet;

class CanonicalTypeParameterKey {
 public:
  explicit CanonicalTypeParameterKey(const TypeParameter& key) : key_(key) {}
  bool Matches(const TypeParameter& arg) const { return key_.Equals(arg); }
  uword Hash() const { return key_.Hash(); }
  const TypeParameter& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical TypeParameter based on its hash.
class CanonicalTypeParameterTraits {
 public:
  static const char* Name() { return "CanonicalTypeParameterTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsTypeParameter() && b.IsTypeParameter());
    const TypeParameter& arg1 = TypeParameter::Cast(a);
    const TypeParameter& arg2 = TypeParameter::Cast(b);
    return arg1.Equals(arg2) && (arg1.Hash() == arg2.Hash());
  }
  static bool IsMatch(const CanonicalTypeParameterKey& a, const Object& b) {
    ASSERT(b.IsTypeParameter());
    return a.Matches(TypeParameter::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(key.IsTypeParameter());
    return TypeParameter::Cast(key).Hash();
  }
  static uword Hash(const CanonicalTypeParameterKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalTypeParameterKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalTypeParameterTraits>
    CanonicalTypeParameterSet;

class CanonicalTypeArgumentsKey {
 public:
  explicit CanonicalTypeArgumentsKey(const TypeArguments& key) : key_(key) {}
  bool Matches(const TypeArguments& arg) const {
    return key_.Equals(arg) && (key_.Hash() == arg.Hash());
  }
  uword Hash() const { return key_.Hash(); }
  const TypeArguments& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical TypeArguments based on its hash.
class CanonicalTypeArgumentsTraits {
 public:
  static const char* Name() { return "CanonicalTypeArgumentsTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsTypeArguments() && b.IsTypeArguments());
    const TypeArguments& arg1 = TypeArguments::Cast(a);
    const TypeArguments& arg2 = TypeArguments::Cast(b);
    return arg1.Equals(arg2) && (arg1.Hash() == arg2.Hash());
  }
  static bool IsMatch(const CanonicalTypeArgumentsKey& a, const Object& b) {
    ASSERT(b.IsTypeArguments());
    return a.Matches(TypeArguments::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(key.IsTypeArguments());
    return TypeArguments::Cast(key).Hash();
  }
  static uword Hash(const CanonicalTypeArgumentsKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalTypeArgumentsKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalTypeArgumentsTraits>
    CanonicalTypeArgumentsSet;

class MetadataMapTraits {
 public:
  static const char* Name() { return "MetadataMapTraits"; }
  static bool ReportStats() { return false; }
  static bool IsMatch(const Object& a, const Object& b);
  static uword Hash(const Object& key);
};
typedef UnorderedHashMap<MetadataMapTraits> MetadataMap;

}  // namespace dart

#endif  // RUNTIME_VM_CANONICAL_TABLES_H_
