// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/double_conversion.h"

#include "third_party/double-conversion/src/double-conversion.h"

#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/object.h"

namespace dart {

static const char kDoubleToStringCommonExponentChar = 'e';
static const char* kDoubleToStringCommonInfinitySymbol = "Infinity";
static const char* kDoubleToStringCommonNaNSymbol = "NaN";

bool DoubleToString(double d, String& result) {
  static const int kDecimalLow = -6;
  static const int kDecimalHigh = 21;
  static const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN |
      double_conversion::DoubleToStringConverter::EMIT_TRAILING_DECIMAL_POINT |
     double_conversion::DoubleToStringConverter::EMIT_TRAILING_ZERO_AFTER_POINT;
  const int kBufferSize = 128;
  // The output contains the sign, at most kDecimalHigh - 1 digits,
  // the decimal point followed by a 0 plus the \0.
  ASSERT(kBufferSize >= 1 + (kDecimalHigh - 1) + 1 + 1 + 1);
  // Or it contains the sign, a 0, the decimal point, kDecimalLow '0's,
  // 17 digits (the precision needed for doubles), plus the \0.
  ASSERT(kBufferSize >= 1 + 1 + 1 + kDecimalLow + 17 + 1);
  // Alternatively it contains a sign, at most 17 digits (precision needed for
  // any double), the decimal point, the exponent character, the exponent's
  // sign, at most three exponent digits, plus the \0.
  ASSERT(kBufferSize >= 1 + 17 + 1 + 1 + 1 + 3 + 1);

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags,
      kDoubleToStringCommonInfinitySymbol,
      kDoubleToStringCommonNaNSymbol,
      kDoubleToStringCommonExponentChar,
      kDecimalLow,
      kDecimalHigh,
      0, 0);  // Last two values are ignored in shortest mode.

  UNIMPLEMENTED();
  return false;
}

bool DoubleToStringAsFixed(double d, int fraction_digits, String& result) {
  static const int kMinFractionDigits = 0;
  static const int kMaxFractionDigits = 20;
  static const int kMaxDigitsBeforePoint = 20;
  // The boundaries are exclusive.
  static const double kLowerBoundary = -1e21;
  static const double kUpperBoundary = 1e21;
  // TODO(floitsch): remove the UNIQUE_ZERO flag when the test is updated.
  static const int kConversionFlags =
      double_conversion::DoubleToStringConverter::UNIQUE_ZERO;
  const int kBufferSize = 128;
  // The output contains the sign, at most kMaxDigitsBeforePoint digits,
  // the decimal point followed by at most fraction_digits digits plus the \0.
  ASSERT(kBufferSize >= 1 + kMaxDigitsBeforePoint + 1 + kMaxFractionDigits + 1);

  if (d <= kLowerBoundary || d >= kUpperBoundary) {
    return false;
  }
  if (fraction_digits < kMinFractionDigits ||
      fraction_digits > kMaxFractionDigits) {
    return false;
  }

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags,
      kDoubleToStringCommonInfinitySymbol,
      kDoubleToStringCommonNaNSymbol,
      kDoubleToStringCommonExponentChar,
      0, 0, 0, 0);  // Last four values are ignored in fixed mode.

  char buffer[kBufferSize];
  double_conversion::StringBuilder builder(buffer, kBufferSize);
  bool status = converter.ToFixed(d, fraction_digits, &builder);
  if (!status) return false;
  int length = builder.position();
  result ^= String::New(reinterpret_cast<uint8_t*>(builder.Finalize()), length);
  return true;
}


bool DoubleToStringAsExponential(double d,
                                 int fraction_digits,
                                 String& result) {
  static const int kMinFractionDigits = 0;
  static const int kMaxFractionDigits = 20;
  static const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN;
  const int kBufferSize = 128;
  // The output contains the sign, at most 1 digits, the decimal point followed
  // by at most kMaxFractionDigits digits, the exponent-character, the
  // exponent-sign and three exponent digits plus \0.
  ASSERT(kBufferSize >= 1 + 1 + kMaxFractionDigits + 1 + 1 + 3 + 1);

  if (!(kMinFractionDigits <= fraction_digits &&
        fraction_digits <= kMaxFractionDigits)) {
    return false;
  }

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags,
      kDoubleToStringCommonInfinitySymbol,
      kDoubleToStringCommonNaNSymbol,
      kDoubleToStringCommonExponentChar,
      0, 0, 0, 0);  // Last four values are ignored in exponential mode.

  UNIMPLEMENTED();
  return false;
}


bool DoubleToStringAsPrecision(double d, int precision, String& result) {
  static const int kMinPrecisionDigits = 1;
  static const int kMaxPrecisionDigits = 21;
  static const int kMaxLeadingPaddingZeroes = 6;
  static const int kMaxTrailingPaddingZeroes = 0;
  static const int kConversionFlags =
      double_conversion::DoubleToStringConverter::EMIT_POSITIVE_EXPONENT_SIGN;
  const int kBufferSize = 128;
  // The output contains the sign, the decimal point, precision digits,
  // the exponent-character, the exponent-sign, three exponent digits
  // plus the \0.
  ASSERT(kBufferSize >= 1 + 1 + kMaxPrecisionDigits + 1 + 1 + 3 + 1);

  if (!(kMinPrecisionDigits <= precision && precision <= kMaxPrecisionDigits)) {
    return false;
  }

  const double_conversion::DoubleToStringConverter converter(
      kConversionFlags,
      kDoubleToStringCommonInfinitySymbol,
      kDoubleToStringCommonNaNSymbol,
      kDoubleToStringCommonExponentChar,
      0, 0,  // Ignored in precision mode.
      kMaxLeadingPaddingZeroes,
      kMaxTrailingPaddingZeroes);

  UNIMPLEMENTED();
  return false;
}

}  // namespace dart
