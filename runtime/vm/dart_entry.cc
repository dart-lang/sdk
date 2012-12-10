// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_entry.h"

#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

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
  const Array& arg_descriptor =
      Array::Handle(ArgumentsDescriptor::New(num_arguments,
                                             optional_arguments_names));
  return entrypoint(code.EntryPoint(), arg_descriptor, args.data(), context);
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
  const Array& arg_descriptor =
      Array::Handle(ArgumentsDescriptor::New(arguments.length(),
                                             optional_arguments_names));
  return entrypoint(code.EntryPoint(), arg_descriptor, arguments.data(),
                    context);
}


RawObject* DartEntry::InvokeClosure(
    const Instance& closure,
    const GrowableArray<const Object*>& arguments,
    const Array& optional_arguments_names) {
  // Get the entrypoint corresponding to the closure specified, this
  // will result in a compilation of the closure if it is not already
  // compiled.
  ASSERT(Class::Handle(closure.clazz()).signature_function() != Object::null());
  const Function& function = Function::Handle(Closure::function(closure));
  const Context& context = Context::Handle(Closure::context(closure));
  ASSERT(!function.IsNull());
  if (!function.HasCode()) {
    const Error& error = Error::Handle(Compiler::CompileFunction(function));
    if (!error.IsNull()) {
      return error.raw();
    }
  }
  // Set up arguments to include the closure as the first argument.
  const int num_arguments = arguments.length() + 1;
  GrowableArray<const Object*> args(num_arguments);
  const Object& arg0 = Object::ZoneHandle(closure.raw());
  args.Add(&arg0);
  for (int i = 1; i < num_arguments; i++) {
    args.Add(arguments[i - 1]);
  }
  // Now Call the invoke stub which will invoke the closure.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  const Array& arg_descriptor =
      Array::Handle(ArgumentsDescriptor::New(num_arguments,
                                             optional_arguments_names));
  return entrypoint(code.EntryPoint(), arg_descriptor, args.data(), context);
}


ArgumentsDescriptor::ArgumentsDescriptor(const Array& array)
    : array_(array) {
}


intptr_t ArgumentsDescriptor::Count() const {
  return Smi::CheckedHandle(array_.At(kCountIndex)).Value();
}


intptr_t ArgumentsDescriptor::PositionalCount() const {
  return Smi::CheckedHandle(array_.At(kPositionalCountIndex)).Value();
}


bool ArgumentsDescriptor::MatchesNameAt(intptr_t index,
                                        const String& other) const {
  const intptr_t offset = kFirstNamedEntryIndex +
                          (index * kNamedEntrySize) +
                          kNameOffset;
  return array_.At(offset) == other.raw();
}


intptr_t ArgumentsDescriptor::count_offset() {
  return Array::data_offset() + (kCountIndex * kWordSize);
}


intptr_t ArgumentsDescriptor::positional_count_offset() {
  return Array::data_offset() + (kPositionalCountIndex * kWordSize);
}


intptr_t ArgumentsDescriptor::first_named_entry_offset() {
  return Array::data_offset() + (kFirstNamedEntryIndex * kWordSize);
}


RawArray* ArgumentsDescriptor::New(intptr_t num_arguments,
                                   const Array& optional_arguments_names) {
  const intptr_t num_named_args =
      optional_arguments_names.IsNull() ? 0 : optional_arguments_names.Length();
  const intptr_t num_pos_args = num_arguments - num_named_args;

  // Build the arguments descriptor array, which consists of the total
  // argument count; the positional argument count; a sequence of (name,
  // position) pairs, sorted by name, for each named optional argument; and
  // a terminating null to simplify iterating in generated code.
  const intptr_t descriptor_len = LengthFor(num_named_args);
  Array& descriptor = Array::Handle(Array::New(descriptor_len, Heap::kOld));

  // Set total number of passed arguments.
  descriptor.SetAt(kCountIndex, Smi::Handle(Smi::New(num_arguments)));
  // Set number of positional arguments.
  descriptor.SetAt(kPositionalCountIndex, Smi::Handle(Smi::New(num_pos_args)));
  // Set alphabetically sorted entries for named arguments.
  String& name = String::Handle();
  Smi& pos = Smi::Handle();
  for (intptr_t i = 0; i < num_named_args; i++) {
    name ^= optional_arguments_names.At(i);
    pos = Smi::New(num_pos_args + i);
    intptr_t insert_index = kFirstNamedEntryIndex + (kNamedEntrySize * i);
    // Shift already inserted pairs with "larger" names.
    String& previous_name = String::Handle();
    Smi& previous_pos = Smi::Handle();
    while (insert_index > kFirstNamedEntryIndex) {
      intptr_t previous_index = insert_index - kNamedEntrySize;
      previous_name ^= descriptor.At(previous_index + kNameOffset);
      intptr_t result = name.CompareTo(previous_name);
      ASSERT(result != 0);  // Duplicate argument names checked in parser.
      if (result > 0) break;
      previous_pos ^= descriptor.At(previous_index + kPositionOffset);
      descriptor.SetAt(insert_index + kNameOffset, previous_name);
      descriptor.SetAt(insert_index + kPositionOffset, previous_pos);
      insert_index = previous_index;
    }
    // Insert pair in descriptor array.
    descriptor.SetAt(insert_index + kNameOffset, name);
    descriptor.SetAt(insert_index + kPositionOffset, pos);
  }
  // Set terminating null.
  descriptor.SetAt(descriptor_len - 1, Object::Handle());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  descriptor ^= descriptor.Canonicalize();
  return descriptor.raw();
}


RawObject* DartLibraryCalls::ExceptionCreate(
    const Library& lib,
    const String& class_name,
    const GrowableArray<const Object*>& arguments) {
  const Class& cls = Class::Handle(lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  // For now, we only support a non-parameterized or raw type.
  const Instance& exception_object = Instance::Handle(Instance::New(cls));
  GrowableArray<const Object*> constructor_arguments(arguments.length() + 2);
  constructor_arguments.Add(&exception_object);
  constructor_arguments.Add(&Smi::Handle(Smi::New(Function::kCtorPhaseAll)));
  constructor_arguments.AddArray(arguments);

  String& constructor_name = String::Handle(
      String::Concat(class_name, Symbols::DotHandle()));
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
      String::Handle(Symbols::New("toString"));
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
  const String& function_name = String::Handle(Symbols::EqualOperator());
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
      String::Handle(Symbols::New("_ReceivePortImpl"));
  const String& class_name =
      String::Handle(isolate_lib.PrivateName(public_class_name));
  const String& function_name =
      String::Handle(Symbols::New("_handleMessage"));
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
  const String& function_name = String::Handle(Symbols::New("_create"));
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
  String& name = String::Handle(Symbols::AssignIndexToken());
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
  const String& field_name = String::Handle(Symbols::New("_id"));
  const Class& cls = Class::Handle(port.clazz());
  const String& func_name = String::Handle(Field::GetterName(field_name));
  const Function& func = Function::Handle(cls.LookupDynamicFunction(func_name));
  ASSERT(!func.IsNull());
  GrowableArray<const Object*> arguments;
  const Array& kNoArgumentNames = Array::Handle();
  return DartEntry::InvokeDynamic(port, func, arguments, kNoArgumentNames);
}


}  // namespace dart
