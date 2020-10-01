// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/isolate.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

// Smi natives.

// Returns false if integer is in wrong representation, e.g., as is a Mint
// when it could have been a Smi.
static bool CheckInteger(const Integer& i) {
  if (i.IsMint()) {
    const Mint& mint = Mint::Cast(i);
    return !Smi::IsValid(mint.value());
  }
  return true;
}

DEFINE_NATIVE_ENTRY(Integer_bitAndFromInteger, 0, 2) {
  const Integer& right =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_bitAndFromInteger %s & %s\n", right.ToCString(),
                 left.ToCString());
  }
  return left.BitOp(Token::kBIT_AND, right);
}

DEFINE_NATIVE_ENTRY(Integer_bitOrFromInteger, 0, 2) {
  const Integer& right =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_bitOrFromInteger %s | %s\n", left.ToCString(),
                 right.ToCString());
  }
  return left.BitOp(Token::kBIT_OR, right);
}

DEFINE_NATIVE_ENTRY(Integer_bitXorFromInteger, 0, 2) {
  const Integer& right =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_bitXorFromInteger %s ^ %s\n", left.ToCString(),
                 right.ToCString());
  }
  return left.BitOp(Token::kBIT_XOR, right);
}

DEFINE_NATIVE_ENTRY(Integer_addFromInteger, 0, 2) {
  const Integer& right_int =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left_int, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_addFromInteger %s + %s\n", left_int.ToCString(),
                 right_int.ToCString());
  }
  return left_int.ArithmeticOp(Token::kADD, right_int);
}

DEFINE_NATIVE_ENTRY(Integer_subFromInteger, 0, 2) {
  const Integer& right_int =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left_int, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_subFromInteger %s - %s\n", left_int.ToCString(),
                 right_int.ToCString());
  }
  return left_int.ArithmeticOp(Token::kSUB, right_int);
}

DEFINE_NATIVE_ENTRY(Integer_mulFromInteger, 0, 2) {
  const Integer& right_int =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left_int, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_mulFromInteger %s * %s\n", left_int.ToCString(),
                 right_int.ToCString());
  }
  return left_int.ArithmeticOp(Token::kMUL, right_int);
}

DEFINE_NATIVE_ENTRY(Integer_truncDivFromInteger, 0, 2) {
  const Integer& right_int =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left_int, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  ASSERT(!right_int.IsZero());
  return left_int.ArithmeticOp(Token::kTRUNCDIV, right_int);
}

DEFINE_NATIVE_ENTRY(Integer_moduloFromInteger, 0, 2) {
  const Integer& right_int =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left_int, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right_int));
  ASSERT(CheckInteger(left_int));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_moduloFromInteger %s mod %s\n", left_int.ToCString(),
                 right_int.ToCString());
  }
  if (right_int.IsZero()) {
    // Should have been caught before calling into runtime.
    UNIMPLEMENTED();
  }
  return left_int.ArithmeticOp(Token::kMOD, right_int);
}

DEFINE_NATIVE_ENTRY(Integer_greaterThanFromInteger, 0, 2) {
  const Integer& right =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, left, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(right));
  ASSERT(CheckInteger(left));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_greaterThanFromInteger %s > %s\n", left.ToCString(),
                 right.ToCString());
  }
  return Bool::Get(left.CompareWith(right) == 1).raw();
}

DEFINE_NATIVE_ENTRY(Integer_equalToInteger, 0, 2) {
  const Integer& left = Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, right, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(left));
  ASSERT(CheckInteger(right));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_equalToInteger %s == %s\n", left.ToCString(),
                 right.ToCString());
  }
  return Bool::Get(left.CompareWith(right) == 0).raw();
}

static IntegerPtr ParseInteger(const String& value) {
  // Used by both Integer_parse and Integer_fromEnvironment.
  if (value.IsOneByteString()) {
    // Quick conversion for unpadded integers in strings.
    const intptr_t len = value.Length();
    if (len > 0) {
      const char* cstr = value.ToCString();
      ASSERT(cstr != NULL);
      char* p_end = NULL;
      const int64_t int_value = strtoll(cstr, &p_end, 10);
      if (p_end == (cstr + len)) {
        if ((int_value != LLONG_MIN) && (int_value != LLONG_MAX)) {
          return Integer::New(int_value);
        }
      }
    }
  }

  return Integer::New(value);
}

DEFINE_NATIVE_ENTRY(Integer_parse, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, value, arguments->NativeArgAt(0));
  return ParseInteger(value);
}

DEFINE_NATIVE_ENTRY(Integer_fromEnvironment, 0, 3) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(Integer, default_value, arguments->NativeArgAt(2));
  // Call the embedder to supply us with the environment.
  const String& env_value =
      String::Handle(Api::GetEnvironmentValue(thread, name));
  if (!env_value.IsNull()) {
    const Integer& result = Integer::Handle(ParseInteger(env_value));
    if (!result.IsNull()) {
      if (result.IsSmi()) {
        return result.raw();
      }
      return result.Canonicalize(thread);
    }
  }
  return default_value.raw();
}

static IntegerPtr ShiftOperationHelper(Token::Kind kind,
                                       const Integer& value,
                                       const Integer& amount) {
  if (amount.AsInt64Value() < 0) {
    Exceptions::ThrowArgumentError(amount);
  }
  return value.ShiftOp(kind, amount, Heap::kNew);
}

DEFINE_NATIVE_ENTRY(Integer_shrFromInteger, 0, 2) {
  const Integer& amount =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, value, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_shrFromInteger: %s >> %s\n", value.ToCString(),
                 amount.ToCString());
  }
  return ShiftOperationHelper(Token::kSHR, value, amount);
}

DEFINE_NATIVE_ENTRY(Integer_shlFromInteger, 0, 2) {
  const Integer& amount =
      Integer::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, value, arguments->NativeArgAt(1));
  ASSERT(CheckInteger(amount));
  ASSERT(CheckInteger(value));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Integer_shlFromInteger: %s << %s\n", value.ToCString(),
                 amount.ToCString());
  }
  return ShiftOperationHelper(Token::kSHL, value, amount);
}

DEFINE_NATIVE_ENTRY(Smi_bitAndFromSmi, 0, 2) {
  const Smi& left = Smi::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, right, arguments->NativeArgAt(1));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Smi_bitAndFromSmi %s & %s\n", left.ToCString(),
                 right.ToCString());
  }
  const Smi& left_value = Smi::Cast(left);
  const Smi& right_value = Smi::Cast(right);
  return Smi::New(left_value.Value() & right_value.Value());
}

DEFINE_NATIVE_ENTRY(Smi_bitNegate, 0, 1) {
  const Smi& operand = Smi::CheckedHandle(zone, arguments->NativeArgAt(0));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Smi_bitNegate: %s\n", operand.ToCString());
  }
  intptr_t result = ~operand.Value();
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}

DEFINE_NATIVE_ENTRY(Smi_bitLength, 0, 1) {
  const Smi& operand = Smi::CheckedHandle(zone, arguments->NativeArgAt(0));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Smi_bitLength: %s\n", operand.ToCString());
  }
  int64_t value = operand.AsInt64Value();
  intptr_t result = Utils::BitLength(value);
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}

// Mint natives.

DEFINE_NATIVE_ENTRY(Mint_bitNegate, 0, 1) {
  const Mint& operand = Mint::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(CheckInteger(operand));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Mint_bitNegate: %s\n", operand.ToCString());
  }
  int64_t result = ~operand.value();
  return Integer::New(result);
}

DEFINE_NATIVE_ENTRY(Mint_bitLength, 0, 1) {
  const Mint& operand = Mint::CheckedHandle(zone, arguments->NativeArgAt(0));
  ASSERT(CheckInteger(operand));
  if (FLAG_trace_intrinsified_natives) {
    OS::PrintErr("Mint_bitLength: %s\n", operand.ToCString());
  }
  int64_t value = operand.AsInt64Value();
  intptr_t result = Utils::BitLength(value);
  ASSERT(Smi::IsValid(result));
  return Smi::New(result);
}

}  // namespace dart
