// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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

// Return the most compact presentation of an integer.
static RawInteger* AsInteger(const Integer& value) {
  if (value.IsSmi()) return value.raw();
  if (value.IsMint()) {
    Mint& mint = Mint::Handle();
    mint ^= value.raw();
    if (Smi::IsValid64(mint.value())) {
      return Smi::New(mint.value());
    } else {
      return value.raw();
    }
  }
  ASSERT(value.IsBigint());
  Bigint& big_value = Bigint::Handle();
  big_value ^= value.raw();
  if (BigintOperations::FitsIntoSmi(big_value)) {
    return BigintOperations::ToSmi(big_value);
  } else if (BigintOperations::FitsIntoInt64(big_value)) {
    return Mint::New(BigintOperations::ToInt64(big_value));
  } else {
    return big_value.raw();
  }
}


// Returns value in form of a RawBigint.
static RawBigint* AsBigint(const Integer& value) {
  ASSERT(!value.IsNull());
  if (value.IsSmi()) {
    Smi& smi = Smi::Handle();
    smi ^= value.raw();
    return BigintOperations::NewFromSmi(smi);
  } else if (value.IsMint()) {
    Mint& mint = Mint::Handle();
    mint ^= value.raw();
    return BigintOperations::NewFromInt64(mint.value());
  } else {
    ASSERT(value.IsBigint());
    Bigint& big = Bigint::Handle();
    big ^= value.raw();
    ASSERT(!BigintOperations::FitsIntoSmi(big));
    return big.raw();
  }
}


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
  } else if (op1_int.IsSmi()) {
    return IntegerBitOperation(kind, op2_int, op1_int);
  } else if (op2_int.IsSmi()) {
    Bigint& op1 = Bigint::Handle(AsBigint(op1_int));
    Smi& op2 = Smi::Handle();
    op2 ^= op2_int.raw();
    switch (kind) {
      case Token::kBIT_AND:
        return BigintOperations::BitAndWithSmi(op1, op2);
      case Token::kBIT_OR:
        return BigintOperations::BitOrWithSmi(op1, op2);
      case Token::kBIT_XOR:
        return BigintOperations::BitXorWithSmi(op1, op2);
      default:
        UNIMPLEMENTED();
    }
  } else {
    Bigint& op1 = Bigint::Handle(AsBigint(op1_int));
    Bigint& op2 = Bigint::Handle(AsBigint(op2_int));
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
        !BigintOperations::FitsIntoInt64(bigint);
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
  const Integer& left = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitAndFromInteger %s & %s\n",
        right.ToCString(), left.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_AND, left, right));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}


DEFINE_NATIVE_ENTRY(Integer_bitOrFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  const Integer& left = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitOrFromInteger %s | %s\n",
        left.ToCString(), right.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_OR, left, right));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}


DEFINE_NATIVE_ENTRY(Integer_bitXorFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  const Integer& left = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_bitXorFromInteger %s ^ %s\n",
        left.ToCString(), right.ToCString());
  }
  Integer& result = Integer::Handle(
      IntegerBitOperation(Token::kBIT_XOR, left, right));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}


// The result is invalid if it is outside the range
// Smi::kMaxValue..Smi::kMinValue.
static int64_t BinaryOpWithTwoSmis(Token::Kind operation,
                                   const Smi& left,
                                   const Smi& right) {
  switch (operation) {
    case Token::kADD:
      return left.Value() + right.Value();
    case Token::kSUB:
      return left.Value() - right.Value();
    case Token::kMUL: {
#if defined(TARGET_ARCH_X64)
      // Overflow check for 64-bit platforms unimplemented.
      UNIMPLEMENTED();
      return 0;
#else
      int64_t result_64 =
          static_cast<int64_t>(left.Value()) *
          static_cast<int64_t>(right.Value());
      return result_64;
#endif
    }
    case Token::kTRUNCDIV:
      return left.Value() / right.Value();
    case Token::kMOD: {
      intptr_t remainder = left.Value() % right.Value();
      if (remainder < 0) {
        if (right.Value() < 0) {
          return remainder - right.Value();
        } else {
          return remainder + right.Value();
        }
      } else {
        return remainder;
      }
    }
    default:
      UNIMPLEMENTED();
      return 0;
  }
}


static RawBigint* BinaryOpWithTwoBigints(Token::Kind operation,
                                         const Bigint& left,
                                         const Bigint& right) {
  switch (operation) {
    case Token::kADD:
      return BigintOperations::Add(left, right);
    case Token::kSUB:
      return BigintOperations::Subtract(left, right);
    case Token::kMUL:
      return BigintOperations::Multiply(left, right);
    case Token::kTRUNCDIV:
      return BigintOperations::Divide(left, right);
    case Token::kMOD:
      return BigintOperations::Modulo(left, right);
    default:
      UNIMPLEMENTED();
      return Bigint::null();
  }
}


// TODO(srdjan): Implement correct overflow checking before allowing 64 bit
// operands.
static bool AreBoth64bitOperands(const Integer& op1, const Integer& op2) {
  return false;
}


static RawInteger* IntegerBinopHelper(Token::Kind operation,
                                      const Integer& left_int,
                                      const Integer& right_int) {
  if (left_int.IsSmi() && right_int.IsSmi()) {
    Smi& left_smi = Smi::Handle();
    Smi& right_smi = Smi::Handle();
    left_smi ^= left_int.raw();
    right_smi ^= right_int.raw();
    int64_t result = BinaryOpWithTwoSmis(operation, left_smi, right_smi);
    if (Smi::IsValid64(result)) {
      return Smi::New(result);
    } else {
      // Overflow to Mint.
      return Mint::New(result);
    }
  } else if (AreBoth64bitOperands(left_int, right_int)) {
    // TODO(srdjan): Test for overflow of result instead of operand
    // types.
    const int64_t a = left_int.AsInt64Value();
    const int64_t b = right_int.AsInt64Value();
    switch (operation) {
      case Token::kADD:
        return Integer::New(a + b);
      case Token::kSUB:
        return Integer::New(a - b);
      case Token::kMUL:
        return Integer::New(a * b);
      case Token::kTRUNCDIV:
        return Integer::New(a / b);
      case Token::kMOD: {
        int64_t remainder = a % b;
        int64_t c = 0;
        if (remainder < 0) {
          if (b < 0) {
            c = remainder - b;
          } else {
            c = remainder + b;
          }
        } else {
          c = remainder;
        }
        return Integer::New(c);
      }
      default:
        UNIMPLEMENTED();
    }
  }
  const Bigint& left_big = Bigint::Handle(AsBigint(left_int));
  const Bigint& right_big = Bigint::Handle(AsBigint(right_int));
  const Bigint& result =
      Bigint::Handle(BinaryOpWithTwoBigints(operation, left_big, right_big));
  return Integer::Handle(AsInteger(result)).raw();
}


DEFINE_NATIVE_ENTRY(Integer_addFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  const Integer& left_int = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_addFromInteger %s + %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  const Integer& result =
      Integer::Handle(IntegerBinopHelper(Token::kADD, left_int, right_int));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_subFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  const Integer& left_int = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_subFromInteger %s - %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  const Integer& result =
      Integer::Handle(IntegerBinopHelper(Token::kSUB, left_int, right_int));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_mulFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  const Integer& left_int = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_mulFromInteger %s * %s\n",
        left_int.ToCString(), right_int.ToCString());
  }
  const Integer& result =
      Integer::Handle(IntegerBinopHelper(Token::kMUL, left_int, right_int));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_truncDivFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  const Integer& left_int = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  ASSERT(!right_int.IsZero());
  const Integer& result = Integer::Handle(
      IntegerBinopHelper(Token::kTRUNCDIV, left_int, right_int));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_moduloFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  const Integer& left_int = Integer::CheckedHandle(arguments->At(1));
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
  const Integer& result =
      Integer::Handle(IntegerBinopHelper(Token::kMOD, left_int, right_int));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_greaterThanFromInteger, 2) {
  const Integer& right = Integer::CheckedHandle(arguments->At(0));
  const Integer& left = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_greaterThanFromInteger %s > %s\n",
        left.ToCString(), right.ToCString());
  }
  const Bool& result = Bool::Handle(Bool::Get(left.CompareWith(right) == 1));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(Integer_equalToInteger, 2) {
  const Integer& left = Integer::CheckedHandle(arguments->At(0));
  const Integer& right = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(left));
  ASSERT(CheckInteger(right));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Integer_equalToInteger %s == %s\n",
        left.ToCString(), right.ToCString());
  }
  const Bool& result = Bool::Handle(Bool::Get(left.CompareWith(right) == 0));
  arguments->SetReturn(result);
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
  ASSERT(right.Value() >= 0);
  intptr_t result = 0;
  switch (kind) {
    case Token::kSHL:
      if ((left.Value() == 0) || (right.Value() == 0)) {
        return left.raw();
      }
      { // Check for overflow.
        int cnt = HighestBit(left.Value());
        if ((cnt + right.Value()) >= Smi::kBits) {
          if ((cnt + right.Value()) >= Mint::kBits) {
            return BigintOperations::ShiftLeft(
                Bigint::Handle(AsBigint(left)), right.Value());
          } else {
            int64_t left_64 = left.Value();
            return Integer::New(left_64 << right.Value());
          }
        }
      }
      result = left.Value() << right.Value();
      break;
    case Token::kSAR: {
        int shift_amount = (right.Value() > 0x1F) ? 0x1F : right.Value();
        result = left.Value() >> shift_amount;
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
        case Token::kSAR:
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
    case Token::kSAR:
      return BigintOperations::ShiftRight(big_value, amount.Value());
    default:
      UNIMPLEMENTED();
  }
  return Integer::null();
}


DEFINE_NATIVE_ENTRY(Smi_sarFromInt, 2) {
  const Smi& amount = Smi::CheckedHandle(arguments->At(0));
  const Integer& value = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  Integer& result = Integer::Handle(
      ShiftOperationHelper(Token::kSAR, value, amount));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}



DEFINE_NATIVE_ENTRY(Smi_shlFromInt, 2) {
  const Smi& amount = Smi::CheckedHandle(arguments->At(0));
  const Integer& value = Integer::CheckedHandle(arguments->At(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Smi_shlFromInt: %s << %s\n",
        value.ToCString(), amount.ToCString());
  }
  Integer& result = Integer::Handle(
      ShiftOperationHelper(Token::kSHL, value, amount));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}


DEFINE_NATIVE_ENTRY(Smi_bitNegate, 1) {
  const Smi& operand = Smi::CheckedHandle(arguments->At(0));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Smi_bitNegate: %s\n", operand.ToCString());
  }
  intptr_t result = ~operand.Value();
  ASSERT(Smi::IsValid(result));
  arguments->SetReturn(Smi::Handle(Smi::New(result)));
}

// Mint natives.

DEFINE_NATIVE_ENTRY(Mint_bitNegate, 1) {
  const Mint& operand = Mint::CheckedHandle(arguments->At(0));
  ASSERT(CheckInteger(operand));
  if (FLAG_trace_intrinsified_natives) {
    OS::Print("Mint_bitNegate: %s\n", operand.ToCString());
  }
  int64_t result = ~operand.value();
  arguments->SetReturn(Integer::Handle(Integer::New(result)));
}

// Bigint natives.

DEFINE_NATIVE_ENTRY(Bigint_bitNegate, 1) {
  const Bigint& value = Bigint::CheckedHandle(arguments->At(0));
  const Bigint& result = Bigint::Handle(BigintOperations::BitNot(value));
  ASSERT(CheckInteger(value));
  ASSERT(CheckInteger(result));
  arguments->SetReturn(Integer::Handle(AsInteger(result)));
}

}  // namespace dart
