// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/token.h"

#include "vm/object.h"

namespace dart {

#define TOKEN_NAME(t, s, p, a) #t,
const char* Token::name_[] = {
  DART_TOKEN_LIST(TOKEN_NAME)
  DART_KEYWORD_LIST(TOKEN_NAME)
};
#undef TOKEN_NAME

#define TOKEN_STRING(t, s, p, a) s,
const char* Token::tok_str_[] = {
  DART_TOKEN_LIST(TOKEN_STRING)
  DART_KEYWORD_LIST(TOKEN_STRING)
};
#undef TOKEN_STRING

#define TOKEN_PRECEDENCE(t, s, p, a) p,
const uint8_t Token::precedence_[] = {
  DART_TOKEN_LIST(TOKEN_PRECEDENCE)
  DART_KEYWORD_LIST(TOKEN_PRECEDENCE)
};
#undef TOKEN_PRECEDENCE

#define TOKEN_ATTRIBUTE(t, s, p, a) a,
  const Token::Attribute Token::attributes_[] = {
    DART_TOKEN_LIST(TOKEN_ATTRIBUTE)
    DART_KEYWORD_LIST(TOKEN_ATTRIBUTE)
  };
#undef TOKEN_ATTRIBUTE


Token::Kind Token::GetBinaryOp(const String& name) {
  if (name.Length() == 1) {
    switch (name.CharAt(0)) {
      case '+' : return Token::kADD;
      case '-' : return Token::kSUB;
      case '*' : return Token::kMUL;
      case '/' : return Token::kDIV;
      case '%' : return Token::kMOD;
      case '|' : return Token::kBIT_OR;
      case '^' : return Token::kBIT_XOR;
      case '&' : return Token::kBIT_AND;
      default: return Token::kILLEGAL;  // Not a binary operation.
    }
  }
  if (name.Length() == 2) {
    switch (name.CharAt(0)) {
      case '|' : return name.CharAt(1) == '|' ? Token::kOR : Token::kILLEGAL;
      case '&' : return name.CharAt(1) == '&' ? Token::kAND : Token::kILLEGAL;
      case '<' : return name.CharAt(1) == '<' ? Token::kSHL : Token::kILLEGAL;
      case '>' : return name.CharAt(1) == '>' ? Token::kSHR : Token::kILLEGAL;
      case '~' :
          return name.CharAt(1) == '/' ? Token::kTRUNCDIV : Token::kILLEGAL;
      default: return Token::kILLEGAL;  // Not a binary operation.
    }
  }
  return Token::kILLEGAL;
}


}  // namespace dart
