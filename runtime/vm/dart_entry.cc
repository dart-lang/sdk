// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_entry.h"

#include "vm/class_finalizer.h"
#include "vm/code_generator.h"
#include "vm/compiler.h"
#include "vm/debugger.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

// A cache of VM heap allocated arguments descriptors.
RawArray* ArgumentsDescriptor::cached_args_descriptors_[kCachedDescriptorCount];


RawObject* DartEntry::InvokeFunction(const Function& function,
                                     const Array& arguments) {
  const Array& arguments_descriptor =
      Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
  return InvokeFunction(function, arguments, arguments_descriptor);
}


RawObject* DartEntry::InvokeFunction(const Function& function,
                                     const Array& arguments,
                                     const Array& arguments_descriptor) {
  const Context& context =
      Context::Handle(Isolate::Current()->object_store()->empty_context());
  ASSERT(context.isolate() == Isolate::Current());
  return InvokeFunction(function, arguments, arguments_descriptor, context);
}


RawObject* DartEntry::InvokeFunction(const Function& function,
                                     const Array& arguments,
                                     const Array& arguments_descriptor,
                                     const Context& context) {
  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  Isolate* isolate = Isolate::Current();
  if (!function.HasCode()) {
    const Error& error = Error::Handle(
        isolate, Compiler::CompileFunction(isolate, function));
    if (!error.IsNull()) {
      return error.raw();
    }
  }
  // Now Call the invoke stub which will invoke the dart function.
  invokestub entrypoint = reinterpret_cast<invokestub>(
      StubCode::InvokeDartCodeEntryPoint());
  const Code& code = Code::Handle(isolate, function.CurrentCode());
  ASSERT(!code.IsNull());
  ASSERT(Isolate::Current()->no_callback_scope_depth() == 0);
#if defined(USING_SIMULATOR)
#if defined(ARCH_IS_64_BIT)
  // TODO(zra): Change to intptr_t so we have only one case.
    return bit_copy<RawObject*, int64_t>(Simulator::Current()->Call(
        reinterpret_cast<int64_t>(entrypoint),
        static_cast<int64_t>(code.EntryPoint()),
        reinterpret_cast<int64_t>(&arguments_descriptor),
        reinterpret_cast<int64_t>(&arguments),
        reinterpret_cast<int64_t>(&context)));
#else
    return bit_copy<RawObject*, int64_t>(Simulator::Current()->Call(
        reinterpret_cast<int32_t>(entrypoint),
        static_cast<int32_t>(code.EntryPoint()),
        reinterpret_cast<int32_t>(&arguments_descriptor),
        reinterpret_cast<int32_t>(&arguments),
        reinterpret_cast<int32_t>(&context)));
#endif
#else
    return entrypoint(code.EntryPoint(),
                      arguments_descriptor,
                      arguments,
                      context);
#endif
}


RawObject* DartEntry::InvokeClosure(const Array& arguments) {
  const Array& arguments_descriptor =
      Array::Handle(ArgumentsDescriptor::New(arguments.Length()));
  return InvokeClosure(arguments, arguments_descriptor);
}


RawObject* DartEntry::InvokeClosure(const Array& arguments,
                                    const Array& arguments_descriptor) {
  Instance& instance = Instance::Handle();
  instance ^= arguments.At(0);
  // Get the entrypoint corresponding to the closure function or to the call
  // method of the instance. This will result in a compilation of the function
  // if it is not already compiled.
  Function& function = Function::Handle();
  Context& context = Context::Handle();
  if (instance.IsCallable(&function, &context)) {
    // Only invoke the function if its arguments are compatible.
    const ArgumentsDescriptor args_desc(arguments_descriptor);
    if (function.AreValidArgumentCounts(args_desc.Count(),
                                        args_desc.NamedCount(),
                                        NULL)) {
      // The closure or non-closure object (receiver) is passed as implicit
      // first argument. It is already included in the arguments array.
      return InvokeFunction(function, arguments, arguments_descriptor, context);
    }
  }
  // There is no compatible 'call' method, so invoke noSuchMethod.
  return InvokeNoSuchMethod(instance,
                            Symbols::Call(),
                            arguments,
                            arguments_descriptor);
}


RawObject* DartEntry::InvokeNoSuchMethod(const Instance& receiver,
                                         const String& target_name,
                                         const Array& arguments,
                                         const Array& arguments_descriptor) {
  ASSERT(receiver.raw() == arguments.At(0));
  // Allocate an Invocation object.
  const Library& core_lib = Library::Handle(Library::CoreLibrary());

  Class& invocation_mirror_class = Class::Handle(
      core_lib.LookupClass(
          String::Handle(core_lib.PrivateName(Symbols::InvocationMirror()))));
  ASSERT(!invocation_mirror_class.IsNull());
  const String& function_name =
      String::Handle(core_lib.PrivateName(Symbols::AllocateInvocationMirror()));
  const Function& allocation_function = Function::Handle(
      invocation_mirror_class.LookupStaticFunction(function_name));
  ASSERT(!allocation_function.IsNull());
  const int kNumAllocationArgs = 4;
  const Array& allocation_args = Array::Handle(Array::New(kNumAllocationArgs));
  allocation_args.SetAt(0, target_name);
  allocation_args.SetAt(1, arguments_descriptor);
  allocation_args.SetAt(2, arguments);
  allocation_args.SetAt(3, Bool::False());  // Not a super invocation.
  const Object& invocation_mirror = Object::Handle(
      InvokeFunction(allocation_function, allocation_args));

  // Now use the invocation mirror object and invoke NoSuchMethod.
  const int kNumArguments = 2;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               Symbols::NoSuchMethod(),
                               args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  args.SetAt(1, invocation_mirror);
  return InvokeFunction(function, args);
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


RawString* ArgumentsDescriptor::NameAt(intptr_t index) const {
  const intptr_t offset = kFirstNamedEntryIndex +
                          (index * kNamedEntrySize) +
                          kNameOffset;
  String& result = String::Handle();
  result ^= array_.At(offset);
  return result.raw();
}


bool ArgumentsDescriptor::MatchesNameAt(intptr_t index,
                                        const String& other) const {
  return NameAt(index) == other.raw();
}


intptr_t ArgumentsDescriptor::count_offset() {
  return Array::element_offset(kCountIndex);
}


intptr_t ArgumentsDescriptor::positional_count_offset() {
  return Array::element_offset(kPositionalCountIndex);
}


intptr_t ArgumentsDescriptor::first_named_entry_offset() {
  return Array::element_offset(kFirstNamedEntryIndex);
}


RawArray* ArgumentsDescriptor::New(intptr_t num_arguments,
                                   const Array& optional_arguments_names) {
  const intptr_t num_named_args =
      optional_arguments_names.IsNull() ? 0 : optional_arguments_names.Length();
  if (num_named_args == 0) {
    return ArgumentsDescriptor::New(num_arguments);
  }
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
  descriptor.SetAt(descriptor_len - 1, Object::null_object());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  descriptor ^= descriptor.CheckAndCanonicalize(NULL);
  ASSERT(!descriptor.IsNull());
  return descriptor.raw();
}


RawArray* ArgumentsDescriptor::New(intptr_t num_arguments) {
  ASSERT(num_arguments >= 0);
  if (num_arguments < kCachedDescriptorCount) {
    return cached_args_descriptors_[num_arguments];
  }
  return NewNonCached(num_arguments);
}


RawArray* ArgumentsDescriptor::NewNonCached(intptr_t num_arguments,
                                            bool canonicalize) {
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
  descriptor.SetAt((descriptor_len - 1), Object::null_object());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  if (canonicalize) {
    descriptor ^= descriptor.CheckAndCanonicalize(NULL);
  }
  ASSERT(!descriptor.IsNull());
  return descriptor.raw();
}


void ArgumentsDescriptor::InitOnce() {
  for (int i = 0; i < kCachedDescriptorCount; i++) {
    cached_args_descriptors_[i] = ArgumentsDescriptor::NewNonCached(i, false);
  }
}


RawObject* DartLibraryCalls::InstanceCreate(const Library& lib,
                                            const String& class_name,
                                            const String& constructor_name,
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

  const String& function_name = String::Handle(
      String::Concat(class_name, constructor_name));
  const Function& constructor =
      Function::Handle(cls.LookupConstructorAllowPrivate(function_name));
  ASSERT(!constructor.IsNull());
  const Object& retval =
    Object::Handle(DartEntry::InvokeFunction(constructor,
                                             constructor_arguments));
  ASSERT(retval.IsNull() || retval.IsError());
  if (retval.IsError()) {
    return retval.raw();
  }
  return exception_object.raw();
}


RawObject* DartLibraryCalls::ToString(const Instance& receiver) {
  const int kNumArguments = 1;  // Receiver.
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               Symbols::toString(),
                               args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                                  args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::HashCode(const Instance& receiver) {
  const int kNumArguments = 1;  // Receiver.
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver,
                               Symbols::hashCode(),
                               args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                                  args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::Equals(const Instance& left,
                                    const Instance& right) {
  const int kNumArguments = 2;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(left,
                               Symbols::EqualOperator(),
                               args_desc));
  ASSERT(!function.IsNull());

  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, left);
  args.SetAt(1, right);
  const Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                                  args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::LookupHandler(Dart_Port port_id) {
  Isolate* isolate = Isolate::Current();
  Function& function =
      Function::Handle(isolate,
                       isolate->object_store()->lookup_port_handler());
  const int kNumArguments = 1;
  if (function.IsNull()) {
    Library& isolate_lib = Library::Handle(Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name =
        String::Handle(isolate_lib.PrivateName(Symbols::_lookupHandler()));
    function = Resolver::ResolveStatic(isolate_lib,
                                       class_name,
                                       function_name,
                                       kNumArguments,
                                       Object::empty_array());
    ASSERT(!function.IsNull());
    isolate->object_store()->set_lookup_port_handler(function);
  }
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, Integer::Handle(Integer::New(port_id)));
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  return result.raw();
}


RawObject* DartLibraryCalls::HandleMessage(const Object& handler,
                                           const Instance& message) {
  Isolate* isolate = Isolate::Current();
  Function& function = Function::Handle(isolate,
      isolate->object_store()->handle_message_function());
  const int kNumArguments = 2;
  if (function.IsNull()) {
    Library& isolate_lib = Library::Handle(isolate, Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name = String::Handle(isolate,
        isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name = String::Handle(isolate,
        isolate_lib.PrivateName(Symbols::_handleMessage()));
    function = Resolver::ResolveStatic(isolate_lib,
                                       class_name,
                                       function_name,
                                       kNumArguments,
                                       Object::empty_array());
    ASSERT(!function.IsNull());
    isolate->object_store()->set_handle_message_function(function);
  }
  const Array& args = Array::Handle(isolate, Array::New(kNumArguments));
  args.SetAt(0, handler);
  args.SetAt(1, message);
  if (isolate->debugger()->IsStepping()) {
    // If the isolate is being debugged and the debugger was stepping
    // through code, enable single stepping so debugger will stop
    // at the first location the user is interested in.
    isolate->debugger()->SetSingleStep();
  }
  const Object& result = Object::Handle(isolate,
      DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsNull() || result.IsError());
  return result.raw();
}


RawObject* DartLibraryCalls::MapSetAt(const Instance& map,
                                      const Instance& key,
                                      const Instance& value) {
  const int kNumArguments = 3;
  ArgumentsDescriptor args_desc(
      Array::Handle(ArgumentsDescriptor::New(kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(map,
                               Symbols::AssignIndexToken(),
                               args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, map);
  args.SetAt(1, key);
  args.SetAt(2, value);
  const Object& result = Object::Handle(DartEntry::InvokeFunction(function,
                                                                  args));
  return result.raw();
}

}  // namespace dart
