// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <ctype.h>  // isspace.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/random.h"
#include "vm/scanner.h"

namespace dart {

DEFINE_NATIVE_ENTRY(MathNatives_sqrt, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(sqrt(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_sin, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(sin(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_cos, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(cos(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_tan, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(tan(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_asin, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(asin(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_acos, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(acos(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_atan, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(atan(operand))));
}

// It is not possible to call the native MathNatives_atan2. Somehow this leads
// to a dynamic error "native function 'MathNatives_atan2' cannot be found".
DEFINE_NATIVE_ENTRY(MathNatives_2atan, 2) {
  const double operand1 = Double::CheckedHandle(arguments->At(0)).value();
  const double operand2 = Double::CheckedHandle(arguments->At(1)).value();
  arguments->SetReturn(Double::Handle(Double::New(atan2(operand1, operand2))));
}

DEFINE_NATIVE_ENTRY(MathNatives_exp, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(exp(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_log, 1) {
  const double operand = Double::CheckedHandle(arguments->At(0)).value();
  arguments->SetReturn(Double::Handle(Double::New(log(operand))));
}

DEFINE_NATIVE_ENTRY(MathNatives_random, 0) {
  arguments->SetReturn(Double::Handle(Double::
      New(static_cast<double>(Random::RandomInt32()-1)/0x80000000)));
}


// TODO(srdjan): Investigate for performance hit; the integer and double parsing
// may not be efficient as we need to generate two extra growable arrays.
static bool IsValidLiteral(const Scanner::GrowableTokenStream& tokens,
                           Token::Kind literal_kind,
                           bool* is_positive,
                           String** value) {
  if ((tokens.length() == 2) &&
      (tokens[0].kind == literal_kind) &&
      (tokens[1].kind == Token::kEOS)) {
    *is_positive = true;
    *value = tokens[0].literal;
    return true;
  }
  if ((tokens.length() == 3) &&
      ((tokens[0].kind == Token::kADD) || (tokens[0].kind == Token::kSUB)) &&
      (tokens[1].kind == literal_kind) &&
      (tokens[2].kind == Token::kEOS)) {
    // Check there is no space between "+/-" and number.
    if ((tokens[0].offset + 1) != tokens[1].offset) {
      return false;
    }
    *is_positive = tokens[0].kind == Token::kADD;
    *value = tokens[1].literal;
    return true;
  }
  return false;
}


DEFINE_NATIVE_ENTRY(MathNatives_parseInt, 1) {
  const String& value = String::CheckedHandle(arguments->At(0));
  Scanner scanner(value, String::Handle());
  const Scanner::GrowableTokenStream& tokens = scanner.GetStream();
  String* int_string;
  bool is_positive;
  if (IsValidLiteral(tokens, Token::kINTEGER, &is_positive, &int_string)) {
    Integer& result = Integer::Handle();
    if (is_positive) {
      result = Integer::New(*int_string);
    } else {
      String& temp = String::Handle();
      temp = String::Concat(String::Handle(String::NewSymbol("-")),
                            *int_string);
      result = Integer::New(temp);
    }
    arguments->SetReturn(result);
  } else {
    GrowableArray<const Object*> args;
    args.Add(&value);
    Exceptions::ThrowByType(Exceptions::kBadNumberFormat, args);
  }
}


DEFINE_NATIVE_ENTRY(MathNatives_parseDouble, 1) {
  const String& value = String::CheckedHandle(arguments->At(0));
  Scanner scanner(value, String::Handle());
  const Scanner::GrowableTokenStream& tokens = scanner.GetStream();
  String* number_string;
  bool is_positive;
  if (IsValidLiteral(tokens, Token::kDOUBLE, &is_positive, &number_string)) {
    const char* cstr = number_string->ToCString();
    char* p_end = NULL;
    double double_value = strtod(cstr, &p_end);
    ASSERT(p_end != cstr);
    if (!is_positive) {
      double_value = -double_value;
    }
    Double& result = Double::Handle(Double::New(double_value));
    arguments->SetReturn(result);
    return;
  }

  if (IsValidLiteral(tokens, Token::kINTEGER, &is_positive, &number_string)) {
    Integer& res = Integer::Handle(Integer::New(*number_string));
    if (is_positive) {
      arguments->SetReturn(Double::Handle(Double::New(res.AsDoubleValue())));
    } else {
      arguments->SetReturn(Double::Handle(Double::New(-res.AsDoubleValue())));
    }
    return;
  }

  // Infinity and nan.
  if (IsValidLiteral(tokens, Token::kIDENT, &is_positive, &number_string)) {
    if (number_string->Equals("NaN")) {
      arguments->SetReturn(Double::Handle(Double::New(NAN)));
      return;
    }
    if (number_string->Equals("Infinity")) {
      if (is_positive) {
        arguments->SetReturn(Double::Handle(Double::New(INFINITY)));
      } else {
        arguments->SetReturn(Double::Handle(Double::New(-INFINITY)));
      }
      return;
    }
  }

  GrowableArray<const Object*> args;
  args.Add(&value);
  Exceptions::ThrowByType(Exceptions::kBadNumberFormat, args);
}

}  // namespace dart
