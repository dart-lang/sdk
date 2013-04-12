// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <math.h>

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/code_generator.h"  // DartModulo.
#include "vm/double_conversion.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, trace_intrinsified_natives);

DEFINE_NATIVE_ENTRY(Double_doubleFromInteger, 2) {
  ASSERT(AbstractTypeArguments::CheckedHandle(
      arguments->NativeArgAt(0)).IsNull());
  const Integer& value = Integer::CheckedHandle(arguments->NativeArgAt(1));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_doubleFromInteger %s\n", value.ToCString());
  }
  return Double::New(value.AsDoubleValue());
}


DEFINE_NATIVE_ENTRY(Double_add, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_add %f + %f\n", left, right);
  }
  return Double::New(left + right);
}


DEFINE_NATIVE_ENTRY(Double_sub, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_sub %f - %f\n", left, right);
  }
  return Double::New(left - right);
}


DEFINE_NATIVE_ENTRY(Double_mul, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_mul %f * %f\n", left, right);
  }
  return Double::New(left * right);
}


DEFINE_NATIVE_ENTRY(Double_div, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_div %f / %f\n", left, right);
  }
  return Double::New(left / right);
}


static RawInteger* DoubleToInteger(double val, const char* error_msg) {
  if (isinf(val) || isnan(val)) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, String::Handle(String::New(error_msg)));
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  const Bigint& big = Bigint::Handle(BigintOperations::NewFromDouble(val));
  if (BigintOperations::FitsIntoSmi(big)) {
    return BigintOperations::ToSmi(big);
  } else if (BigintOperations::FitsIntoMint(big)) {
    return Mint::New(BigintOperations::ToMint(big));
  } else {
    return big.raw();
  }
}

DEFINE_NATIVE_ENTRY(Double_trunc_div, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_trunc_div %f ~/ %f\n", left, right);
  }
  return DoubleToInteger(trunc(left / right),
                         "Result of truncating division is Infinity or NaN");
}


DEFINE_NATIVE_ENTRY(Double_modulo, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  return Double::New(DartModulo(left, right));
}


DEFINE_NATIVE_ENTRY(Double_remainder, 2) {
  double left = Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  return Double::New(fmod_ieee(left, right));
}


DEFINE_NATIVE_ENTRY(Double_greaterThan, 2) {
  const Double& left = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right, arguments->NativeArgAt(1));
  bool result = right.IsNull() ? false : (left.value() > right.value());
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_greaterThan %s > %s\n",
        left.ToCString(), right.ToCString());
  }
  return Bool::Get(result);
}


DEFINE_NATIVE_ENTRY(Double_greaterThanFromInteger, 2) {
  const Double& right = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  return Bool::Get(left.AsDoubleValue() > right.value());
}


DEFINE_NATIVE_ENTRY(Double_equal, 2) {
  const Double& left = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right, arguments->NativeArgAt(1));
  bool result = right.IsNull() ? false : (left.value() == right.value());
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_equal %s == %s\n",
        left.ToCString(), right.ToCString());
  }
  return Bool::Get(result);
}


DEFINE_NATIVE_ENTRY(Double_equalToInteger, 2) {
  const Double& left = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, right, arguments->NativeArgAt(1));
  return Bool::Get(left.value() == right.AsDoubleValue());
}


DEFINE_NATIVE_ENTRY(Double_round, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Double::New(round(arg.value()));
}

DEFINE_NATIVE_ENTRY(Double_floor, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Double::New(floor(arg.value()));
}

DEFINE_NATIVE_ENTRY(Double_ceil, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Double::New(ceil(arg.value()));
}


DEFINE_NATIVE_ENTRY(Double_truncate, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Double::New(trunc(arg.value()));
}


DEFINE_NATIVE_ENTRY(Double_pow, 2) {
  const double operand =
      Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(
      Double, exponent_object, arguments->NativeArgAt(1));
  const double exponent = exponent_object.value();
  return Double::New(pow(operand, exponent));
}


#if defined(TARGET_OS_MACOS)
// MAC OSX math library produces old style cast warning.
#pragma GCC diagnostic ignored "-Wold-style-cast"
#endif

DEFINE_NATIVE_ENTRY(Double_toInt, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return DoubleToInteger(arg.value(), "Infinity or NaN toInt");
}


DEFINE_NATIVE_ENTRY(Double_parse, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, value, arguments->NativeArgAt(0));
  if (value.IsOneByteString()) {
    // Quick conversion for unpadded doubles in strings.
    const intptr_t len = value.Length();
    if (len > 0) {
      const char* cstr = value.ToCString();
      ASSERT(cstr != NULL);
      // Dart differences from strtod:
      // a) '5.' is not a valid double (no digit after period).
      // b) '+5.0' is not a valid double (leading plus).
      if (cstr[0] != '+') {
        bool dot_ok = true;
        const char* tmp = cstr;
        while (*tmp != '\0') {
          const char ch = *tmp++;
          if (ch == '.') {
            const char nextCh = *tmp;
            dot_ok = ('0' <= nextCh) && (nextCh <= '9');
            break;
          }
        }
        if (dot_ok) {
          double double_value;
          if (CStringToDouble(cstr, len, &double_value)) {
            return Double::New(double_value);
          }
        }
      }
    }
  }
  Scanner scanner(value, Symbols::Empty());
  const Scanner::GrowableTokenStream& tokens = scanner.GetStream();
  String* number_string;
  bool is_positive;
  if (Scanner::IsValidLiteral(tokens,
                              Token::kDOUBLE,
                              &is_positive,
                              &number_string)) {
    // Even if original string was two byte string the scanner should produce
    // literal value that is represented as a one byte string because all
    // characters in the double literal are Latin-1.
    ASSERT(number_string->IsOneByteString());
    const char* cstr = number_string->ToCString();

    double double_value;
    bool ok = CStringToDouble(cstr, number_string->Length(), &double_value);
    ASSERT(ok);

    if (!is_positive) {
      double_value = -double_value;
    }
    return Double::New(double_value);
  }

  if (Scanner::IsValidLiteral(tokens,
                              Token::kINTEGER,
                              &is_positive,
                              &number_string)) {
    Integer& res = Integer::Handle(Integer::New(*number_string));
    if (is_positive) {
      return Double::New(res.AsDoubleValue());
    }
    return Double::New(-res.AsDoubleValue());
  }

  // Infinity and nan.
  if (Scanner::IsValidLiteral(tokens,
                              Token::kIDENT,
                              &is_positive,
                              &number_string)) {
    if (number_string->Equals("NaN")) {
      return Double::New(NAN);
    }
    if (number_string->Equals("Infinity")) {
      if (is_positive) {
        return Double::New(INFINITY);
      }
      return Double::New(-INFINITY);
    }
  }

  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, value);
  Exceptions::ThrowByType(Exceptions::kFormat, args);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(Double_toStringAsFixed, 2) {
  // The boundaries are exclusive.
  static const double kLowerBoundary = -1e21;
  static const double kUpperBoundary = 1e21;

  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, fraction_digits, arguments->NativeArgAt(1));
  double d = arg.value();
  intptr_t fraction_digits_value = fraction_digits.Value();
  if (0 <= fraction_digits_value && fraction_digits_value <= 20
      && kLowerBoundary < d && d < kUpperBoundary) {
    return DoubleToStringAsFixed(d, static_cast<int>(fraction_digits_value));
  } else {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, String::Handle(
        String::New("Illegal arguments to double.toStringAsFixed")));
    Exceptions::ThrowByType(Exceptions::kArgument, args);
    return Object::null();
  }
}


DEFINE_NATIVE_ENTRY(Double_toStringAsExponential, 2) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, fraction_digits, arguments->NativeArgAt(1));
  double d = arg.value();
  intptr_t fraction_digits_value = fraction_digits.Value();
  if (-1 <= fraction_digits_value && fraction_digits_value <= 20) {
    return DoubleToStringAsExponential(
        d, static_cast<int>(fraction_digits_value));
  } else {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, String::Handle(
        String::New("Illegal arguments to double.toStringAsExponential")));
    Exceptions::ThrowByType(Exceptions::kArgument, args);
    return Object::null();
  }
}


DEFINE_NATIVE_ENTRY(Double_toStringAsPrecision, 2) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, precision, arguments->NativeArgAt(1));
  double d = arg.value();
  intptr_t precision_value = precision.Value();
  if (1 <= precision_value && precision_value <= 21) {
    return DoubleToStringAsPrecision(d, static_cast<int>(precision_value));
  } else {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, String::Handle(
        String::New("Illegal arguments to double.toStringAsPrecision")));
    Exceptions::ThrowByType(Exceptions::kArgument, args);
    return Object::null();
  }
}


DEFINE_NATIVE_ENTRY(Double_getIsInfinite, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Bool::Get(isinf(arg.value()));
}


DEFINE_NATIVE_ENTRY(Double_getIsNaN, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Bool::Get(isnan(arg.value()));
}


DEFINE_NATIVE_ENTRY(Double_getIsNegative, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  // Include negative zero, infinity.
  return Bool::Get(signbit(arg.value()) && !isnan(arg.value()));
}

// Add here only functions using/referring to old-style casts.

}  // namespace dart
