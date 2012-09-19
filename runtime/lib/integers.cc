// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_FLAG(bool, trace_intrinsified_natives, false,
    "Report if any of the intrinsified natives are called");

// Smi natives.

static bool Are64bitOperands(const Integer& op1, const Integer& op2) {
  return !op1.IsBigint() && !op2.IsBigint();
}


static RawInteger* IntegerBitOperation(Token::Kind kind,
                                       const Integer& op1_int,
                                       const Integer& op2_int) {
  if (op1_int.IsSmi() && op2_int.IsSmi()) {
    Smi& op1 = Smi::Handle();
    Smi& op2 = Smi::Handle();
    op1 ^= op1_int.raw();
    op2 ^= op2_int.raw();
    intptr_t result = 0;
    switch (kind) {
      case Token::kBIT_AND:
        result = op1.Value() & op2.Value();
        break;
      case Token::kBIT_OR:
        result = op1.Value() | op2.Value();
        break;
      case Token::kBIT_XOR:
        result = op1.Value() ^ op2.Value();
        break;
      default:
        UNIMPLEMENTED();
    }
    ASSERT(Smi::IsValid(result));
    return Smi::New(result);
  } else if (Are64bitOperands(op1_int, op2_int)) {
    int64_t a = op1_int.AsInt64Value();
    int64_t b = op2_int.AsInt64Value();
    switch (kind) {
      case Token::kBIT_AND:
        return Integer::New(a & b);
      case Token::kBIT_OR:
        return Integer::New(a | b);
      case Token::kBIT_XOR:
        return Integer::New(a ^ b);
      default:
        UNIMPLEMENTED();
    }
  } else {
    Bigint& op1 = Bigint::Handle(Bigint::AsBigint(op1_int));
    Bigint& op2 = Bigint::Handle(Bigint::AsBigint(op2_int));
    switch (kind) {
      case Token::kBIT_AND:
        return BigintOperations::BitAnd(op1, op2);
      case Token::kBIT_OR:
        return BigintOperations::BitOr(op1, op2);
      case Token::kBIT_XOR:
        return BigintOperations::BitXor(op1, op2);
      default:
        UNIMPLEMENTED();
    }
  }
  return Integer::null();
}


// Returns false if integer is in wrong representation, e.g., as is a Bigint
// when it could have been a Smi.
static bool CheckInteger(const Integer& i) {
  if (i.IsBigint()) {
    Bigint& bigint = Bigint::Handle();
    bigint ^= i.raw();
    return !BigintOperations::FitsIntoSmi(bigint) &&
        !BigintOperations::FitsIntoMint(bigint);
  }
  if (i.IsMint()) {
    Mint& mint = Mint::Handle();
    mint ^= i.raw();
    return !Smi::IsValid64(mint.value());
  }
  return true;
}


DEFINE_NATIVE_ENTRY(Integer_bitAndFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left, arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitAndFromInteger %s & %s\n",
        right.ToCString(), left.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_AND, left, right));
  return Integer::AsInteger(result);
}


DEFINE_NATIVE_ENTRY(Integer_bitOrFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left, arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitOrFromInteger %s | %s\n",
        left.ToCString(), right.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_OR, left, right));
  return Integer::AsInteger(result);
}


DEFINE_NATIVE_ENTRY(Integer_bitXorFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left, arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitXorFromInteger %s ^ %s\n",
        left.ToCString(), right.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_XOR, left, right));
  return Integer::AsInteger(result);
}


DEFINE_NATIVE_ENTRY(Integer_addFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_addFromInteger %s + %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  return Integer::BinaryOp(Token::kADD, left_int, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_subFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_subFromInteger %s - %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  return Integer::BinaryOp(Token::kSUB, left_int, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_mulFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_mulFromInteger %s * %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  return Integer::BinaryOp(Token::kMUL, left_int, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_truncDivFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  ASSERT(!right_int.IsZero());
  return Integer::BinaryOp(Token::kTRUNCDIV, left_int, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_moduloFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(right_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_moduloFromInteger %s mod %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  if (right_int.IsZero()) {
    // Should have been caught before calling into runtime.
    UNIMPLEMENTED();
  }
  return Integer::BinaryOp(Token::kMOD, left_int, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_greaterThanFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left, arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_greaterThanFromInteger %s > %s\n",
        left.ToCString(), right.ToCString());
  }
  return Bool::Get(left.CompareWith(right) == 1);
}


DEFINE_NATIVE_ENTRY(Integer_equalToInteger, 2) {
  const Integer& left = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, right, arguments->At(1));
  ASSERT(CheckInteger(left));
  ASSERT(CheckInteger(right));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_equalToInteger %s == %s\n",
        left.ToCString(), right.ToCString());
  }
  return Bool::Get(left.CompareWith(right) == 0);
}


static int HighestBit(int64_t v) {
  uint64_t t = static_cast<uint64_t>((v > 0) ? v : -v);
  int count = 0;
  while ((t >>= 1) != 0) {
    count++;
  }
  return count;
}


// TODO(srdjan): Clarify handling of negative right operand in a shift op.
static RawInteger* SmiShiftOperation(Token::Kind kind,
                                     const Smi& left,
                                     const Smi& right) {
  intptr_t result = 0;
  const intptr_t left_value = left.Value();
  const intptr_t right_value = right.Value();
  ASSERT(right_value >= 0);
  switch (kind) {
    case Token::kSHL: {
      if ((left_value == 0) || (right_value == 0)) {
        return left.raw();
      }
      { // Check for overflow.
        int cnt = HighestBit(left_value);
        if ((cnt + right_value) >= Smi::kBits) {
          if ((cnt + right_value) >= Mint::kBits) {
            return BigintOperations::ShiftLeft(
                Bigint::Handle(Bigint::AsBigint(left)), right_value);
          } else {
            int64_t left_64 = left_value;
            return Integer::New(left_64 << right_value);
          }
        }
      }
      result = left_value << right_value;
      break;
    }
    case Token::kSHR: {
      const intptr_t shift_amount =
          (right_value >= kBitsPerWord) ? (kBitsPerWord - 1) : right_value;
      result = left_value >> shift_amount;
      break;
    }
    default:
      UNIMPLEMENTED();
  }
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}


static RawInteger* ShiftOperationHelper(Token::Kind kind,
                                        const Integer& value,
                                        const Smi& amount) {
  if (amount.Value() < 0) {
    GrowableArray<const Object*> args;
    args.Add(&amount);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  if (value.IsSmi()) {
    Smi& smi_value = Smi::Handle();
    smi_value ^= value.raw();
    return SmiShiftOperation(kind, smi_value, amount);
  }
  Bigint& big_value = Bigint::Handle();
  if (value.IsMint()) {
    const int64_t mint_value = value.AsInt64Value();
    const int count = HighestBit(mint_value);
    if ((count + amount.Value()) < Mint::kBits) {
      switch (kind) {
        case Token::kSHL:
          return Integer::New(mint_value << amount.Value());
        case Token::kSHR:
          return Integer::New(mint_value >> amount.Value());
        default:
          UNIMPLEMENTED();
      }
    } else {
      // Overflow in shift, use Bigints
      big_value = BigintOperations::NewFromInt64(mint_value);
    }
  } else {
    ASSERT(value.IsBigint());
    big_value ^= value.raw();
  }
  switch (kind) {
    case Token::kSHL:
      return BigintOperations::ShiftLeft(big_value, amount.Value());
    case Token::kSHR:
      return BigintOperations::ShiftRight(big_value, amount.Value());
    default:
      UNIMPLEMENTED();
  }
  return Integer::null();
}


DEFINE_NATIVE_ENTRY(Smi_shrFromInt, 2) {
  const Smi& amount = Smi::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, value, arguments->At(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  Integer& result = Integer::Handle(
      ShiftOperationHelper(Token::kSHR, value, amount));
  return Integer::AsInteger(result);
}



DEFINE_NATIVE_ENTRY(Smi_shlFromInt, 2) {
  const Smi& amount = Smi::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, value, arguments->At(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Smi_shlFromInt: %s << %s\n",
        value.ToCString(), amount.ToCString());
  }
  Integer& result = Integer::Handle(
      ShiftOperationHelper(Token::kSHL, value, amount));
  return Integer::AsInteger(result);
}


DEFINE_NATIVE_ENTRY(Smi_bitNegate, 1) {
  const Smi& operand = Smi::CheckedHandle(arguments->At(0));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Smi_bitNegate: %s\n", operand.ToCString());
  }
  intptr_t result = ~operand.Value();
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}

// Mint natives.

DEFINE_NATIVE_ENTRY(Mint_bitNegate, 1) {
  const Mint& operand = Mint::CheckedHandle(arguments->At(0));
  ASSERT(CheckInteger(operand));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Mint_bitNegate: %s\n", operand.ToCString());
  }
  int64_t result = ~operand.value();
  return Integer::New(result);
}

// Bigint natives.

DEFINE_NATIVE_ENTRY(Bigint_bitNegate, 1) {
  const Bigint& value = Bigint::CheckedHandle(arguments->At(0));
  const Bigint& result = Bigint::Handle(BigintOperations::BitNot(value));
  ASSERT(CheckInteger(value));
  ASSERT(CheckInteger(result));
  return Integer::AsInteger(result);
}

}  // namespace dart
