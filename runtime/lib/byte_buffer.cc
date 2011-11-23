// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/assembler.h"
#include "vm/assert.h"
#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(ByteBuffer_allocate, 1) {
  GET_NATIVE_ARGUMENT(Smi, length, arguments->At(0));
  if (length.Value() < 0) {
    GrowableArray<const Object*> args;
    args.Add(&length);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  uint8_t* data = new uint8_t[length.Value()];
  memset(data, 0, length.Value());
  const ByteBuffer& new_array =
      ByteBuffer::Handle(ByteBuffer::New(data, length.Value()));
  arguments->SetReturn(new_array);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getLength, 1) {
  const ByteBuffer& array = ByteBuffer::CheckedHandle(arguments->At(0));
  const Smi& length = Smi::Handle(Smi::New(array.Length()));
  arguments->SetReturn(length);
}


template<typename ValueType, typename ObjectType>
static void GetIndexed(NativeArguments* arguments) {
  const ByteBuffer& buffer = ByteBuffer::CheckedHandle(arguments->At(0));
  const Instance& index_instance = Instance::CheckedHandle(arguments->At(1));
  if (!index_instance.IsSmi()) {
    GrowableArray<const Object*> args;
    args.Add(&index_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  Smi& index = Smi::Handle();
  index ^= index_instance.raw();
  if (buffer.IsNull() || index.IsNull()) {
    // TODO(asiva): Need to handle error cases.
    UNIMPLEMENTED();
    return;
  }
  intptr_t num_bytes = sizeof(ValueType);
  if ((index.Value() < 0) || ((index.Value() + num_bytes) > buffer.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  arguments->SetReturn(
      ObjectType::Handle(
          ObjectType::New(buffer.UnalignedAt<ValueType>(index.Value()))));
}


template<typename T> static bool HasType(const Object& obj);


template<>
bool HasType<Smi>(const Object& obj) {
  return obj.IsSmi();
}


template<>
bool HasType<Integer>(const Object& obj) {
  return obj.IsInteger();
}


template<>
bool HasType<Double>(const Object& obj) {
  return obj.IsDouble();
}


static intptr_t Value(const Smi& obj) {
  return obj.Value();
}


static int64_t Value(const Integer& obj) {
  return obj.AsInt64Value();
}


static double Value(const Double& obj) {
  return obj.value();
}


template<typename ValueType, typename ObjectType>
static void SetIndexed(const NativeArguments* arguments) {
  const ByteBuffer& buffer = ByteBuffer::CheckedHandle(arguments->At(0));
  const Instance& index_instance = Instance::CheckedHandle(arguments->At(1));
  if (!index_instance.IsSmi()) {
    GrowableArray<const Object*> args;
    args.Add(&index_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  Smi& index = Smi::Handle();
  index ^= index_instance.raw();
  const Instance& value_instance = Instance::CheckedHandle(arguments->At(2));
  if (buffer.IsNull() || index.IsNull()) {
    // TODO(asiva): Need to handle error cases.
    UNIMPLEMENTED();
    return;
  }
  if (index.Value() >= buffer.Length()) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  if (!HasType<ObjectType>(value_instance)) {
    GrowableArray<const Object*> args;
    args.Add(&value_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  ObjectType& value = ObjectType::Handle();
  value ^= value_instance.raw();
  buffer.SetUnalignedAt<ValueType>(index.Value(), Value(value));
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getInt8, 2) {
  GetIndexed<int8_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setInt8, 3) {
  SetIndexed<int8_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getUint8, 2) {
  GetIndexed<uint8_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setUint8, 3) {
  SetIndexed<uint8_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getInt16, 2) {
  GetIndexed<int16_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setInt16, 3) {
  SetIndexed<int16_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getUint16, 2) {
  GetIndexed<uint16_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setUint16, 3) {
  SetIndexed<uint16_t, Smi>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getInt32, 2) {
  GetIndexed<int32_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setInt32, 3) {
  SetIndexed<int32_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getUint32, 2) {
  GetIndexed<uint32_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setUint32, 3) {
  SetIndexed<uint32_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getInt64, 2) {
  GetIndexed<int64_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setInt64, 3) {
  SetIndexed<int64_t, Integer>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getUint64, 2) {
  UNIMPLEMENTED();  // TODO(cshapiro): need getter implementation.
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setUint64, 3) {
  UNIMPLEMENTED();  // TODO(cshapiro): need setter implementation.
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getFloat32, 2) {
  GetIndexed<float, Double>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setFloat32, 3) {
  SetIndexed<float, Double>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_getFloat64, 2) {
  GetIndexed<double, Double>(arguments);
}


DEFINE_NATIVE_ENTRY(ByteBuffer_setFloat64, 3) {
  SetIndexed<double, Double>(arguments);
}

}  // namespace dart
