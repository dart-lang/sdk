// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/assembler.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"

namespace dart {

DEFINE_NATIVE_ENTRY(List_allocate, 2) {
  // Implemented in FlowGraphBuilder::VisitNativeBody.
  UNREACHABLE();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(List_getIndexed, 2) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    Exceptions::ThrowRangeError("index", index, 0, array.Length());
  }
  return array.At(index.Value());
}


DEFINE_NATIVE_ENTRY(List_setIndexed, 3) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  const Instance& value = Instance::CheckedHandle(arguments->NativeArgAt(2));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    Exceptions::ThrowRangeError("index", index, 0, array.Length());
  }
  array.SetAt(index.Value(), value);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(List_getLength, 1) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(array.Length());
}


// ObjectArray src, int start, int count, bool needTypeArgument.
DEFINE_NATIVE_ENTRY(List_slice, 4) {
  const Array& src = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, start, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, count, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, needs_type_arg, arguments->NativeArgAt(3));
  intptr_t icount = count.Value();
  // Zero count should be handled outside already.
  if ((icount <= 0) || (icount > src.Length())) {
    Exceptions::ThrowRangeError(
        "count",
        Smi::Handle(Smi::New(icount)),
        1,
        src.Length() + 1);
  }
  intptr_t istart = start.Value();
  if ((istart < 0) || ((istart + icount) > src.Length())) {
    Exceptions::ThrowRangeError(
        "start",
        Smi::Handle(Smi::New(istart)),
        0,
        src.Length() - icount + 1);
  }

  return src.Slice(istart, icount, needs_type_arg.value());
}


// Private factory, expects correct arguments.
DEFINE_NATIVE_ENTRY(ImmutableList_from, 4) {
  // Ignore first argument of a thsi factory (type argument).
  const Array& from_array = Array::CheckedHandle(arguments->NativeArgAt(1));
  const Smi& smi_offset = Smi::CheckedHandle(arguments->NativeArgAt(2));
  const Smi& smi_length = Smi::CheckedHandle(arguments->NativeArgAt(3));
  const intptr_t length = smi_length.Value();
  const intptr_t offset = smi_offset.Value();
  const Array& result = Array::Handle(Array::New(length));
  Object& temp = Object::Handle();
  for (intptr_t i = 0; i < length; i++) {
    temp = from_array.At(i + offset);
    result.SetAt(i, temp);
  }
  result.MakeImmutable();
  return result.raw();
}

}  // namespace dart
