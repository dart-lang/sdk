// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_
#define RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_

#include "platform/text_buffer.h"

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/hash.h"
#include "vm/hash_map.h"
#include "vm/zone.h"

namespace dart {

#define FOR_EACH_S_EXPRESSION_ATOM(M)                                          \
  M(Bool, bool)                                                                \
  M(Integer, intptr_t)                                                         \
  M(String, const char*)                                                       \
  M(Symbol, const char*)

#define FOR_EACH_S_EXPRESSION(M)                                               \
  FOR_EACH_S_EXPRESSION_ATOM(M)                                                \
  M(List, _)

#define FOR_EACH_ABSTRACT_S_EXPRESSION(M) M(Atom, _)

#define FORWARD_DECLARATION(name, value_type) class SExp##name;
FOR_EACH_S_EXPRESSION(FORWARD_DECLARATION)
FOR_EACH_ABSTRACT_S_EXPRESSION(FORWARD_DECLARATION)
#undef FORWARD_DECLARATION

// Abstract base class for S-expressions used as an intermediate form for the
// IL serializer. These aren't true (LISP-like) S-expressions, as the atoms
// are more restricted and the lists have extra information. Here is an
// illustrative BNF-style grammar of the current serialized form of
// S-expressions that includes non-whitespace literal tokens:
//
// <s-exp>      ::= <atom> | <list>
// <atom>       ::= <bool> | <integer> | <string> | <symbol>
// <list>       ::= '(' <s-exp>* <extra-info>? ')'
// <extra-info> ::= '{' <extra-elem>* '}'
// <extra-elem> ::= <symbol> <s-exp> ','
//
// Here, <string>s are double-quoted strings with backslash escaping and
// <symbol>s are sequences of consecutive non-whitespace characters that do not
// include commas (,), parentheses (()), curly braces ({}), or the double-quote
// character (").
//
// In addition, the <extra-info> is considered a map from symbol labels to
// S-expression values, and as such each symbol used as a key in an <extra-info>
// block should only appear once as a key within that block.
class SExpression : public ZoneAllocated {
 public:
  explicit SExpression(intptr_t start = kInvalidPos) : start_(start) {}
  virtual ~SExpression() {}

  static intptr_t const kInvalidPos = -1;

  static SExpression* FromCString(Zone* zone, const char* cstr);
  intptr_t start() const { return start_; }

#define S_EXPRESSION_TYPE_CHECK(name, value_type)                              \
  bool Is##name() { return (As##name() != nullptr); }                          \
  virtual SExp##name* As##name() { return nullptr; }

  FOR_EACH_S_EXPRESSION(S_EXPRESSION_TYPE_CHECK)
  FOR_EACH_ABSTRACT_S_EXPRESSION(S_EXPRESSION_TYPE_CHECK)

  virtual const char* DebugName() const = 0;
  virtual bool Equals(SExpression* sexp) const = 0;
  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const = 0;
  virtual void SerializeToLine(TextBuffer* buffer) const = 0;

 private:
  // Starting character position of the s-expression in the original
  // serialization, if it was deserialized.
  intptr_t const start_;
  DISALLOW_COPY_AND_ASSIGN(SExpression);
};

class SExpAtom : public SExpression {
 public:
  explicit SExpAtom(intptr_t start = kInvalidPos) : SExpression(start) {}

  virtual SExpAtom* AsAtom() { return this; }
  // No atoms have sub-elements, so they always print to a single line.
  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const {
    SerializeToLine(buffer);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(SExpAtom);
};

#define DEFINE_S_EXPRESSION_TYPE_CHECK(name)                                   \
  virtual SExp##name* As##name() { return this; }                              \
  virtual const char* DebugName() const { return #name; }

// The various concrete S-expression atom classes are thin wrappers around
// their contained value that includes serialization and type check methods.
#define DEFINE_S_EXPRESSION_ATOM_CLASS(name, value_type)                       \
  class SExp##name : public SExpAtom {                                         \
   public:                                                                     \
    explicit SExp##name(value_type val, intptr_t start = kInvalidPos)          \
        : SExpAtom(start), val_(val) {}                                        \
    value_type value() const { return val_; }                                  \
    virtual bool Equals(SExpression* sexp) const;                              \
    virtual void SerializeToLine(TextBuffer* buffer) const;                    \
    DEFINE_S_EXPRESSION_TYPE_CHECK(name)                                       \
   private:                                                                    \
    value_type const val_;                                                     \
    DISALLOW_COPY_AND_ASSIGN(SExp##name);                                      \
  };

FOR_EACH_S_EXPRESSION_ATOM(DEFINE_S_EXPRESSION_ATOM_CLASS)

// A list of S-expressions. Unlike normal S-expressions, an S-expression list
// also contains a hash map kept separate from the elements, which we use for
// extra non-argument information for IL instructions.
class SExpList : public SExpression {
 public:
  explicit SExpList(Zone* zone, intptr_t start = kInvalidPos)
      : SExpression(start), contents_(zone, 2), extra_info_(zone) {}

  template <typename V>
  class CStringPointerKeyValueTrait {
   public:
    typedef const char* Key;
    typedef V Value;

    struct Pair {
      Key key;
      Value value;
      Pair() : key(NULL), value() {}
      Pair(const Key key, const Value& value) : key(key), value(value) {}
      Pair(const Pair& other) : key(other.key), value(other.value) {}
    };

    static Key KeyOf(Pair kv) { return kv.key; }
    static Value ValueOf(Pair kv) { return kv.value; }
    static intptr_t Hashcode(Key key) {
      intptr_t hash = 0;
      for (size_t i = 0; i < strlen(key); i++) {
        hash = CombineHashes(hash, key[i]);
      }
      return FinalizeHash(hash, kBitsPerWord - 1);
    }
    static bool IsKeyEqual(Pair kv, Key key) {
      return kv.key == key || strcmp(kv.key, key) == 0;
    }
  };

  using ExtraInfoKeyValueTrait = CStringPointerKeyValueTrait<SExpression*>;
  using ExtraInfoHashMap = DirectChainedHashMap<ExtraInfoKeyValueTrait>;

  void Add(SExpression* sexp);
  void AddExtra(const char* label, SExpression* value);

  SExpression* At(intptr_t i) const { return contents_.At(i); }
  intptr_t Length() const { return contents_.length(); }

  intptr_t ExtraLength() const { return extra_info_.Length(); }
  ExtraInfoHashMap::Iterator ExtraIterator() const {
    return extra_info_.GetIterator();
  }
  bool ExtraHasKey(const char* cstr) const { return extra_info_.HasKey(cstr); }
  ExtraInfoKeyValueTrait::Value ExtraLookupValue(const char* cstr) const {
    return extra_info_.LookupValue(cstr);
  }

  DEFINE_S_EXPRESSION_TYPE_CHECK(List)
  virtual bool Equals(SExpression* sexp) const;
  virtual void SerializeTo(Zone* zone,
                           TextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const;
  virtual void SerializeToLine(TextBuffer* buffer) const;

 private:
  static const char* const kElemIndent;
  static const char* const kExtraIndent;

  void SerializeExtraInfoTo(Zone* zone,
                            TextBuffer* buffer,
                            const char* indent,
                            int width) const;
  void SerializeExtraInfoToLine(TextBuffer* buffer) const;

  ZoneGrowableArray<SExpression*> contents_;
  ExtraInfoHashMap extra_info_;

  DISALLOW_COPY_AND_ASSIGN(SExpList);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_
