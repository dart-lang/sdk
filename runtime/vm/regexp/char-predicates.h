// Copyright 2011 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef V8_STRINGS_CHAR_PREDICATES_H_
#define V8_STRINGS_CHAR_PREDICATES_H_

#include "platform/unicode.h"
#include "vm/regexp/base.h"

namespace dart {

// Unicode character predicates as defined by ECMA-262, 3rd,
// used for lexical analysis.

inline constexpr int AsciiAlphaToLower(base::uc32 c);
inline constexpr bool IsCarriageReturn(base::uc32 c);
inline constexpr bool IsLineFeed(base::uc32 c);
inline constexpr bool IsAsciiIdentifier(base::uc32 c);
inline constexpr bool IsAlphaNumeric(base::uc32 c);
inline constexpr bool IsDecimalDigit(base::uc32 c);
inline constexpr bool IsHexDigit(base::uc32 c);
inline constexpr bool IsOctalDigit(base::uc32 c);
inline constexpr bool IsBinaryDigit(base::uc32 c);
inline constexpr bool IsRegExpWord(base::uc32 c);

template <typename Char>
inline constexpr bool IsAsciiLower(Char ch);
template <typename Char>
inline constexpr bool IsAsciiUpper(Char ch);

inline constexpr base::uc32 ToAsciiUpper(base::uc32 ch);
inline constexpr base::uc32 ToAsciiLower(base::uc32 ch);

// ES#sec-names-and-keywords
// This includes '_', '$' and '\', and ID_Start according to
// http://www.unicode.org/reports/tr31/, which consists of categories
// 'Lu', 'Ll', 'Lt', 'Lm', 'Lo', 'Nl', but excluding properties
// 'Pattern_Syntax' or 'Pattern_White_Space'.
inline bool IsIdentifierStart(base::uc32 c);
bool IsIdentifierStartSlow(base::uc32 c);

// ES#sec-names-and-keywords
// This includes \u200c and \u200d, and ID_Continue according to
// http://www.unicode.org/reports/tr31/, which consists of ID_Start,
// the categories 'Mn', 'Mc', 'Nd', 'Pc', but excluding properties
// 'Pattern_Syntax' or 'Pattern_White_Space'.
inline bool IsIdentifierPart(base::uc32 c);
bool IsIdentifierPartSlow(base::uc32 c);

// ES6 draft section 11.2
// This includes all code points of Unicode category 'Zs'.
// Further included are \u0009, \u000b, \u000c, and \ufeff.
inline bool IsWhiteSpace(base::uc32 c);
bool IsWhiteSpaceSlow(base::uc32 c);

// WhiteSpace and LineTerminator according to ES6 draft section 11.2 and 11.3
// This includes all the characters with Unicode category 'Z' (= Zs+Zl+Zp)
// as well as \u0009 - \u000d and \ufeff.
inline bool IsWhiteSpaceOrLineTerminator(base::uc32 c);
inline bool IsWhiteSpaceOrLineTerminatorSlow(base::uc32 c) {
  return IsWhiteSpaceSlow(c) || IsLineTerminator(c);
}

inline bool IsLineTerminatorSequence(base::uc32 c, base::uc32 next);

}  // namespace dart

#endif  // V8_STRINGS_CHAR_PREDICATES_H_
