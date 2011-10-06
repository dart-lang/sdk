// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_entry.h"

#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"

namespace dart {

RawInstance* DartEntry::InvokeDynamic(
    const Instance& receiver,
    const Function& function,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  if (!function.HasCode()) {
    Compiler::CompileFunction(function);
  }
  const Code& code = Code::Handle(function.code());
  ASSERT(!code.IsNull());
  const Instructions& instrs = Instructions::Handle(code.instructions());
  ASSERT(!instrs.IsNull());

  // Set up arguments to include the receiver as the first argument.
  const int num_arguments = arguments.length() + 1;
  GrowableArray<const Object*> args(num_arguments);
  const Object& arg0 = Object::ZoneHandle(receiver.raw());
  args.Add(&arg0);
  for (int i = 1; i < num_arguments; i++) {
    args.Add(arguments[i - 1]);
  }

  // Now Call the invoke stub which will invoke the dart function.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  const Context& context =
      Context::ZoneHandle(Isolate::Current()->object_store()->empty_context());
  ASSERT(context.isolate() == Isolate::Current());
  return entrypoint(
      instrs.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(num_arguments,
                                         optional_arguments_names),
      args.data(),
      context);
}


RawInstance* DartEntry::InvokeStatic(
    const Function& function,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    Compiler::CompileFunction(function);
  }
  const Code& code = Code::Handle(function.code());
  ASSERT(!code.IsNull());
  const Instructions& instrs = Instructions::Handle(code.instructions());
  ASSERT(!instrs.IsNull());

  // Now Call the invoke stub which will invoke the dart function.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  const Context& context =
      Context::ZoneHandle(Isolate::Current()->object_store()->empty_context());
  ASSERT(context.isolate() == Isolate::Current());
  return entrypoint(
      instrs.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(arguments.length(),
                                         optional_arguments_names),
      arguments.data(),
      context);
}


RawInstance* DartEntry::InvokeClosure(
    const Closure& closure,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the closure specified, this
  // will result in a compilation of the closure if it is not already
  // compiled.
  ASSERT(Class::Handle(closure.clazz()).signature_function() != Object::null());
  const Function& function = Function::Handle(closure.function());
  const Context& context = Context::Handle(closure.context());
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    Compiler::CompileFunction(function);
  }
  const Code& code = Code::Handle(function.code());
  ASSERT(!code.IsNull());
  const Instructions& instrs = Instructions::Handle(code.instructions());
  ASSERT(!instrs.IsNull());

  // Now Call the invoke stub which will invoke the closure.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  return entrypoint(
      instrs.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(arguments.length(),
                                         optional_arguments_names),
      arguments.data(),
      context);
}


RawInstance* DartLibraryCalls::ExceptionCreate(
    const String& class_name,
    const GrowableArray<const Object*>& arguments) {
  const Library& core_lib = Library::Handle(Library::CoreLibrary());
  const Class& cls = Class::Handle(core_lib.LookupClass(class_name));
  ASSERT(!cls.IsNull());
  // For now, we only support a non-parameterized or raw type.
  const Instance& exception_object = Instance::Handle(Instance::New(cls));
  GrowableArray<const Object*> constructor_arguments(arguments.length() + 1);
  constructor_arguments.Add(&exception_object);
  constructor_arguments.AddArray(arguments);

  const String& period = String::Handle(String::New("."));
  String& constructor_name = String::Handle(String::Concat(class_name, period));
  Function& constructor =
      Function::Handle(cls.LookupConstructor(constructor_name));
  ASSERT(!constructor.IsNull());
  const Array& kNoArgumentNames = Array::Handle();
  DartEntry::InvokeStatic(constructor, constructor_arguments, kNoArgumentNames);
  return exception_object.raw();
}


RawInstance* DartLibraryCalls::ToString(const Instance& receiver) {
  const String& function_name =
      String::Handle(String::NewSymbol("toString"));
  GrowableArray<const Object*> arguments;
  const int kNumArguments = 1;  // Receiver.
  const int kNumNamedArguments = 0;  // None.
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               function_name,
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());
  const Instance& result = Instance::Handle(
      DartEntry::InvokeDynamic(receiver,
                               function,
                               arguments,
                               kNoArgumentNames));
  // Object's 'toString' threw an exception, let the caller handle it.
  ASSERT(result.IsString() || result.IsUnhandledException());
  return result.raw();
}


RawInstance* DartLibraryCalls::Equals(const Instance& left,
                                      const Instance& right) {
  const String& function_name =
      String::Handle(String::NewSymbol("=="));
  GrowableArray<const Object*> arguments;
  arguments.Add(&right);
  const int kNumArguments = 2;
  const int kNumNamedArguments = 0;
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(left,
                               function_name,
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());
  const Instance& result = Instance::Handle(
      DartEntry::InvokeDynamic(left, function, arguments, kNoArgumentNames));
  // Object's '==' threw an exception, let the caller handle it.
  ASSERT(result.IsBool() || result.IsUnhandledException());
  return result.raw();
}

}  // namespace dart
