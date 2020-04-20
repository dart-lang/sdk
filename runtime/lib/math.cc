// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <ctype.h>  // isspace.

#include "vm/bootstrap_natives.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Math_sqrt, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sqrt(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_sin, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(sin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_cos, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(cos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_tan, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(tan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_asin, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(asin(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_acos, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(acos(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(atan(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_atan2, 0, 2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand1, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand2, arguments->NativeArgAt(1));
  return Double::New(atan2_ieee(operand1.value(), operand2.value()));
}

DEFINE_NATIVE_ENTRY(Math_exp, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(exp(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_log, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Double, operand, arguments->NativeArgAt(0));
  return Double::New(log(operand.value()));
}

DEFINE_NATIVE_ENTRY(Math_doublePow, 0, 2) {
  const double operand =
      Double::CheckedHandle(zone, arguments->NativeArgAt(0)).value();
  GET_NON_NULL_NATIVE_ARGUMENT(Double, exponent_object,
                               arguments->NativeArgAt(1));
  const double exponent = exponent_object.value();
  return Double::New(pow(operand, exponent));
}

// Returns the typed-data array store in '_Random._state' field.
static RawTypedData* GetRandomStateArray(const Instance& receiver) {
  const Class& random_class = Class::Handle(receiver.clazz());
  const Field& state_field =
      Field::Handle(random_class.LookupFieldAllowPrivate(Symbols::_state()));
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
//   var state =
//       ((_A * (_state[_kSTATE_LO])) + _state[_kSTATE_HI]) & (1 << 64) - 1);
//   _state[_kSTATE_LO] = state & (1 << 32) - 1);
//   _state[_kSTATE_HI] = state >> 32;
DEFINE_NATIVE_ENTRY(Random_nextState, 0, 1) {
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

RawTypedData* CreateRandomState(Zone* zone, uint64_t seed) {
  const TypedData& result =
      TypedData::Handle(zone, TypedData::New(kTypedDataUint32ArrayCid, 2));
  result.SetUint32(0, static_cast<uint32_t>(seed));
  result.SetUint32(result.ElementSizeInBytes(),
                   static_cast<uint32_t>(seed >> 32));
  return result.raw();
}

uint64_t mix64(uint64_t n) {
  // Thomas Wang 64-bit mix.
  // http://www.concentric.net/~Ttwang/tech/inthash.htm
  // via. http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm
  n = (~n) + (n << 21);  // n = (n << 21) - n - 1;
  n = n ^ (n >> 24);
  n = n * 265;  // n = (n + (n << 3)) + (n << 8);
  n = n ^ (n >> 14);
  n = n * 21;  // n = (n + (n << 2)) + (n << 4);
  n = n ^ (n >> 28);
  n = n + (n << 31);
  return n;
}

// Implements:
//   uint64_t hash = 0;
//   do {
//      hash = hash * 1037 ^ mix64((uint64_t)seed);
//      seed >>= 64;
//   } while (seed != 0 && seed != -1);  // Limits if seed positive or negative.
//   if (hash == 0) {
//     hash = 0x5A17;
//   }
//   var result = new Uint32List(2);
//   result[_kSTATE_LO] = seed & ((1 << 32) - 1);
//   result[_kSTATE_HI] = seed >> 32;
//   return result;
DEFINE_NATIVE_ENTRY(Random_setupSeed, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, seed_int, arguments->NativeArgAt(0));
  uint64_t seed = mix64(static_cast<uint64_t>(seed_int.AsInt64Value()));

  if (seed == 0) {
    seed = 0x5a17;
  }
  return CreateRandomState(zone, seed);
}

DEFINE_NATIVE_ENTRY(Random_initialSeed, 0, 0) {
  Random* rnd = isolate->random();
  uint64_t seed = rnd->NextUInt32();
  seed |= (static_cast<uint64_t>(rnd->NextUInt32()) << 32);
  return CreateRandomState(zone, seed);
}

DEFINE_NATIVE_ENTRY(SecureRandom_getBytes, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, count, arguments->NativeArgAt(0));
  const intptr_t n = count.Value();
  ASSERT((n > 0) && (n <= 8));
  uint8_t buffer[8];
  Dart_EntropySource entropy_source = Dart::entropy_source_callback();
  if ((entropy_source == NULL) || !entropy_source(buffer, n)) {
    const String& error = String::Handle(String::New(
        "No source of cryptographically secure random numbers available."));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kUnsupported, args);
  }
  uint64_t result = 0;
  for (intptr_t i = 0; i < n; i++) {
    result = (result << 8) | buffer[i];
  }
  return Integer::New(result);
}

}  // namespace dart
