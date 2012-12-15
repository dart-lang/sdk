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

// TODO(regis): Factorize this static helper copied from code_generator.cc.
static RawObject* InvokeNoSuchMethod(const Instance& receiver,
                                     const String& target_name,
                                     const Array& arguments_descriptor,
                                     const Array& arguments) {
  // Allocate an InvocationMirror object.
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const String& invocation_mirror_name =
      String::Handle(Symbols::InvocationMirror());
  Class& invocation_mirror_class =
      Class::Handle(core_lib.LookupClassAllowPrivate(invocation_mirror_name));
  ASSERT(!invocation_mirror_class.IsNull());
  const String& allocation_function_name =
      String::Handle(Symbols::AllocateInvocationMirror());
  const Function& allocation_function = Function::Handle(
      Resolver::ResolveStaticByName(invocation_mirror_class,
                                    allocation_function_name,
                                    Resolver::kIsQualified));
  ASSERT(!allocation_function.IsNull());
  GrowableArray<const Object*> allocation_arguments(3);
  allocation_arguments.Add(&target_name);
  allocation_arguments.Add(&arguments_descriptor);
  allocation_arguments.Add(&arguments);
  const Array& kNoArgumentNames = Array::Handle();
  const Object& invocation_mirror =
      Object::Handle(DartEntry::InvokeStatic(allocation_function,
                                             allocation_arguments,
                                             kNoArgumentNames));

  const String& function_name = String::Handle(Symbols::NoSuchMethod());
  const int kNumArguments = 2;
  const int kNumNamedArguments = 0;
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               function_name,
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());
  GrowableArray<const Object*> invoke_arguments(1);
  invoke_arguments.Add(&invocation_mirror);
  const Object& result =
      Object::Handle(DartEntry::InvokeDynamic(receiver,
                                              function,
                                              invoke_arguments,
                                              kNoArgumentNames));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}


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
  if (function.IsNull()) {
    return InvokeNoSuchMethod(receiver,
                              fun_name,
                              fun_args_desc,
                              invoke_arguments);
  }
  // TODO(regis): Simply call DartEntry::InvokeDynamic once it is modified to
  // take an arguments descriptor array and an arguments array.
  // Get the entrypoint corresponding to the instance function. This will
  // result in a compilation of the function if it is not already compiled.
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      Exceptions::PropagateError(error);
    }
  }
  // Set up arguments as GrowableArray.
  GrowableArray<const Object*> args(num_arguments);
  for (int i = 0; i < num_arguments; i++) {
    args.Add(&Object::ZoneHandle(invoke_arguments.At(i)));
  }
  // Now call the invoke stub which will invoke the function.
  DartEntry::invokestub entrypoint = reinterpret_cast<DartEntry::invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  const Context& context = Context::ZoneHandle(
      Isolate::Current()->object_store()->empty_context());
  const Object& result = Object::Handle(
      entrypoint(code.EntryPoint(), fun_args_desc, args.data(), context));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}

}  // namespace dart
