// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Function_apply, 2) {
  const Array& fun_arguments = Array::CheckedHandle(arguments->NativeArgAt(0));
  const Array& fun_arg_names = Array::CheckedHandle(arguments->NativeArgAt(1));
  const Array& fun_args_desc =
      Array::Handle(ArgumentsDescriptor::New(fun_arguments.Length(),
                                             fun_arg_names));
  const Object& result =
      Object::Handle(DartEntry::InvokeClosure(fun_arguments, fun_args_desc));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}

}  // namespace dart
