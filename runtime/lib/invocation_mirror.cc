// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(InvocationMirror_invoke, 4) {
  const Instance& receiver = Instance::CheckedHandle(arguments->NativeArgAt(0));
  const String& fun_name = String::CheckedHandle(arguments->NativeArgAt(1));
  const Array& fun_args_desc = Array::CheckedHandle(arguments->NativeArgAt(2));
  const Array& fun_arguments = Array::CheckedHandle(arguments->NativeArgAt(3));

  // Allocate a fixed-length array duplicating the original function arguments
  // and replace the receiver.
  const int num_arguments = fun_arguments.Length();
  const Array& invoke_arguments = Array::Handle(Array::New(num_arguments));
  invoke_arguments.SetAt(0, receiver);
  Object& arg = Object::Handle();
  for (int i = 1; i < num_arguments; i++) {
    arg = fun_arguments.At(i);
    invoke_arguments.SetAt(i, arg);
  }
  // Resolve dynamic function given by name.
  const ArgumentsDescriptor args_desc(fun_args_desc);
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               fun_name,
                               args_desc.Count(),
                               args_desc.NamedCount()));
  Object& result = Object::Handle();
  if (function.IsNull()) {
    result = DartEntry::InvokeNoSuchMethod(receiver,
                                           fun_name,
                                           invoke_arguments,
                                           fun_args_desc);
  } else {
    result = DartEntry::InvokeFunction(function,
                                       invoke_arguments,
                                       fun_args_desc);
  }
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}

}  // namespace dart
