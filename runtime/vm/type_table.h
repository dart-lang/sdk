// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_TYPE_TABLE_H_
#define RUNTIME_VM_TYPE_TABLE_H_

#include "platform/assert.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {

class CanonicalTypeKey {
 public:
  explicit CanonicalTypeKey(const Type& key) : key_(key) {}
  bool Matches(const Type& arg) const { return key_.Equals(arg); }
  uword Hash() const { return key_.Hash(); }
  const Type& key_;

 private:
  DISALLOW_ALLOCATION();
};

// Traits for looking up Canonical Type based on it's hash.
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
  static RawObject* NewKey(const CanonicalTypeKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalTypeTraits> CanonicalTypeSet;

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
  static RawObject* NewKey(const CanonicalTypeArgumentsKey& obj) {
    return obj.key_.raw();
  }
};
typedef UnorderedHashSet<CanonicalTypeArgumentsTraits>
    CanonicalTypeArgumentsSet;

}  // namespace dart

#endif  // RUNTIME_VM_TYPE_TABLE_H_
