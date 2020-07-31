// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include <math.h>

#include "vm/dart_entry.h"
#include "vm/double_conversion.h"
#include "vm/double_internals.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"  // DartModulo.
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Double_doubleFromInteger, 0, 2) {
  ASSERT(
      TypeArguments::CheckedHandle(zone, arguments->NativeArgAt(0)).IsNull());
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, value, arguments->NativeArgAt(1));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_doubleFromInteger %s\n", value.ToCString());
  }
  return Double::New(value.AsDoubleValue());
}

DEFINE_NATIVE_ENTRY(Double_add, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_add %f + %f\n", left, right);
  }
  return Double::New(left + right);
}

DEFINE_NATIVE_ENTRY(Double_sub, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_sub %f - %f\n", left, right);
  }
  return Double::New(left - right);
}

DEFINE_NATIVE_ENTRY(Double_mul, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_mul %f * %f\n", left, right);
  }
  return Double::New(left * right);
}

DEFINE_NATIVE_ENTRY(Double_div, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_div %f / %f\n", left, right);
  }
  return Double::New(left / right);
}

static IntegerPtr DoubleToInteger(double val, const char* error_msg) {
  if (isinf(val) || isnan(val)) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, String::Handle(String::New(error_msg)));
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  int64_t ival = 0;
  if (val <= static_cast<double>(kMinInt64)) {
    ival = kMinInt64;
  } else if (val >= static_cast<double>(kMaxInt64)) {
    ival = kMaxInt64;
  } else {  // Representable in int64_t.
    ival = static_cast<int64_t>(val);
  }
  return Integer::New(ival);
}

DEFINE_NATIVE_ENTRY(Double_hashCode, 0, 1) {
  double val = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_hashCode %f\n", val);
  }
  if ((val >= kMinInt64RepresentableAsDouble) &&
      (val <= kMaxInt64RepresentableAsDouble)) {
    int64_t ival = static_cast<int64_t>(val);
    if (static_cast<double>(ival) == val) {
      return Integer::New(ival);
    }
  }

  uint64_t uval = bit_cast<uint64_t>(val);
  return Smi::New(((uval >> 32) ^ (uval)) & kSmiMax);
}

DEFINE_NATIVE_ENTRY(Double_trunc_div, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_trunc_div %f ~/ %f\n", left, right);
  }
  return DoubleToInteger(trunc(left / right),
                         "Result of truncating division is Infinity or NaN");
}

DEFINE_NATIVE_ENTRY(Double_modulo, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  return Double::New(DartModulo(left, right));
}

DEFINE_NATIVE_ENTRY(Double_remainder, 0, 2) {
  double left = Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right_object, arguments->NativeArgAt(1));
  double right = right_object.value();
  return Double::New(fmod_ieee(left, right));
}

DEFINE_NATIVE_ENTRY(Double_greaterThan, 0, 2) {
  const Double& left = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right, arguments->NativeArgAt(1));
  bool result = right.IsNull() ? false : (left.value() > right.value());
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_greaterThan %s > %s\n", left.ToCString(),
                 right.ToCString());
  }
  return Bool::Get(result).raw();
}

DEFINE_NATIVE_ENTRY(Double_greaterThanFromInteger, 0, 2) {
  const Double& right = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  return Bool::Get(left.AsDoubleValue() > right.value()).raw();
}

DEFINE_NATIVE_ENTRY(Double_equal, 0, 2) {
  const Double& left = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, right, arguments->NativeArgAt(1));
  bool result = right.IsNull() ? false : (left.value() == right.value());
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Double_equal %s == %s\n", left.ToCString(),
                 right.ToCString());
  }
  return Bool::Get(result).raw();
}

DEFINE_NATIVE_ENTRY(Double_equalToInteger, 0, 2) {
  const Double& left = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, right, arguments->NativeArgAt(1));
  return Bool::Get(left.value() == right.AsDoubleValue()).raw();
}

DEFINE_NATIVE_ENTRY(Double_round, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Double::New(round(arg.value()));
}

DEFINE_NATIVE_ENTRY(Double_floor, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Double::New(floor(arg.value()));
}

DEFINE_NATIVE_ENTRY(Double_ceil, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Double::New(ceil(arg.value()));
}

DEFINE_NATIVE_ENTRY(Double_truncate, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Double::New(trunc(arg.value()));
}

#if defined(HOST_OS_MACOS)
// MAC OSX math library produces old style cast warning.
#pragma GCC diagnostic ignored "-Wold-style-cast"
#endif

DEFINE_NATIVE_ENTRY(Double_toInt, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return DoubleToInteger(arg.value(), "Infinity or NaN toInt");
}

DEFINE_NATIVE_ENTRY(Double_parse, 0, 3) {
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

DEFINE_NATIVE_ENTRY(Double_toString, 0, 1) {
  const Number& number = Number::CheckedHandle(zone, arguments->NativeArgAt(0));
  return number.ToString(Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Double_toStringAsFixed, 0, 2) {
  // The boundaries are exclusive.
  static const double kLowerBoundary = -1e21;
  static const double kUpperBoundary = 1e21;

  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, fraction_digits, arguments->NativeArgAt(1));
  double d = arg.value();
  intptr_t fraction_digits_value = fraction_digits.Value();
  if (0 <= fraction_digits_value && fraction_digits_value <= 20 &&
      kLowerBoundary < d && d < kUpperBoundary) {
    return DoubleToStringAsFixed(d, static_cast<int>(fraction_digits_value));
  } else {
    Exceptions::ThrowArgumentError(String::Handle(
        String::New("Illegal arguments to double.toStringAsFixed")));
    return Object::null();
  }
}

DEFINE_NATIVE_ENTRY(Double_toStringAsExponential, 0, 2) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, fraction_digits, arguments->NativeArgAt(1));
  double d = arg.value();
  intptr_t fraction_digits_value = fraction_digits.Value();
  if (-1 <= fraction_digits_value && fraction_digits_value <= 20) {
    return DoubleToStringAsExponential(d,
                                       static_cast<int>(fraction_digits_value));
  } else {
    Exceptions::ThrowArgumentError(String::Handle(
        String::New("Illegal arguments to double.toStringAsExponential")));
    return Object::null();
  }
}

DEFINE_NATIVE_ENTRY(Double_toStringAsPrecision, 0, 2) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
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

DEFINE_NATIVE_ENTRY(Double_getIsInfinite, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Bool::Get(isinf(arg.value())).raw();
}

DEFINE_NATIVE_ENTRY(Double_getIsNaN, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Bool::Get(isnan(arg.value())).raw();
}

DEFINE_NATIVE_ENTRY(Double_getIsNegative, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  // Include negative zero, infinity.
  double dval = arg.value();
  return Bool::Get(signbit(dval) && !isnan(dval)).raw();
}

DEFINE_NATIVE_ENTRY(Double_flipSignBit, 0, 1) {
  const Double& arg = Double::CheckedHandle(zone, arguments->NativeArgAt(0));
  const double in_val = arg.value();
  const int64_t bits = bit_cast<int64_t, double>(in_val) ^ kSignBitDouble;
  return Double::New(bit_cast<double, int64_t>(bits));
}

// Add here only functions using/referring to old-style casts.

}  // namespace dart
