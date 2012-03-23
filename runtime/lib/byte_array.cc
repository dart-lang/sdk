// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(ByteArray_getLength, 1) {
  const ByteArray& byte_array = ByteArray::CheckedHandle(arguments->At(0));
  const Smi& length = Smi::Handle(Smi::New(byte_array.Length()));
  arguments->SetReturn(length);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_allocate, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->At(0));
  if (length.Value() < 0) {
    GrowableArray<const Object*> args;
    args.Add(&length);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  const InternalByteArray& new_array =
      InternalByteArray::Handle(InternalByteArray::New(length.Value()));
  arguments->SetReturn(new_array);
}


static void RangeCheck(const ByteArray& array,
                       intptr_t index,
                       intptr_t num_bytes) {
  if (!Utils::RangeCheck(index, num_bytes, array.Length())) {
    GrowableArray<const Object*> arguments;
    const Smi &index_object = Smi::Handle(Smi::New(index));
    arguments.Add(&index_object);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
}


DEFINE_NATIVE_ENTRY(ByteArray_setRange, 5) {
  ByteArray& dst = ByteArray::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, dst_start, arguments->At(1));
  GET_NATIVE_ARGUMENT(Smi, length, arguments->At(2));
  GET_NATIVE_ARGUMENT(ByteArray, src, arguments->At(3));
  GET_NATIVE_ARGUMENT(Smi, src_start, arguments->At(4));
  intptr_t length_value = length.Value();
  intptr_t src_start_value = src_start.Value();
  intptr_t dst_start_value = dst_start.Value();
  if (length_value < 0) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  RangeCheck(src, src_start_value, length_value);
  RangeCheck(dst, dst_start_value, length_value);
  ByteArray::Copy(dst, dst_start_value, src, src_start_value, length_value);
}

#define GETTER_ARGUMENTS(ArrayT, ValueT)                                \
  GET_NATIVE_ARGUMENT(ArrayT, array, arguments->At(0));                 \
  GET_NATIVE_ARGUMENT(Smi, index, arguments->At(1));                    \
  RangeCheck(array, index.Value(), sizeof(ValueT));


#define SETTER_ARGUMENTS(ArrayT, ObjectT, ValueT)                       \
  GET_NATIVE_ARGUMENT(ArrayT, array, arguments->At(0));                 \
  GET_NATIVE_ARGUMENT(Smi, index, arguments->At(1));                    \
  RangeCheck(array, index.Value(), sizeof(ValueT));                     \
  GET_NATIVE_ARGUMENT(ObjectT, integer_value, arguments->At(2));


#define GETTER(ArrayT, ObjectT, ValueT)                                 \
  GETTER_ARGUMENTS(ArrayT, ValueT);                                     \
  ValueT result = array.UnalignedAt<ValueT>(index.Value());             \
  arguments->SetReturn(ObjectT::Handle(ObjectT::New(result)));


#define SETTER(ArrayT, ObjectT, Getter, ValueT)                         \
  SETTER_ARGUMENTS(ArrayT, ObjectT, ValueT);                            \
  array.SetUnalignedAt<ValueT>(index.Value(), integer_value.Getter());


#define GETTER_UINT64(ArrayT)                                           \
  GETTER_ARGUMENTS(ArrayT, uint64_t);                                   \
  uint64_t value = array.UnalignedAt<uint64_t>(index.Value());          \
  Integer& result = Integer::Handle();                                  \
  if (value > static_cast<uint64_t>(Mint::kMaxValue)) {                 \
    result = BigintOperations::NewFromUint64(value);                    \
  } else if (value > static_cast<uint64_t>(Smi::kMaxValue)) {           \
    result = Mint::New(value);                                          \
  } else {                                                              \
    result = Smi::New(value);                                           \
  }                                                                     \
  arguments->SetReturn(result);


#define SETTER_UINT64(ArrayT)                                           \
  SETTER_ARGUMENTS(ArrayT, Integer, uint64_t);                          \
  uint64_t value;                                                       \
  if (integer_value.IsBigint()) {                                       \
    Bigint& bigint_value = Bigint::Handle();                            \
    bigint_value ^= integer_value.raw();                                \
    ASSERT(BigintOperations::FitsIntoUint64(bigint_value));             \
    value = BigintOperations::AbsToUint64(bigint_value);                \
  } else {                                                              \
    ASSERT(integer_value.IsMint() || integer_value.IsSmi());            \
    value = integer_value.AsInt64Value();                               \
  }                                                                     \
  array.SetUnalignedAt<uint64_t>(index.Value(), value);


DEFINE_NATIVE_ENTRY(InternalByteArray_getInt8, 2) {
  GETTER(InternalByteArray, Smi, int8_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setInt8, 3) {
  SETTER(InternalByteArray, Smi, Value, int8_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getUint8, 2) {
  GETTER(InternalByteArray, Smi, uint8_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setUint8, 3) {
  SETTER(InternalByteArray, Smi, Value, uint8_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getInt16, 2) {
  GETTER(InternalByteArray, Smi, int16_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setInt16, 3) {
  SETTER(InternalByteArray, Smi, Value, int16_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getUint16, 2) {
  GETTER(InternalByteArray, Smi, uint16_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setUint16, 3) {
  SETTER(InternalByteArray, Smi, Value, uint16_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getInt32, 2) {
  GETTER(InternalByteArray, Integer, int32_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setInt32, 3) {
  SETTER(InternalByteArray, Integer, AsInt64Value, int32_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getUint32, 2) {
  GETTER(InternalByteArray, Integer, uint32_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setUint32, 3) {
  SETTER(InternalByteArray, Integer, AsInt64Value, uint32_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getInt64, 2) {
  GETTER(InternalByteArray, Integer, int64_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setInt64, 3) {
  SETTER(InternalByteArray, Integer, AsInt64Value, int64_t);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getUint64, 2) {
  GETTER_UINT64(InternalByteArray);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setUint64, 3) {
  SETTER_UINT64(InternalByteArray);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getFloat32, 2) {
  GETTER(InternalByteArray, Double, float);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setFloat32, 3) {
  SETTER(InternalByteArray, Double, value, float);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_getFloat64, 2) {
  GETTER(InternalByteArray, Double, double);
}


DEFINE_NATIVE_ENTRY(InternalByteArray_setFloat64, 3) {
  SETTER(InternalByteArray, Double, value, double);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getInt8, 2) {
  GETTER(ExternalByteArray, Smi, int8_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setInt8, 3) {
  SETTER(ExternalByteArray, Smi, Value, int8_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getUint8, 2) {
  GETTER(ExternalByteArray, Smi, uint8_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setUint8, 3) {
  SETTER(ExternalByteArray, Smi, Value, uint8_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getInt16, 2) {
  GETTER(ExternalByteArray, Smi, int16_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setInt16, 3) {
  SETTER(ExternalByteArray, Smi, Value, int16_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getUint16, 2) {
  GETTER(ExternalByteArray, Smi, uint16_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setUint16, 3) {
  SETTER(ExternalByteArray, Smi, Value, uint16_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getInt32, 2) {
  GETTER(ExternalByteArray, Integer, int32_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setInt32, 3) {
  SETTER(ExternalByteArray, Integer, AsInt64Value, int32_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getUint32, 2) {
  GETTER(ExternalByteArray, Integer, uint32_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setUint32, 3) {
  SETTER(ExternalByteArray, Integer, AsInt64Value, uint32_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getInt64, 2) {
  GETTER(ExternalByteArray, Integer, int64_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setInt64, 3) {
  SETTER(ExternalByteArray, Integer, AsInt64Value, int64_t);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getUint64, 2) {
  GETTER_UINT64(ExternalByteArray);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setUint64, 3) {
  SETTER_UINT64(ExternalByteArray);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getFloat32, 2) {
  GETTER(ExternalByteArray, Double, float);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setFloat32, 3) {
  SETTER(ExternalByteArray, Double, value, float);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_getFloat64, 2) {
  GETTER(ExternalByteArray, Double, double);
}


DEFINE_NATIVE_ENTRY(ExternalByteArray_setFloat64, 3) {
  SETTER(ExternalByteArray, Double, value, double);
}

}  // namespace dart
