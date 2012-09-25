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
  Integer& result =
      Integer::Handle(left.BitOp(Token::kBIT_AND, right));
  return result.AsInteger();
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
  Integer& result =
      Integer::Handle(left.BitOp(Token::kBIT_OR, right));
  return result.AsInteger();
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
  Integer& result =
      Integer::Handle(left.BitOp(Token::kBIT_XOR, right));
  return result.AsInteger();
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
  return left_int.ArithmeticOp(Token::kADD, right_int);
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
  return left_int.ArithmeticOp(Token::kSUB, right_int);
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
  return left_int.ArithmeticOp(Token::kMUL, right_int);
}


DEFINE_NATIVE_ENTRY(Integer_truncDivFromInteger, 2) {
  const Integer& right_int = Integer::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Integer, left_int, arguments->At(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  ASSERT(!right_int.IsZero());
  return left_int.ArithmeticOp(Token::kTRUNCDIV, right_int);
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
  return left_int.ArithmeticOp(Token::kMOD, right_int);
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


static RawInteger* ShiftOperationHelper(Token::Kind kind,
                                        const Integer& value,
                                        const Smi& amount) {
  if (amount.Value() < 0) {
    GrowableArray<const Object*> args;
    args.Add(&amount);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  if (value.IsSmi()) {
    Smi& smi_value = Smi::Handle();
    smi_value ^= value.raw();
    return smi_value.ShiftOp(kind, amount);
  }
  Bigint& big_value = Bigint::Handle();
  if (value.IsMint()) {
    const int64_t mint_value = value.AsInt64Value();
    const int count = Utils::HighestBit(mint_value);
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
  return result.AsInteger();
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
  return result.AsInteger();
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
  return result.AsInteger();
}

}  // namespace dart
