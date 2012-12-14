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
  // TODO(regis): Simply call DartEntry::InvokeClosure once it is modified to
  // take an arguments descriptor array and an arguments array.
  Instance& instance = Instance::Handle();
  instance ^= fun_arguments.At(0);
  // Get the entrypoint corresponding to the closure function or to the call
  // method of the instance. This will result in a compilation of the function
  // if it is not already compiled.
  Function& function = Function::Handle();
  Context& context = Context::Handle();
  if (!instance.IsCallable(&function, &context)) {
    const String& call_symbol = String::Handle(Symbols::Call());
    const Object& null_object = Object::Handle();
    GrowableArray<const Object*> dart_arguments(5);
    dart_arguments.Add(&instance);
    dart_arguments.Add(&call_symbol);
    dart_arguments.Add(&fun_arguments);  // Including instance.
    dart_arguments.Add(&null_object);  // TODO(regis): Provide names.
    // If a function "call" with different arguments exists, it will have been
    // invoked above, so no need to handle this case here.
    Exceptions::ThrowByType(Exceptions::kNoSuchMethod, dart_arguments);
    UNREACHABLE();
    return Object::null();
  }
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  // Set up arguments as GrowableArray.
  const int num_arguments = fun_arguments.Length();
  GrowableArray<const Object*> args(num_arguments);
  for (int i = 0; i < num_arguments; i++) {
    args.Add(&Object::ZoneHandle(fun_arguments.At(i)));
  }
  // Now call the invoke stub which will invoke the closure.
  DartEntry::invokestub entrypoint = reinterpret_cast<DartEntry::invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  const Array& fun_args_desc =
      Array::Handle(ArgumentsDescriptor::New(num_arguments, fun_arg_names));
  const Object& result = Object::Handle(
      entrypoint(code.EntryPoint(), fun_args_desc, args.data(), context));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}

}  // namespace dart
