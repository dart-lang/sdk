// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bigint_operations.h"

#include <openssl/crypto.h>

#include "vm/bigint_store.h"
#include "vm/double_internals.h"
#include "vm/exceptions.h"
#include "vm/utils.h"
#include "vm/zone.h"

namespace dart {

bool Bigint::IsZero() const { return BN_is_zero(BNAddr()); }
bool Bigint::IsNegative() const { return !!BNAddr()->neg; }


void Bigint::SetSign(bool is_negative) const {
  BIGNUM* bn = MutableBNAddr();
  // Danger Will Robinson! Use of OpenSSL internals!
  // FIXME(benl): can be changed to use BN_set_negative() on more
  // recent OpenSSL releases (> 1.0.0).
  if (!is_negative || BN_is_zero(bn)) {
    bn->neg = 0;
  } else {
    bn->neg = 1;
  }
}


BIGNUM* BigintOperations::TmpBN() {
  BigintStore* store = BigintStore::Get();
  if (store->bn_ == NULL) {
    store->bn_ = BN_new();
  }
  return store->bn_;
}


BN_CTX* BigintOperations::TmpBNCtx() {
  BigintStore* store = BigintStore::Get();
  if (store->bn_ctx_ == NULL) {
    store->bn_ctx_ = BN_CTX_new();
  }
  return store->bn_ctx_;
}


RawBigint* BigintOperations::NewFromSmi(const Smi& smi, Heap::Space space) {
  intptr_t value = smi.Value();
  bool is_negative = value < 0;

  if (is_negative) {
    value = -value;
  }

  BN_set_word(TmpBN(), value);

  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN(), space));
  result.SetSign(is_negative);

  return result.raw();
}


RawBigint* BigintOperations::NewFromInt64(int64_t value, Heap::Space space) {
  bool is_negative = value < 0;

  if (is_negative) {
    value = -value;
  }

  const int kNumBytes = sizeof(value);
  unsigned char pch[kNumBytes];
  for (int i = kNumBytes - 1; i >= 0; i--) {
    unsigned char c = value & 0xFF;
    value >>=8;
    pch[i] = c;
  }

  BN_bin2bn(pch, kNumBytes, TmpBN());

  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN(), space));
  result.SetSign(is_negative);

  return result.raw();
}


RawBigint* BigintOperations::NewFromCString(const char* str,
                                            Heap::Space space) {
  ASSERT(str != NULL);
  if (str[0] == '\0') {
    return NewFromInt64(0, space);
  }

  // If the string starts with '-' recursively restart the whole operation
  // without the character and then toggle the sign.
  // This allows multiple leading '-' (which will cancel each other out), but
  // we have added an assert, to make sure that the returned result of the
  // recursive call is not negative.
  // We don't catch leading '-'s for zero. Ex: "--0", or "---".
  if (str[0] == '-') {
    const Bigint& result = Bigint::Handle(NewFromCString(&str[1], space));
    if (!result.IsNull()) {
      result.ToggleSign();
      // FIXME(benl): this will fail if there is more than one leading '-'.
      ASSERT(result.IsZero() || result.IsNegative());
    }
    return result.raw();
  }

  intptr_t str_length = strlen(str);
  if ((str_length > 2) &&
      (str[0] == '0') &&
      ((str[1] == 'x') || (str[1] == 'X'))) {
    const Bigint& result = Bigint::Handle(FromHexCString(&str[2], space));
    return result.raw();
  } else {
    return FromDecimalCString(str, space);
  }
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
    GrowableArray<const Object*> exception_arguments;
    exception_arguments.Add(
        &Object::ZoneHandle(String::New("BigintOperations::NewFromDouble")));
    exception_arguments.Add(&Object::ZoneHandle(Double::New(d)));
    Exceptions::ThrowByType(Exceptions::kInternalError,
                            exception_arguments);
  }
  uint64_t significand = internals.Significand();
  int exponent = internals.Exponent();
  int sign = internals.Sign();
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


RawBigint* BigintOperations::FromHexCString(const char* hex_string,
                                            Heap::Space space) {
  BIGNUM *bn = TmpBN();
  BN_hex2bn(&bn, hex_string);
  ASSERT(bn == TmpBN());
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN(), space));
  return result.raw();
}


RawBigint* BigintOperations::FromDecimalCString(const char* str,
                                                Heap::Space space) {
  BIGNUM *bn = TmpBN();
  int len = BN_dec2bn(&bn, str);
  if (len == 0) {
    return Bigint::null();
  }
  ASSERT(bn == TmpBN());
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN(), space));
  return result.raw();
}


const char* BigintOperations::ToHexCString(const BIGNUM *bn,
                                           uword (*allocator)(intptr_t size)) {
  char* str = BN_bn2hex(bn);
  char* to_free = str;
  intptr_t neg = 0;
  if (str[0] == '-') {
    ++str;
    neg = 1;
  }
  if (str[0] == '0' && str[1] != '\0') {
    ++str;
  }
  intptr_t length = strlen(str) + 3 + neg;
  char *result = reinterpret_cast<char*>(allocator(length));
  if (neg) {
    result[0] = '-';
    result[1] = '0';
    result[2] = 'x';
    // memcpy would suffice
    memmove(result + 3, str, length - 3);
  } else {
    result[0] = '0';
    result[1] = 'x';
    // memcpy would suffice
    memmove(result + 2, str, length - 2);
  }
  OPENSSL_free(to_free);
  return result;
}


const char* BigintOperations::ToDecCString(const Bigint& bigint,
                                           uword (*allocator)(intptr_t size)) {
  return ToDecCString(bigint.BNAddr(), allocator);
}


const char* BigintOperations::ToDecCString(const BIGNUM *bn,
                                           uword (*allocator)(intptr_t size)) {
  char* str = BN_bn2dec(bn);
  intptr_t length = strlen(str) + 1;  // '\0'-terminated.
  char* result = reinterpret_cast<char*>(allocator(length));
  memmove(result, str, length);
  OPENSSL_free(str);
  return result;
}


const char* BigintOperations::ToHexCString(const Bigint& bigint,
                                           uword (*allocator)(intptr_t size)) {
  return ToHexCString(bigint.BNAddr(), allocator);
}


bool BigintOperations::FitsIntoSmi(const Bigint& bigint) {
  const BIGNUM *bn = bigint.BNAddr();
  int bits = BN_num_bits(bn);
  // Special case for kMinValue as the absolute value is 1 bit longer
  // than anything else
  if (bits == Smi::kBits + 1 && BN_abs_is_word(bn, -Smi::kMinValue)
      && bigint.IsNegative()) {
    return true;
  }
  // All other cases must have no more bits than the size of an Smi
  if (bits > Smi::kBits) {
    return false;
  }
  return true;
}


RawSmi* BigintOperations::ToSmi(const Bigint& bigint) {
  ASSERT(FitsIntoSmi(bigint));
  unsigned char bytes[kBitsPerWord / kBitsPerByte];
  ASSERT(BN_num_bytes(bigint.BNAddr()) <= static_cast<int>(sizeof bytes));
  int n = BN_bn2bin(bigint.BNAddr(), bytes);
  ASSERT(n >= 0);
  intptr_t value = 0;
  ASSERT(n <= static_cast<int>(sizeof value));
  for (int i = 0; i < n; ++i) {
    value <<= 8;
    value |= bytes[i];
  }
  if (bigint.IsNegative()) {
    value = -value;
  }
  return Smi::New(value);
}


RawDouble* BigintOperations::ToDouble(const Bigint& bigint) {
  // TODO(floitsch/benl): This is a quick and dirty implementation to unblock
  // other areas of the code. It does not handle all bit-twiddling correctly.
  double value = 0.0;
  for (int i = bigint.NumberOfBits() - 1; i >= 0; --i) {
    value *= 2;
    value += static_cast<double>(bigint.Bit(i));
  }
  if (bigint.IsNegative()) {
    value = -value;
  }
  return Double::New(value);
}


bool BigintOperations::FitsIntoInt64(const Bigint& bigint) {
  const BIGNUM *bn = bigint.BNAddr();
  int bits = BN_num_bits(bn);
  if (bits <= 63) return true;
  if (bits > 64) return false;
  if (!bigint.IsNegative()) return false;
  // Special case for negative values, since Int64 representation may lose
  // one bit.
  ASSERT(bigint.Bit(63) != 0);
  for (int i = 0; i < 63; i++) {
    // Verify that all 63 least significant bits are 0.
    if (bigint.Bit(i) != 0) return false;
  }
  return true;
}


int64_t BigintOperations::ToInt64(const Bigint& bigint) {
  ASSERT(FitsIntoInt64(bigint));
  unsigned char bytes[8];
  ASSERT(BN_num_bytes(bigint.BNAddr()) <= static_cast<int>(sizeof bytes));
  int n = BN_bn2bin(bigint.BNAddr(), bytes);
  ASSERT(n >= 0);
  int64_t value = 0;
  ASSERT(n <= static_cast<int>(sizeof value));
  for (int i = 0; i < n; ++i) {
    value <<= 8;
    value |= bytes[i];
  }
  if (bigint.IsNegative()) {
    value = -value;
  }
  return value;
}


RawBigint* BigintOperations::Add(const Bigint& a, const Bigint& b) {
  int status = BN_add(TmpBN(), a.BNAddr(), b.BNAddr());
  ASSERT(status == 1);
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}


RawBigint* BigintOperations::Subtract(const Bigint& a, const Bigint& b) {
  int status = BN_sub(TmpBN(), a.BNAddr(), b.BNAddr());
  ASSERT(status == 1);
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}


RawBigint* BigintOperations::Multiply(const Bigint& a, const Bigint& b) {
  int status = BN_mul(TmpBN(), a.BNAddr(), b.BNAddr(), TmpBNCtx());
  ASSERT(status == 1);
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}


RawBigint* BigintOperations::Divide(const Bigint& a, const Bigint& b) {
  int status = BN_div(TmpBN(), NULL, a.BNAddr(), b.BNAddr(), TmpBNCtx());
  ASSERT(status == 1);
  const Bigint& quotient = Bigint::Handle(Bigint::New(TmpBN()));
  return quotient.raw();
}


RawBigint* BigintOperations::Modulo(const Bigint& a, const Bigint& b) {
  int status = BN_nnmod(TmpBN(), a.BNAddr(), b.BNAddr(), TmpBNCtx());
  ASSERT(status == 1);
  const Bigint& modulo = Bigint::Handle(Bigint::New(TmpBN()));
  return modulo.raw();
}


RawBigint* BigintOperations::Remainder(const Bigint& a, const Bigint& b) {
  int status = BN_div(NULL, TmpBN(), a.BNAddr(), b.BNAddr(), TmpBNCtx());
  ASSERT(status == 1);
  const Bigint& remainder = Bigint::Handle(Bigint::New(TmpBN()));
  return remainder.raw();
}


RawBigint* BigintOperations::ShiftLeft(const Bigint& bigint, intptr_t amount) {
  int status = BN_lshift(TmpBN(), bigint.BNAddr(), amount);
  ASSERT(status == 1);
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}


RawBigint* BigintOperations::ShiftRight(const Bigint& bigint, intptr_t amount) {
  ASSERT(amount >= 0);
  int status = BN_rshift(TmpBN(), bigint.BNAddr(), amount);
  ASSERT(status == 1);

  // OpenSSL doesn't take account of sign when shifting - this fixes it.
  if (bigint.IsNegative()) {
    for (intptr_t i = 0; i < amount; ++i) {
      if (bigint.IsBitSet(i)) {
        int status = BN_sub_word(TmpBN(), 1);
        ASSERT(status == 1);
        break;
      }
    }
  }
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}

/* Bit operations are complicated by negatives: BIGNUMs don't use 2's
 * complement, but instead store the absolute value and a sign
 * indicator. However bit operations are defined on 2's complement
 * representations. This function handles the necessary
 * invert-and-carry operations to deal with the fact that -x = ~x + 1
 * both on the operands and result. The actual operation performed is
 * specified by the truth table |tt|, which is in the order of input
 * bits (00, 01, 10, 11).
 */
RawBigint* BigintOperations::BitTT(const Bigint& a, const Bigint& b,
                                   bool tt[4]) {
  BN_zero(TmpBN());
  int n;
  int rflip = 0;
  int rborrow = 0;
  // There's probably a clever way to figure out why these are what
  // they are, but I confess I worked them out pragmatically.
  if (a.IsNegative() && b.IsNegative()) {
    if (tt[3]) {
      rflip = -1;
      rborrow = -1;
    }
    if (tt[2] != tt[3]) {
      n = Utils::Maximum(a.NumberOfBits(), b.NumberOfBits());
    } else {
      n = Utils::Minimum(a.NumberOfBits(), b.NumberOfBits());
    }
  } else if (a.IsNegative() || b.IsNegative()) {
    if (tt[2]) {
      rflip = rborrow = -1;
    }
    n = Utils::Maximum(a.NumberOfBits(), b.NumberOfBits());
  } else {
    if (tt[2]) {
      n = Utils::Maximum(a.NumberOfBits(), b.NumberOfBits());
    } else {
      n = Utils::Minimum(a.NumberOfBits(), b.NumberOfBits());
    }
  }
  bool aflip = false;
  int acarry = 0;
  if (a.IsNegative()) {
    aflip = true;
    acarry = 1;
  }
  bool bflip = false;
  int bcarry = 0;
  if (b.IsNegative()) {
    bflip = true;
    bcarry = 1;
  }
  for (int i = 0 ; i < n ; ++i) {
    int ab = (a.Bit(i) ^ (aflip ? 1 : 0)) + acarry;
    ASSERT(ab <= 2 && ab >= 0);
    int bb = (b.Bit(i) ^ (bflip ? 1 : 0)) + bcarry;
    ASSERT(bb <= 2 && bb >= 0);
    int r = tt[(ab & 1) + ((bb & 1) << 1)];
    r = r + rborrow;
    ASSERT(r >= -1 && r <= 1);
    if ((r ^ rflip) & 1) {
      int status = BN_set_bit(TmpBN(), i);
      ASSERT(status == 1);
    }
    acarry = ab >> 1;
    bcarry = bb >> 1;
    rborrow = r >> 1;
    }
  if (rborrow) {
    int status = BN_set_bit(TmpBN(), n);
    ASSERT(status == 1);
  }
  if (rflip) {
    // FIXME(benl): can be changed to use BN_set_negative() on more
    // recent OpenSSL releases (> 1.0.0).
    ASSERT(!BN_is_zero(TmpBN()));
    TmpBN()->neg = 1;
  }
  const Bigint& result = Bigint::Handle(Bigint::New(TmpBN()));
  return result.raw();
}


RawSmi* BigintOperations::BitOpWithSmi(Token::Kind kind,
                                       const Bigint& bigint,
                                       const Smi& smi) {
  ASSERT((kind == Token::kBIT_OR) || (kind == Token::kBIT_AND));
  intptr_t smi_value = smi.Value();
  intptr_t big_value = 0;
  // We take Smi::kBits + 1 (one more bit), in case bigint is negative.
  ASSERT((Smi::kBits + 1) <= (sizeof(big_value) * kBitsPerByte));
  intptr_t num_bits = bigint.NumberOfBits();
  int n = Utils::Minimum(num_bits, Smi::kBits + 1);
  for (int i = n - 1; i >= 0; i--) {
    big_value <<= 1;
    big_value += bigint.Bit(i);
  }
  if (bigint.IsNegative()) {
    big_value = -big_value;
  }
  intptr_t result;
  if (kind == Token::kBIT_OR) {
    result = smi_value | big_value;
  } else {
    result = smi_value & big_value;
  }
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}


RawBigint* BigintOperations::BitAnd(const Bigint& a, const Bigint& b) {
  static bool tt_and[] = { false, false, false, true };
  return BitTT(a, b, tt_and);
}


RawInteger* BigintOperations::BitAndWithSmi(const Bigint& bigint,
                                            const Smi& smi) {
  if (smi.IsNegative()) {
    Bigint& other = Bigint::Handle(NewFromSmi(smi));
    return BitAnd(bigint, other);
  }
  return BitOpWithSmi(Token::kBIT_AND, bigint, smi);
}


RawBigint* BigintOperations::BitOr(const Bigint& a, const Bigint& b) {
  static bool tt_or[] = { false, true, true, true };
  return BitTT(a, b, tt_or);
}


RawInteger* BigintOperations::BitOrWithSmi(const Bigint& bigint,
                                           const Smi& smi) {
  if (!smi.IsNegative()) {
    Bigint& other = Bigint::Handle(NewFromSmi(smi));
    return BitOr(bigint, other);
  }
  return BitOpWithSmi(Token::kBIT_OR, bigint, smi);
}


RawBigint* BigintOperations::BitXor(const Bigint& a, const Bigint& b) {
  static bool tt_xor[] = { false, true, true, false };
  return BitTT(a, b, tt_xor);
}


RawInteger* BigintOperations::BitXorWithSmi(const Bigint& bigint,
                                            const Smi& smi) {
  Bigint& other = Bigint::Handle(NewFromSmi(smi));
  return BitXor(bigint, other);
}


RawBigint* BigintOperations::BitNot(const Bigint& bigint) {
  const Bigint& one_bigint = Bigint::Handle(One());
  const Bigint& result = Bigint::Handle(Add(bigint, one_bigint));
  result.ToggleSign();
  return result.raw();
}


int BigintOperations::Compare(const Bigint& a, const Bigint& b) {
  return BN_cmp(a.BNAddr(), b.BNAddr());
}

}  // namespace dart
