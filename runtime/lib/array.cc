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

DEFINE_NATIVE_ENTRY(ObjectArray_allocate, 2) {
  const TypeArguments& type_arguments =
      TypeArguments::CheckedHandle(arguments->At(0));
  const Instance& length_instance = Instance::CheckedHandle(arguments->At(1));
  if (!length_instance.IsSmi()) {
    GrowableArray<const Object*> args;
    args.Add(&length_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  Smi& length = Smi::Handle();
  length ^= length_instance.raw();
  ASSERT(type_arguments.IsNull() ||
         (type_arguments.IsInstantiated() && (type_arguments.Length() == 1)));
  if (length.IsNull() || (length.Value() < 0)) {
    GrowableArray<const Object*> args;
    args.Add(&length);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  const Array& new_array = Array::Handle(Array::New(length.Value()));
  new_array.SetTypeArguments(type_arguments);
  arguments->SetReturn(new_array);
}


DEFINE_NATIVE_ENTRY(ObjectArray_getIndexed, 2) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  const Instance& index_instance = Instance::CheckedHandle(arguments->At(1));
  if (!index_instance.IsSmi()) {
    GrowableArray<const Object*> args;
    args.Add(&index_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  Smi& index = Smi::Handle();
  index ^= index_instance.raw();
  if (array.IsNull() || index.IsNull()) {
    // TODO(asiva): Need to handle error cases.
    UNIMPLEMENTED();
    return;
  }
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  const Instance& obj = Instance::CheckedHandle(array.At(index.Value()));
  arguments->SetReturn(obj);
}


DEFINE_NATIVE_ENTRY(ObjectArray_setIndexed, 3) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  const Instance& index_instance = Instance::CheckedHandle(arguments->At(1));
  if (!index_instance.IsSmi()) {
    GrowableArray<const Object*> args;
    args.Add(&index_instance);
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  Smi& index = Smi::Handle();
  index ^= index_instance.raw();
  const Instance& value = Instance::CheckedHandle(arguments->At(2));
  if (array.IsNull() || index.IsNull()) {
    // TODO(asiva): Need to handle error cases.
    UNIMPLEMENTED();
    return;
  }
  if ((index.Value() < 0) || (index.Value() >= array.Length())) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&index);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  array.SetAt(index.Value(), value);
}


DEFINE_NATIVE_ENTRY(ObjectArray_getLength, 1) {
  const Array& array = Array::CheckedHandle(arguments->At(0));
  if (array.IsNull()) {
    // TODO(asiva): Need to handle error cases.
    UNIMPLEMENTED();
    return;
  }
  const Smi& length = Smi::Handle(Smi::New(array.Length()));
  arguments->SetReturn(length);
}


// ObjectArray src, int srcStart, int dstStart, int count.
DEFINE_NATIVE_ENTRY(ObjectArray_copyFromObjectArray, 5) {
  const Array& dest = Array::CheckedHandle(arguments->At(0));
  const Array& source = Array::CheckedHandle(arguments->At(1));
  const Smi& src_start = Smi::CheckedHandle(arguments->At(2));
  const Smi& dst_start = Smi::CheckedHandle(arguments->At(3));
  const Smi& count = Smi::CheckedHandle(arguments->At(4));
  if (dest.IsNull() || source.IsNull() || src_start.IsNull() ||
      dst_start.IsNull() || count.IsNull()) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  intptr_t icount = count.Value();
  if (icount < 0) {
    GrowableArray<const Object*> args;
    Exceptions::ThrowByType(Exceptions::kIllegalArgument, args);
  }
  if (icount == 0) {
    return;
  }
  intptr_t isrc_start = src_start.Value();
  intptr_t idst_start = dst_start.Value();
  if ((isrc_start + icount) > source.Length()) {
    GrowableArray<const Object*> arguments;
    arguments.Add(&src_start);
    Exceptions::ThrowByType(Exceptions::kIndexOutOfRange, arguments);
  }
  if ((idst_start + icount) > dest.Length()) {
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
}

}  // namespace dart
