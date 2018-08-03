// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/token.h"

#include "vm/object.h"

namespace dart {

#define TOKEN_NAME(t, s, p, a) #t,
const char* Token::name_[] = {DART_TOKEN_LIST(TOKEN_NAME)
                                  DART_KEYWORD_LIST(TOKEN_NAME)};
#undef TOKEN_NAME

#define TOKEN_STRING(t, s, p, a) s,
const char* Token::tok_str_[] = {DART_TOKEN_LIST(TOKEN_STRING)
                                     DART_KEYWORD_LIST(TOKEN_STRING)};
#undef TOKEN_STRING

#define TOKEN_PRECEDENCE(t, s, p, a) p,
const uint8_t Token::precedence_[] = {DART_TOKEN_LIST(TOKEN_PRECEDENCE)
                                          DART_KEYWORD_LIST(TOKEN_PRECEDENCE)};
#undef TOKEN_PRECEDENCE

#define TOKEN_ATTRIBUTE(t, s, p, a) a,
const Token::Attribute Token::attributes_[] = {
    DART_TOKEN_LIST(TOKEN_ATTRIBUTE) DART_KEYWORD_LIST(TOKEN_ATTRIBUTE)};
#undef TOKEN_ATTRIBUTE

bool Token::IsBinaryOperator(Token::Kind token) {
  switch (token) {
    case Token::kOR:
    case Token::kAND:
      return true;
    default:
      return IsBinaryArithmeticOperator(token);
  }
}

bool Token::IsUnaryOperator(Token::Kind token) {
  return (token == kNOT) || IsUnaryArithmeticOperator(token);
}

bool Token::IsBinaryArithmeticOperator(Token::Kind token) {
  switch (token) {
    case Token::kADD:
    case Token::kSUB:
    case Token::kMUL:
    case Token::kDIV:
    case Token::kTRUNCDIV:
    case Token::kMOD:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      return true;
    default:
      return false;
  }
}

bool Token::IsUnaryArithmeticOperator(Token::Kind token) {
  return (token == kBIT_NOT) || (token == kNEGATE);
}

bool Token::IsBinaryBitwiseOperator(Token::Kind token) {
  switch (token) {
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kSHL:
    case Token::kSHR:
      return true;
    default:
      return false;
  }
}

}  // namespace dart
