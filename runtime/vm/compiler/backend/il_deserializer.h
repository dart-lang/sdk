// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_
#define RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_

#include "vm/allocation.h"
#include "vm/compiler/backend/sexpression.h"
#include "vm/growable_array.h"
#include "vm/zone.h"

namespace dart {

class SExpParser : public ValueObject {
 public:
  SExpParser(Zone* zone, const char* cstr)
      : SExpParser(zone, cstr, strlen(cstr)) {}
  SExpParser(Zone* zone, const char* cstr, intptr_t len)
      : zone_(zone),
        buffer_(cstr),
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

  SExpression* Parse();
  void ReportError() const;

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
  void StoreError(intptr_t pos, const char* format, ...);

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

#endif  // RUNTIME_VM_COMPILER_BACKEND_IL_DESERIALIZER_H_
