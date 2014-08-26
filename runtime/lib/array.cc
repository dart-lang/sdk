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

DEFINE_NATIVE_ENTRY(List_allocate, 2) {
  // Implemented in FlowGraphBuilder::VisitNativeBody.
  UNREACHABLE();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(List_getIndexed, 2) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  return array.At(index.Value());
}


DEFINE_NATIVE_ENTRY(List_setIndexed, 3) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, index, arguments->NativeArgAt(1));
  const Instance& value = Instance::CheckedHandle(arguments->NativeArgAt(2));
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, index);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  array.SetAt(index.Value(), value);
  return Object::null();
}


DEFINE_NATIVE_ENTRY(List_getLength, 1) {
  const Array& array = Array::CheckedHandle(arguments->NativeArgAt(0));
  return Smi::New(array.Length());
}


// ObjectArray src, int srcStart, int dstStart, int count.
DEFINE_NATIVE_ENTRY(List_copyFromObjectArray, 5) {
  const Array& dest = Array::CheckedHandle(arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, source, arguments->NativeArgAt(1));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, src_start, arguments->NativeArgAt(2));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, dst_start, arguments->NativeArgAt(3));
  GET_NON_NULL_NATIVE_ARGUMENT(Smi, count, arguments->NativeArgAt(4));
  intptr_t icount = count.Value();
  if (icount < 0) {
    Exceptions::ThrowByType(Exceptions::kArgument, Object::empty_array());
  }
  if (icount == 0) {
    return Object::null();
  }
  intptr_t isrc_start = src_start.Value();
  intptr_t idst_start = dst_start.Value();
  if ((isrc_start < 0) || ((isrc_start + icount) > source.Length())) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, src_start);
    Exceptions::ThrowByType(Exceptions::kRange, args);
  }
  if ((idst_start < 0) || ((idst_start + icount) > dest.Length())) {
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, dst_start);
    Exceptions::ThrowByType(Exceptions::kRange, args);
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
