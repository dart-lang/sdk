// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/token.h"

namespace dart {

#define TOKEN_NAME(t, s, p, a) #t,
const char* Token::name_[kNumTokens] = {
  DART_TOKEN_LIST(TOKEN_NAME)
  DART_KEYWORD_LIST(TOKEN_NAME)
};
#undef TOKEN_NAME

#define TOKEN_STRING(t, s, p, a) s,
const char* Token::tok_str_[kNumTokens] = {
  DART_TOKEN_LIST(TOKEN_STRING)
  DART_KEYWORD_LIST(TOKEN_STRING)
};
#undef TOKEN_STRING

#define TOKEN_PRECEDENCE(t, s, p, a) p,
const uint8_t Token::precedence_[kNumTokens] = {
  DART_TOKEN_LIST(TOKEN_PRECEDENCE)
  DART_KEYWORD_LIST(TOKEN_PRECEDENCE)
};
#undef TOKEN_PRECEDENCE

#define TOKEN_ATTRIBUTE(t, s, p, a) a,
  const Token::Attribute Token::attributes_[kNumTokens] = {
    DART_TOKEN_LIST(TOKEN_ATTRIBUTE)
    DART_KEYWORD_LIST(TOKEN_ATTRIBUTE)
  };
#undef TOKEN_ATTRIBUTE


}  // namespace dart
