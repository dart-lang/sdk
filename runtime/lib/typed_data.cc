// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

// TypedData.

// Checks to see if offsetInBytes + num_bytes is in the range.
static void RangeCheck(intptr_t offset_in_bytes,
                       intptr_t access_size,
                       intptr_t length_in_bytes,
                       intptr_t element_size_in_bytes) {
  if (!Utils::RangeCheck(offset_in_bytes, access_size, length_in_bytes)) {
    const intptr_t index =
        (offset_in_bytes + access_size) / element_size_in_bytes;
    const intptr_t length = length_in_bytes / element_size_in_bytes;
    Exceptions::ThrowRangeError("index", Integer::Handle(Integer::New(index)),
                                0, length);
  }
}

DEFINE_NATIVE_ENTRY(TypedDataBase_length, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, array, arguments->NativeArgAt(0));
  return Smi::New(array.Length());
}

DEFINE_NATIVE_ENTRY(TypedDataView_offsetInBytes, 0, 1) {
  // "this" is either a _*ArrayView class or _ByteDataView.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0));
  ASSERT(instance.IsTypedDataView());
  return TypedDataView::Cast(instance).offset_in_bytes();
}

DEFINE_NATIVE_ENTRY(TypedDataView_typedData, 0, 1) {
  // "this" is either a _*ArrayView class or _ByteDataView.
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0));
  ASSERT(instance.IsTypedDataView());
  return TypedDataView::Cast(instance).typed_data();
}

static bool IsClamped(intptr_t cid) {
  COMPILE_ASSERT((kTypedDataUint8ClampedArrayCid + 1 ==
                  kTypedDataUint8ClampedArrayViewCid) &&
                 (kTypedDataUint8ClampedArrayCid + 2 ==
                  kExternalTypedDataUint8ClampedArrayCid) &&
                 (kTypedDataUint8ClampedArrayCid + 3 ==
                  kUnmodifiableTypedDataUint8ClampedArrayViewCid));
  return cid >= kTypedDataUint8ClampedArrayCid &&
         cid <= kUnmodifiableTypedDataUint8ClampedArrayViewCid;
}

static bool IsUint8(intptr_t cid) {
  COMPILE_ASSERT(
      (kTypedDataUint8ArrayCid + 1 == kTypedDataUint8ArrayViewCid) &&
      (kTypedDataUint8ArrayCid + 2 == kExternalTypedDataUint8ArrayCid) &&
      (kTypedDataUint8ArrayCid + 3 ==
       kUnmodifiableTypedDataUint8ArrayViewCid) &&
      (kTypedDataUint8ArrayCid + 4 == kTypedDataUint8ClampedArrayCid));
  return cid >= kTypedDataUint8ArrayCid &&
         cid <= kUnmodifiableTypedDataUint8ClampedArrayViewCid;
}

DEFINE_NATIVE_ENTRY(TypedDataBase_setClampedRange, 0, 5) {
  // This is called after bounds checking, so the numeric inputs are
  // guaranteed to be Smis, and the length is guaranteed to be non-zero.
  const TypedDataBase& dst =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& dst_start_smi =
      Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  const Smi& length_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(2));
  const TypedDataBase& src =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(3));
  const Smi& src_start_smi =
      Smi::CheckedHandle(zone, arguments->NativeArgAt(4));

  const intptr_t element_size_in_bytes = dst.ElementSizeInBytes();
  ASSERT_EQUAL(src.ElementSizeInBytes(), element_size_in_bytes);

  const intptr_t dst_start_in_bytes =
      dst_start_smi.Value() * element_size_in_bytes;
  const intptr_t length_in_bytes = length_smi.Value() * element_size_in_bytes;
  const intptr_t src_start_in_bytes =
      src_start_smi.Value() * element_size_in_bytes;

#if defined(DEBUG)
  // Verify bounds checks weren't needed.
  ASSERT(dst_start_in_bytes >= 0);
  ASSERT(src_start_in_bytes >= 0);
  // The callers of this native function never call it for a zero-sized copy.
  ASSERT(length_in_bytes > 0);

  const intptr_t dst_length_in_bytes = dst.LengthInBytes();
  // Since the length is non-zero, the start can't be the same as the end.
  ASSERT(dst_start_in_bytes < dst_length_in_bytes);
  ASSERT(length_in_bytes <= dst_length_in_bytes - dst_start_in_bytes);

  const intptr_t src_length_in_bytes = src.LengthInBytes();
  // Since the length is non-zero, the start can't be the same as the end.
  ASSERT(src_start_in_bytes < src_length_in_bytes);
  ASSERT(length_in_bytes <= src_length_in_bytes - src_start_in_bytes);
#endif

  ASSERT_EQUAL(element_size_in_bytes, 1);
  ASSERT(IsClamped(dst.ptr()->GetClassId()));
  ASSERT(!IsUint8(src.ptr()->GetClassId()));

  NoSafepointScope no_safepoint;
  uint8_t* dst_data =
      reinterpret_cast<uint8_t*>(dst.DataAddr(dst_start_in_bytes));
  int8_t* src_data =
      reinterpret_cast<int8_t*>(src.DataAddr(src_start_in_bytes));
  for (intptr_t ix = 0; ix < length_in_bytes; ix++) {
    int8_t v = *src_data;
    if (v < 0) v = 0;
    *dst_data = v;
    src_data++;
    dst_data++;
  }

  return Object::null();
}

#define TYPED_DATA_GETTER(getter, object, ctor, access_size)                   \
  DEFINE_NATIVE_ENTRY(TypedData_##getter, 0, 2) {                              \
    GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, array,                         \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),      \
               access_size);                                                   \
    return object::ctor(array.getter(offsetInBytes.Value()));                  \
  }

#define TYPED_DATA_SETTER(setter, object, get_object_value, access_size,       \
                          access_type)                                         \
  DEFINE_NATIVE_ENTRY(TypedData_##setter, 0, 3) {                              \
    GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, array,                         \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(object, value, arguments->NativeArgAt(2));    \
    RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),      \
               access_size);                                                   \
    array.setter(offsetInBytes.Value(),                                        \
                 static_cast<access_type>(value.get_object_value()));          \
    return Object::null();                                                     \
  }

#define TYPED_DATA_NATIVES(type_name, object, ctor, get_object_value,          \
                           access_size, access_type)                           \
  TYPED_DATA_GETTER(Get##type_name, object, ctor, access_size)                 \
  TYPED_DATA_SETTER(Set##type_name, object, get_object_value, access_size,     \
                    access_type)

TYPED_DATA_NATIVES(Int8, Integer, New, AsTruncatedUint32Value, 1, int8_t)
TYPED_DATA_NATIVES(Uint8, Integer, New, AsTruncatedUint32Value, 1, uint8_t)
TYPED_DATA_NATIVES(Int16, Integer, New, AsTruncatedUint32Value, 2, int16_t)
TYPED_DATA_NATIVES(Uint16, Integer, New, AsTruncatedUint32Value, 2, uint16_t)
TYPED_DATA_NATIVES(Int32, Integer, New, AsTruncatedUint32Value, 4, int32_t)
TYPED_DATA_NATIVES(Uint32, Integer, New, AsTruncatedUint32Value, 4, uint32_t)
TYPED_DATA_NATIVES(Int64, Integer, New, AsTruncatedInt64Value, 8, int64_t)
TYPED_DATA_NATIVES(Uint64,
                   Integer,
                   NewFromUint64,
                   AsTruncatedInt64Value,
                   8,
                   uint64_t)
TYPED_DATA_NATIVES(Float32, Double, New, value, 4, float)
TYPED_DATA_NATIVES(Float64, Double, New, value, 8, double)
TYPED_DATA_NATIVES(Float32x4, Float32x4, New, value, 16, simd128_value_t)
TYPED_DATA_NATIVES(Int32x4, Int32x4, New, value, 16, simd128_value_t)
TYPED_DATA_NATIVES(Float64x2, Float64x2, New, value, 16, simd128_value_t)

}  // namespace dart
