// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BIGINT_OPERATIONS_H_
#define VM_BIGINT_OPERATIONS_H_

#include "vm/heap.h"
#include "vm/object.h"
#include "vm/token.h"

// This should be folded into OpenSSL
#undef BN_abs_is_word
#define BN_abs_is_word(a, w) (((a)->top == 1) \
                               && ((a)->d[0] == static_cast<BN_ULONG>(w)))

namespace dart {

class BigintOperations : public AllStatic {
 public:
  static RawBigint* NewFromSmi(const Smi& smi, Heap::Space space = Heap::kNew);
  static RawBigint* NewFromInt64(int64_t value, Heap::Space space = Heap::kNew);
  // The given string must be a valid integer representation. It may be
  // prefixed by a minus and/or "0x".
  // Returns Bigint::null() if the string cannot be parsed.
  static RawBigint* NewFromCString(const char* str,
                                   Heap::Space space = Heap::kNew);
  static RawBigint* NewFromDouble(double d, Heap::Space space = Heap::kNew);

  // The given string must be a nul-terminated string of hex-digits. It must
  // only contain hex-digits. No sign or leading "0x" is allowed.
  static RawBigint* FromHexCString(const char* str,
                                   Heap::Space space = Heap::kNew);
  // The given string must be a nul-terminated string of decimal digits. It
  // must only contain decimal digits (0-9). No sign is allowed. Leading
  // zeroes are ignored.
  static RawBigint* FromDecimalCString(const char* str,
                                       Heap::Space space = Heap::kNew);
  // Converts the bigint to a string. The returned string is prepended by
  // a "0x" (after the optional minus-sign).
  static const char* ToHexCString(const BIGNUM* bn,
                                  uword (*allocator)(intptr_t size));
  static const char* ToHexCString(const Bigint& bigint,
                                  uword (*allocator)(intptr_t size));

  // Converts the bigint to a string.
  static const char* ToDecCString(const BIGNUM* bn,
                                  uword (*allocator)(intptr_t size));
  static const char* ToDecCString(const Bigint& bigint,
                                  uword (*allocator)(intptr_t size));

  static bool FitsIntoSmi(const Bigint& bigint);
  static RawSmi* ToSmi(const Bigint& bigint);

  static bool FitsIntoInt64(const Bigint& bigint);
  static int64_t ToInt64(const Bigint& bigint);

  static RawDouble* ToDouble(const Bigint& bigint);

  static RawBigint* Add(const Bigint& a, const Bigint& b);
  static RawBigint* Subtract(const Bigint& a, const Bigint& b);
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
  static RawInteger* BitAndWithSmi(const Bigint& bigint, const Smi& smi);
  static RawInteger* BitOrWithSmi(const Bigint& bigint, const Smi& smi);
  static RawInteger* BitXorWithSmi(const Bigint& bigint, const Smi& smi);

  static int Compare(const Bigint& a, const Bigint& b);


 private:
  static BIGNUM* TmpBN();
  static BN_CTX* TmpBNCtx();

  static RawBigint* One() {
    Bigint& result = Bigint::Handle(NewFromInt64(1));
    return result.raw();
  }
  static RawBigint* BitTT(const Bigint& a, const Bigint& b, bool tt[4]);
  // The following function only works for bit-and and bit-or.
  static RawSmi* BitOpWithSmi(Token::Kind kind,
                              const Bigint& bigint,
                              const Smi& smi);

  DISALLOW_IMPLICIT_CONSTRUCTORS(BigintOperations);
};

}  // namespace dart

#endif  // VM_BIGINT_OPERATIONS_H_
