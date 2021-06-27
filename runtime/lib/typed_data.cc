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

static void AlignmentCheck(intptr_t offset_in_bytes, intptr_t element_size) {
  if ((offset_in_bytes % element_size) != 0) {
    const auto& error = String::Handle(String::NewFormatted(
        "Offset in bytes (%" Pd ") must be a multiple of %" Pd "",
        offset_in_bytes, element_size));
    Exceptions::ThrowArgumentError(error);
  }
}

// Checks to see if a length will not result in an OOM error.
static void LengthCheck(intptr_t len, intptr_t max) {
  if (len < 0 || len > max) {
    const String& error = String::Handle(String::NewFormatted(
        "Length (%" Pd ") of object must be in range [0..%" Pd "]", len, max));
    Exceptions::ThrowArgumentError(error);
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

static BoolPtr CopyData(const TypedDataBase& dst_array,
                        const TypedDataBase& src_array,
                        const Smi& dst_start,
                        const Smi& src_start,
                        const Smi& length,
                        bool clamped) {
  const intptr_t dst_offset_in_bytes = dst_start.Value();
  const intptr_t src_offset_in_bytes = src_start.Value();
  const intptr_t length_in_bytes = length.Value();
  ASSERT(Utils::RangeCheck(src_offset_in_bytes, length_in_bytes,
                           src_array.LengthInBytes()));
  ASSERT(Utils::RangeCheck(dst_offset_in_bytes, length_in_bytes,
                           dst_array.LengthInBytes()));
  if (clamped) {
    TypedData::ClampedCopy(dst_array, dst_offset_in_bytes, src_array,
                           src_offset_in_bytes, length_in_bytes);
  } else {
    TypedData::Copy(dst_array, dst_offset_in_bytes, src_array,
                    src_offset_in_bytes, length_in_bytes);
  }
  return Bool::True().ptr();
}

static bool IsClamped(intptr_t cid) {
  switch (cid) {
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataUint8ClampedArrayViewCid:
      return true;
    default:
      return false;
  }
}

static bool IsUint8(intptr_t cid) {
  switch (cid) {
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataUint8ClampedArrayViewCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ArrayViewCid:
      return true;
    default:
      return false;
  }
}

DEFINE_NATIVE_ENTRY(TypedDataBase_setRange, 0, 7) {
  const TypedDataBase& dst =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Smi& dst_start = Smi::CheckedHandle(zone, arguments->NativeArgAt(1));
  const Smi& length = Smi::CheckedHandle(zone, arguments->NativeArgAt(2));
  const TypedDataBase& src =
      TypedDataBase::CheckedHandle(zone, arguments->NativeArgAt(3));
  const Smi& src_start = Smi::CheckedHandle(zone, arguments->NativeArgAt(4));
  const Smi& to_cid_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(5));
  const Smi& from_cid_smi = Smi::CheckedHandle(zone, arguments->NativeArgAt(6));

  if (length.Value() < 0) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%" Pd ") must be non-negative", length.Value()));
    Exceptions::ThrowArgumentError(error);
  }
  const intptr_t to_cid = to_cid_smi.Value();
  const intptr_t from_cid = from_cid_smi.Value();

  const bool needs_clamping = IsClamped(to_cid) && !IsUint8(from_cid);
  return CopyData(dst, src, dst_start, src_start, length, needs_clamping);
}

// Native methods for typed data allocation are recognized and implemented
// in FlowGraphBuilder::BuildGraphOfRecognizedMethod.
// These bodies exist only to assert that they are not used.
#define TYPED_DATA_NEW(name)                                                   \
  DEFINE_NATIVE_ENTRY(TypedData_##name##_new, 0, 2) {                          \
    UNREACHABLE();                                                             \
    return Object::null();                                                     \
  }

#define TYPED_DATA_NEW_NATIVE(name) TYPED_DATA_NEW(name)

CLASS_LIST_TYPED_DATA(TYPED_DATA_NEW_NATIVE)
#undef TYPED_DATA_NEW_NATIVE
#undef TYPED_DATA_NEW

// We check the length parameter against a possible maximum length for the
// array based on available physical addressable memory on the system.
//
// More specifically
//
//   TypedData::MaxElements(cid) is equal to (kSmiMax / ElementSizeInBytes(cid))
//
// which ensures that the number of bytes the array holds is guaranteed to fit
// into a _Smi.
//
// Argument 0 is type arguments and is ignored.
static InstancePtr NewTypedDataView(intptr_t cid,
                                    intptr_t element_size,
                                    Zone* zone,
                                    NativeArguments* arguments) {
  GET_NON_NULL_NATIVE_ARGUMENT(TypedDataBase, typed_data,
                               arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, offset, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, len, arguments->NativeArgAt(3));
  const intptr_t backing_length = typed_data.LengthInBytes();
  const intptr_t offset_in_bytes = offset.Value();
  const intptr_t length = len.Value();
  AlignmentCheck(offset_in_bytes, element_size);
  LengthCheck(offset_in_bytes + length * element_size, backing_length);
  return TypedDataView::New(cid, typed_data, offset_in_bytes, length);
}

#define TYPED_DATA_VIEW_NEW(native_name, cid)                                  \
  DEFINE_NATIVE_ENTRY(native_name, 0, 4) {                                     \
    return NewTypedDataView(cid, TypedDataBase::ElementSizeInBytes(cid), zone, \
                            arguments);                                        \
  }

#define TYPED_DATA_NEW_NATIVE(name)                                            \
  TYPED_DATA_VIEW_NEW(TypedDataView_##name##View_new, kTypedData##name##ViewCid)

CLASS_LIST_TYPED_DATA(TYPED_DATA_NEW_NATIVE)
TYPED_DATA_VIEW_NEW(TypedDataView_ByteDataView_new, kByteDataViewCid)
#undef TYPED_DATA_NEW_NATIVE
#undef TYPED_DATA_VIEW_NEW

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
