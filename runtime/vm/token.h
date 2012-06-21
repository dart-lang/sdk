// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TOKEN_H_
#define VM_TOKEN_H_

#include "platform/assert.h"

namespace dart {

//  Operator precedence table
//
//  13  multiplicative  * / ~/ %
//  12  additive        + -
//  11  shift           << >>
//  10  relational      >= > <= < is
//   9  equality        == != === !==
//   8  bitwise and     &
//   7  bitwise xor     ^
//   6  bitwise or      |
//   5  logical and     &&
//   4  logical or      ||
//   3  conditional     ?
//   2  assignment      = *= /= ~/= %= += -= <<= >>= &= ^= |=
//   1  comma           ,


// Token definitions.
// Some operator tokens appear in blocks, e.g. assignment operators.
// There is code that depends on the values within a block to be
// contiguous, and on the order of values.
#define DART_TOKEN_LIST(TOK)                                                   \
  TOK(kEOS, "", 0, kNoAttribute)                                               \
                                                                               \
  TOK(kLPAREN, "(", 0, kNoAttribute)                                           \
  TOK(kRPAREN, ")", 0, kNoAttribute)                                           \
  TOK(kLBRACK, "[", 0, kNoAttribute)                                           \
  TOK(kRBRACK, "]", 0, kNoAttribute)                                           \
  TOK(kLBRACE, "{", 0, kNoAttribute)                                           \
  TOK(kRBRACE, "}", 0, kNoAttribute)                                           \
  TOK(kARROW, "=>", 0, kNoAttribute)                                           \
  TOK(kCOLON,  ":", 0, kNoAttribute)                                           \
  TOK(kSEMICOLON, ";", 0, kNoAttribute)                                        \
  TOK(kPERIOD, ".", 0, kNoAttribute)                                           \
  TOK(kINCR,   "++", 0, kNoAttribute)                                          \
  TOK(kDECR,   "--", 0, kNoAttribute)                                          \
                                                                               \
  /* Assignment operators.                            */                       \
  /* Please update IsAssignmentOperator() if you make */                       \
  /* any changes to this block.                       */                       \
  TOK(kASSIGN, "=", 2, kNoAttribute)                                           \
  TOK(kASSIGN_OR, "|=", 2, kNoAttribute)                                       \
  TOK(kASSIGN_XOR, "^=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_AND, "&=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_SHL, "<<=", 2, kNoAttribute)                                     \
  TOK(kASSIGN_SHR, ">>=", 2, kNoAttribute)                                     \
  TOK(kASSIGN_ADD, "+=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_SUB, "-=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_MUL, "*=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_TRUNCDIV, "~/=", 2, kNoAttribute)                                \
  TOK(kASSIGN_DIV, "/=", 2, kNoAttribute)                                      \
  TOK(kASSIGN_MOD, "%=", 2, kNoAttribute)                                      \
                                                                               \
  TOK(kCOMMA, ",", 1, kNoAttribute)                                            \
  TOK(kOR, "||", 4, kNoAttribute)                                              \
  TOK(kAND, "&&", 5, kNoAttribute)                                             \
  TOK(kBIT_OR, "|", 6, kNoAttribute)                                           \
  TOK(kBIT_XOR, "^", 7, kNoAttribute)                                          \
  TOK(kBIT_AND, "&", 8, kNoAttribute)                                          \
  TOK(kBIT_NOT, "~", 0, kNoAttribute)                                          \
                                                                               \
  /* Shift operators. */                                                       \
  TOK(kSHL, "<<", 11, kNoAttribute)                                            \
  TOK(kSHR, ">>", 11, kNoAttribute)                                            \
                                                                               \
  /* Additive operators. */                                                    \
  TOK(kADD, "+", 12, kNoAttribute)                                             \
  TOK(kSUB, "-", 12, kNoAttribute)                                             \
  /* A 'plus' without a trailing whitespace (handle literals). */              \
  TOK(kTIGHTADD, "+", 12, kNoAttribute)                                        \
                                                                               \
  /* Multiplicative operators */                                               \
  TOK(kMUL, "*", 13, kNoAttribute)                                             \
  TOK(kDIV, "/", 13, kNoAttribute)                                             \
  TOK(kTRUNCDIV, "~/", 13, kNoAttribute)                                       \
  TOK(kMOD, "%", 13, kNoAttribute)                                             \
                                                                               \
  TOK(kNOT, "!", 0, kNoAttribute)                                              \
  TOK(kCONDITIONAL, "?", 3, kNoAttribute)                                      \
                                                                               \
  /* Equality operators.                             */                        \
  /* Please update IsEqualityOperator() if you make  */                        \
  /* any changes to this block.                      */                        \
  TOK(kEQ, "==", 9, kNoAttribute)                                              \
  TOK(kNE, "!=", 9, kNoAttribute)                                              \
  TOK(kEQ_STRICT, "===", 9, kNoAttribute)                                      \
  TOK(kNE_STRICT, "!==", 9, kNoAttribute)                                      \
                                                                               \
  /* Relational operators.                             */                      \
  /* Please update IsRelationalOperator() if you make  */                      \
  /* any changes to this block.                        */                      \
  TOK(kLT, "<", 10, kNoAttribute)                                              \
  TOK(kGT, ">", 10, kNoAttribute)                                              \
  TOK(kLTE, "<=", 10, kNoAttribute)                                            \
  TOK(kGTE, ">=", 10, kNoAttribute)                                            \
                                                                               \
  /* Internal token for !(expr is Type) negative type test operator */         \
  TOK(kISNOT, "", 0, kNoAttribute)                                             \
                                                                               \
  TOK(kINDEX, "[]", 0, kNoAttribute)                                           \
  TOK(kASSIGN_INDEX, "[]=", 0, kNoAttribute)                                   \
                                                                               \
  TOK(kIDENT, "", 0, kNoAttribute)                                             \
  TOK(kSTRING, "", 0, kNoAttribute)                                            \
  TOK(kINTEGER, "", 0, kNoAttribute)                                           \
  TOK(kDOUBLE, "", 0, kNoAttribute)                                            \
                                                                               \
  TOK(kINTERPOL_VAR, "", 0, kNoAttribute)                                      \
  TOK(kINTERPOL_START, "", 0, kNoAttribute)                                    \
  TOK(kINTERPOL_END, "", 0, kNoAttribute)                                      \
                                                                               \
  TOK(kWHITESP, "", 0, kNoAttribute)                                           \
  TOK(kERROR, "", 0, kNoAttribute)                                             \
  TOK(kILLEGAL, "", 0, kNoAttribute)                                           \
                                                                               \
  /* Support for Dart scripts. */                                              \
  TOK(kSCRIPTTAG, "#!", 0, kNoAttribute)                                       \
  TOK(kLIBRARY, "#library", 0, kNoAttribute)                                   \
  TOK(kIMPORT, "#import", 0, kNoAttribute)                                     \
  TOK(kSOURCE, "#source", 0, kNoAttribute)                                     \
  TOK(kRESOURCE, "#resource", 0, kNoAttribute)                                 \

// List of keywords. The list must be alphabetically ordered. The
// keyword recognition code depends on the ordering.
// If you add a keyword at the beginning or end of this list, make sure
// to update kFirstKeyword and kLastKeyword below.
#define DART_KEYWORD_LIST(KW)                                                  \
  KW(kABSTRACT, "abstract", 0, kPseudoKeyword) /* == kFirstKeyword */          \
  KW(kASSERT, "assert", 0, kPseudoKeyword)                                     \
  KW(kBREAK, "break", 0, kKeyword)                                             \
  KW(kCASE, "case", 0, kKeyword)                                               \
  KW(kCATCH, "catch", 0, kKeyword)                                             \
  KW(kCLASS, "class", 0, kKeyword)                                             \
  KW(kCONST, "const", 0, kKeyword)                                             \
  KW(kCONTINUE, "continue", 0, kKeyword)                                       \
  KW(kDEFAULT, "default", 0, kKeyword)                                         \
  KW(kDO, "do", 0, kKeyword)                                                   \
  KW(kELSE, "else", 0, kKeyword)                                               \
  KW(kEXTENDS, "extends", 0, kKeyword)                                         \
  KW(kFACTORY, "factory", 0, kPseudoKeyword)                                   \
  KW(kFALSE, "false", 0, kKeyword)                                             \
  KW(kFINAL, "final", 0, kKeyword)                                             \
  KW(kFINALLY, "finally", 0, kKeyword)                                         \
  KW(kFOR, "for", 0, kKeyword)                                                 \
  KW(kGET, "get", 0, kPseudoKeyword)                                           \
  KW(kIF, "if", 0, kKeyword)                                                   \
  KW(kIMPLEMENTS, "implements", 0, kPseudoKeyword)                             \
  KW(kIN, "in", 0, kKeyword)                                                   \
  KW(kINTERFACE, "interface", 0, kPseudoKeyword)                               \
  KW(kIS, "is", 10, kKeyword)                                                  \
  KW(kNEGATE, "negate", 0, kPseudoKeyword)                                     \
  KW(kNEW, "new", 0, kKeyword)                                                 \
  KW(kNULL, "null", 0, kKeyword)                                               \
  KW(kOPERATOR, "operator", 0, kPseudoKeyword)                                 \
  KW(kRETURN, "return", 0, kKeyword)                                           \
  KW(kSET, "set", 0, kPseudoKeyword)                                           \
  KW(kSTATIC, "static", 0, kPseudoKeyword)                                     \
  KW(kSUPER, "super", 0, kKeyword)                                             \
  KW(kSWITCH, "switch", 0, kKeyword)                                           \
  KW(kTHIS, "this", 0, kKeyword)                                               \
  KW(kTHROW, "throw", 0, kKeyword)                                             \
  KW(kTRUE, "true", 0, kKeyword)                                               \
  KW(kTRY, "try", 0, kKeyword)                                                 \
  KW(kTYPEDEF, "typedef", 0, kPseudoKeyword)                                   \
  KW(kVAR, "var", 0, kKeyword)                                                 \
  KW(kVOID, "void", 0, kKeyword)                                               \
  KW(kWHILE, "while", 0, kKeyword) /* == kLastKeyword */


class String;

class Token {
 public:
#define T(t, s, p, a) t,
  enum Kind {
    DART_TOKEN_LIST(T)
    DART_KEYWORD_LIST(T)
    kNumTokens
  };
#undef T

  enum Attribute {
    kNoAttribute     = 0,
    kKeyword         = 1 << 0,
    kPseudoKeyword   = 1 << 1,
  };

  static const Kind kFirstKeyword = kABSTRACT;
  static const Kind kLastKeyword = kWHILE;
  static const int  numKeywords = kWHILE - kABSTRACT + 1;

  static bool IsAssignmentOperator(Kind tok) {
    return kASSIGN <= tok && tok <= kASSIGN_MOD;
  }

  static bool IsRelationalOperator(Kind tok) {
    return kLT <= tok && tok <= kGTE;
  }

  static bool IsEqualityOperator(Kind tok) {
    return kEQ <= tok && tok <= kNE_STRICT;
  }

  static bool IsInstanceofOperator(Kind tok) {
    return (tok == kIS) || (tok == kISNOT);
  }

  static bool IsPseudoKeyword(Kind tok) {
    return (Attributes(tok) & kPseudoKeyword) != 0;
  }

  static bool IsKeyword(Kind tok) {
    return (Attributes(tok) & kKeyword) != 0;
  }

  static bool IsIdentifier(Kind tok) {
    return (tok == kIDENT) || IsPseudoKeyword(tok);
  }

  static const char* Name(Kind tok) {
    ASSERT(tok < kNumTokens);
    return name_[tok];
  }

  static const char* Str(Kind tok) {
    ASSERT(tok < kNumTokens);
    return tok_str_[tok];
  }

  static int Precedence(Kind tok) {
    ASSERT(tok < kNumTokens);
    return precedence_[tok];
  }

  static Attribute Attributes(Kind tok) {
    ASSERT(tok < kNumTokens);
    return attributes_[tok];
  }

  static bool CanBeOverloaded(Kind tok) {
    ASSERT(tok < kNumTokens);
    return IsRelationalOperator(tok) ||
           (tok == kEQ) ||
           (tok >= kADD && tok <= kMOD) ||  // Arithmetic operations.
           (tok >= kBIT_OR && tok <= kSHR) ||  // Bit operations.
           (tok == kINDEX) ||
           (tok == kASSIGN_INDEX) ||
           (tok == kNEGATE);
  }

  static bool NeedsLiteralToken(Kind tok) {
    ASSERT(tok < kNumTokens);
    return ((tok == Token::kINTEGER) ||
            (tok == Token::kSTRING) ||
            (tok == Token::kINTERPOL_VAR) ||
            (tok == Token::kERROR) ||
            (tok == Token::kDOUBLE));
  }

  static bool IsBinaryToken(Token::Kind token);
  static bool IsUnaryToken(Token::Kind token);

 private:
  static const char* name_[];
  static const char* tok_str_[];
  static const uint8_t precedence_[];
  static const Attribute attributes_[];
};


}  // namespace dart

#endif  // VM_TOKEN_H_
