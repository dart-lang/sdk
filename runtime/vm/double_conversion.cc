// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/double_conversion.h"

#include "third_party/double-conversion/src/double-conversion.h"

#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

static constexpr char kExponentChar = 'e';
static constexpr const char* kInfinitySymbol = "Infinity";
static constexpr const char* kNaNSymbol = "NaN";

void DoubleToCString(double d, char* buffer, int buffer_size) {
  const int kDecimalLow = -6;
  const int kDecimalHigh = 21;

  // The output contains the sign, at most kDecimalHigh - 1 digits,
  // the decimal point followed by a 0 plus the \0.
  ASSERT(buffer_size >= 1 + (kDecimalHigh - 1) + 1 + 1 + 1);
  // Or it contains the sign, a 0, the decimal point, kDecimalLow '0's,
  // 17 digits (the precision needed for doubles), plus the \0.
  ASSERT(buffer_size >= 1 + 1 + 1 + kDecimalLow + 17 + 1);
  // Alternatively it contains a sign, at most 17 digits (precision needed for
  // any double), the decimal point, the exponent character, the exponent's
  // sign, at most three exponent digits, plus the \0.
  ASSERT(buffer_size >= 1 + 17 + 1 + 1 + 1 + 3 + 1);

  const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN |
      double_conversion::DoubleToStringConverter::EMIT_TRAILING_DECIMAL_POINT |
      double_conversion::DoubleToStringConverter::
          EMIT_TRAILING_ZERO_AFTER_POINT;

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags, kInfinitySymbol, kNaNSymbol, kExponentChar, kDecimalLow,
      kDecimalHigh, 0,
      0);  // Last two values are ignored in shortest mode.

  double_conversion::StringBuilder builder(buffer, buffer_size);
  bool status = converter.ToShortest(d, &builder);
  ASSERT(status);
  char* result = builder.Finalize();
  ASSERT(result == buffer);
}

StringPtr DoubleToStringAsFixed(double d, int fraction_digits) {
  const int kMinFractionDigits = 0;
  const int kMaxFractionDigits = 20;
  const int kMaxDigitsBeforePoint = 20;
  // The boundaries are exclusive.
  const double kLowerBoundary = -1e21;
  const double kUpperBoundary = 1e21;
  // TODO(floitsch): remove the UNIQUE_ZERO flag when the test is updated.
  const int kConversionFlags =
      double_conversion::DoubleToStringConverter::NO_FLAGS;
  const int kBufferSize = 128;

  USE(kMaxDigitsBeforePoint);
  USE(kMaxFractionDigits);
  USE(kLowerBoundary);
  USE(kUpperBoundary);
  USE(kMinFractionDigits);
  USE(kMaxFractionDigits);
  // The output contains the sign, at most kMaxDigitsBeforePoint digits,
  // the decimal point followed by at most fraction_digits digits plus the \0.
  ASSERT(kBufferSize >= 1 + kMaxDigitsBeforePoint + 1 + kMaxFractionDigits + 1);

  ASSERT(kLowerBoundary < d && d < kUpperBoundary);

  ASSERT(kMinFractionDigits <= fraction_digits &&
         fraction_digits <= kMaxFractionDigits);

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags, kInfinitySymbol, kNaNSymbol, kExponentChar, 0, 0, 0,
      0);  // Last four values are ignored in fixed mode.

  char* buffer = Thread::Current()->zone()->Alloc<char>(kBufferSize);
  buffer[kBufferSize - 1] = '\0';
  double_conversion::StringBuilder builder(buffer, kBufferSize);
  bool status = converter.ToFixed(d, fraction_digits, &builder);
  ASSERT(status);
  return String::New(builder.Finalize());
}

StringPtr DoubleToStringAsExponential(double d, int fraction_digits) {
  const int kMinFractionDigits = -1;  // -1 represents shortest mode.
  const int kMaxFractionDigits = 20;
  const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN;
  const int kBufferSize = 128;

  USE(kMinFractionDigits);
  USE(kMaxFractionDigits);
  // The output contains the sign, at most 1 digits, the decimal point followed
  // by at most kMaxFractionDigits digits, the exponent-character, the
  // exponent-sign and three exponent digits plus \0.
  ASSERT(kBufferSize >= 1 + 1 + kMaxFractionDigits + 1 + 1 + 3 + 1);

  ASSERT(kMinFractionDigits <= fraction_digits &&
         fraction_digits <= kMaxFractionDigits);

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags, kInfinitySymbol, kNaNSymbol, kExponentChar, 0, 0, 0,
      0);  // Last four values are ignored in exponential mode.

  char* buffer = Thread::Current()->zone()->Alloc<char>(kBufferSize);
  buffer[kBufferSize - 1] = '\0';
  double_conversion::StringBuilder builder(buffer, kBufferSize);
  bool status = converter.ToExponential(d, fraction_digits, &builder);
  ASSERT(status);
  return String::New(builder.Finalize());
}

StringPtr DoubleToStringAsPrecision(double d, int precision) {
  const int kMinPrecisionDigits = 1;
  const int kMaxPrecisionDigits = 21;
  const int kMaxLeadingPaddingZeroes = 6;
  const int kMaxTrailingPaddingZeroes = 0;
  const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN;
  const int kBufferSize = 128;

  USE(kMinPrecisionDigits);
  USE(kMaxPrecisionDigits);
  // The output contains the sign, a potential leading 0, the decimal point,
  // at most kMax{Leading|Trailing} padding zeroes, precision digits,
  // the exponent-character, the exponent-sign, three exponent digits
  // plus the \0.
  // Note that padding and exponent are exclusive. We still add them up.
  ASSERT(kBufferSize >= 1 + 1 + 1 + kMaxLeadingPaddingZeroes +
                            kMaxTrailingPaddingZeroes + kMaxPrecisionDigits +
                            1 + 1 + 3 + 1);

  ASSERT(kMinPrecisionDigits <= precision && precision <= kMaxPrecisionDigits);

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags, kInfinitySymbol, kNaNSymbol, kExponentChar, 0,
      0,  // Ignored in precision mode.
      kMaxLeadingPaddingZeroes, kMaxTrailingPaddingZeroes);

  char* buffer = Thread::Current()->zone()->Alloc<char>(kBufferSize);
  buffer[kBufferSize - 1] = '\0';
  double_conversion::StringBuilder builder(buffer, kBufferSize);
  bool status = converter.ToPrecision(d, precision, &builder);
  ASSERT(status);
  return String::New(builder.Finalize());
}

bool CStringToDouble(const char* str, intptr_t length, double* result) {
  if (length == 0) {
    return false;
  }

  double_conversion::StringToDoubleConverter converter(
      double_conversion::StringToDoubleConverter::NO_FLAGS, 0.0, 0.0,
      kInfinitySymbol, kNaNSymbol);

  int parsed_count = 0;
  *result =
      converter.StringToDouble(str, static_cast<int>(length), &parsed_count);
  return (parsed_count == length);
}

IntegerPtr DoubleToInteger(Zone* zone, double val) {
  if (isinf(val) || isnan(val)) {
    const Array& args = Array::Handle(zone, Array::New(1));
    args.SetAt(0, String::Handle(zone, String::New("Infinity or NaN toInt")));
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

}  // namespace dart
