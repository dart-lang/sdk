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

RawObject* DartEntry::InvokeDynamic(const Function& function,
                                    const Array& arguments) {
  const Array& arg_desc =
      Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
  return InvokeDynamic(function, arguments, arg_desc);
}


RawObject* DartEntry::InvokeDynamic(const Function& function,
                                    const Array& arguments,
                                    const Array& arg_descriptor) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
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
  return entrypoint(code.EntryPoint(), arg_descriptor, arguments, context);
}


RawObject* DartEntry::InvokeStatic(const Function& function,
                                   const Array& arguments) {
  const Array& arg_desc =
      Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
  return InvokeStatic(function, arguments, arg_desc);
}


RawObject* DartEntry::InvokeStatic(const Function& function,
                                   const Array& arguments,
                                   const Array& arg_descriptor) {
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
  return entrypoint(code.EntryPoint(), arg_descriptor, arguments, context);
}


RawObject* DartEntry::InvokeClosure(const Instance& closure,
                                    const Array& arguments) {
  const Array& arg_desc =
      Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
  return InvokeClosure(closure, arguments, arg_desc);
}


RawObject* DartEntry::InvokeClosure(const Instance& instance,
                                    const Array& arguments,
                                    const Array& arg_descriptor) {
  ASSERT(instance.raw() == arguments.At(0));
  // Get the entrypoint corresponding to the closure function or to the call
  // method of the instance. This will result in a compilation of the function
  // if it is not already compiled.
  Function& function = Function::Handle();
  Context& context = Context::Handle();
  if (!instance.IsCallable(&function, &context)) {
    // Set up arguments to include the receiver as the first argument.
    const String& call_symbol = String::Handle(Symbols::Call());
    const Object& null_object = Object::Handle();
    const Array& dart_arguments = Array::Handle(Array::New(4));
    dart_arguments.SetAt(0, instance);
    dart_arguments.SetAt(1, call_symbol);
    dart_arguments.SetAt(2, arguments);  // Includes instance.
    dart_arguments.SetAt(3, null_object);  // TODO(regis): Provide names.
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
      return error.raw();
    }
  }
  // Now call the invoke stub which will invoke the closure.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  ASSERT(context.isolate() == Isolate::Current());
  const Code& code = Code::Handle(function.CurrentCode());
  ASSERT(!code.IsNull());
  return entrypoint(code.EntryPoint(), arg_descriptor, arguments, context);
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


RawArray* ArgumentsDescriptor::New(intptr_t num_arguments) {
  // Build the arguments descriptor array, which consists of the total
  // argument count; the positional argument count; and
  // a terminating null to simplify iterating in generated code.
  const intptr_t descriptor_len = LengthFor(0);
  Array& descriptor = Array::Handle(Array::New(descriptor_len, Heap::kOld));
  const Smi& arg_count = Smi::Handle(Smi::New(num_arguments));

  // Set total number of passed arguments.
  descriptor.SetAt(kCountIndex, arg_count);

  // Set number of positional arguments.
  descriptor.SetAt(kPositionalCountIndex, arg_count);

  // Set terminating null.
  descriptor.SetAt((descriptor_len - 1), Object::Handle());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  descriptor ^= descriptor.Canonicalize();
  return descriptor.raw();
}


RawObject* DartLibraryCalls::ExceptionCreate(const Library& lib,
                                             const String& class_name,
                                             const Array& arguments) {
  const Class& cls = Class::Handle(lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  // For now, we only support a non-parameterized or raw type.
  const int kNumExtraArgs = 2;  // implicit rcvr and construction phase args.
  const Instance& exception_object = Instance::Handle(Instance::New(cls));
  const Array& constructor_arguments =
    Array::Handle(Array::New(arguments.Length() + kNumExtraArgs));
  constructor_arguments.SetAt(0, exception_object);
  constructor_arguments.SetAt(
      1, Smi::Handle(Smi::New(Function::kCtorPhaseAll)));
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < arguments.Length(); i++) {
    obj = arguments.At(i);
    constructor_arguments.SetAt((i + kNumExtraArgs), obj);
  }

  String& constructor_name = String::Handle(
      String::Concat(class_name, Symbols::DotHandle()));
  Function& constructor =
      Function::Handle(cls.LookupConstructor(constructor_name));
  ASSERT(!constructor.IsNull());
  const Object& retval =
    Object::Handle(DartEntry::InvokeStatic(constructor, constructor_arguments));
  ASSERT(retval.IsNull() || retval.IsError());
  if (retval.IsError()) {
    return retval.raw();
  }
  return exception_object.raw();
}


RawObject* DartLibraryCalls::ToString(const Instance& receiver) {
  const String& function_name =
      String::Handle(Symbols::New("toString"));
  const int kNumArguments = 1;  // Receiver.
  const int kNumNamedArguments = 0;  // None.
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               function_name,
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result = Object::Handle(DartEntry::InvokeDynamic(function,
                                                                 args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::Equals(const Instance& left,
                                    const Instance& right) {
  const int kNumArguments = 2;
  const int kNumNamedArguments = 0;
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(left,
                               Symbols::EqualOperatorHandle(),
                               kNumArguments,
                               kNumNamedArguments));
  ASSERT(!function.IsNull());

  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, left);
  args.SetAt(1, right);
  const Object& result = Object::Handle(DartEntry::InvokeDynamic(function,
                                                                 args));
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
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, Integer::Handle(Integer::New(dest_port_id)));
  args.SetAt(1, Integer::Handle(Integer::New(reply_port_id)));
  args.SetAt(2, message);
  const Object& result = Object::Handle(DartEntry::InvokeStatic(function,
                                                                args));
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
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, Integer::Handle(Integer::New(port_id)));
  return DartEntry::InvokeStatic(function, args);
}


RawObject* DartLibraryCalls::MapSetAt(const Instance& map,
                                      const Instance& key,
                                      const Instance& value) {
  String& name = String::Handle(Symbols::AssignIndexToken());
  const int kNumArguments = 3;
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(map, name, kNumArguments, 0));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, map);
  args.SetAt(1, key);
  args.SetAt(2, value);
  const Object& result = Object::Handle(DartEntry::InvokeDynamic(function,
                                                                 args));
  return result.raw();
}


RawObject* DartLibraryCalls::PortGetId(const Instance& port) {
  const String& field_name = String::Handle(Symbols::New("_id"));
  const Class& cls = Class::Handle(port.clazz());
  const String& func_name = String::Handle(Field::GetterName(field_name));
  const Function& func = Function::Handle(cls.LookupDynamicFunction(func_name));
  ASSERT(!func.IsNull());
  const Array& args = Array::Handle(Array::New(1));
  args.SetAt(0, port);
  return DartEntry::InvokeDynamic(func, args);
}


}  // namespace dart
