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
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(MathNatives_sqrt, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sqrt(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_sin, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sin(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_cos, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(cos(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_tan, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(tan(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_asin, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(asin(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_acos, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(acos(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_atan, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(atan(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_atan2, 2) {
  GET_NATIVE_ARGUMENT(Double, operand1, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Double, operand2, arguments->NativeArgAt(1));
  return Double::New(atan2(operand1.value(), operand2.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_exp, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(exp(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_log, 1) {
  GET_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(log(operand.value()));
}

DEFINE_NATIVE_ENTRY(MathNatives_random, 0) {
  return Double::New(static_cast<double>(Random::RandomInt32()-1)/0x80000000);
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
      ((tokens[0].kind == Token::kTIGHTADD) ||
          (tokens[0].kind == Token::kSUB)) &&
      (tokens[1].kind == literal_kind) &&
      (tokens[2].kind == Token::kEOS)) {
    // Check there is no space between "+/-" and number.
    if ((tokens[0].offset + 1) != tokens[1].offset) {
      return false;
    }
    *is_positive = tokens[0].kind == Token::kTIGHTADD;
    *value = tokens[1].literal;
    return true;
  }
  return false;
}


DEFINE_NATIVE_ENTRY(MathNatives_parseInt, 1) {
  GET_NATIVE_ARGUMENT(String, value, arguments->NativeArgAt(0));
  const String& dummy_key = String::Handle(Symbols::Empty());
  Scanner scanner(value, dummy_key);
  const Scanner::GrowableTokenStream& tokens = scanner.GetStream();
  String* int_string;
  bool is_positive;
  if (IsValidLiteral(tokens, Token::kINTEGER, &is_positive, &int_string)) {
    if (is_positive) {
      return Integer::New(*int_string);
    } else {
      String& temp = String::Handle();
      temp = String::Concat(String::Handle(Symbols::New("-")),
                            *int_string);
      return Integer::New(temp);
    }
  } else {
    GrowableArray<const Object*> args;
    args.Add(&value);
    Exceptions::ThrowByType(Exceptions::kFormat, args);
    return Object::null();
  }
}


DEFINE_NATIVE_ENTRY(MathNatives_parseDouble, 1) {
  GET_NATIVE_ARGUMENT(String, value, arguments->NativeArgAt(0));
  const String& dummy_key = String::Handle(Symbols::Empty());
  Scanner scanner(value, dummy_key);
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
    return Double::New(double_value);
  }

  if (IsValidLiteral(tokens, Token::kINTEGER, &is_positive, &number_string)) {
    Integer& res = Integer::Handle(Integer::New(*number_string));
    if (is_positive) {
      return Double::New(res.AsDoubleValue());
    } else {
      return Double::New(-res.AsDoubleValue());
    }
  }

  // Infinity and nan.
  if (IsValidLiteral(tokens, Token::kIDENT, &is_positive, &number_string)) {
    if (number_string->Equals("NaN")) {
      return Double::New(NAN);
    }
    if (number_string->Equals("Infinity")) {
      if (is_positive) {
        return Double::New(INFINITY);
      } else {
        return Double::New(-INFINITY);
      }
    }
  }

  GrowableArray<const Object*> args;
  args.Add(&value);
  Exceptions::ThrowByType(Exceptions::kFormat, args);
  return Object::null();
}

}  // namespace dart
