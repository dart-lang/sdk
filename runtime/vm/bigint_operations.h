// Copyright 2012 Google Inc. All Rights Reserved.

#ifndef VM_BIGINT_OPERATIONS_H_
#define VM_BIGINT_OPERATIONS_H_

#include "platform/utils.h"

#include "vm/object.h"

namespace dart {

class BigintOperations : public AllStatic {
 public:
  static RawBigint* NewFromSmi(const Smi& smi, Heap::Space space = Heap::kNew);
  static RawBigint* NewFromInt64(int64_t value, Heap::Space space = Heap::kNew);
  static RawBigint* NewFromUint64(uint64_t value,
                                  Heap::Space space = Heap::kNew);
  // The given string must be a valid integer representation. It may be
  // prefixed by a minus and/or "0x".
  // Returns Bigint::null() if the string cannot be parsed.
  static RawBigint* NewFromCString(const char* str,
                                   Heap::Space space = Heap::kNew);
  static RawBigint* NewFromDouble(double d, Heap::Space space = Heap::kNew);

  // Compute chunk length of the bigint instance created for the
  // specified hex string.  The specified hex string must be a
  // nul-terminated string of hex-digits.  It must only contain
  // hex-digits. Leading "0x" is not allowed.
  static intptr_t ComputeChunkLength(const char* hex_string);

  // Create a bigint instance from the specified hex string. The given string
  // must be a nul-terminated string of hex-digits. It must only contain
  // hex-digits. Leading "0x" is not allowed.
  static RawBigint* FromHexCString(const char* hex_string,
                                   Heap::Space space = Heap::kNew);

  // Helper method to initialize a bigint instance object with the bigint value
  // in the specified string. The given string must be a nul-terminated string
  // of hex-digits. It must only contain hex-digits, leading "0x" is not
  // allowed.
  static void FromHexCString(const char* hex_string, const Bigint& value);

  // The given string must be a nul-terminated string of decimal digits. It
  // must only contain decimal digits (0-9). No sign is allowed. Leading
  // zeroes are ignored.
  static RawBigint* FromDecimalCString(const char* str,
                                   Heap::Space space = Heap::kNew);

  // Converts the bigint to a HEX string. The returned string is prepended by
  // a "0x" (after the optional minus-sign).
  static const char* ToHexCString(intptr_t length,
                                  bool is_negative,
                                  void* data,
                                  uword (*allocator)(intptr_t size));

  static const char* ToHexCString(const Bigint& bigint,
                                  uword (*allocator)(intptr_t size));

  static const char* ToDecimalCString(const Bigint& bigint,
                                      uword (*allocator)(intptr_t size));

  static bool FitsIntoSmi(const Bigint& bigint);
  static RawSmi* ToSmi(const Bigint& bigint);

  static bool FitsIntoMint(const Bigint& bigint);
  static int64_t ToMint(const Bigint& bigint);

  static bool FitsIntoUint64(const Bigint& bigint);
  static bool AbsFitsIntoUint64(const Bigint& bigint);
  static uint64_t ToUint64(const Bigint& bigint);
  static uint64_t AbsToUint64(const Bigint& bigint);

  static RawDouble* ToDouble(const Bigint& bigint);

  static RawBigint* Add(const Bigint& a, const Bigint& b) {
    bool negate_b = false;
    return AddSubtract(a, b, negate_b);
  }
  static RawBigint* Subtract(const Bigint& a, const Bigint& b) {
    bool negate_b = true;
    return AddSubtract(a, b, negate_b);
  }
  static RawBigint* Multiply(const Bigint& a, const Bigint& b);
  // TODO(floitsch): what to do for divisions by zero.
  static RawBigint* Divide(const Bigint& a, const Bigint& b);
  static RawBigint* Modulo(const Bigint& a, const Bigint& b);
  static RawBigint* Remainder(const Bigint& a, const Bigint& b);

  static RawBigint* ShiftLeft(const Bigint& bigint, intptr_t amount);
  static RawBigint* ShiftRight(const Bigint& bigint, intptr_t amount);
  static RawBigint* BitAnd(const Bigint& a, const Bigint& b);
  static RawBigint* BitOr(const Bigint& a, const Bigint& b);
  static RawBigint* BitXor(const Bigint& a, const Bigint& b);
  static RawBigint* BitNot(const Bigint& bigint);

  static int Compare(const Bigint& a, const Bigint& b);

  static bool IsClamped(const Bigint& bigint) {
    intptr_t length = bigint.Length();
    return (length == 0) || (bigint.GetChunkAt(length - 1) != 0);
  }

 private:
  typedef Bigint::Chunk Chunk;
  typedef Bigint::DoubleChunk DoubleChunk;

  static const int kDigitBitSize = 28;
  static const Chunk kDigitMask = (static_cast<Chunk>(1) << kDigitBitSize) - 1;
  static const Chunk kDigitMaxValue = kDigitMask;
  static const int kChunkSize = sizeof(Chunk);
  static const int kChunkBitSize = kChunkSize * kBitsPerByte;
  static const int kHexCharsPerDigit = kDigitBitSize / 4;

  static RawBigint* Zero() { return Bigint::Allocate(0); }
  static RawBigint* One() {
    Bigint& result = Bigint::Handle(Bigint::Allocate(1));
    result.SetChunkAt(0, 1);
    return result.raw();
  }
  static RawBigint* MinusOne() {
    Bigint& result = Bigint::Handle(One());
    result.ToggleSign();
    return result.raw();
  }

  // Performs an addition or subtraction depending on the negate_b argument.
  static RawBigint* AddSubtract(const Bigint& a,
                                const Bigint& b,
                                bool negate_b);

  static int UnsignedCompare(const Bigint& a, const Bigint& b);
  static int UnsignedCompareNonClamped(const Bigint& a, const Bigint& b);
  static RawBigint* UnsignedAdd(const Bigint& a, const Bigint& b);
  static RawBigint* UnsignedSubtract(const Bigint& a, const Bigint& b);

  static RawBigint* MultiplyWithDigit(const Bigint& bigint, Chunk digit);
  static RawBigint* DigitsShiftLeft(const Bigint& bigint, intptr_t amount) {
    return ShiftLeft(bigint, amount * kDigitBitSize);
  }
  static void DivideRemainder(const Bigint& a, const Bigint& b,
                              Bigint* quotient, Bigint* remainder);

  // Removes leading zero-chunks by adjusting the bigint's length.
  static void Clamp(const Bigint& bigint);

  static RawBigint* Copy(const Bigint& bigint);

  static int CountBits(Chunk digit);

  DISALLOW_IMPLICIT_CONSTRUCTORS(BigintOperations);
};

}  // namespace dart

#endif  // VM_BIGINT_OPERATIONS_H_
