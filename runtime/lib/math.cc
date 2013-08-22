// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <ctype.h>  // isspace.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/scanner.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Math_sqrt, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sqrt(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_sin, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_cos, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(cos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_tan, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(tan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_asin, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(asin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_acos, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(acos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(atan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan2, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand1, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand2, arguments->NativeArgAt(1));
  return Double::New(atan2_ieee(operand1.value(), operand2.value()));
}

DEFINE_NATIVE_ENTRY(Math_exp, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(exp(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_log, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(log(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_doublePow, 2) {
  const double operand =
      Double::CheckedHandle(arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(
      Double, exponent_object, arguments->NativeArgAt(1));
  const double exponent = exponent_object.value();
  return Double::New(pow(operand, exponent));
}


// Returns the typed-data array store in '_Random._state' field.
static RawTypedData* GetRandomStateArray(const Instance& receiver) {
  const Class& random_class = Class::Handle(receiver.clazz());
  const Field& state_field =
      Field::Handle(random_class.LookupField(Symbols::_state()));
  ASSERT(!state_field.IsNull());
  const Instance& state_field_value =
      Instance::Cast(Object::Handle(receiver.GetField(state_field)));
  ASSERT(!state_field_value.IsNull());
  ASSERT(state_field_value.IsTypedData());
  const TypedData& array = TypedData::Cast(state_field_value);
  ASSERT(array.Length() == 2);
  ASSERT(array.ElementType() == kUint32ArrayElement);
  return array.raw();
}


// Implements:
//   var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
//   _state[kSTATE_LO] = state & _MASK_32;
//   _state[kSTATE_HI] = state >> 32;
DEFINE_NATIVE_ENTRY(Random_nextState, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, receiver, arguments->NativeArgAt(0));
  const TypedData& array = TypedData::Handle(GetRandomStateArray(receiver));
  const uint64_t state_lo = array.GetUint32(0);
  const uint64_t state_hi = array.GetUint32(array.ElementSizeInBytes());
  const uint64_t A = 0xffffda61;
  uint64_t state = (A * state_lo) + state_hi;
  array.SetUint32(0, static_cast<uint32_t>(state));
  array.SetUint32(array.ElementSizeInBytes(),
      static_cast<uint32_t>(state >> 32));
  return Object::null();
}


// Implements:
//   do {
//     seed = (seed + 0x5A17) & _Random._MASK_64;
//   } while (seed == 0);
//   _state[kSTATE_LO] = seed & _MASK_32;
//   _state[kSTATE_HI] = seed >> 32;
DEFINE_NATIVE_ENTRY(Random_setupSeed, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, receiver, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, seed_int, arguments->NativeArgAt(1));
  const TypedData& array = TypedData::Handle(GetRandomStateArray(receiver));
  ASSERT(!seed_int.IsNull());
  ASSERT(!array.IsNull());
  // TODO(srdjan): Reduce Bigint to 64 bit value.
  int64_t seed = seed_int.IsBigint() ? 0 : seed_int.AsInt64Value();
  do {
    seed = seed + 0x5A17;
  } while (seed == 0);
  array.SetUint32(0, static_cast<uint32_t>(seed));
  array.SetUint32(array.ElementSizeInBytes(),
      static_cast<uint32_t>(seed >> 32));
  return Object::null();
}

}  // namespace dart
