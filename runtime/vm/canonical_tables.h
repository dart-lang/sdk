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
    return result.ptr();
  }
  bool Equals(const String& other) const {
    ASSERT(other.HasHash());
    if (other.Hash() != hash_) {
      return false;
    }
    return other.Equals(data_, len_);
  }
  uword Hash() const { return hash_; }

 private:
  const CharType* data_;
  intptr_t len_;
  uword hash_;
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
  uword Hash() const { return hash_; }

 private:
  bool is_all() const { return begin_index_ == 0 && len_ == str_.Length(); }
  const String& str_;
  intptr_t begin_index_;
  intptr_t len_;
  uword hash_;
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
  uword Hash() const { return hash_; }

 private:
  const String& str1_;
  const String& str2_;
  uword hash_;
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

typedef UnorderedHashSet<SymbolTraits, WeakAcqRelStorageTraits>
    CanonicalStringSet;

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
    return obj.key_.ptr();
  }
};
typedef UnorderedHashSet<CanonicalTypeTraits> CanonicalTypeSet;

class CanonicalFunctionTypeKey {
 public:
  explicit CanonicalFunctionTypeKey(const FunctionType& key) : key_(key) {}
  bool Matches(const FunctionType& arg) const { return key_.Equals(arg); }
  uword Hash() const { return key_.Hash(); }
  const FunctionType& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical FunctionType based on its hash.
class CanonicalFunctionTypeTraits {
 public:
  static const char* Name() { return "CanonicalFunctionTypeTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsFunctionType() && b.IsFunctionType());
    const FunctionType& arg1 = FunctionType::Cast(a);
    const FunctionType& arg2 = FunctionType::Cast(b);
    return arg1.Equals(arg2) && (arg1.Hash() == arg2.Hash());
  }
  static bool IsMatch(const CanonicalFunctionTypeKey& a, const Object& b) {
    ASSERT(b.IsFunctionType());
    return a.Matches(FunctionType::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(key.IsFunctionType());
    return FunctionType::Cast(key).Hash();
  }
  static uword Hash(const CanonicalFunctionTypeKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalFunctionTypeKey& obj) {
    return obj.key_.ptr();
  }
};
typedef UnorderedHashSet<CanonicalFunctionTypeTraits> CanonicalFunctionTypeSet;

class CanonicalRecordTypeKey {
 public:
  explicit CanonicalRecordTypeKey(const RecordType& key) : key_(key) {}
  bool Matches(const RecordType& arg) const { return key_.Equals(arg); }
  uword Hash() const { return key_.Hash(); }
  const RecordType& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical RecordType based on its hash.
class CanonicalRecordTypeTraits {
 public:
  static const char* Name() { return "CanonicalRecordTypeTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    ASSERT(a.IsRecordType() && b.IsRecordType());
    const RecordType& arg1 = RecordType::Cast(a);
    const RecordType& arg2 = RecordType::Cast(b);
    return arg1.Equals(arg2) && (arg1.Hash() == arg2.Hash());
  }
  static bool IsMatch(const CanonicalRecordTypeKey& a, const Object& b) {
    ASSERT(b.IsRecordType());
    return a.Matches(RecordType::Cast(b));
  }
  static uword Hash(const Object& key) {
    ASSERT(key.IsRecordType());
    return RecordType::Cast(key).Hash();
  }
  static uword Hash(const CanonicalRecordTypeKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const CanonicalRecordTypeKey& obj) {
    return obj.key_.ptr();
  }
};
typedef UnorderedHashSet<CanonicalRecordTypeTraits> CanonicalRecordTypeSet;

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
    return obj.key_.ptr();
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
    return obj.key_.ptr();
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

class DispatcherKey {
 public:
  DispatcherKey(const String& name,
                const Array& args_desc,
                UntaggedFunction::Kind kind)
      : name_(name), args_desc_(args_desc), kind_(kind) {}
  bool Equals(const Function& other) const {
    return (name_.ptr() == other.name()) &&
           (args_desc_.ptr() == other.saved_args_desc()) &&
           (kind_ == other.kind());
  }
  uword Hash() const { return CombineHashes(name_.Hash(), kind_); }

 private:
  const String& name_;
  const Array& args_desc_;
  UntaggedFunction::Kind kind_;
};

class DispatcherTraits {
 public:
  static const char* Name() { return "DispatcherTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b) {
    const Function& a_func = Function::Cast(a);
    const Function& b_func = Function::Cast(b);
    return (a_func.name() == b_func.name()) &&
           (a_func.kind() == b_func.kind()) &&
           (a_func.saved_args_desc() == b_func.saved_args_desc());
  }
  static bool IsMatch(const DispatcherKey& key, const Object& obj) {
    return key.Equals(Function::Cast(obj));
  }
  static uword Hash(const Object& key) {
    const Function& func = Function::Cast(key);
    return CombineHashes(String::Hash(func.name()), func.kind());
  }
  static uword Hash(const DispatcherKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const DispatcherKey& key) { UNREACHABLE(); }
};

typedef UnorderedHashSet<DispatcherTraits, AcqRelStorageTraits> DispatcherSet;

class CanonicalInstanceKey {
 public:
  explicit CanonicalInstanceKey(const Instance& key);
  bool Matches(const Instance& obj) const;
  uword Hash() const;
  const Instance& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical Instances based on a hash of the fields.
class CanonicalInstanceTraits {
 public:
  static const char* Name() { return "CanonicalInstanceTraits"; }
  static bool ReportStats() { return false; }

  // Called when growing the table.
  static bool IsMatch(const Object& a, const Object& b);
  static bool IsMatch(const CanonicalInstanceKey& a, const Object& b);
  static uword Hash(const Object& key);
  static uword Hash(const CanonicalInstanceKey& key);
  static ObjectPtr NewKey(const CanonicalInstanceKey& obj);
};

typedef UnorderedHashSet<CanonicalInstanceTraits> CanonicalInstancesSet;

struct CanonicalFfiCallbackFunctionTraits {
  static uint32_t Hash(const Object& key) { return Function::Cast(key).Hash(); }
  static const char* Name() { return "CanonicalFfiCallbackFunctionTraits"; }
  static bool IsMatch(const Object& x, const Object& y) {
    const auto& f1 = Function::Cast(x);
    const auto& f2 = Function::Cast(y);
    return (f1.FfiCallbackTarget() == f2.FfiCallbackTarget() &&
            f1.FfiCSignature() == f2.FfiCSignature() &&
            f1.FfiCallbackExceptionalReturn() ==
                f2.FfiCallbackExceptionalReturn() &&
            f1.GetFfiFunctionKind() == f2.GetFfiFunctionKind());
  }
  static bool ReportStats() { return false; }
};

using FfiCallbackFunctionSet =
    UnorderedHashSet<CanonicalFfiCallbackFunctionTraits>;

class RegExpKey {
 public:
  RegExpKey(const String& pattern, RegExpFlags flags)
      : pattern_(pattern), flags_(flags) {}

  bool Equals(const RegExp& other) const {
    return pattern_.Equals(String::Handle(other.pattern())) &&
           (flags_ == other.flags());
  }
  uword Hash() const {
    // Must agree with RegExp::CanonicalizeHash.
    return CombineHashes(pattern_.Hash(), flags_.value());
  }

  const String& pattern_;
  RegExpFlags flags_;

 private:
  DISALLOW_ALLOCATION();
};

class CanonicalRegExpTraits {
 public:
  static const char* Name() { return "CanonicalRegExpTraits"; }
  static bool ReportStats() { return false; }
  static bool IsMatch(const Object& a, const Object& b) {
    return RegExp::Cast(a).CanonicalizeEquals(RegExp::Cast(b));
  }
  static bool IsMatch(const RegExpKey& a, const Object& b) {
    return a.Equals(RegExp::Cast(b));
  }
  static uword Hash(const Object& key) {
    return RegExp::Cast(key).CanonicalizeHash();
  }
  static uword Hash(const RegExpKey& key) { return key.Hash(); }
  static ObjectPtr NewKey(const RegExpKey& key);
};

typedef UnorderedHashSet<CanonicalRegExpTraits, WeakAcqRelStorageTraits>
    CanonicalRegExpSet;

}  // namespace dart

#endif  // RUNTIME_VM_CANONICAL_TABLES_H_
