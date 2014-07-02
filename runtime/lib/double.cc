// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "platform/math.h"

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
  ASSERT(TypeArguments::CheckedHandle(arguments->NativeArgAt(0)).IsNull());
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
  return big.AsValidInteger();
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
  return Bool::Get(result).raw();
}


DEFINE_NATIVE_ENTRY(Double_greaterThanFromInteger, 2) {
  const Double& right = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  return Bool::Get(left.AsDoubleValue() > right.value()).raw();
}


DEFINE_NATIVE_ENTRY(Double_equal, 2) {
  const Double& left = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right, arguments->NativeArgAt(1));
  bool result = right.IsNull() ? false : (left.value() == right.value());
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Double_equal %s == %s\n",
        left.ToCString(), right.ToCString());
  }
  return Bool::Get(result).raw();
}


DEFINE_NATIVE_ENTRY(Double_equalToInteger, 2) {
  const Double& left = Double::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, right, arguments->NativeArgAt(1));
  return Bool::Get(left.value() == right.AsDoubleValue()).raw();
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


#if defined(TARGET_OS_MACOS)
// MAC OSX math library produces old style cast warning.
#pragma GCC diagnostic ignored "-Wold-style-cast"
#endif

DEFINE_NATIVE_ENTRY(Double_toInt, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return DoubleToInteger(arg.value(), "Infinity or NaN toInt");
}


DEFINE_NATIVE_ENTRY(Double_parse, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, value, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, startValue, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, endValue, arguments->NativeArgAt(2));

  const intptr_t start = startValue.AsTruncatedUint32Value();
  const intptr_t end = endValue.AsTruncatedUint32Value();
  const intptr_t len = value.Length();

  // Indices should be inside the string, and 0 <= start < end <= len.
  if (0 <= start && start < end && end <= len) {
    double double_value;
    if (String::ParseDouble(value, start, end, &double_value)) {
      return Double::New(double_value);
    }
  }
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
    Exceptions::ThrowArgumentError(String::Handle(
        String::New("Illegal arguments to double.toStringAsFixed")));
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
    Exceptions::ThrowArgumentError(String::Handle(
        String::New("Illegal arguments to double.toStringAsExponential")));
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
    Exceptions::ThrowArgumentError(String::Handle(
        String::New("Illegal arguments to double.toStringAsPrecision")));
    return Object::null();
  }
}


DEFINE_NATIVE_ENTRY(Double_getIsInfinite, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Bool::Get(isinf(arg.value())).raw();
}


DEFINE_NATIVE_ENTRY(Double_getIsNaN, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  return Bool::Get(isnan(arg.value())).raw();
}


DEFINE_NATIVE_ENTRY(Double_getIsNegative, 1) {
  const Double& arg = Double::CheckedHandle(arguments->NativeArgAt(0));
  // Include negative zero, infinity.
  double dval = arg.value();
  return Bool::Get(signbit(dval) && !isnan(dval)).raw();
}

// Add here only functions using/referring to old-style casts.

}  // namespace dart
