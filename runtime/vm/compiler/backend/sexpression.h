// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_
#define RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/text_buffer.h"

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/zone.h"

namespace dart {

#define FOR_EACH_S_EXPRESSION_ATOM(M)                                          \
  M(Bool, bool)                                                                \
  M(Double, double)                                                            \
  M(Integer, int64_t)                                                          \
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
  const char* ToCString(Zone* zone) const;
  intptr_t start() const { return start_; }

#define S_EXPRESSION_TYPE_CHECK(name, value_type)                              \
  bool Is##name() const { return (As##name() != nullptr); }                    \
  SExp##name* As##name() {                                                     \
    auto const const_this = const_cast<const SExpression*>(this);              \
    return const_cast<SExp##name*>(const_this->As##name());                    \
  }                                                                            \
  virtual const SExp##name* As##name() const { return nullptr; }

  FOR_EACH_S_EXPRESSION(S_EXPRESSION_TYPE_CHECK)
  FOR_EACH_ABSTRACT_S_EXPRESSION(S_EXPRESSION_TYPE_CHECK)

  virtual const char* DebugName() const = 0;
  virtual bool Equals(SExpression* sexp) const = 0;
  virtual void SerializeTo(Zone* zone,
                           BaseTextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const = 0;
  virtual void SerializeToLine(BaseTextBuffer* buffer) const = 0;

 private:
  // Starting character position of the s-expression in the original
  // serialization, if it was deserialized.
  intptr_t const start_;
  DISALLOW_COPY_AND_ASSIGN(SExpression);
};

class SExpAtom : public SExpression {
 public:
  explicit SExpAtom(intptr_t start = kInvalidPos) : SExpression(start) {}

  virtual const SExpAtom* AsAtom() const { return this; }
  // No atoms have sub-elements, so they always print to a single line.
  virtual void SerializeTo(Zone* zone,
                           BaseTextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const {
    SerializeToLine(buffer);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(SExpAtom);
};

#define DEFINE_S_EXPRESSION_TYPE_CHECK(name)                                   \
  virtual const SExp##name* As##name() const { return this; }                  \
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
    bool Equals(value_type val) const;                                         \
    virtual void SerializeToLine(BaseTextBuffer* buffer) const;                \
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

  using ExtraInfoHashMap = CStringMap<SExpression*>;

  void Add(SExpression* sexp);
  void AddExtra(const char* label, SExpression* value);

  SExpression* At(intptr_t i) const { return contents_.At(i); }
  intptr_t Length() const { return contents_.length(); }

  intptr_t ExtraLength() const { return extra_info_.Length(); }
  ExtraInfoHashMap::Iterator ExtraIterator() const {
    return extra_info_.GetIterator();
  }
  bool ExtraHasKey(const char* cstr) const { return extra_info_.HasKey(cstr); }
  SExpression* ExtraLookupValue(const char* cstr) const {
    return extra_info_.LookupValue(cstr);
  }

  // Shortcut for retrieving the tag from a tagged list (list that contains an
  // initial symbol). Returns nullptr if the list is not a tagged list.
  SExpSymbol* Tag() const {
    if (Length() == 0 || !At(0)->IsSymbol()) return nullptr;
    return At(0)->AsSymbol();
  }

  DEFINE_S_EXPRESSION_TYPE_CHECK(List)
  virtual bool Equals(SExpression* sexp) const;
  virtual void SerializeTo(Zone* zone,
                           BaseTextBuffer* buffer,
                           const char* indent,
                           intptr_t width = 80) const;
  virtual void SerializeToLine(BaseTextBuffer* buffer) const;

 private:
  static const char* const kElemIndent;
  static const char* const kExtraIndent;

  void SerializeExtraInfoTo(Zone* zone,
                            BaseTextBuffer* buffer,
                            const char* indent,
                            int width) const;
  void SerializeExtraInfoToLine(BaseTextBuffer* buffer) const;

  ZoneGrowableArray<SExpression*> contents_;
  ExtraInfoHashMap extra_info_;

  DISALLOW_COPY_AND_ASSIGN(SExpList);
};

class SExpParser : public ValueObject {
 public:
  SExpParser(Zone* zone, const char* cstr)
      : SExpParser(zone, cstr, strlen(cstr)) {}
  SExpParser(Zone* zone, const char* cstr, intptr_t len)
      : zone_(zone),
        buffer_(ASSERT_NOTNULL(cstr)),
        buffer_size_(strnlen(cstr, len)),
        cur_label_(nullptr),
        cur_value_(nullptr),
        list_stack_(zone, 2),
        in_extra_stack_(zone, 2),
        extra_start_stack_(zone, 2),
        cur_label_stack_(zone, 2),
        error_message_(nullptr) {}

  // Constants used in serializing and deserializing S-expressions.
  static const char* const kBoolTrueSymbol;
  static const char* const kBoolFalseSymbol;
  static char const kDoubleExponentChar;
  static const char* const kDoubleInfinitySymbol;
  static const char* const kDoubleNaNSymbol;

  struct ErrorStrings : AllStatic {
    static const char* const kOpenString;
    static const char* const kBadUnicodeEscape;
    static const char* const kOpenSExpList;
    static const char* const kOpenMap;
    static const char* const kNestedMap;
    static const char* const kMapOutsideList;
    static const char* const kNonSymbolLabel;
    static const char* const kNoMapLabel;
    static const char* const kRepeatedMapLabel;
    static const char* const kNoMapValue;
    static const char* const kExtraMapValue;
    static const char* const kUnexpectedComma;
    static const char* const kUnexpectedRightParen;
    static const char* const kUnexpectedRightCurly;
  };

  intptr_t error_pos() const { return error_pos_; }
  const char* error_message() const { return error_message_; }

  const char* Input() const { return buffer_; }
  SExpression* Parse();
  DART_NORETURN void ReportError() const;

 private:
#define S_EXP_TOKEN_LIST(M)                                                    \
  M(LeftParen)                                                                 \
  M(RightParen)                                                                \
  M(Comma)                                                                     \
  M(LeftCurly)                                                                 \
  M(RightCurly)                                                                \
  M(QuotedString)                                                              \
  M(Integer)                                                                   \
  M(Double)                                                                    \
  M(Boolean)                                                                   \
  M(Symbol)

  // clang-format off
#define DEFINE_S_EXP_TOKEN_ENUM_LINE(name) k##name,
  enum TokenType {
    S_EXP_TOKEN_LIST(DEFINE_S_EXP_TOKEN_ENUM_LINE)
    kMaxTokens,
  };
#undef DEFINE_S_EXP_TOKEN_ENUM
  // clang-format on

  class Token : public ZoneAllocated {
   public:
    Token(TokenType type, const char* cstr, intptr_t len)
        : type_(type), cstr_(cstr), len_(len) {}

    TokenType type() const { return type_; }
    intptr_t length() const { return len_; }
    const char* cstr() const { return cstr_; }
    const char* DebugName() const { return TokenNames[type()]; }
    const char* ToCString(Zone* zone);

   private:
    static const char* const TokenNames[kMaxTokens];

    TokenType const type_;
    const char* const cstr_;
    intptr_t const len_;
  };

  SExpression* TokenToSExpression(Token* token);
  Token* GetNextToken();
  void Reset();
  void StoreError(intptr_t pos, const char* format, ...) PRINTF_ATTRIBUTE(3, 4);

  static bool IsSymbolContinue(char c);

  Zone* const zone_;
  const char* const buffer_;
  intptr_t const buffer_size_;
  intptr_t cur_pos_ = 0;
  bool in_extra_ = false;
  intptr_t extra_start_ = -1;
  const char* cur_label_;
  SExpression* cur_value_;
  ZoneGrowableArray<SExpList*> list_stack_;
  ZoneGrowableArray<bool> in_extra_stack_;
  ZoneGrowableArray<intptr_t> extra_start_stack_;
  ZoneGrowableArray<const char*> cur_label_stack_;
  intptr_t error_pos_ = -1;
  const char* error_message_;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_SEXPRESSION_H_
