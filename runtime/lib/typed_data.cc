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

static bool IsTypedDataUint8ArrayClassId(intptr_t cid) {
  if (!IsTypedDataBaseClassId(cid)) return false;
  const intptr_t internal_cid =
      cid - ((cid - kFirstTypedDataCid) % kNumTypedDataCidRemainders) +
      kTypedDataCidRemainderInternal;
  return internal_cid == kTypedDataUint8ArrayCid ||
         internal_cid == kTypedDataUint8ClampedArrayCid;
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

  ASSERT(IsClampedTypedDataBaseClassId(dst.ptr()->GetClassId()));
  // The algorithm below assumes the clamped destination has uint8 elements.
  ASSERT_EQUAL(element_size_in_bytes, 1);
  ASSERT(IsTypedDataUint8ArrayClassId(dst.ptr()->GetClassId()));
  // The native entry should only be called when clamping is needed. When the
  // source has uint8 elements, a direct memory move should be used instead.
  ASSERT(!IsTypedDataUint8ArrayClassId(src.ptr()->GetClassId()));

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

DEFINE_NATIVE_ENTRY(TypedDataBase_memEquals, 0, 5) {
  const TypedDataBase& a =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& a_start_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  const TypedDataBase& b =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(2));
  const Smi& b_start_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(3));
  const Smi& count_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(4));

  const intptr_t count = count_smi.Value();
  if (count == 0) {
    return Bool::True().ptr();
  }

  const intptr_t a_len = a.Length();
  const intptr_t b_len = b.Length();
  const intptr_t a_start = a_start_smi.Value();
  const intptr_t b_start = b_start_smi.Value();
  if (a_start < 0 || count < 0 || a_start > a_len - count) {
    Exceptions::ThrowRangeError("aStart", a_start_smi, 0,
                                a_len - count >= 0 ? a_len - count : 0);
  }
  if (b_start < 0 || b_start > b_len - count) {
    Exceptions::ThrowRangeError("bStart", b_start_smi, 0,
                                b_len - count >= 0 ? b_len - count : 0);
  }

  const intptr_t a_element_size = a.ElementSizeInBytes();
  if (a_element_size != b.ElementSizeInBytes()) {
    Exceptions::ThrowArgumentError(
        String::Handle(String::New("Typed data element sizes do not match")));
  }

  const intptr_t a_start_in_bytes = a_start * a_element_size;
  const intptr_t b_start_in_bytes = b_start * a_element_size;
  const intptr_t length_in_bytes = count * a_element_size;

  NoSafepointScope no_safepoint;
  const void* a_data =
      reinterpret_cast<const void*>(a.DataAddr(a_start_in_bytes));
  const void* b_data =
      reinterpret_cast<const void*>(b.DataAddr(b_start_in_bytes));
  if (a_data == b_data) {
    return Bool::True().ptr();
  }

  return Bool::Get(memcmp(a_data, b_data, length_in_bytes) == 0).ptr();
}

// The native getter and setter functions defined here are only called if
// unboxing doubles or SIMD values is not supported by the flow graph compiler,
// and the provided offsets have already been range checked by the calling code.

#define TYPED_DATA_GETTER(getter, object, ctor)                                \
  DEFINE_NATIVE_ENTRY(TypedData_##getter, 0, 2) {                              \
    GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, array,                         \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    return object::ctor(array.getter(offsetInBytes.Value()));                  \
  }

#define TYPED_DATA_SETTER(setter, object, get_object_value, access_type)       \
  DEFINE_NATIVE_ENTRY(TypedData_##setter, 0, 3) {                              \
    GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, array,                         \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(object, value, arguments->NativeArgAt(2));    \
    array.setter(offsetInBytes.Value(),                                        \
                 static_cast<access_type>(value.get_object_value()));          \
    return Object::null();                                                     \
  }

#define TYPED_DATA_NATIVES(type_name, object, ctor, get_object_value,          \
                           access_type)                                        \
  TYPED_DATA_GETTER(Get##type_name, object, ctor)                              \
  TYPED_DATA_SETTER(Set##type_name, object, get_object_value, access_type)

TYPED_DATA_NATIVES(Float32, Double, New, value, float)
TYPED_DATA_NATIVES(Float64, Double, New, value, double)
TYPED_DATA_NATIVES(Float32x4, Float32x4, New, value, simd128_value_t)
TYPED_DATA_NATIVES(Int32x4, Int32x4, New, value, simd128_value_t)
TYPED_DATA_NATIVES(Float64x2, Float64x2, New, value, simd128_value_t)

}  // namespace dart
