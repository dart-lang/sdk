// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_entry.h"

#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"

namespace dart {

RawObject* DartEntry::InvokeDynamic(
    const Instance& receiver,
    const Function& function,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      return error.raw();
    }
  }

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
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  return entrypoint(
      code.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(num_arguments,
                                         optional_arguments_names),
      args.data(),
      context);
}


RawObject* DartEntry::InvokeStatic(
    const Function& function,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      return error.raw();
    }
  }
  // Now Call the invoke stub which will invoke the dart function.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  const Context& context =
      Context::ZoneHandle(Isolate::Current()->object_store()->empty_context());
  ASSERT(context.isolate() == Isolate::Current());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  return entrypoint(
      code.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(arguments.length(),
                                         optional_arguments_names),
      arguments.data(),
      context);
}


RawObject* DartEntry::InvokeClosure(
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
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      return error.raw();
    }
  }
  // Now Call the invoke stub which will invoke the closure.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  return entrypoint(
      code.EntryPoint(),
      CodeGenerator::ArgumentsDescriptor(arguments.length(),
                                         optional_arguments_names),
      arguments.data(),
      context);
}


RawObject* DartLibraryCalls::ExceptionCreate(
    const Library& lib,
    const String& class_name,
    const GrowableArray<const Object*>& arguments) {
  const Class& cls = Class::Handle(lib.LookupClass(class_name));
  ASSERT(!cls.IsNull());
  // For now, we only support a non-parameterized or raw type.
  const Instance& exception_object = Instance::Handle(Instance::New(cls));
  GrowableArray<const Object*> constructor_arguments(arguments.length() + 2);
  constructor_arguments.Add(&exception_object);
  constructor_arguments.Add(&Smi::Handle(Smi::New(Function::kCtorPhaseAll)));
  constructor_arguments.AddArray(arguments);

  const String& period = String::Handle(String::New("."));
  String& constructor_name = String::Handle(String::Concat(class_name, period));
  Function& constructor =
      Function::Handle(cls.LookupConstructor(constructor_name));
  ASSERT(!constructor.IsNull());
  const Array& kNoArgumentNames = Array::Handle();
  const Object& retval = Object::Handle(
      DartEntry::InvokeStatic(constructor, constructor_arguments,
                              kNoArgumentNames));
  ASSERT(retval.IsNull() || retval.IsError());
  if (retval.IsError()) {
    return retval.raw();
  }
  return exception_object.raw();
}


RawObject* DartLibraryCalls::ToString(const Instance& receiver) {
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
  const Object& result = Object::Handle(
      DartEntry::InvokeDynamic(receiver,
                               function,
                               arguments,
                               kNoArgumentNames));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::Equals(const Instance& left,
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
  const Object& result = Object::Handle(
      DartEntry::InvokeDynamic(left, function, arguments, kNoArgumentNames));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::HandleMessage(Dart_Port dest_port_id,
                                           Dart_Port reply_port_id,
                                           const Instance& message) {
  Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
  ASSERT(!isolate_lib.IsNull());
  const String& public_class_name =
      String::Handle(String::NewSymbol("_ReceivePortImpl"));
  const String& class_name =
      String::Handle(isolate_lib.PrivateName(public_class_name));
  const String& function_name =
      String::Handle(String::NewSymbol("_handleMessage"));
  const int kNumArguments = 3;
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveStatic(isolate_lib,
                              class_name,
                              function_name,
                              kNumArguments,
                              kNoArgumentNames,
                              Resolver::kIsQualified));
  GrowableArray<const Object*> arguments(kNumArguments);
  arguments.Add(&Integer::Handle(Integer::New(dest_port_id)));
  arguments.Add(&Integer::Handle(Integer::New(reply_port_id)));
  arguments.Add(&message);
  const Object& result = Object::Handle(
      DartEntry::InvokeStatic(function, arguments, kNoArgumentNames));
  ASSERT(result.IsNull() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::NewSendPort(intptr_t port_id) {
  Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
  ASSERT(!isolate_lib.IsNull());
  const String& public_class_name =
      String::Handle(String::New("_SendPortImpl"));
  const String& class_name =
      String::Handle(isolate_lib.PrivateName(public_class_name));
  const String& function_name = String::Handle(String::NewSymbol("_create"));
  const int kNumArguments = 1;
  const Array& kNoArgumentNames = Array::Handle();
  const Function& function = Function::Handle(
      Resolver::ResolveStatic(isolate_lib,
                              class_name,
                              function_name,
                              kNumArguments,
                              kNoArgumentNames,
                              Resolver::kIsQualified));
  GrowableArray<const Object*> arguments(kNumArguments);
  arguments.Add(&Integer::Handle(Integer::New(port_id)));
  return DartEntry::InvokeStatic(function, arguments, kNoArgumentNames);
}


RawObject* DartLibraryCalls::MapSetAt(const Instance& map,
                                      const Instance& key,
                                      const Instance& value) {
  String& name = String::Handle(String::New("[]="));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(map, name, 3, 0));
  ASSERT(!function.IsNull());
  GrowableArray<const Object*> args(2);
  args.Add(&key);
  args.Add(&value);
  const Array& kNoArgumentNames = Array::Handle();
  const Object& result = Object::Handle(
      DartEntry::InvokeDynamic(map, function, args, kNoArgumentNames));
  return result.raw();
}


RawObject* DartLibraryCalls::PortGetId(const Instance& port) {
  const String& field_name = String::Handle(String::NewSymbol("_id"));
  const Class& cls = Class::Handle(port.clazz());
  const String& func_name = String::Handle(Field::GetterName(field_name));
  const Function& func = Function::Handle(cls.LookupDynamicFunction(func_name));
  ASSERT(!func.IsNull());
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle();
  return DartEntry::InvokeDynamic(port, func, arguments, kNoArgumentNames);
}


}  // namespace dart
