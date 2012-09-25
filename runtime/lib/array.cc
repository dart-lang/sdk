// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/assembler.h"
#include "vm/bigint_operations.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(ObjectArray_allocate, 2) {
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::CheckedHandle(arguments->At(0));
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.IsInstantiated() && (type_arguments.Length() == 1)));
  GET_NATIVE_ARGUMENT(Smi, length, arguments->At(1));
  intptr_t len = length.Value();
  if (len < 0 || len > Array::kMaxElements) {
    const String& error = String::Handle(String::NewFormatted(
        "length (%"Pd") must be in the range [0..%"Pd"]",
        len, Array::kMaxElements));
    GrowableArray<const Object*> args;
    args.Add(&error);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  const Array& new_array = Array::Handle(Array::New(length.Value()));
  new_array.SetTypeArguments(type_arguments);
  return new_array.raw();
}


DEFINE_NATIVE_ENTRY(ObjectArray_getIndexed, 2) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, index, arguments->At(1));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  return array.At(index.Value());
}


DEFINE_NATIVE_ENTRY(ObjectArray_setIndexed, 3) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, index, arguments->At(1));
  const Instance& value = Instance::CheckedHandle(arguments->At(2));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  array.SetAt(index.Value(), value);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(ObjectArray_getLength, 1) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  return Smi::New(array.Length());
}


// ObjectArray src, int srcStart, int dstStart, int count.
DEFINE_NATIVE_ENTRY(ObjectArray_copyFromObjectArray, 5) {
  const Array& dest = Array::CheckedHandle(arguments->At(0));
  GET_NATIVE_ARGUMENT(Array, source, arguments->At(1));
  GET_NATIVE_ARGUMENT(Smi, src_start, arguments->At(2));
  GET_NATIVE_ARGUMENT(Smi, dst_start, arguments->At(3));
  GET_NATIVE_ARGUMENT(Smi, count, arguments->At(4));
  intptr_t icount = count.Value();
  if (icount < 0) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  if (icount == 0) {
    return Object::null();
  }
  intptr_t isrc_start = src_start.Value();
  intptr_t idst_start = dst_start.Value();
  if ((isrc_start < 0) || ((isrc_start + icount) > source.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&src_start);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  if ((idst_start < 0) || ((idst_start + icount) > dest.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&dst_start);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }

  Object& src_obj = Object::Handle();
  if (isrc_start < idst_start) {
    for (intptr_t i = icount - 1; i >= 0; i--) {
      src_obj = source.At(isrc_start + i);
      dest.SetAt(idst_start + i, src_obj);
    }
  } else {
    for (intptr_t i = 0; i < icount; i++) {
      src_obj = source.At(isrc_start + i);
      dest.SetAt(idst_start + i, src_obj);
    }
  }
  return Object::null();
}

}  // namespace dart
