// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

// ByteArray

// Checks to see if (index * num_bytes) is in the range
// [0..array.ByteLength()).  without the risk of integer overflow.  If
// the index is out of range, then a RangeError is thrown.
static void RangeCheck(const ByteArray& array,
                       intptr_t index,
                       intptr_t num_bytes) {
  if (!Utils::RangeCheck(index, num_bytes, array.ByteLength())) {
    const String& error = String::Handle(String::NewFormatted(
        "index (%"Pd") must be in the range [0..%"Pd")",
        index, (array.ByteLength() / num_bytes)));
    GrowableArray<const Object*> args;
    args.Add(&error);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
}


// Checks to see if a length is in the range [0..max].  If the length
// is out of range, then an ArgumentError is thrown.
static void LengthCheck(intptr_t len, intptr_t max) {
  if (len < 0 || len > max) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%"Pd") must be in the range [0..%"Pd"]", len, max));
    GrowableArray<const Object*> args;
    args.Add(&error);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
}


#define GETTER_ARGUMENTS(ArrayT, ValueT)                                \
  GET_NATIVE_ARGUMENT(ArrayT, array, arguments->NativeArgAt(0));        \
  GET_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));


#define SETTER_ARGUMENTS(ArrayT, ObjectT, ValueT)                       \
  GET_NATIVE_ARGUMENT(ArrayT, array, arguments->NativeArgAt(0));        \
  GET_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));           \
  GET_NATIVE_ARGUMENT(ObjectT, value_object, arguments->NativeArgAt(2));


#define GETTER(ArrayT, ObjectT, ValueT)                                 \
  GETTER_ARGUMENTS(ArrayT, ValueT);                                     \
  RangeCheck(array, index.Value() * sizeof(ValueT), sizeof(ValueT));    \
  ValueT result = array.At(index.Value());                              \
  return ObjectT::New(result);


#define SETTER(ArrayT, ObjectT, Getter, ValueT)                         \
  SETTER_ARGUMENTS(ArrayT, ObjectT, ValueT);                            \
  RangeCheck(array, index.Value() * sizeof(ValueT), sizeof(ValueT));    \
  ValueT value = value_object.Getter();                                 \
  array.SetAt(index.Value(), value);                                    \
  return Object::null();


#define UNALIGNED_GETTER(ArrayT, ObjectT, ValueT)                       \
  GETTER_ARGUMENTS(ArrayT, ValueT);                                     \
  RangeCheck(array, index.Value(), sizeof(ValueT));                     \
  ValueT result;                                                        \
  ByteArray::Copy(&result, array, index.Value(), sizeof(ValueT));       \
  return ObjectT::New(result);


#define UNALIGNED_SETTER(ArrayT, ObjectT, Getter, ValueT)               \
  SETTER_ARGUMENTS(ArrayT, ObjectT, ValueT);                            \
  RangeCheck(array, index.Value(), sizeof(ValueT));                     \
  ValueT src = value_object.Getter();                                   \
  ByteArray::Copy(array, index.Value(), &src, sizeof(ValueT));          \
  return Integer::New(index.Value() + sizeof(ValueT));


#define UINT64_TO_INTEGER(value, integer)                               \
  if (value > static_cast<uint64_t>(Mint::kMaxValue)) {                 \
    result = BigintOperations::NewFromUint64(value);                    \
  } else if (value > static_cast<uint64_t>(Smi::kMaxValue)) {           \
    result = Mint::New(value);                                          \
  } else {                                                              \
    result = Smi::New(value);                                           \
  }


#define GETTER_UINT64(ArrayT)                                           \
  GETTER_ARGUMENTS(ArrayT, uint64_t);                                   \
  intptr_t size = sizeof(uint64_t);                                     \
  RangeCheck(array, index.Value() * size, size);                        \
  uint64_t value = array.At(index.Value());                             \
  Integer& result = Integer::Handle();                                  \
  UINT64_TO_INTEGER(value, result);                                     \
  return result.raw();


#define UNALIGNED_GETTER_UINT64(ArrayT)                                 \
  GETTER_ARGUMENTS(ArrayT, uint64_t);                                   \
  RangeCheck(array, index.Value(), sizeof(uint64_t));                   \
  uint64_t value;                                                       \
  ByteArray::Copy(&value, array, index.Value(), sizeof(uint64_t));      \
  Integer& result = Integer::Handle();                                  \
  UINT64_TO_INTEGER(value, result);                                     \
  return result.raw();


#define INTEGER_TO_UINT64(integer, uint64)                              \
  if (integer.IsBigint()) {                                             \
    Bigint& bigint = Bigint::Handle();                                  \
    bigint ^= integer.raw();                                            \
    ASSERT(BigintOperations::FitsIntoUint64(bigint));                   \
    value = BigintOperations::AbsToUint64(bigint);                      \
  } else {                                                              \
    ASSERT(integer.IsMint() || integer.IsSmi());                        \
    value = integer.AsInt64Value();                                     \
  }                                                                     \


#define SETTER_UINT64(ArrayT)                                           \
  SETTER_ARGUMENTS(ArrayT, Integer, uint64_t);                          \
  intptr_t size = sizeof(uint64_t);                                     \
  RangeCheck(array, index.Value() * size, size);                        \
  uint64_t value;                                                       \
  INTEGER_TO_UINT64(value_object, value);                               \
  array.SetAt(index.Value(), value);                                    \
  return Object::null();


#define UNALIGNED_SETTER_UINT64(ArrayT)                                 \
  SETTER_ARGUMENTS(ArrayT, Integer, uint64_t);                          \
  RangeCheck(array, index.Value(), sizeof(uint64_t));                   \
  uint64_t value;                                                       \
  INTEGER_TO_UINT64(value_object, value);                               \
  ByteArray::Copy(array, index.Value(), &value, sizeof(uint64_t));      \
  return Integer::New(index.Value() + sizeof(uint64_t));


DEFINE_NATIVE_ENTRY(ByteArray_getLength, 1) {
  GET_NATIVE_ARGUMENT(ByteArray, array, arguments->NativeArgAt(0));
  return Smi::New(array.Length());
}


DEFINE_NATIVE_ENTRY(ByteArray_getInt8, 2) {
  UNALIGNED_GETTER(ByteArray, Smi, int8_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setInt8, 3) {
  UNALIGNED_SETTER(ByteArray, Smi, Value, int8_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getUint8, 2) {
  UNALIGNED_GETTER(ByteArray, Smi, uint8_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setUint8, 3) {
  UNALIGNED_SETTER(ByteArray, Smi, Value, uint8_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getInt16, 2) {
  UNALIGNED_GETTER(ByteArray, Smi, int16_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setInt16, 3) {
  UNALIGNED_SETTER(ByteArray, Smi, Value, int16_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getUint16, 2) {
  UNALIGNED_GETTER(ByteArray, Smi, uint16_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setUint16, 3) {
  UNALIGNED_SETTER(ByteArray, Smi, Value, uint16_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getInt32, 2) {
  UNALIGNED_GETTER(ByteArray, Integer, int32_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setInt32, 3) {
  UNALIGNED_SETTER(ByteArray, Integer, AsInt64Value, int32_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getUint32, 2) {
  UNALIGNED_GETTER(ByteArray, Integer, uint32_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setUint32, 3) {
  UNALIGNED_SETTER(ByteArray, Integer, AsInt64Value, uint32_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getInt64, 2) {
  UNALIGNED_GETTER(ByteArray, Integer, int64_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_setInt64, 3) {
  UNALIGNED_SETTER(ByteArray, Integer, AsInt64Value, int64_t);
}


DEFINE_NATIVE_ENTRY(ByteArray_getUint64, 2) {
  UNALIGNED_GETTER_UINT64(ByteArray);
}


DEFINE_NATIVE_ENTRY(ByteArray_setUint64, 3) {
  UNALIGNED_SETTER_UINT64(ByteArray);
}


DEFINE_NATIVE_ENTRY(ByteArray_getFloat32, 2) {
  UNALIGNED_GETTER(ByteArray, Double, float);
}


DEFINE_NATIVE_ENTRY(ByteArray_setFloat32, 3) {
  UNALIGNED_SETTER(ByteArray, Double, value, float);
}


DEFINE_NATIVE_ENTRY(ByteArray_getFloat64, 2) {
  UNALIGNED_GETTER(ByteArray, Double, double);
}


DEFINE_NATIVE_ENTRY(ByteArray_setFloat64, 3) {
  UNALIGNED_SETTER(ByteArray, Double, value, double);
}


DEFINE_NATIVE_ENTRY(ByteArray_setRange, 5) {
  ByteArray& dst = ByteArray::CheckedHandle(arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Smi, dst_start, arguments->NativeArgAt(1));
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(2));
  GET_NATIVE_ARGUMENT(ByteArray, src, arguments->NativeArgAt(3));
  GET_NATIVE_ARGUMENT(Smi, src_start, arguments->NativeArgAt(4));
  intptr_t length_value = length.Value();
  intptr_t src_start_value = src_start.Value();
  intptr_t dst_start_value = dst_start.Value();
  if (length_value < 0) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%"Pd") must be non-negative", length_value));
    GrowableArray<const Object*> args;
    args.Add(&error);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  RangeCheck(src, src_start_value, length_value);
  RangeCheck(dst, dst_start_value, length_value);
  ByteArray::Copy(dst, dst_start_value, src, src_start_value, length_value);
  return Object::null();
}


// Int8Array

DEFINE_NATIVE_ENTRY(Int8Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int8Array::kMaxElements);
  return Int8Array::New(len);
}


DEFINE_NATIVE_ENTRY(Int8Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int8Array::kMaxElements);
  int8_t* bytes = OS::AllocateAlignedArray<int8_t>(
      len,
      ExternalByteArrayData<int8_t>::kAlignment);
  return ExternalInt8Array::New(bytes,
                                len,
                                bytes,
                                OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Int8Array_getIndexed, 2) {
  GETTER(Int8Array, Smi, int8_t);
}


DEFINE_NATIVE_ENTRY(Int8Array_setIndexed, 3) {
  SETTER(Int8Array, Smi, Value, int8_t);
}


// Uint8Array

DEFINE_NATIVE_ENTRY(Uint8Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint8Array::kMaxElements);
  return Uint8Array::New(len);
}


DEFINE_NATIVE_ENTRY(Uint8Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint8Array::kMaxElements);
  uint8_t* bytes = OS::AllocateAlignedArray<uint8_t>(
      len,
      ExternalByteArrayData<uint8_t>::kAlignment);
  return ExternalUint8Array::New(bytes,
                                 len,
                                 bytes,
                                 OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Uint8Array_getIndexed, 2) {
  GETTER(Uint8Array, Smi, uint8_t);
}


DEFINE_NATIVE_ENTRY(Uint8Array_setIndexed, 3) {
  SETTER(Uint8Array, Smi, Value, uint8_t);
}


// Int16Array

DEFINE_NATIVE_ENTRY(Int16Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int16Array::kMaxElements);
  return Int16Array::New(len);
}


DEFINE_NATIVE_ENTRY(Int16Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int16Array::kMaxElements);
  int16_t* bytes = OS::AllocateAlignedArray<int16_t>(
      len,
      ExternalByteArrayData<int16_t>::kAlignment);
  return ExternalInt16Array::New(bytes,
                                 len,
                                 bytes,
                                 OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Int16Array_getIndexed, 2) {
  GETTER(Int16Array, Smi, int16_t);
}


DEFINE_NATIVE_ENTRY(Int16Array_setIndexed, 3) {
  SETTER(Int16Array, Smi, Value, int16_t);
}


// Uint16Array

DEFINE_NATIVE_ENTRY(Uint16Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint16Array::kMaxElements);
  return Uint16Array::New(len);
}


DEFINE_NATIVE_ENTRY(Uint16Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint16Array::kMaxElements);
  uint16_t* bytes = OS::AllocateAlignedArray<uint16_t>(
      len,
      ExternalByteArrayData<uint16_t>::kAlignment);
  return ExternalUint16Array::New(bytes,
                                  len,
                                  bytes,
                                  OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Uint16Array_getIndexed, 2) {
  GETTER(Uint16Array, Smi, uint16_t);
}


DEFINE_NATIVE_ENTRY(Uint16Array_setIndexed, 3) {
  SETTER(Uint16Array, Smi, Value, uint16_t);
}


// Int32Array

DEFINE_NATIVE_ENTRY(Int32Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int32Array::kMaxElements);
  return Int32Array::New(len);
}


DEFINE_NATIVE_ENTRY(Int32Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int32Array::kMaxElements);
  int32_t* bytes = OS::AllocateAlignedArray<int32_t>(
      len,
      ExternalByteArrayData<int32_t>::kAlignment);
  return ExternalInt32Array::New(bytes,
                                 len,
                                 bytes,
                                 OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Int32Array_getIndexed, 2) {
  GETTER(Int32Array, Integer, int32_t);
}


DEFINE_NATIVE_ENTRY(Int32Array_setIndexed, 3) {
  SETTER(Int32Array, Integer, AsInt64Value, int32_t);
}


// Uint32Array

DEFINE_NATIVE_ENTRY(Uint32Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint32Array::kMaxElements);
  return Uint32Array::New(len);
}


DEFINE_NATIVE_ENTRY(Uint32Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint32Array::kMaxElements);
  uint32_t* bytes = OS::AllocateAlignedArray<uint32_t>(
      len,
      ExternalByteArrayData<uint32_t>::kAlignment);
  return ExternalUint32Array::New(bytes,
                                  len,
                                  bytes,
                                  OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Uint32Array_getIndexed, 2) {
  GETTER(Uint32Array, Integer, uint32_t);
}


DEFINE_NATIVE_ENTRY(Uint32Array_setIndexed, 3) {
  SETTER(Uint32Array, Integer, AsInt64Value, uint32_t);
}


// Int64Array

DEFINE_NATIVE_ENTRY(Int64Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int64Array::kMaxElements);
  return Int64Array::New(len);
}


DEFINE_NATIVE_ENTRY(Int64Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Int64Array::kMaxElements);
  int64_t* bytes = OS::AllocateAlignedArray<int64_t>(
      len,
      ExternalByteArrayData<int64_t>::kAlignment);
  return ExternalInt64Array::New(bytes,
                                 len,
                                 bytes,
                                 OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Int64Array_getIndexed, 2) {
  GETTER(Int64Array, Integer, int64_t);
}


DEFINE_NATIVE_ENTRY(Int64Array_setIndexed, 3) {
  SETTER(Int64Array, Integer, AsInt64Value, int64_t);
}


// Uint64Array

DEFINE_NATIVE_ENTRY(Uint64Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint64Array::kMaxElements);
  return Uint64Array::New(len);
}


DEFINE_NATIVE_ENTRY(Uint64Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Uint64Array::kMaxElements);
  uint64_t* bytes = OS::AllocateAlignedArray<uint64_t>(
      len,
      ExternalByteArrayData<uint64_t>::kAlignment);
  return ExternalUint64Array::New(bytes,
                                  len,
                                  bytes,
                                  OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Uint64Array_getIndexed, 2) {
  GETTER_UINT64(Uint64Array);
}


DEFINE_NATIVE_ENTRY(Uint64Array_setIndexed, 3) {
  SETTER_UINT64(Uint64Array);
}


// Float32Array

DEFINE_NATIVE_ENTRY(Float32Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Float32Array::kMaxElements);
  return Float32Array::New(len);
}


DEFINE_NATIVE_ENTRY(Float32Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Float32Array::kMaxElements);
  float* bytes = OS::AllocateAlignedArray<float>(
      len,
      ExternalByteArrayData<float>::kAlignment);
  return ExternalFloat32Array::New(bytes,
                                   len,
                                   bytes,
                                   OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Float32Array_getIndexed, 2) {
  GETTER(Float32Array, Double, float);
}


DEFINE_NATIVE_ENTRY(Float32Array_setIndexed, 3) {
  SETTER(Float32Array, Double, value, float);
}


// Float64Array

DEFINE_NATIVE_ENTRY(Float64Array_new, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Float64Array::kMaxElements);
  return Float64Array::New(len);
}


DEFINE_NATIVE_ENTRY(Float64Array_newTransferrable, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));
  intptr_t len = length.Value();
  LengthCheck(len, Float64Array::kMaxElements);
  double* bytes = OS::AllocateAlignedArray<double>(
      len,
      ExternalByteArrayData<double>::kAlignment);
  return ExternalFloat64Array::New(bytes,
                                   len,
                                   bytes,
                                   OS::AlignedFree);
}


DEFINE_NATIVE_ENTRY(Float64Array_getIndexed, 2) {
  GETTER(Float64Array, Double, double);
}


DEFINE_NATIVE_ENTRY(Float64Array_setIndexed, 3) {
  SETTER(Float64Array, Double, value, double);
}


// ExternalInt8Array

DEFINE_NATIVE_ENTRY(ExternalInt8Array_getIndexed, 2) {
  GETTER(ExternalInt8Array, Smi, int8_t);
}


DEFINE_NATIVE_ENTRY(ExternalInt8Array_setIndexed, 3) {
  SETTER(ExternalInt8Array, Smi, Value, int8_t);
}


// ExternalUint8Array

DEFINE_NATIVE_ENTRY(ExternalUint8Array_getIndexed, 2) {
  UNALIGNED_GETTER(ExternalUint8Array, Smi, uint8_t);
}


DEFINE_NATIVE_ENTRY(ExternalUint8Array_setIndexed, 3) {
  UNALIGNED_SETTER(ExternalUint8Array, Smi, Value, uint8_t);
}


// ExternalInt16Array

DEFINE_NATIVE_ENTRY(ExternalInt16Array_getIndexed, 2) {
  GETTER(ExternalInt16Array, Smi, int16_t);
}


DEFINE_NATIVE_ENTRY(ExternalInt16Array_setIndexed, 3) {
  SETTER(ExternalInt16Array, Smi, Value, int16_t);
}


// ExternalUint16Array

DEFINE_NATIVE_ENTRY(ExternalUint16Array_getIndexed, 2) {
  UNALIGNED_GETTER(ExternalUint16Array, Smi, uint16_t);
}


DEFINE_NATIVE_ENTRY(ExternalUint16Array_setIndexed, 3) {
  UNALIGNED_SETTER(ExternalUint16Array, Smi, Value, uint16_t);
}


// ExternalInt32Array

DEFINE_NATIVE_ENTRY(ExternalInt32Array_getIndexed, 2) {
  GETTER(ExternalInt32Array, Integer, int32_t);
}


DEFINE_NATIVE_ENTRY(ExternalInt32Array_setIndexed, 3) {
  SETTER(ExternalInt32Array, Integer, AsInt64Value, int32_t);
}


// ExternalUint32Array

DEFINE_NATIVE_ENTRY(ExternalUint32Array_getIndexed, 2) {
  UNALIGNED_GETTER(ExternalUint32Array, Integer, uint32_t);
}


DEFINE_NATIVE_ENTRY(ExternalUint32Array_setIndexed, 3) {
  UNALIGNED_SETTER(ExternalUint32Array, Integer, AsInt64Value, uint32_t);
}


// ExternalInt64Array

DEFINE_NATIVE_ENTRY(ExternalInt64Array_getIndexed, 2) {
  GETTER(ExternalInt64Array, Integer, int64_t);
}


DEFINE_NATIVE_ENTRY(ExternalInt64Array_setIndexed, 3) {
  SETTER(ExternalInt64Array, Integer, AsInt64Value, int64_t);
}


// ExternalUint64Array

DEFINE_NATIVE_ENTRY(ExternalUint64Array_getIndexed, 2) {
  GETTER_UINT64(ExternalUint64Array);
}


DEFINE_NATIVE_ENTRY(ExternalUint64Array_setIndexed, 3) {
  SETTER_UINT64(ExternalUint64Array);
}


// ExternalFloat32Array

DEFINE_NATIVE_ENTRY(ExternalFloat32Array_getIndexed, 2) {
  GETTER(ExternalFloat32Array, Double, float);
}


DEFINE_NATIVE_ENTRY(ExternalFloat32Array_setIndexed, 3) {
  SETTER(ExternalFloat32Array, Double, value, float);
}


// ExternalFloat64Array

DEFINE_NATIVE_ENTRY(ExternalFloat64Array_getIndexed, 2) {
  GETTER(ExternalFloat64Array, Double, double);
}


DEFINE_NATIVE_ENTRY(ExternalFloat64Array_setIndexed, 3) {
  SETTER(ExternalFloat64Array, Double, value, double);
}

}  // namespace dart
