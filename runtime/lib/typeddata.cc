// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "include/dart_api.h"

#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

// TypedData.

// Checks to see if offset_in_bytes is in the range.
static bool RangeCheck(intptr_t offset_in_bytes, intptr_t length_in_bytes) {
  return ((offset_in_bytes >= 0) &&
          (length_in_bytes > 0) &&
          (offset_in_bytes < length_in_bytes));
}


// Checks to see if offsetInBytes + num_bytes is in the range.
static void SetRangeCheck(intptr_t offset_in_bytes,
                          intptr_t num_bytes,
                          intptr_t length_in_bytes,
                          intptr_t element_size_in_bytes) {
  if (!Utils::RangeCheck(offset_in_bytes, num_bytes, length_in_bytes)) {
    const String& error = String::Handle(String::NewFormatted(
        "index (%"Pd") must be in the range [0..%"Pd")",
        (offset_in_bytes / element_size_in_bytes),
        (length_in_bytes / element_size_in_bytes)));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
}


// Checks to see if a length will not result in an OOM error.
static void LengthCheck(intptr_t len, intptr_t max) {
  ASSERT(len >= 0);
  if (len > max) {
    const String& error = String::Handle(String::NewFormatted(
        "insufficient memory to allocate a TypedData object of length (%"Pd")",
        len));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kOutOfMemory, args);
  }
}


static void PeerFinalizer(Dart_Handle handle, void* peer) {
  Dart_DeletePersistentHandle(handle);
  OS::AlignedFree(peer);
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
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, error);
  Exceptions::ThrowByType(Exceptions::kArgument, args);
  return Integer::null();
}


#define COPY_DATA(type, dst, src)                                              \
  const type& dst_array = type::Cast(dst);                                     \
  const type& src_array = type::Cast(src);                                     \
  intptr_t element_size_in_bytes = dst_array.ElementSizeInBytes();             \
  intptr_t length_in_bytes = length.Value() * element_size_in_bytes;           \
  intptr_t src_offset_in_bytes = src_start.Value() * element_size_in_bytes;    \
  intptr_t dst_offset_in_bytes = dst_start.Value() * element_size_in_bytes;    \
  SetRangeCheck(src_offset_in_bytes,                                           \
                length_in_bytes,                                               \
                src_array.LengthInBytes(),                                     \
                element_size_in_bytes);                                        \
  SetRangeCheck(dst_offset_in_bytes,                                           \
                length_in_bytes,                                               \
                dst_array.LengthInBytes(),                                     \
                element_size_in_bytes);                                        \
  type::Copy(dst_array, dst_offset_in_bytes,                                   \
             src_array, src_offset_in_bytes,                                   \
             length_in_bytes);

DEFINE_NATIVE_ENTRY(TypedData_setRange, 5) {
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, dst, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, dst_start, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, src, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, src_start, arguments->NativeArgAt(4));

  if (length.Value() < 0) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%"Pd") must be non-negative", length.Value()));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, error);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  if ((dst.IsTypedData() || dst.IsExternalTypedData()) &&
      (dst.clazz() == src.clazz())) {
    if (dst.IsTypedData()) {
      ASSERT(src.IsTypedData());
      COPY_DATA(TypedData, dst, src);
    } else {
      ASSERT(src.IsExternalTypedData());
      ASSERT(dst.IsExternalTypedData());
      COPY_DATA(ExternalTypedData, dst, src);
    }
    return Bool::True().raw();
  }
  return Bool::False().raw();
}


// We check the length parameter against a possible maximum length for the
// array based on available physical addressable memory on the system. The
// maximum possible length is a scaled value of kSmiMax which is set up based
// on whether the underlying architecture is 32-bit or 64-bit.
#define TYPED_DATA_NEW(name)                                                   \
DEFINE_NATIVE_ENTRY(TypedData_##name##_new, 1) {                               \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));        \
  intptr_t cid = kTypedData##name##Cid;                                        \
  intptr_t len = length.Value();                                               \
  intptr_t max = TypedData::MaxElements(cid);                                  \
  LengthCheck(len, max);                                                       \
  return TypedData::New(cid, len);                                             \
}                                                                              \


// We check the length parameter against a possible maximum length for the
// array based on available physical addressable memory on the system. The
// maximum possible length is a scaled value of kSmiMax which is set up based
// on whether the underlying architecture is 32-bit or 64-bit.
#define EXT_TYPED_DATA_NEW(name)                                               \
DEFINE_NATIVE_ENTRY(ExternalTypedData_##name##_new, 1) {                       \
  const int kAlignment = 16;                                                   \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(0));        \
  intptr_t cid = kExternalTypedData##name##Cid;                                \
  intptr_t len = length.Value();                                               \
  intptr_t max = ExternalTypedData::MaxElements(cid);                          \
  LengthCheck(len, max);                                                       \
  intptr_t len_bytes = len * ExternalTypedData::ElementSizeInBytes(cid);       \
  uint8_t* data = OS::AllocateAlignedArray<uint8_t>(len_bytes, kAlignment);    \
  const ExternalTypedData& obj =                                               \
      ExternalTypedData::Handle(ExternalTypedData::New(cid, data, len));       \
  obj.AddFinalizer(data, PeerFinalizer);                                       \
  return obj.raw();                                                            \
}                                                                              \


#define TYPED_DATA_NEW_NATIVE(name)                                            \
  TYPED_DATA_NEW(name)                                                         \
  EXT_TYPED_DATA_NEW(name)                                                     \


CLASS_LIST_TYPED_DATA(TYPED_DATA_NEW_NATIVE)

#define TYPED_DATA_GETTER(getter, object)                                      \
DEFINE_NATIVE_ENTRY(TypedData_##getter, 2) {                                   \
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0)); \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes, arguments->NativeArgAt(1)); \
  if (instance.IsTypedData()) {                                                \
    const TypedData& array = TypedData::Cast(instance);                        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    return object::New(array.getter(offsetInBytes.Value()));                   \
  }                                                                            \
  if (instance.IsExternalTypedData()) {                                        \
    const ExternalTypedData& array = ExternalTypedData::Cast(instance);        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    return object::New(array.getter(offsetInBytes.Value()));                   \
  }                                                                            \
  const String& error = String::Handle(String::NewFormatted(                   \
      "Expected a TypedData object but found %s", instance.ToCString()));      \
  const Array& args = Array::Handle(Array::New(1));                            \
  args.SetAt(0, error);                                                        \
  Exceptions::ThrowByType(Exceptions::kArgument, args);                        \
  return object::null();                                                       \
}                                                                              \


#define TYPED_DATA_SETTER(setter, object, get_object_value)                    \
DEFINE_NATIVE_ENTRY(TypedData_##setter, 3) {                                   \
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0)); \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes, arguments->NativeArgAt(1)); \
  GET_NON_NULL_NATIVE_ARGUMENT(object, value, arguments->NativeArgAt(2));      \
  if (instance.IsTypedData()) {                                                \
    const TypedData& array = TypedData::Cast(instance);                        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    array.setter(offsetInBytes.Value(), value.get_object_value());             \
  } else if (instance.IsExternalTypedData()) {                                 \
    const ExternalTypedData& array = ExternalTypedData::Cast(instance);        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    array.setter(offsetInBytes.Value(), value.get_object_value());             \
  } else {                                                                     \
    const String& error = String::Handle(String::NewFormatted(                 \
        "Expected a TypedData object but found %s", instance.ToCString()));    \
    const Array& args = Array::Handle(Array::New(1));                          \
    args.SetAt(0, error);                                                      \
    Exceptions::ThrowByType(Exceptions::kArgument, args);                      \
  }                                                                            \
  return Object::null();                                                       \
}


#define TYPED_DATA_UINT64_GETTER(getter, object)                               \
DEFINE_NATIVE_ENTRY(TypedData_##getter, 2) {                                   \
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0)); \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes, arguments->NativeArgAt(1)); \
  uint64_t value = 0;                                                          \
  if (instance.IsTypedData()) {                                                \
    const TypedData& array = TypedData::Cast(instance);                        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    value = array.getter(offsetInBytes.Value());                               \
  } else if (instance.IsExternalTypedData()) {                                 \
    const ExternalTypedData& array = ExternalTypedData::Cast(instance);        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    value = array.getter(offsetInBytes.Value());                               \
  } else {                                                                     \
    const String& error = String::Handle(String::NewFormatted(                 \
        "Expected a TypedData object but found %s", instance.ToCString()));    \
    const Array& args = Array::Handle(Array::New(1));                          \
    args.SetAt(0, error);                                                      \
    Exceptions::ThrowByType(Exceptions::kArgument, args);                      \
  }                                                                            \
  Integer& result = Integer::Handle();                                         \
  if (value > static_cast<uint64_t>(Mint::kMaxValue)) {                        \
    result = BigintOperations::NewFromUint64(value);                           \
  } else if (value > static_cast<uint64_t>(Smi::kMaxValue)) {                  \
    result = Mint::New(value);                                                 \
  } else {                                                                     \
    result = Smi::New(value);                                                  \
  }                                                                            \
  return result.raw();                                                         \
}                                                                              \


// TODO(asiva): Consider truncating the bigint value if it does not fit into
// a uint64_t value (see ASSERT(BigintOperations::FitsIntoUint64(bigint))).
#define TYPED_DATA_UINT64_SETTER(setter, object)                               \
DEFINE_NATIVE_ENTRY(TypedData_##setter, 3) {                                   \
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, instance, arguments->NativeArgAt(0)); \
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, offsetInBytes, arguments->NativeArgAt(1)); \
  GET_NON_NULL_NATIVE_ARGUMENT(object, value, arguments->NativeArgAt(2));      \
  uint64_t object_value;                                                       \
  if (value.IsBigint()) {                                                      \
    const Bigint& bigint = Bigint::Cast(value);                                \
    ASSERT(BigintOperations::FitsIntoUint64(bigint));                          \
    object_value = BigintOperations::AbsToUint64(bigint);                      \
  } else {                                                                     \
    ASSERT(value.IsMint() || value.IsSmi());                                   \
    object_value = value.AsInt64Value();                                       \
  }                                                                            \
  if (instance.IsTypedData()) {                                                \
    const TypedData& array = TypedData::Cast(instance);                        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    array.setter(offsetInBytes.Value(), object_value);                         \
  } else if (instance.IsExternalTypedData()) {                                 \
    const ExternalTypedData& array = ExternalTypedData::Cast(instance);        \
    ASSERT(RangeCheck(offsetInBytes.Value(), array.LengthInBytes()));          \
    array.setter(offsetInBytes.Value(), object_value);                         \
  } else {                                                                     \
    const String& error = String::Handle(String::NewFormatted(                 \
        "Expected a TypedData object but found %s", instance.ToCString()));    \
    const Array& args = Array::Handle(Array::New(1));                          \
    args.SetAt(0, error);                                                      \
    Exceptions::ThrowByType(Exceptions::kArgument, args);                      \
  }                                                                            \
  return Object::null();                                                       \
}


#define TYPED_DATA_NATIVES(name, getter, setter, object, get_object_value)     \
  TYPED_DATA_GETTER(getter, object)                                            \
  TYPED_DATA_SETTER(setter, object, get_object_value)                          \


#define TYPED_DATA_UINT64_NATIVES(name, getter, setter, object)                \
  TYPED_DATA_UINT64_GETTER(getter, object)                                     \
  TYPED_DATA_UINT64_SETTER(setter, object)                                     \


TYPED_DATA_NATIVES(Int8Array, GetInt8, SetInt8, Smi, Value)
TYPED_DATA_NATIVES(Uint8Array, GetUint8, SetUint8, Smi, Value)
TYPED_DATA_NATIVES(Int16Array, GetInt16, SetInt16, Smi, Value)
TYPED_DATA_NATIVES(Uint16Array, GetUint16, SetUint16, Smi, Value)
TYPED_DATA_NATIVES(Int32Array, GetInt32, SetInt32, Integer, AsInt64Value)
TYPED_DATA_NATIVES(Uint32Array, GetUint32, SetUint32, Integer, AsInt64Value)
TYPED_DATA_NATIVES(Int64Array, GetInt64, SetInt64, Integer, AsInt64Value)
TYPED_DATA_UINT64_NATIVES(Uint64Array, GetUint64, SetUint64, Integer)
TYPED_DATA_NATIVES(Float32Array, GetFloat32, SetFloat32, Double, value)
TYPED_DATA_NATIVES(Float64Array, GetFloat64, SetFloat64, Double, value)
TYPED_DATA_NATIVES(Float32x4Array, GetFloat32x4, SetFloat32x4, Float32x4, value)

}  // namespace dart
