// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

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

// Checks to see if a length will not result in an OOM error.
static void LengthCheck(intptr_t len, intptr_t max) {
  if (len < 0 || len > max) {
    const String& error = String::Handle(String::NewFormatted(
        "Length (%" Pd ") of object must be in range [0..%" Pd "]", len, max));
    Exceptions::ThrowArgumentError(error);
  }
}

DEFINE_NATIVE_ENTRY(TypedData_length, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0));
  if (instance.IsTypedData()) {
    const TypedData& array = TypedData::Cast(instance);
    return Smi::New(array.Length());
  }
  if (instance.IsExternalTypedData()) {
    const ExternalTypedData& array = ExternalTypedData::Cast(instance);
    return Smi::New(array.Length());
  }
  const String& error = String::Handle(String::NewFormatted(
      "Expected a TypedData object but found %s", instance.ToCString()));
  Exceptions::ThrowArgumentError(error);
  return Integer::null();
}

template <typename DstType, typename SrcType>
static RawBool* CopyData(const Instance& dst,
                         const Instance& src,
                         const Smi& dst_start,
                         const Smi& src_start,
                         const Smi& length,
                         bool clamped) {
  const DstType& dst_array = DstType::Cast(dst);
  const SrcType& src_array = SrcType::Cast(src);
  const intptr_t dst_offset_in_bytes = dst_start.Value();
  const intptr_t src_offset_in_bytes = src_start.Value();
  const intptr_t length_in_bytes = length.Value();
  ASSERT(Utils::RangeCheck(src_offset_in_bytes, length_in_bytes,
                           src_array.LengthInBytes()));
  ASSERT(Utils::RangeCheck(dst_offset_in_bytes, length_in_bytes,
                           dst_array.LengthInBytes()));
  if (clamped) {
    TypedData::ClampedCopy<DstType, SrcType>(dst_array, dst_offset_in_bytes,
                                             src_array, src_offset_in_bytes,
                                             length_in_bytes);
  } else {
    TypedData::Copy<DstType, SrcType>(dst_array, dst_offset_in_bytes, src_array,
                                      src_offset_in_bytes, length_in_bytes);
  }
  return Bool::True().raw();
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

DEFINE_NATIVE_ENTRY(TypedData_setRange, 7) {
  const Instance& dst = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const Smi& dst_start = Smi::CheckedHandle(arguments->NativeArgAt(1));
  const Smi& length = Smi::CheckedHandle(arguments->NativeArgAt(2));
  const Instance& src = Instance::CheckedHandle(arguments->NativeArgAt(3));
  const Smi& src_start = Smi::CheckedHandle(arguments->NativeArgAt(4));
  const Smi& to_cid_smi = Smi::CheckedHandle(arguments->NativeArgAt(5));
  const Smi& from_cid_smi = Smi::CheckedHandle(arguments->NativeArgAt(6));

  if (length.Value() < 0) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%" Pd ") must be non-negative", length.Value()));
    Exceptions::ThrowArgumentError(error);
  }
  const intptr_t to_cid = to_cid_smi.Value();
  const intptr_t from_cid = from_cid_smi.Value();

  const bool needs_clamping = IsClamped(to_cid) && !IsUint8(from_cid);
  if (dst.IsTypedData()) {
    if (src.IsTypedData()) {
      return CopyData<TypedData, TypedData>(dst, src, dst_start, src_start,
                                            length, needs_clamping);
    } else if (src.IsExternalTypedData()) {
      return CopyData<TypedData, ExternalTypedData>(
          dst, src, dst_start, src_start, length, needs_clamping);
    }
  } else if (dst.IsExternalTypedData()) {
    if (src.IsTypedData()) {
      return CopyData<ExternalTypedData, TypedData>(
          dst, src, dst_start, src_start, length, needs_clamping);
    } else if (src.IsExternalTypedData()) {
      return CopyData<ExternalTypedData, ExternalTypedData>(
          dst, src, dst_start, src_start, length, needs_clamping);
    }
  }
  UNREACHABLE();
  return Bool::False().raw();
}

// We check the length parameter against a possible maximum length for the
// array based on available physical addressable memory on the system. The
// maximum possible length is a scaled value of kSmiMax which is set up based
// on whether the underlying architecture is 32-bit or 64-bit.
// Argument 0 is type arguments and is ignored.
#define TYPED_DATA_NEW(name)                                                   \
  DEFINE_NATIVE_ENTRY(TypedData_##name##_new, 2) {                             \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(1));      \
    intptr_t cid = kTypedData##name##Cid;                                      \
    intptr_t len = length.Value();                                             \
    intptr_t max = TypedData::MaxElements(cid);                                \
    LengthCheck(len, max);                                                     \
    return TypedData::New(cid, len);                                           \
  }

#define TYPED_DATA_NEW_NATIVE(name) TYPED_DATA_NEW(name)

CLASS_LIST_TYPED_DATA(TYPED_DATA_NEW_NATIVE)

#define TYPED_DATA_GETTER(getter, object, ctor, access_size)                   \
  DEFINE_NATIVE_ENTRY(TypedData_##getter, 2) {                                 \
    GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance,                           \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    if (instance.IsTypedData()) {                                              \
      const TypedData& array = TypedData::Cast(instance);                      \
      RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),    \
                 access_size);                                                 \
      return object::ctor(array.getter(offsetInBytes.Value()));                \
    }                                                                          \
    if (instance.IsExternalTypedData()) {                                      \
      const ExternalTypedData& array = ExternalTypedData::Cast(instance);      \
      RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),    \
                 access_size);                                                 \
      return object::ctor(array.getter(offsetInBytes.Value()));                \
    }                                                                          \
    const String& error = String::Handle(String::NewFormatted(                 \
        "Expected a TypedData object but found %s", instance.ToCString()));    \
    Exceptions::ThrowArgumentError(error);                                     \
    return object::null();                                                     \
  }

#define TYPED_DATA_SETTER(setter, object, get_object_value, access_size,       \
                          access_type)                                         \
  DEFINE_NATIVE_ENTRY(TypedData_##setter, 3) {                                 \
    GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance,                           \
                                 arguments->NativeArgAt(0));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes,                           \
                                 arguments->NativeArgAt(1));                   \
    GET_NON_NULL_NATIVE_ARGUMENT(object, value, arguments->NativeArgAt(2));    \
    if (instance.IsTypedData()) {                                              \
      const TypedData& array = TypedData::Cast(instance);                      \
      RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),    \
                 access_size);                                                 \
      array.setter(offsetInBytes.Value(),                                      \
                   static_cast<access_type>(value.get_object_value()));        \
    } else if (instance.IsExternalTypedData()) {                               \
      const ExternalTypedData& array = ExternalTypedData::Cast(instance);      \
      RangeCheck(offsetInBytes.Value(), access_size, array.LengthInBytes(),    \
                 access_size);                                                 \
      array.setter(offsetInBytes.Value(),                                      \
                   static_cast<access_type>(value.get_object_value()));        \
    } else {                                                                   \
      const String& error = String::Handle(String::NewFormatted(               \
          "Expected a TypedData object but found %s", instance.ToCString()));  \
      Exceptions::ThrowArgumentError(error);                                   \
    }                                                                          \
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
