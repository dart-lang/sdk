// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/assembler.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(GrowableObjectArray_allocate, 2) {
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments->NativeArgAt(0));
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.IsInstantiated() && (type_arguments.Length() == 1)));
  GET_NATIVE_ARGUMENT(Array, data, arguments->NativeArgAt(1));
  if ((data.Length() <= 0)) {
    const Integer& index = Integer::Handle(Integer::New(data.Length()));
    GrowableArray<const Object*> args;
    args.Add(&index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  const GrowableObjectArray& new_array =
      GrowableObjectArray::Handle(GrowableObjectArray::New(data));
  new_array.SetTypeArguments(type_arguments);
  return new_array.raw();
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_getIndexed, 2) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> args;
    args.Add(&index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  const Instance& obj = Instance::CheckedHandle(array.At(index.Value()));
  return obj.raw();
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_setIndexed, 3) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> args;
    args.Add(&index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  GET_NATIVE_ARGUMENT(Instance, value, arguments->NativeArgAt(2));
  array.SetAt(index.Value(), value);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_getLength, 1) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(array.Length());
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_getCapacity, 1) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(array.Capacity());
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_setLength, 2) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Smi, length, arguments->NativeArgAt(1));
  if ((length.Value() < 0) || (length.Value() > array.Capacity())) {
    GrowableArray<const Object*> args;
    args.Add(&length);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  array.SetLength(length.Value());
  return Object::null();
}


DEFINE_NATIVE_ENTRY(GrowableObjectArray_setData, 2) {
  const GrowableObjectArray& array =
      GrowableObjectArray::CheckedHandle(arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Array, data, arguments->NativeArgAt(1));
  ASSERT(data.Length() > 0);
  array.SetData(data);
  return Object::null();
}

}  // namespace dart
