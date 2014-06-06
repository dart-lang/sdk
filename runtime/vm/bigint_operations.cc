// Copyright 2012 Google Inc. All Rights Reserved.

#include "vm/bigint_operations.h"

#include "platform/assert.h"
#include "platform/utils.h"

#include "vm/double_internals.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/zone.h"

namespace dart {

RawBigint* BigintOperations::NewFromSmi(const Smi& smi, Heap::Space space) {
  intptr_t value = smi.Value();
  if (value == 0) {
    return Zero();
  }

  bool is_negative = (value < 0);
  if (is_negative) {
    value = -value;
  }
  // Assert that there are no overflows. Smis reserve a bit for themselves, but
  // protect against future changes.
  ASSERT(-Smi::kMinValue > 0);

  // A single digit of a Bigint might not be sufficient to store a Smi.
  // Count number of needed Digits.
  intptr_t digit_count = 0;
  intptr_t count_value = value;
  while (count_value > 0) {
    digit_count++;
    count_value >>= kDigitBitSize;
  }

  // Allocate a bigint of the correct size and copy the bits.
  const Bigint& result = Bigint::Handle(Bigint::Allocate(digit_count, space));
  for (intptr_t i = 0; i < digit_count; i++) {
    result.SetChunkAt(i, static_cast<Chunk>(value & kDigitMask));
    value >>= kDigitBitSize;
  }
  result.SetSign(is_negative);
  ASSERT(IsClamped(result));
  return result.raw();
}


RawBigint* BigintOperations::NewFromInt64(int64_t value, Heap::Space space) {
  bool is_negative = value < 0;

  if (is_negative) {
    value = -value;
  }

  const Bigint& result = Bigint::Handle(NewFromUint64(value, space));
  result.SetSign(is_negative);

  return result.raw();
}


RawBigint* BigintOperations::NewFromUint64(uint64_t value, Heap::Space space) {
  if (value == 0) {
    return Zero();
  }
  // A single digit of a Bigint might not be sufficient to store the value.
  // Count number of needed Digits.
  intptr_t digit_count = 0;
  uint64_t count_value = value;
  while (count_value > 0) {
    digit_count++;
    count_value >>= kDigitBitSize;
  }

  // Allocate a bigint of the correct size and copy the bits.
  const Bigint& result = Bigint::Handle(Bigint::Allocate(digit_count, space));
  for (intptr_t i = 0; i < digit_count; i++) {
    result.SetChunkAt(i, static_cast<Chunk>(value & kDigitMask));
    value >>= kDigitBitSize;
  }
  result.SetSign(false);
  ASSERT(IsClamped(result));
  return result.raw();
}


RawBigint* BigintOperations::NewFromCString(const char* str,
                                            Heap::Space space) {
  ASSERT(str != NULL);
  if (str[0] == '\0') {
    return Zero();
  }

  // If the string starts with '-' recursively restart the whole operation
  // without the character and then toggle the sign.
  // This allows multiple leading '-' (which will cancel each other out), but
  // we have added an assert, to make sure that the returned result of the
  // recursive call is not negative.
  // We don't catch leading '-'s for zero. Ex: "--0", or "---".
  if (str[0] == '-') {
    const Bigint& result = Bigint::Handle(NewFromCString(&str[1], space));
    result.ToggleSign();
    ASSERT(result.IsZero() || result.IsNegative());
    ASSERT(IsClamped(result));
    return result.raw();
  }

  // No overflow check needed since overflowing str_length implies that we take
  // the branch to FromDecimalCString() which contains a check itself.
  const intptr_t str_length = strlen(str);
  if ((str_length > 2) &&
      (str[0] == '0') &&
      ((str[1] == 'x') || (str[1] == 'X'))) {
    const Bigint& result = Bigint::Handle(FromHexCString(&str[2], space));
    ASSERT(IsClamped(result));
    return result.raw();
  } else {
    return FromDecimalCString(str, space);
  }
}


intptr_t BigintOperations::ComputeChunkLength(const char* hex_string) {
  ASSERT(kDigitBitSize % 4 == 0);
  const intptr_t hex_length = strlen(hex_string);
  if (hex_length < 0) {
    FATAL("Fatal error in BigintOperations::ComputeChunkLength: "
          "string too long");
  }
  // Round up.
  intptr_t bigint_length = ((hex_length - 1) / kHexCharsPerDigit) + 1;
  return bigint_length;
}


RawBigint* BigintOperations::FromHexCString(const char* hex_string,
                                            Heap::Space space) {
  // If the string starts with '-' recursively restart the whole operation
  // without the character and then toggle the sign.
  // This allows multiple leading '-' (which will cancel each other out), but
  // we have added an assert, to make sure that the returned result of the
  // recursive call is not negative.
  // We don't catch leading '-'s for zero. Ex: "--0", or "---".
  if (hex_string[0] == '-') {
    const Bigint& value = Bigint::Handle(FromHexCString(&hex_string[1], space));
    value.ToggleSign();
    ASSERT(value.IsZero() || value.IsNegative());
    ASSERT(IsClamped(value));
    return value.raw();
  }
  intptr_t bigint_length = ComputeChunkLength(hex_string);
  const Bigint& result = Bigint::Handle(Bigint::Allocate(bigint_length, space));
  FromHexCString(hex_string, result);
  return result.raw();
}


RawBigint* BigintOperations::FromDecimalCString(const char* str,
                                                Heap::Space space) {
  Isolate* isolate = Isolate::Current();
  // Read 8 digits a time. 10^8 < 2^27.
  const int kDigitsPerIteration = 8;
  const Chunk kTenMultiplier = 100000000;
  ASSERT(kDigitBitSize >= 27);

  const intptr_t str_length = strlen(str);
  if (str_length < 0) {
    FATAL("Fatal error in BigintOperations::FromDecimalCString: "
          "string too long");
  }
  intptr_t str_pos = 0;

  // Read first digit separately. This avoids a multiplication and addition.
  // The first digit might also not have kDigitsPerIteration decimal digits.
  intptr_t first_digit_decimal_digits = str_length % kDigitsPerIteration;
  Chunk digit = 0;
  for (intptr_t i = 0; i < first_digit_decimal_digits; i++) {
    char c = str[str_pos++];
    ASSERT(('0' <= c) && (c <= '9'));
    digit = digit * 10 + c - '0';
  }
  Bigint& result = Bigint::Handle(Bigint::Allocate(1));
  result.SetChunkAt(0, digit);
  Clamp(result);  // Multiplication requires the inputs to be clamped.

  // Read kDigitsPerIteration at a time, and store it in 'increment'.
  // Then multiply the temporary result by 10^kDigitsPerIteration and add
  // 'increment' to the new result.
  const Bigint& increment = Bigint::Handle(Bigint::Allocate(1));
  while (str_pos < str_length - 1) {
    HANDLESCOPE(isolate);
    Chunk digit = 0;
    for (intptr_t i = 0; i < kDigitsPerIteration; i++) {
      char c = str[str_pos++];
      ASSERT(('0' <= c) && (c <= '9'));
      digit = digit * 10 + c - '0';
    }
    result = MultiplyWithDigit(result, kTenMultiplier);
    if (digit != 0) {
      increment.SetChunkAt(0, digit);
      result = Add(result, increment);
    }
  }
  Clamp(result);
  if ((space == Heap::kOld) && !result.IsOld()) {
    result ^= Object::Clone(result, Heap::kOld);
  }
  return result.raw();
}


RawBigint* BigintOperations::NewFromDouble(double d, Heap::Space space) {
  if ((-1.0 < d) && (d < 1.0)) {
    // Shortcut for small numbers. Also makes the right-shift below
    // well specified.
    Smi& zero = Smi::Handle(Smi::New(0));
    return NewFromSmi(zero, space);
  }
  DoubleInternals internals = DoubleInternals(d);
  if (internals.IsSpecial()) {
    const Array& exception_arguments = Array::Handle(Array::New(1));
    exception_arguments.SetAt(
        0, Object::Handle(String::New("BigintOperations::NewFromDouble")));
    Exceptions::ThrowByType(Exceptions::kInternalError, exception_arguments);
  }
  uint64_t significand = internals.Significand();
  intptr_t exponent = internals.Exponent();
  intptr_t sign = internals.Sign();
  if (exponent <= 0) {
    significand >>= -exponent;
    exponent = 0;
  } else if (exponent <= 10) {
    // A double significand has at most 53 bits. The following shift will
    // hence not overflow, and yield an integer of at most 63 bits.
    significand <<= exponent;
    exponent = 0;
  }
  // A significand has at most 63 bits (after the shift above).
  // The cast to int64_t is hence safe.
  const Bigint& result =
      Bigint::Handle(NewFromInt64(static_cast<int64_t>(significand), space));
  result.SetSign(sign < 0);
  if (exponent > 0) {
    return ShiftLeft(result, exponent);
  } else {
    return result.raw();
  }
}


const char* BigintOperations::ToHexCString(intptr_t length,
                                           bool is_negative,
                                           void* data,
                                           uword (*allocator)(intptr_t size)) {
  NoGCScope no_gc;

  ASSERT(kDigitBitSize % 4 == 0);

  // Conservative maximum chunk length.
  const intptr_t kMaxChunkLen =
      (kIntptrMax - 2 /* 0x */
                  - 1 /* trailing '\0' */
                  - 1 /* leading '-' */) / kHexCharsPerDigit;
  const intptr_t chunk_length = length;
  // Conservative check assuming leading bigint-digit also takes up
  // kHexCharsPerDigit.
  if (chunk_length > kMaxChunkLen) {
    FATAL("Fatal error in BigintOperations::ToHexCString: string too long");
  }
  Chunk* chunk_data = reinterpret_cast<Chunk*>(data);
  if (length == 0) {
    const char* zero = "0x0";
    const intptr_t kLength = strlen(zero);
    char* result = reinterpret_cast<char*>(allocator(kLength + 1));
    ASSERT(result != NULL);
    memmove(result, zero, kLength);
    result[kLength] = '\0';
    return result;
  }
  ASSERT(chunk_data != NULL);

  // Compute the number of hex-digits that are needed to represent the
  // leading bigint-digit. All other digits need exactly kHexCharsPerDigit
  // characters.
  intptr_t leading_hex_digits = 0;
  Chunk leading_digit = chunk_data[chunk_length - 1];
  while (leading_digit != 0) {
    leading_hex_digits++;
    leading_digit >>= 4;
  }
  // Sum up the space that is needed for the string-representation.
  intptr_t required_size = 0;
  if (is_negative) {
    required_size++;  // For the leading "-".
  }
  required_size += 2;  // For the "0x".
  required_size += leading_hex_digits;
  required_size += (chunk_length - 1) * kHexCharsPerDigit;
  required_size++;  // For the trailing '\0'.
  char* result = reinterpret_cast<char*>(allocator(required_size));
  // Print the number into the string.
  // Start from the last position.
  intptr_t pos = required_size - 1;
  result[pos--] = '\0';
  for (intptr_t i = 0; i < (chunk_length - 1); i++) {
    // Print all non-leading characters (which are printed with
    // kHexCharsPerDigit characters.
    Chunk digit = chunk_data[i];
    for (intptr_t j = 0; j < kHexCharsPerDigit; j++) {
      result[pos--] = Utils::IntToHexDigit(static_cast<int>(digit & 0xF));
      digit >>= 4;
    }
  }
  // Print the leading digit.
  leading_digit = chunk_data[chunk_length - 1];
  while (leading_digit != 0) {
    result[pos--] = Utils::IntToHexDigit(static_cast<int>(leading_digit & 0xF));
    leading_digit >>= 4;
  }
  result[pos--] = 'x';
  result[pos--] = '0';
  if (is_negative) {
    result[pos--] = '-';
  }
  ASSERT(pos == -1);
  return result;
}


const char* BigintOperations::ToHexCString(const Bigint& bigint,
                                           uword (*allocator)(intptr_t size)) {
  NoGCScope no_gc;

  intptr_t length = bigint.Length();
  return ToHexCString(length,
                      bigint.IsNegative(),
                      length ? bigint.ChunkAddr(0) : NULL,
                      allocator);
}


const char* BigintOperations::ToDecimalCString(
    const Bigint& bigint, uword (*allocator)(intptr_t size)) {
  // log10(2) ~= 0.30102999566398114.
  const intptr_t kLog2Dividend = 30103;
  const intptr_t kLog2Divisor = 100000;
  // We remove a small constant for rounding imprecision, the \0 character and
  // the negative sign.
  const intptr_t kMaxAllowedDigitLength =
      (kIntptrMax - 10) / kLog2Dividend / kDigitBitSize * kLog2Divisor;

  const intptr_t length = bigint.Length();
  Isolate* isolate = Isolate::Current();
  if (length >= kMaxAllowedDigitLength) {
    // Use the preallocated out of memory exception to avoid calling
    // into dart code or allocating any code.
    const Instance& exception =
        Instance::Handle(isolate->object_store()->out_of_memory());
    Exceptions::Throw(exception);
    UNREACHABLE();
  }

  // Approximate the size of the resulting string. We prefer overestimating
  // to not allocating enough.
  int64_t bit_length = length * kDigitBitSize;
  ASSERT(bit_length > length || length == 0);
  int64_t decimal_length = (bit_length * kLog2Dividend / kLog2Divisor) + 1;
  // Add one byte for the trailing \0 character.
  int64_t required_size = decimal_length + 1;
  if (bigint.IsNegative()) {
    required_size++;
  }
  ASSERT(required_size == static_cast<intptr_t>(required_size));
  // We will fill the result in the inverse order and then exchange at the end.
  char* result =
      reinterpret_cast<char*>(allocator(static_cast<intptr_t>(required_size)));
  ASSERT(result != NULL);
  intptr_t result_pos = 0;

  // We divide the input into pieces of ~27 bits which can be efficiently
  // handled.
  const intptr_t kChunkDivisor = 100000000;
  const int kChunkDigits = 8;
  ASSERT(pow(10.0, kChunkDigits) == kChunkDivisor);
  ASSERT(static_cast<Chunk>(kChunkDivisor) < kDigitMaxValue);
  ASSERT(Smi::IsValid(kChunkDivisor));
  const Chunk divisor = static_cast<Chunk>(kChunkDivisor);

  // Rest contains the remaining bigint that needs to be printed.
  const Bigint& rest = Bigint::Handle(Copy(bigint));
  while (!rest.IsZero()) {
    Chunk remainder = InplaceUnsignedDivideRemainderDigit(rest, divisor);
    intptr_t part = static_cast<intptr_t>(remainder);
    for (int i = 0; i < kChunkDigits; i++) {
      result[result_pos++] = '0' + (part % 10);
      part /= 10;
    }
    ASSERT(part == 0);
  }
  // Add a leading zero, so that we have at least one digit.
  result[result_pos++] = '0';
  // Move the resulting position back until we don't have any zeroes anymore
  // or we reach the first digit. This is done so that we can remove all
  // redundant leading zeroes.
  while (result_pos > 1 && result[result_pos - 1] == '0') {
    result_pos--;
  }
  if (bigint.IsNegative()) {
    result[result_pos++] = '-';
  }
  // Reverse the string.
  int i = 0;
  int j = result_pos - 1;
  while (i < j) {
    char tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
    i++;
    j--;
  }
  ASSERT(result_pos >= 0);
  result[result_pos] = '\0';
  return result;
}


bool BigintOperations::FitsIntoSmi(const Bigint& bigint) {
  intptr_t bigint_length = bigint.Length();
  if (bigint_length == 0) {
    return true;
  }
  if ((bigint_length == 1) &&
      (static_cast<size_t>(kDigitBitSize) <
       (sizeof(intptr_t) * kBitsPerByte))) {
    return true;
  }

  uintptr_t limit;
  if (bigint.IsNegative()) {
    limit = static_cast<uintptr_t>(-Smi::kMinValue);
  } else {
    limit = static_cast<uintptr_t>(Smi::kMaxValue);
  }
  bool bigint_is_greater = false;
  // Consume the least-significant digits of the bigint.
  // If bigint_is_greater is set, then the processed sub-part of the bigint is
  // greater than the corresponding part of the limit.
  for (intptr_t i = 0; i < bigint_length - 1; i++) {
    Chunk limit_digit = static_cast<Chunk>(limit & kDigitMask);
    Chunk bigint_digit = bigint.GetChunkAt(i);
    if (limit_digit < bigint_digit) {
      bigint_is_greater = true;
    } else if (limit_digit > bigint_digit) {
      bigint_is_greater = false;
    }  // else don't change the boolean.
    limit >>= kDigitBitSize;

    // Bail out if the bigint is definitely too big.
    if (limit == 0) {
      return false;
    }
  }
  Chunk most_significant_digit = bigint.GetChunkAt(bigint_length - 1);
  if (limit > most_significant_digit) {
    return true;
  }
  if (limit < most_significant_digit) {
    return false;
  }
  return !bigint_is_greater;
}


RawSmi* BigintOperations::ToSmi(const Bigint& bigint) {
  ASSERT(FitsIntoSmi(bigint));
  intptr_t value = 0;
  for (intptr_t i = bigint.Length() - 1; i >= 0; i--) {
    value <<= kDigitBitSize;
    value += static_cast<intptr_t>(bigint.GetChunkAt(i));
  }
  if (bigint.IsNegative()) {
    value = -value;
  }
  return Smi::New(value);
}


static double Uint64ToDouble(uint64_t x) {
#if _WIN64
  // For static_cast<double>(x) MSVC x64 generates
  //
  //    cvtsi2sd xmm0, rax
  //    test  rax, rax
  //    jns done
  //    addsd xmm0, static_cast<double>(2^64)
  //  done:
  //
  // while GCC -m64 generates
  //
  //    test rax, rax
  //    js negative
  //    cvtsi2sd xmm0, rax
  //    jmp done
  //  negative:
  //    mov rdx, rax
  //    shr rdx, 1
  //    and eax, 0x1
  //    or rdx, rax
  //    cvtsi2sd xmm0, rdx
  //    addsd xmm0, xmm0
  //  done:
  //
  // which results in a different rounding.
  //
  // For consistency between platforms fallback to GCC style converstion
  // on Win64.
  //
  const int64_t y = static_cast<int64_t>(x);
  if (y > 0) {
    return static_cast<double>(y);
  } else {
    const double half = static_cast<double>(
        static_cast<int64_t>(x >> 1) | (y & 1));
    return half + half;
  }
#else
  return static_cast<double>(x);
#endif
}


RawDouble* BigintOperations::ToDouble(const Bigint& bigint) {
  ASSERT(IsClamped(bigint));
  if (bigint.IsZero()) {
    return Double::New(0.0);
  }
  if (AbsFitsIntoUint64(bigint)) {
    double absolute_value = Uint64ToDouble(AbsToUint64(bigint));
    double result = bigint.IsNegative() ? -absolute_value : absolute_value;
    return Double::New(result);
  }

  static const int kPhysicalSignificandSize = 52;
  // The significand size has an additional hidden bit.
  static const int kSignificandSize = kPhysicalSignificandSize + 1;
  static const int kExponentBias = 0x3FF + kPhysicalSignificandSize;
  static const int kMaxExponent = 0x7FF - kExponentBias;
  static const uint64_t kOne64 = 1;
  static const uint64_t kInfinityBits =
      DART_2PART_UINT64_C(0x7FF00000, 00000000);

  // A double is composed of an exponent e and a significand s. Its value equals
  // s * 2^e. The significand has 53 bits of which the first one must always be
  // 1 (at least for then numbers we are working with here) and is therefore
  // omitted. The physical size of the significand is thus 52 bits.
  // The exponent has 11 bits and is biased by 0x3FF + 52. For example an
  // exponent e = 10 is written as 0x3FF + 52 + 10 (in the 11 bits that are
  // reserved for the exponent).
  // When converting the given bignum to a double we have to pay attention to
  // the rounding. In particular we have to decide which double to pick if an
  // input lies exactly between two doubles. As usual with double operations
  // we pick the double with an even significand in such cases.
  //
  // General approach of this algorithm: Get 54 bits (one more than the
  // significand size) of the bigint. If the last bit is then 1, then (without
  // knowledge of the remaining bits) we could have a half-way number.
  // If the second-to-last bit is odd then we know that we have to round up:
  // if the remaining bits are not zero then the input lies closer to the higher
  // double. If the remaining bits are zero then we have a half-way case and
  // we need to round up too (rounding to the even double).
  // If the second-to-last bit is even then we need to look at the remaining
  // bits to determine if any of them is not zero. If that's the case then the
  // number lies closer to the next-higher double. Otherwise we round the
  // half-way case down to even.

  intptr_t length = bigint.Length();
  if (((length - 1) * kDigitBitSize) > (kMaxExponent + kSignificandSize)) {
    // Does not fit into a double.
    double infinity = bit_cast<double>(kInfinityBits);
    return Double::New(bigint.IsNegative() ? -infinity : infinity);
  }


  intptr_t digit_index = length - 1;
  // In order to round correctly we need to look at half-way cases. Therefore we
  // get kSignificandSize + 1 bits. If the last bit is 1 then we have to look
  // at the remaining bits to know if we have to round up.
  int needed_bits = kSignificandSize + 1;
  ASSERT((kDigitBitSize < needed_bits) && (2 * kDigitBitSize >= needed_bits));
  bool discarded_bits_were_zero = true;

  Chunk firstDigit = bigint.GetChunkAt(digit_index--);
  uint64_t twice_significand_floor = firstDigit;
  intptr_t twice_significant_exponent = (digit_index + 1) * kDigitBitSize;
  needed_bits -= CountBits(firstDigit);

  if (needed_bits >= kDigitBitSize) {
    twice_significand_floor <<= kDigitBitSize;
    twice_significand_floor |= bigint.GetChunkAt(digit_index--);
    twice_significant_exponent -= kDigitBitSize;
    needed_bits -= kDigitBitSize;
  }
  if (needed_bits > 0) {
    ASSERT(needed_bits <= kDigitBitSize);
    Chunk digit = bigint.GetChunkAt(digit_index--);
    int discarded_bits_count = kDigitBitSize - needed_bits;
    twice_significand_floor <<= needed_bits;
    twice_significand_floor |= digit >> discarded_bits_count;
    twice_significant_exponent -= needed_bits;
    uint64_t discarded_bits_mask = (kOne64 << discarded_bits_count) - 1;
    discarded_bits_were_zero = ((digit & discarded_bits_mask) == 0);
  }
  ASSERT((twice_significand_floor >> kSignificandSize) == 1);

  // We might need to round up the significand later.
  uint64_t significand = twice_significand_floor >> 1;
  intptr_t exponent = twice_significant_exponent + 1;

  if (exponent >= kMaxExponent) {
    // Infinity.
    // Does not fit into a double.
    double infinity = bit_cast<double>(kInfinityBits);
    return Double::New(bigint.IsNegative() ? -infinity : infinity);
  }

  if ((twice_significand_floor & 1) == 1) {
    bool round_up = false;

    if ((significand & 1) != 0 || !discarded_bits_were_zero) {
      // Even if the remaining bits are zero we still need to round up since we
      // want to round to even for half-way cases.
      round_up = true;
    } else {
      // Could be a half-way case. See if the remaining bits are non-zero.
      for (intptr_t i = 0; i <= digit_index; i++) {
        if (bigint.GetChunkAt(i) != 0) {
          round_up = true;
          break;
        }
      }
    }

    if (round_up) {
      significand++;
      // It might be that we just went from 53 bits to 54 bits.
      // Example: After adding 1 to 1FFF..FF (with 53 bits set to 1) we have
      // 2000..00 (= 2 ^ 54). When adding the exponent and significand together
      // this will increase the exponent by 1 which is exactly what we want.
    }
  }

  ASSERT((significand >> (kSignificandSize - 1)) == 1
         || significand == kOne64 << kSignificandSize);
  uint64_t biased_exponent = exponent + kExponentBias;
  // The significand still has the hidden bit. We simply decrement the biased
  // exponent by one instead of playing around with the significand.
  biased_exponent--;
  // Note that we must use the plus operator instead of bit-or.
  uint64_t double_bits =
      (biased_exponent << kPhysicalSignificandSize) + significand;

  double value = bit_cast<double>(double_bits);
  if (bigint.IsNegative()) {
    value = -value;
  }
  return Double::New(value);
}


bool BigintOperations::FitsIntoInt64(const Bigint& bigint) {
  intptr_t bigint_length = bigint.Length();
  if (bigint_length == 0) {
    return true;
  }
  if ((bigint_length < 3) &&
      (static_cast<size_t>(kDigitBitSize) <
       (sizeof(intptr_t) * kBitsPerByte))) {
    return true;
  }

  uint64_t limit;
  if (bigint.IsNegative()) {
    limit = static_cast<uint64_t>(Mint::kMinValue);
  } else {
    limit = static_cast<uint64_t>(Mint::kMaxValue);
  }
  bool bigint_is_greater = false;
  // Consume the least-significant digits of the bigint.
  // If bigint_is_greater is set, then the processed sub-part of the bigint is
  // greater than the corresponding part of the limit.
  for (intptr_t i = 0; i < bigint_length - 1; i++) {
    Chunk limit_digit = static_cast<Chunk>(limit & kDigitMask);
    Chunk bigint_digit = bigint.GetChunkAt(i);
    if (limit_digit < bigint_digit) {
      bigint_is_greater = true;
    } else if (limit_digit > bigint_digit) {
      bigint_is_greater = false;
    }  // else don't change the boolean.
    limit >>= kDigitBitSize;

    // Bail out if the bigint is definitely too big.
    if (limit == 0) {
      return false;
    }
  }
  Chunk most_significant_digit = bigint.GetChunkAt(bigint_length - 1);
  if (limit > most_significant_digit) {
    return true;
  }
  if (limit < most_significant_digit) {
    return false;
  }
  return !bigint_is_greater;
}


uint64_t BigintOperations::AbsToUint64(const Bigint& bigint) {
  ASSERT(AbsFitsIntoUint64(bigint));
  uint64_t value = 0;
  for (intptr_t i = bigint.Length() - 1; i >= 0; i--) {
    value <<= kDigitBitSize;
    value += static_cast<intptr_t>(bigint.GetChunkAt(i));
  }
  return value;
}


int64_t BigintOperations::ToInt64(const Bigint& bigint) {
  if (bigint.IsZero()) {
    return 0;
  }
  ASSERT(FitsIntoInt64(bigint));
  int64_t value = AbsToUint64(bigint);
  if (bigint.IsNegative()) {
    value = -value;
  }
  return value;
}


uint32_t BigintOperations::TruncateToUint32(const Bigint& bigint) {
  uint32_t value = 0;
  for (intptr_t i = bigint.Length() - 1; i >= 0; i--) {
    value <<= kDigitBitSize;
    value += static_cast<uint32_t>(bigint.GetChunkAt(i));
  }
  return value;
}


bool BigintOperations::AbsFitsIntoUint64(const Bigint& bigint) {
  if (bigint.IsZero()) {
    return true;
  }
  intptr_t b_length = bigint.Length();
  intptr_t num_bits = CountBits(bigint.GetChunkAt(b_length - 1));
  num_bits += (kDigitBitSize * (b_length - 1));
  if (num_bits > 64) return false;
  return true;
}


bool BigintOperations::FitsIntoUint64(const Bigint& bigint) {
  if (bigint.IsNegative()) return false;
  return AbsFitsIntoUint64(bigint);
}


uint64_t BigintOperations::ToUint64(const Bigint& bigint) {
  ASSERT(FitsIntoUint64(bigint));
  return AbsToUint64(bigint);
}


RawBigint* BigintOperations::Multiply(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  intptr_t result_length = a_length + b_length;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

  if (a.IsNegative() != b.IsNegative()) {
    result.ToggleSign();
  }

  // Comba multiplication: compute each column separately.
  // Example: r = a2a1a0 * b2b1b0.
  //    r =  1    * a0b0 +
  //        10    * (a1b0 + a0b1) +
  //        100   * (a2b0 + a1b1 + a0b2) +
  //        1000  * (a2b1 + a1b2) +
  //        10000 * a2b2
  //
  // Each column will be accumulated in an integer of type DoubleChunk. We must
  // guarantee that the column-sum will not overflow.  We achieve this by
  // 'blocking' the sum into overflow-free sums followed by propagating the
  // overflow.
  //
  // Each bigint digit fits in kDigitBitSize bits.
  // Each product fits in 2*kDigitBitSize bits.
  // The accumulator is 8 * sizeof(DoubleChunk) == 2*kDigitBitSize + kCarryBits.
  //
  // Each time we add a product to the accumulator it could carry one bit into
  // the carry bits, supporting kBlockSize = 2^kCarryBits - 1 addition
  // operations before the DoubleChunk overflows.
  //
  // At the end of the column sum and after each batch of kBlockSize additions
  // the high kCarryBits+kDigitBitSize of accumulator are flushed to
  // accumulator_overflow.
  //
  // Diagramatically, using one char per 4 bits:
  //
  //  0aaaaaaa * 0bbbbbbb  ->  00pppppppppppppp   product of 2 digits
  //                                   |
  //                                   +          ...added to
  //                                   v
  //                           ccSSSSSSSsssssss   accumulator
  //                                              ...flushed to
  //                           000000000sssssss   accumulator
  //                    vvvvvvvvvVVVVVVV          accumulator_overflow
  //
  //  'sssssss' becomes the column sum an overflow is carried to next column:
  //
  //                           000000000VVVVVVV   accumulator
  //                    0000000vvvvvvvvv          accumulator_overflow
  //
  // accumulator_overflow supports 2^(kDigitBitSize + kCarryBits) additions of
  // products.
  //
  // Since the bottom (kDigitBitSize + kCarryBits) bits of accumulator_overflow
  // are initialized from the previous column, that uses up the capacity to
  // absorb 2^kCarryBits additions.  The accumulator_overflow can overflow if
  // the column has more than 2^(kDigitBitSize + kCarryBits) - 2^kCarryBits
  // elements With current configuration that is 2^36-2^8 elements.  That is too
  // high to happen in practice.  Comba multiplication is O(N^2) so overflow
  // won't happen during a human lifespan.

  const intptr_t kCarryBits = 8 * sizeof(DoubleChunk) - 2 * kDigitBitSize;
  const intptr_t kBlockSize = (1 << kCarryBits) - 1;

  DoubleChunk accumulator = 0;  // Accumulates the result of one column.
  DoubleChunk accumulator_overflow = 0;
  for (intptr_t i = 0; i < result_length; i++) {
    // Example: r = a2a1a0 * b2b1b0.
    //   For i == 0, compute a0b0.
    //       i == 1,         a1b0 + a0b1 + overflow from i == 0.
    //       i == 2,         a2b0 + a1b1 + a0b2 + overflow from i == 1.
    //       ...
    // The indices into a and b are such that their sum equals i.
    intptr_t a_index = Utils::Minimum(a_length - 1, i);
    intptr_t b_index = i - a_index;
    ASSERT(a_index + b_index == i);

    // Instead of testing for a_index >= 0 && b_index < b_length we compute the
    // number of iterations first.
    intptr_t iterations = Utils::Minimum(b_length - b_index, a_index + 1);

    // For large products we need extra bit for the overflow.  The sum is broken
    // into blocks to avoid dealing with the overflow on each iteration.
    for (intptr_t j_block = 0; j_block < iterations; j_block += kBlockSize) {
      intptr_t j_end = Utils::Minimum(j_block + kBlockSize, iterations);
      for (intptr_t j = j_block; j < j_end; j++) {
        DoubleChunk chunk_a = a.GetChunkAt(a_index);
        DoubleChunk chunk_b = b.GetChunkAt(b_index);
        accumulator += chunk_a * chunk_b;
        a_index--;
        b_index++;
      }
      accumulator_overflow += (accumulator >> kDigitBitSize);
      accumulator &= kDigitMask;
    }
    result.SetChunkAt(i, static_cast<Chunk>(accumulator));
    // Overflow becomes the initial accumulator for the next column.
    accumulator = accumulator_overflow & kDigitMask;
    // And the overflow from the overflow becomes the new overflow.
    accumulator_overflow = (accumulator_overflow >> kDigitBitSize);
  }
  ASSERT(accumulator == 0);
  ASSERT(accumulator_overflow == 0);

  Clamp(result);
  return result.raw();
}


RawBigint* BigintOperations::Divide(const Bigint& a, const Bigint& b) {
  Bigint& quotient = Bigint::Handle();
  Bigint& remainder = Bigint::Handle();
  DivideRemainder(a, b, &quotient, &remainder);
  return quotient.raw();
}


RawBigint* BigintOperations::Modulo(const Bigint& a, const Bigint& b) {
  Bigint& quotient = Bigint::Handle();
  Bigint& remainder = Bigint::Handle();
  DivideRemainder(a, b, &quotient, &remainder);
  // Emulating code in Integer::ArithmeticOp (Euclidian modulo).
  if (remainder.IsNegative()) {
    if (b.IsNegative()) {
      return BigintOperations::Subtract(remainder, b);
    } else {
      return BigintOperations::Add(remainder, b);
    }
  }
  return remainder.raw();
}


RawBigint* BigintOperations::Remainder(const Bigint& a, const Bigint& b) {
  Bigint& quotient = Bigint::Handle();
  Bigint& remainder = Bigint::Handle();
  DivideRemainder(a, b, &quotient, &remainder);
  return remainder.raw();
}


RawBigint* BigintOperations::ShiftLeft(const Bigint& bigint, intptr_t amount) {
  ASSERT(IsClamped(bigint));
  ASSERT(amount >= 0);
  intptr_t bigint_length = bigint.Length();
  if (bigint.IsZero()) {
    return Zero();
  }
  // TODO(floitsch): can we reuse the input?
  if (amount == 0) {
    return Copy(bigint);
  }
  intptr_t digit_shift = amount / kDigitBitSize;
  intptr_t bit_shift = amount % kDigitBitSize;
  if (bit_shift == 0) {
    const Bigint& result =
        Bigint::Handle(Bigint::Allocate(bigint_length + digit_shift));
    for (intptr_t i = 0; i < digit_shift; i++) {
      result.SetChunkAt(i, 0);
    }
    for (intptr_t i = 0; i < bigint_length; i++) {
      result.SetChunkAt(i + digit_shift, bigint.GetChunkAt(i));
    }
    if (bigint.IsNegative()) {
      result.ToggleSign();
    }
    return result.raw();
  } else {
    const Bigint& result =
        Bigint::Handle(Bigint::Allocate(bigint_length + digit_shift + 1));
    for (intptr_t i = 0; i < digit_shift; i++) {
      result.SetChunkAt(i, 0);
    }
    Chunk carry = 0;
    for (intptr_t i = 0; i < bigint_length; i++) {
      Chunk digit = bigint.GetChunkAt(i);
      Chunk shifted_digit = ((digit << bit_shift) & kDigitMask) + carry;
      result.SetChunkAt(i + digit_shift, shifted_digit);
      carry = digit >> (kDigitBitSize - bit_shift);
    }
    result.SetChunkAt(bigint_length + digit_shift, carry);
    if (bigint.IsNegative()) {
      result.ToggleSign();
    }
    Clamp(result);
    return result.raw();
  }
}


RawBigint* BigintOperations::ShiftRight(const Bigint& bigint, intptr_t amount) {
  ASSERT(IsClamped(bigint));
  ASSERT(amount >= 0);
  intptr_t bigint_length = bigint.Length();
  if (bigint.IsZero()) {
    return Zero();
  }
  // TODO(floitsch): can we reuse the input?
  if (amount == 0) {
    return Copy(bigint);
  }
  intptr_t digit_shift = amount / kDigitBitSize;
  intptr_t bit_shift = amount % kDigitBitSize;
  if (digit_shift >= bigint_length) {
    return bigint.IsNegative() ? MinusOne() : Zero();
  }

  const Bigint& result =
      Bigint::Handle(Bigint::Allocate(bigint_length - digit_shift));
  if (bit_shift == 0) {
    for (intptr_t i = 0; i < bigint_length - digit_shift; i++) {
      result.SetChunkAt(i, bigint.GetChunkAt(i + digit_shift));
    }
  } else {
    Chunk carry = 0;
    for (intptr_t i = bigint_length - 1; i >= digit_shift; i--) {
      Chunk digit = bigint.GetChunkAt(i);
      Chunk shifted_digit = (digit >> bit_shift) + carry;
      result.SetChunkAt(i - digit_shift, shifted_digit);
      carry = (digit << (kDigitBitSize - bit_shift)) & kDigitMask;
    }
    Clamp(result);
  }

  if (bigint.IsNegative()) {
    result.ToggleSign();
    // If the input is negative then the result needs to be rounded down.
    // Example: -5 >> 2 => -2
    bool needs_rounding = false;
    for (intptr_t i = 0; i < digit_shift; i++) {
      if (bigint.GetChunkAt(i) != 0) {
        needs_rounding = true;
        break;
      }
    }
    if (!needs_rounding && (bit_shift > 0)) {
      Chunk digit = bigint.GetChunkAt(digit_shift);
      needs_rounding = (digit << (kChunkBitSize - bit_shift)) != 0;
    }
    if (needs_rounding) {
      Bigint& one = Bigint::Handle(One());
      return Subtract(result, one);
    }
  }

  return result.raw();
}


RawBigint* BigintOperations::BitAnd(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));

  if (a.IsZero() || b.IsZero()) {
    return Zero();
  }
  if (a.IsNegative() && !b.IsNegative()) {
    return BitAnd(b, a);
  }
  if ((a.IsNegative() == b.IsNegative()) && (a.Length() < b.Length())) {
    return BitAnd(b, a);
  }

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  intptr_t min_length = Utils::Minimum(a_length, b_length);
  intptr_t max_length = Utils::Maximum(a_length, b_length);
  if (!b.IsNegative()) {
    ASSERT(!a.IsNegative());
    intptr_t result_length = min_length;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

    for (intptr_t i = 0; i < min_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i) & b.GetChunkAt(i));
    }
    Clamp(result);
    return result.raw();
  }

  // Bigints encode negative values by storing the absolute value and the sign
  // separately. To do bit operations we need to simulate numbers that are
  // implemented as two's complement.
  // The negation of a positive number x would be encoded as follows in
  // two's complement: n = ~(x - 1).
  // The inverse transformation is hence (~n) + 1.

  if (!a.IsNegative()) {
    ASSERT(b.IsNegative());
    // The result will be positive.
    intptr_t result_length = a_length;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
    Chunk borrow = 1;
    for (intptr_t i = 0; i < min_length; i++) {
      Chunk b_digit = b.GetChunkAt(i) - borrow;
      result.SetChunkAt(i, a.GetChunkAt(i) & (~b_digit) & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
    }
    for (intptr_t i = min_length; i < a_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i) & (kDigitMaxValue - borrow));
      borrow = 0;
    }
    Clamp(result);
    return result.raw();
  }

  ASSERT(a.IsNegative());
  ASSERT(b.IsNegative());
  // The result will be negative.
  // We need to convert a and b to two's complement. Do the bit-operation there,
  // and transform the resulting bits from two's complement back to separated
  // magnitude and sign.
  // a & b is therefore computed as ~((~(a - 1)) & (~(b - 1))) + 1 which is
  //   equal to ((a-1) | (b-1)) + 1.
  intptr_t result_length = max_length + 1;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
  result.ToggleSign();
  Chunk a_borrow = 1;
  Chunk b_borrow = 1;
  Chunk result_carry = 1;
  ASSERT(a_length >= b_length);
  for (intptr_t i = 0; i < b_length; i++) {
    Chunk a_digit = a.GetChunkAt(i) - a_borrow;
    Chunk b_digit = b.GetChunkAt(i) - b_borrow;
    Chunk result_chunk = ((a_digit | b_digit) & kDigitMask) + result_carry;
    result.SetChunkAt(i, result_chunk & kDigitMask);
    a_borrow = a_digit >> (kChunkBitSize - 1);
    b_borrow = b_digit >> (kChunkBitSize - 1);
    result_carry = result_chunk >> kDigitBitSize;
  }
  for (intptr_t i = b_length; i < a_length; i++) {
    Chunk a_digit = a.GetChunkAt(i) - a_borrow;
    Chunk b_digit = -b_borrow;
    Chunk result_chunk = ((a_digit | b_digit) & kDigitMask) + result_carry;
    result.SetChunkAt(i, result_chunk & kDigitMask);
    a_borrow = a_digit >> (kChunkBitSize - 1);
    b_borrow = 0;
    result_carry = result_chunk >> kDigitBitSize;
  }
  Chunk a_digit = -a_borrow;
  Chunk b_digit = -b_borrow;
  Chunk result_chunk = ((a_digit | b_digit) & kDigitMask) + result_carry;
  result.SetChunkAt(a_length, result_chunk & kDigitMask);
  Clamp(result);
  return result.raw();
}


RawBigint* BigintOperations::BitOr(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));

  if (a.IsNegative() && !b.IsNegative()) {
    return BitOr(b, a);
  }
  if ((a.IsNegative() == b.IsNegative()) && (a.Length() < b.Length())) {
    return BitOr(b, a);
  }

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  intptr_t min_length = Utils::Minimum(a_length, b_length);
  intptr_t max_length = Utils::Maximum(a_length, b_length);
  if (!b.IsNegative()) {
    ASSERT(!a.IsNegative());
    intptr_t result_length = max_length;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

    ASSERT(a_length >= b_length);
    for (intptr_t i = 0; i < b_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i) | b.GetChunkAt(i));
    }
    for (intptr_t i = b_length; i < a_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i));
    }
    return result.raw();
  }

  // Bigints encode negative values by storing the absolute value and the sign
  // separately. To do bit operations we need to simulate numbers that are
  // implemented as two's complement.
  // The negation of a positive number x would be encoded as follows in
  // two's complement: n = ~(x - 1).
  // The inverse transformation is hence (~n) + 1.

  if (!a.IsNegative()) {
    ASSERT(b.IsNegative());
    if (a.IsZero()) {
      return Copy(b);
    }
    // The result will be negative.
    // We need to convert  b to two's complement. Do the bit-operation there,
    // and transform the resulting bits from two's complement back to separated
    // magnitude and sign.
    // a | b is therefore computed as ~((a & (~(b - 1))) + 1 which is
    //   equal to ((~a) & (b-1)) + 1.
    intptr_t result_length = b_length;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
    result.ToggleSign();
    Chunk borrow = 1;
    Chunk result_carry = 1;
    for (intptr_t i = 0; i < min_length; i++) {
      Chunk a_digit = a.GetChunkAt(i);
      Chunk b_digit = b.GetChunkAt(i) - borrow;
      Chunk result_digit = ((~a_digit) & b_digit & kDigitMask) + result_carry;
      result.SetChunkAt(i, result_digit & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
      result_carry = result_digit >> kDigitBitSize;
    }
    ASSERT(result_carry == 0);
    for (intptr_t i = min_length; i < b_length; i++) {
      Chunk b_digit = b.GetChunkAt(i) - borrow;
      Chunk result_digit = (b_digit & kDigitMask) + result_carry;
      result.SetChunkAt(i, result_digit & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
      result_carry = result_digit >> kDigitBitSize;
    }
    ASSERT(result_carry == 0);
    Clamp(result);
    return result.raw();
  }

  ASSERT(a.IsNegative());
  ASSERT(b.IsNegative());
  // The result will be negative.
  // We need to convert a and b to two's complement. Do the bit-operation there,
  // and transform the resulting bits from two's complement back to separated
  // magnitude and sign.
  // a & b is therefore computed as ~((~(a - 1)) | (~(b - 1))) + 1 which is
  //   equal to ((a-1) & (b-1)) + 1.
  ASSERT(a_length >= b_length);
  ASSERT(min_length == b_length);
  intptr_t result_length = min_length + 1;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
  result.ToggleSign();
  Chunk a_borrow = 1;
  Chunk b_borrow = 1;
  Chunk result_carry = 1;
  for (intptr_t i = 0; i < b_length; i++) {
    Chunk a_digit = a.GetChunkAt(i) - a_borrow;
    Chunk b_digit = b.GetChunkAt(i) - b_borrow;
    Chunk result_chunk = ((a_digit & b_digit) & kDigitMask) + result_carry;
    result.SetChunkAt(i, result_chunk & kDigitMask);
    a_borrow = a_digit >> (kChunkBitSize - 1);
    b_borrow = b_digit >> (kChunkBitSize - 1);
    result_carry = result_chunk >> kDigitBitSize;
  }
  result.SetChunkAt(b_length, result_carry);
  Clamp(result);
  return result.raw();
}


RawBigint* BigintOperations::BitXor(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));

  if (a.IsZero()) {
    return Copy(b);
  }
  if (b.IsZero()) {
    return Copy(a);
  }
  if (a.IsNegative() && !b.IsNegative()) {
    return BitXor(b, a);
  }
  if ((a.IsNegative() == b.IsNegative()) && (a.Length() < b.Length())) {
    return BitXor(b, a);
  }

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  intptr_t min_length = Utils::Minimum(a_length, b_length);
  intptr_t max_length = Utils::Maximum(a_length, b_length);
  if (!b.IsNegative()) {
    ASSERT(!a.IsNegative());
    intptr_t result_length = max_length;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

    ASSERT(a_length >= b_length);
    for (intptr_t i = 0; i < b_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i) ^ b.GetChunkAt(i));
    }
    for (intptr_t i = b_length; i < a_length; i++) {
      result.SetChunkAt(i, a.GetChunkAt(i));
    }
    Clamp(result);
    return result.raw();
  }

  // Bigints encode negative values by storing the absolute value and the sign
  // separately. To do bit operations we need to simulate numbers that are
  // implemented as two's complement.
  // The negation of a positive number x would be encoded as follows in
  // two's complement: n = ~(x - 1).
  // The inverse transformation is hence (~n) + 1.

  if (!a.IsNegative()) {
    ASSERT(b.IsNegative());
    // The result will be negative.
    // We need to convert  b to two's complement. Do the bit-operation there,
    // and transform the resulting bits from two's complement back to separated
    // magnitude and sign.
    // a ^ b is therefore computed as ~((a ^ (~(b - 1))) + 1.
    intptr_t result_length = max_length + 1;
    const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
    result.ToggleSign();
    Chunk borrow = 1;
    Chunk result_carry = 1;
    for (intptr_t i = 0; i < min_length; i++) {
      Chunk a_digit = a.GetChunkAt(i);
      Chunk b_digit = b.GetChunkAt(i) - borrow;
      Chunk result_digit =
          ((~(a_digit ^ ~b_digit)) & kDigitMask) + result_carry;
      result.SetChunkAt(i, result_digit & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
      result_carry = result_digit >> kDigitBitSize;
    }
    for (intptr_t i = min_length; i < a_length; i++) {
      Chunk a_digit = a.GetChunkAt(i);
      Chunk b_digit = -borrow;
      Chunk result_digit =
          ((~(a_digit ^ ~b_digit)) & kDigitMask) + result_carry;
      result.SetChunkAt(i, result_digit & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
      result_carry = result_digit >> kDigitBitSize;
    }
    for (intptr_t i = min_length; i < b_length; i++) {
      // a_digit = 0.
      Chunk b_digit = b.GetChunkAt(i) - borrow;
      Chunk result_digit = (b_digit & kDigitMask) + result_carry;
      result.SetChunkAt(i, result_digit & kDigitMask);
      borrow = b_digit >> (kChunkBitSize - 1);
      result_carry = result_digit >> kDigitBitSize;
    }
    result.SetChunkAt(max_length, result_carry);
    Clamp(result);
    return result.raw();
  }

  ASSERT(a.IsNegative());
  ASSERT(b.IsNegative());
  // The result will be positive.
  // We need to convert a and b to two's complement, do the bit-operation there,
  // and simply store the result.
  // a ^ b is therefore computed as (~(a - 1)) ^ (~(b - 1)).
  ASSERT(a_length >= b_length);
  ASSERT(max_length == a_length);
  intptr_t result_length = max_length;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));
  Chunk a_borrow = 1;
  Chunk b_borrow = 1;
  for (intptr_t i = 0; i < b_length; i++) {
    Chunk a_digit = a.GetChunkAt(i) - a_borrow;
    Chunk b_digit = b.GetChunkAt(i) - b_borrow;
    Chunk result_chunk = (~a_digit) ^ (~b_digit);
    result.SetChunkAt(i, result_chunk & kDigitMask);
    a_borrow = a_digit >> (kChunkBitSize - 1);
    b_borrow = b_digit >> (kChunkBitSize - 1);
  }
  ASSERT(b_borrow == 0);
  for (intptr_t i = b_length; i < a_length; i++) {
    Chunk a_digit = a.GetChunkAt(i) - a_borrow;
    // (~a_digit) ^ 0xFFF..FFF == a_digit.
    result.SetChunkAt(i, a_digit & kDigitMask);
    a_borrow = a_digit >> (kChunkBitSize - 1);
  }
  ASSERT(a_borrow == 0);
  Clamp(result);
  return result.raw();
}


RawBigint* BigintOperations::BitNot(const Bigint& bigint) {
  if (bigint.IsZero()) {
    return MinusOne();
  }
  const Bigint& one_bigint = Bigint::Handle(One());
  if (bigint.IsNegative()) {
    return UnsignedSubtract(bigint, one_bigint);
  } else {
    const Bigint& result = Bigint::Handle(UnsignedAdd(bigint, one_bigint));
    result.ToggleSign();
    return result.raw();
  }
}


int64_t BigintOperations::BitLength(const Bigint& bigint) {
  ASSERT(IsClamped(bigint));
  intptr_t length = bigint.Length();
  if (length == 0) return 0;
  intptr_t last = length - 1;

  Chunk high_chunk = bigint.GetChunkAt(last);
  ASSERT(high_chunk != 0);
  int64_t bit_length =
      static_cast<int64_t>(kDigitBitSize) * last + CountBits(high_chunk);

  if (bigint.IsNegative()) {
    // We are calculating the 2's complement bitlength but we have a sign and
    // magnitude representation.  The length is the same except when the
    // magnitude is an exact power of two, 2^k.  In 2's complement format,
    // -(2^k) takes one fewer bit than (2^k).

    if ((high_chunk & (high_chunk - 1)) == 0) {  // Single bit set?
      for (intptr_t i = 0; i < last; i++) {
        if (bigint.GetChunkAt(i) != 0) return bit_length;
      }
      bit_length -= 1;
    }
  }
  return bit_length;
}


int BigintOperations::Compare(const Bigint& a, const Bigint& b) {
  bool a_is_negative = a.IsNegative();
  bool b_is_negative = b.IsNegative();
  if (a_is_negative != b_is_negative) {
    return a_is_negative ? -1 : 1;
  }

  if (a_is_negative) {
    return -UnsignedCompare(a, b);
  }
  return UnsignedCompare(a, b);
}


void BigintOperations::FromHexCString(const char* hex_string,
                                      const Bigint& value) {
  ASSERT(hex_string[0] != '-');
  intptr_t bigint_length = ComputeChunkLength(hex_string);
  // The bigint's least significant digit (lsd) is at position 0, whereas the
  // given string has it's lsd at the last position.
  // The hex_i index, pointing into the string, starts therefore at the end,
  // whereas the bigint-index (i) starts at 0.
  const intptr_t hex_length = strlen(hex_string);
  if (hex_length < 0) {
    FATAL("Fatal error in BigintOperations::FromHexCString: string too long");
  }
  intptr_t hex_i = hex_length - 1;
  for (intptr_t i = 0; i < bigint_length; i++) {
    Chunk digit = 0;
    int shift = 0;
    for (int j = 0; j < kHexCharsPerDigit; j++) {
      // Reads a block of hexadecimal digits and stores it in 'digit'.
      // Ex: "0123456" with kHexCharsPerDigit == 3, hex_i == 6, reads "456".
      if (hex_i < 0) {
        break;
      }
      ASSERT(hex_i >= 0);
      char c = hex_string[hex_i--];
      ASSERT(Utils::IsHexDigit(c));
      digit += static_cast<Chunk>(Utils::HexDigitToInt(c)) << shift;
      shift += 4;
    }
    value.SetChunkAt(i, digit);
  }
  ASSERT(hex_i == -1);
  Clamp(value);
}


RawBigint* BigintOperations::AddSubtract(const Bigint& a,
                                         const Bigint& b,
                                         bool negate_b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));
  Bigint& result = Bigint::Handle();
  // We perform the subtraction by simulating a negation of the b-argument.
  bool b_is_negative = negate_b ? !b.IsNegative() : b.IsNegative();

  // If both are of the same sign, then we can compute the unsigned addition
  // and then simply adjust the sign (if necessary).
  // Ex: -3 + -5 -> -(3 + 5)
  if (a.IsNegative() == b_is_negative) {
    result = UnsignedAdd(a, b);
    result.SetSign(b_is_negative);
    ASSERT(IsClamped(result));
    return result.raw();
  }

  // The signs differ.
  // Take the number with small magnitude and subtract its absolute value from
  // the absolute value of the other number. Then adjust the sign, if necessary.
  // The sign is the same as for the number with the greater magnitude.
  // Ex:  -8 + 3  -> -(8 - 3)
  //       8 + -3 ->  (8 - 3)
  //      -3 + 8  ->  (8 - 3)
  //       3 + -8 -> -(8 - 3)
  int comp = UnsignedCompare(a, b);
  if (comp < 0) {
    result = UnsignedSubtract(b, a);
    result.SetSign(b_is_negative);
  } else if (comp > 0) {
    result = UnsignedSubtract(a, b);
    result.SetSign(a.IsNegative());
  } else {
    return Zero();
  }
  ASSERT(IsClamped(result));
  return result.raw();
}


int BigintOperations::UnsignedCompare(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));
  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  if (a_length < b_length) return -1;
  if (a_length > b_length) return 1;
  for (intptr_t i = a_length - 1; i >= 0; i--) {
    Chunk digit_a = a.GetChunkAt(i);
    Chunk digit_b = b.GetChunkAt(i);
    if (digit_a < digit_b) return -1;
    if (digit_a > digit_b) return 1;
    // Else look at the next digit.
  }
  return 0;  // They are equal.
}


int BigintOperations::UnsignedCompareNonClamped(
    const Bigint& a, const Bigint& b) {
  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  while (a_length > b_length) {
    if (a.GetChunkAt(a_length - 1) != 0) return 1;
    a_length--;
  }
  while (b_length > a_length) {
    if (b.GetChunkAt(b_length - 1) != 0) return -1;
    b_length--;
  }
  for (intptr_t i = a_length - 1; i >= 0; i--) {
    Chunk digit_a = a.GetChunkAt(i);
    Chunk digit_b = b.GetChunkAt(i);
    if (digit_a < digit_b) return -1;
    if (digit_a > digit_b) return 1;
    // Else look at the next digit.
  }
  return 0;  // They are equal.
}


RawBigint* BigintOperations::UnsignedAdd(const Bigint& a, const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();
  if (a_length < b_length) {
    return UnsignedAdd(b, a);
  }

  // We might request too much space, in which case we will adjust the length
  // afterwards.
  intptr_t result_length = a_length + 1;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

  Chunk carry = 0;
  // b has fewer digits than a.
  ASSERT(b_length <= a_length);
  for (intptr_t i = 0; i < b_length; i++) {
    Chunk sum = a.GetChunkAt(i) + b.GetChunkAt(i) + carry;
    result.SetChunkAt(i, sum & kDigitMask);
    carry = sum >> kDigitBitSize;
  }
  // Copy over the remaining digits of a, but don't forget the carry.
  for (intptr_t i = b_length; i < a_length; i++) {
    Chunk sum = a.GetChunkAt(i) + carry;
    result.SetChunkAt(i, sum & kDigitMask);
    carry = sum >> kDigitBitSize;
  }
  // Shrink the result if there was no overflow. Otherwise apply the carry.
  if (carry == 0) {
    // TODO(floitsch): We change the size of bigint-objects here.
    result.SetLength(a_length);
  } else {
    result.SetChunkAt(a_length, carry);
  }
  ASSERT(IsClamped(result));
  return result.raw();
}


RawBigint* BigintOperations::UnsignedSubtract(const Bigint& a,
                                              const Bigint& b) {
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));
  ASSERT(UnsignedCompare(a, b) >= 0);

  const int kSignBitPos = Bigint::kChunkSize * kBitsPerByte - 1;

  intptr_t a_length = a.Length();
  intptr_t b_length = b.Length();

  // We might request too much space, in which case we will adjust the length
  // afterwards.
  intptr_t result_length = a_length;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

  Chunk borrow = 0;
  ASSERT(b_length <= a_length);
  for (intptr_t i = 0; i < b_length; i++) {
    Chunk difference = a.GetChunkAt(i) - b.GetChunkAt(i) - borrow;
    result.SetChunkAt(i, difference & kDigitMask);
    borrow = difference >> kSignBitPos;
    ASSERT((borrow == 0) || (borrow == 1));
  }
  // Copy over the remaining digits of a, but don't forget the borrow.
  for (intptr_t i = b_length; i < a_length; i++) {
    Chunk difference = a.GetChunkAt(i) - borrow;
    result.SetChunkAt(i, difference & kDigitMask);
    borrow = (difference >> kSignBitPos);
    ASSERT((borrow == 0) || (borrow == 1));
  }
  ASSERT(borrow == 0);
  Clamp(result);
  return result.raw();
}


RawBigint* BigintOperations::MultiplyWithDigit(
    const Bigint& bigint, Chunk digit) {
  ASSERT(digit <= kDigitMaxValue);
  if (digit == 0) return Zero();
  if (bigint.IsZero()) return Zero();

  intptr_t length = bigint.Length();
  intptr_t result_length = length + 1;
  const Bigint& result = Bigint::Handle(Bigint::Allocate(result_length));

  Chunk carry = 0;
  for (intptr_t i = 0; i < length; i++) {
    Chunk chunk = bigint.GetChunkAt(i);
    DoubleChunk product = (static_cast<DoubleChunk>(chunk) * digit) + carry;
    result.SetChunkAt(i, static_cast<Chunk>(product & kDigitMask));
    carry = static_cast<Chunk>(product >> kDigitBitSize);
  }
  result.SetChunkAt(length, carry);

  result.SetSign(bigint.IsNegative());
  Clamp(result);
  return result.raw();
}


void BigintOperations::DivideRemainder(
    const Bigint& a, const Bigint& b, Bigint* quotient, Bigint* remainder) {
  // TODO(floitsch): This function is very memory-intensive since all
  // intermediate bigint results are allocated in new memory. It would be
  // much more efficient to reuse the space of temporary intermediate variables.
  ASSERT(IsClamped(a));
  ASSERT(IsClamped(b));
  ASSERT(!b.IsZero());

  int comp = UnsignedCompare(a, b);
  if (comp < 0) {
    (*quotient) = Zero();
    (*remainder) = Copy(a);  // TODO(floitsch): can we reuse the input?
    return;
  } else if (comp == 0) {
    (*quotient) = One();
    quotient->SetSign(a.IsNegative() != b.IsNegative());
    (*remainder) = Zero();
    return;
  }

  intptr_t b_length = b.Length();

  if (b_length == 1) {
    const Bigint& dividend_quotient = Bigint::Handle(Copy(a));
    Chunk remainder_digit =
        BigintOperations::InplaceUnsignedDivideRemainderDigit(
            dividend_quotient, b.GetChunkAt(0));
    dividend_quotient.SetSign(a.IsNegative() != b.IsNegative());
    *quotient = dividend_quotient.raw();
    *remainder = Bigint::Allocate(1);
    remainder->SetChunkAt(0, remainder_digit);
    remainder->SetSign(a.IsNegative());
    Clamp(*remainder);
    return;
  }

  // High level description:
  // The algorithm is basically the algorithm that is taught in school:
  // Let a the dividend and b the divisor. We are looking for
  // the quotient q = truncate(a / b), and
  // the remainder r = a - q * b.
  // School algorithm:
  // q = 0
  // n = number_of_digits(a) - number_of_digits(b)
  // for (i = n; i >= 0; i--) {
  //   Maximize k such that k*y*10^i is less than or equal to a and
  //                  (k + 1)*y*10^i is greater.
  //   q = q + k * 10^i   // Add new digit to result.
  //   a = a - k * b * 10^i
  // }
  // r = a
  //
  // Instead of working in base 10 we work in base kDigitBitSize.

  int normalization_shift =
      kDigitBitSize - CountBits(b.GetChunkAt(b_length - 1));
  Bigint& dividend = Bigint::Handle(ShiftLeft(a, normalization_shift));
  const Bigint& divisor = Bigint::Handle(ShiftLeft(b, normalization_shift));
  dividend.SetSign(false);
  divisor.SetSign(false);

  intptr_t dividend_length = dividend.Length();
  intptr_t divisor_length = b_length;
  ASSERT(divisor_length == divisor.Length());

  intptr_t quotient_length = dividend_length - divisor_length + 1;
  *quotient = Bigint::Allocate(quotient_length);
  quotient->SetSign(a.IsNegative() != b.IsNegative());

  intptr_t quotient_pos = dividend_length - divisor_length;
  // Find the first quotient-digit.
  // The first digit must be computed separately from the other digits because
  // the preconditions for the loop are not yet satisfied.
  // For simplicity use a shifted divisor, so that the comparison and
  // subtraction are easier.
  int divisor_shift_amount = dividend_length - divisor_length;
  Bigint& shifted_divisor =
      Bigint::Handle(DigitsShiftLeft(divisor, divisor_shift_amount));
  Chunk first_quotient_digit = 0;
  Isolate* isolate = Isolate::Current();
  while (UnsignedCompare(dividend, shifted_divisor) >= 0) {
    HANDLESCOPE(isolate);
    first_quotient_digit++;
    dividend = Subtract(dividend, shifted_divisor);
  }
  quotient->SetChunkAt(quotient_pos--, first_quotient_digit);

  // Find the remainder of the digits.

  Chunk first_divisor_digit = divisor.GetChunkAt(divisor_length - 1);
  // The short divisor only represents the first two digits of the divisor.
  // If the divisor has only one digit, then the second part is zeroed out.
  Bigint& short_divisor = Bigint::Handle(Bigint::Allocate(2));
  if (divisor_length > 1) {
    short_divisor.SetChunkAt(0, divisor.GetChunkAt(divisor_length - 2));
  } else {
    short_divisor.SetChunkAt(0, 0);
  }
  short_divisor.SetChunkAt(1, first_divisor_digit);
  // The following bigint will be used inside the loop. It is allocated outside
  // the loop to avoid repeated allocations.
  Bigint& target = Bigint::Handle(Bigint::Allocate(3));
  // The dividend_length here must be from the initial dividend.
  for (intptr_t i = dividend_length - 1; i >= divisor_length; i--) {
    // Invariant: let t = i - divisor_length
    //   then dividend / (divisor << (t * kDigitBitSize)) <= kDigitMaxValue.
    // Ex: dividend: 53451232, and divisor: 535  (with t == 5) is ok.
    //     dividend: 56822123, and divisor: 563  (with t == 5) is bad.
    //     dividend:  6822123, and divisor: 563  (with t == 5) is ok.

    HANDLESCOPE(isolate);
    // The dividend has changed. So recompute its length.
    dividend_length = dividend.Length();
    Chunk dividend_digit;
    if (i > dividend_length) {
      quotient->SetChunkAt(quotient_pos--, 0);
      continue;
    } else if (i == dividend_length) {
      dividend_digit = 0;
    } else {
      ASSERT(i + 1 == dividend_length);
      dividend_digit = dividend.GetChunkAt(i);
    }
    Chunk quotient_digit;
    // Compute an estimate of the quotient_digit. The estimate will never
    // be too small.
    if (dividend_digit == first_divisor_digit) {
      // Small shortcut: the else-branch would compute a value > kDigitMaxValue.
      // However, by hypothesis, we know that the quotient_digit must fit into
      // a digit. Avoid going through repeated iterations of the adjustment
      // loop by directly assigning kDigitMaxValue to the quotient_digit.
      // Ex:  51235 / 523.
      //    51 / 5 would yield 10 (if computed in the else branch).
      // However we know that 9 is the maximal value.
      quotient_digit = kDigitMaxValue;
    } else {
      // Compute the estimate by using two digits of the dividend and one of
      // the divisor.
      // Ex: 32421 / 535
      //    32 / 5 -> 6
      // The estimate would hence be 6.
      DoubleChunk two_dividend_digits = dividend_digit;
      two_dividend_digits <<= kDigitBitSize;
      two_dividend_digits += dividend.GetChunkAt(i - 1);
      DoubleChunk q = two_dividend_digits / first_divisor_digit;
      if (q > kDigitMaxValue) q = kDigitMaxValue;
      quotient_digit = static_cast<Chunk>(q);
    }

    // Refine estimation.
    quotient_digit++;  // The following loop will start by decrementing.
    Bigint& estimation_product = Bigint::Handle();
    target.SetChunkAt(0, ((i - 2) < 0) ? 0 : dividend.GetChunkAt(i - 2));
    target.SetChunkAt(1, ((i - 1) < 0) ? 0 : dividend.GetChunkAt(i - 1));
    target.SetChunkAt(2, dividend_digit);
    do {
      HANDLESCOPE(isolate);
      quotient_digit = (quotient_digit - 1) & kDigitMask;
      estimation_product = MultiplyWithDigit(short_divisor, quotient_digit);
    } while (UnsignedCompareNonClamped(estimation_product, target) > 0);
    // At this point the quotient_digit is fairly accurate.
    // At the worst it is off by one.
    // Remove a multiple of the divisor. If the estimate is incorrect we will
    // subtract the divisor another time.
    // Let t = i - divisor_length.
    // dividend -= (quotient_digit * divisor) << (t * kDigitBitSize);
    shifted_divisor = MultiplyWithDigit(divisor, quotient_digit);
    shifted_divisor = DigitsShiftLeft(shifted_divisor, i - divisor_length);
    dividend = Subtract(dividend, shifted_divisor);
    if (dividend.IsNegative()) {
      // The estimation was still too big.
      quotient_digit--;
      // TODO(floitsch): allocate space for the shifted_divisor once and reuse
      // it at every iteration.
      shifted_divisor = DigitsShiftLeft(divisor, i - divisor_length);
      // TODO(floitsch): reuse the space of the previous dividend.
      dividend = Add(dividend, shifted_divisor);
    }
    quotient->SetChunkAt(quotient_pos--, quotient_digit);
  }
  ASSERT(quotient_pos == -1);
  Clamp(*quotient);
  *remainder = ShiftRight(dividend, normalization_shift);
  remainder->SetSign(a.IsNegative());
}


BigintOperations::Chunk BigintOperations::InplaceUnsignedDivideRemainderDigit(
    const Bigint& dividend_quotient, Chunk divisor_digit) {
  Chunk remainder = 0;
  for (intptr_t i = dividend_quotient.Length() - 1; i >= 0; i--) {
    DoubleChunk dividend_digit =
        (static_cast<DoubleChunk>(remainder) << kDigitBitSize) +
        dividend_quotient.GetChunkAt(i);
    Chunk quotient_digit = static_cast<Chunk>(dividend_digit / divisor_digit);
    remainder = static_cast<Chunk>(
        dividend_digit -
        static_cast<DoubleChunk>(quotient_digit) * divisor_digit);
    dividend_quotient.SetChunkAt(i, quotient_digit);
  }
  Clamp(dividend_quotient);
  return remainder;
}


void BigintOperations::Clamp(const Bigint& bigint) {
  intptr_t length = bigint.Length();
  while (length > 0 && (bigint.GetChunkAt(length - 1) == 0)) {
    length--;
  }
  // TODO(floitsch): We change the size of bigint-objects here.
  bigint.SetLength(length);
}


RawBigint* BigintOperations::Copy(const Bigint& bigint) {
  intptr_t bigint_length = bigint.Length();
  Bigint& copy = Bigint::Handle(Bigint::Allocate(bigint_length));
  for (intptr_t i = 0; i < bigint_length; i++) {
    copy.SetChunkAt(i, bigint.GetChunkAt(i));
  }
  copy.SetSign(bigint.IsNegative());
  return copy.raw();
}


intptr_t BigintOperations::CountBits(Chunk digit) {
  intptr_t result = 0;
  while (digit != 0) {
    digit >>= 1;
    result++;
  }
  return result;
}

}  // namespace dart
