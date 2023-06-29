// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_entry.h"

#include "platform/safe_stack.h"
#include "vm/class_finalizer.h"
#include "vm/debugger.h"
#include "vm/dispatch_table.h"
#include "vm/heap/safepoint.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/jit/compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

DECLARE_FLAG(bool, precompiled_mode);

// A cache of VM heap allocated arguments descriptors.
ArrayPtr ArgumentsDescriptor::cached_args_descriptors_[kCachedDescriptorCount];

ObjectPtr DartEntry::InvokeFunction(const Function& function,
                                    const Array& arguments) {
  ASSERT(Thread::Current()->IsDartMutatorThread());
  const int kTypeArgsLen = 0;  // No support to pass type args to generic func.
  const Array& arguments_descriptor = Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, arguments.Length()));
  return InvokeFunction(function, arguments, arguments_descriptor);
}

class DartEntryScope : public TransitionToGenerated {
 public:
  NO_SANITIZE_SAFE_STACK
  explicit DartEntryScope(Thread* thread) : TransitionToGenerated(thread) {
    // Ensure we do not attempt to long jump across Dart frames.
    saved_long_jump_base_ = thread->long_jump_base();
    thread->set_long_jump_base(nullptr);

#if defined(USING_SAFE_STACK)
    // Remember the safestack pointer at entry so it can be restored in
    // Exceptions::JumpToFrame when a Dart exception jumps over C++ frames.
    saved_safestack_limit_ = OSThread::GetCurrentSafestackPointer();
    thread->set_saved_safestack_limit(saved_safestack_limit_);
#endif
  }

  ~DartEntryScope() {
#if defined(USING_SAFE_STACK)
    thread()->set_saved_safestack_limit(saved_safestack_limit_);
#endif

    ASSERT(thread()->long_jump_base() == nullptr);
    thread()->set_long_jump_base(saved_long_jump_base_);
  }

 private:
  LongJumpScope* saved_long_jump_base_;
#if defined(USING_SAFE_STACK)
  uword saved_safestack_limit_ = 0;
#endif
};

// Note: The invocation stub follows the C ABI, so we cannot pass C++ struct
// values like ObjectPtr. In some calling conventions (IA32), ObjectPtr is
// passed/returned different from a pointer.
extern "C" typedef uword /*ObjectPtr*/ (*invokestub)(
#if defined(DART_PRECOMPILED_RUNTIME)
    uword entry_point,
#else
    uword /*CodePtr*/ target_code,
#endif
    uword /*ArrayPtr*/ arguments_descriptor,
    uword /*ArrayPtr*/ arguments,
    Thread* thread);

ObjectPtr DartEntry::InvokeFunction(const Function& function,
                                    const Array& arguments,
                                    const Array& arguments_descriptor) {
#if defined(DART_PRECOMPILER)
  if (FLAG_precompiled_mode) {
    FATAL("Should never invoke Dart code during AOT compilation");
  }
#endif

  Thread* thread = Thread::Current();
  ASSERT(thread->IsDartMutatorThread());
  ASSERT(!function.IsNull());

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!function.HasCode()) {
    const Object& result = Object::Handle(
        thread->zone(), Compiler::CompileFunction(thread, function));
    if (result.IsError()) {
      return Error::Cast(result).ptr();
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  ASSERT(function.HasCode());

  DartEntryScope dart_entry_scope(thread);

  const uword stub = StubCode::InvokeDartCode().EntryPoint();
#if defined(USING_SIMULATOR)
  return bit_copy<ObjectPtr, int64_t>(Simulator::Current()->Call(
      static_cast<intptr_t>(stub),
#if defined(DART_PRECOMPILED_RUNTIME)
      static_cast<intptr_t>(function.entry_point()),
#else
      static_cast<intptr_t>(function.CurrentCode()),
#endif
      static_cast<intptr_t>(arguments_descriptor.ptr()),
      static_cast<intptr_t>(arguments.ptr()),
      reinterpret_cast<intptr_t>(thread)));
#else  // USING_SIMULATOR
  return static_cast<ObjectPtr>((reinterpret_cast<invokestub>(stub))(
#if defined(DART_PRECOMPILED_RUNTIME)
      function.entry_point(),
#else
      static_cast<uword>(function.CurrentCode()),
#endif
      static_cast<uword>(arguments_descriptor.ptr()),
      static_cast<uword>(arguments.ptr()), thread));
#endif
}

#if defined(TESTING)
NO_SANITIZE_SAFE_STACK
ObjectPtr DartEntry::InvokeCode(const Code& code,
                                const Array& arguments_descriptor,
                                const Array& arguments,
                                Thread* thread) {
#if defined(DART_PRECOMPILER)
  if (FLAG_precompiled_mode) {
    FATAL("Should never invoke Dart code during AOT compilation");
  }
#endif

  ASSERT(!code.IsNull());
  ASSERT(thread->no_callback_scope_depth() == 0);
  ASSERT(!thread->isolate_group()->null_safety_not_set());

  DartEntryScope dart_entry_scope(thread);

  const uword stub = StubCode::InvokeDartCode().EntryPoint();
#if defined(DART_PRECOMPILED_RUNTIME)
#if defined(USING_SIMULATOR)
  return bit_copy<ObjectPtr, int64_t>(Simulator::Current()->Call(
      static_cast<intptr_t>(stub), static_cast<intptr_t>(code.EntryPoint()),
      static_cast<intptr_t>(arguments_descriptor.ptr()),
      static_cast<intptr_t>(arguments.ptr()),
      reinterpret_cast<intptr_t>(thread)));
#else
  return static_cast<ObjectPtr>((reinterpret_cast<invokestub>(stub))(
      code.EntryPoint(), arguments_descriptor.ptr(), arguments.ptr(), thread));
#endif
#else  // defined(DART_PRECOMPILED_RUNTIME)
#if defined(USING_SIMULATOR)
  return bit_copy<ObjectPtr, int64_t>(Simulator::Current()->Call(
      static_cast<intptr_t>(stub), static_cast<intptr_t>(code.ptr()),
      static_cast<intptr_t>(arguments_descriptor.ptr()),
      static_cast<intptr_t>(arguments.ptr()),
      reinterpret_cast<intptr_t>(thread)));
#else
  return static_cast<ObjectPtr>((reinterpret_cast<invokestub>(stub))(
      static_cast<uword>(code.ptr()),
      static_cast<uword>(arguments_descriptor.ptr()),
      static_cast<uword>(arguments.ptr()), thread));
#endif
#endif
}
#endif  // defined(TESTING)

ObjectPtr DartEntry::ResolveCallable(Thread* thread,
                                     const Array& arguments,
                                     const Array& arguments_descriptor) {
  auto isolate_group = thread->isolate_group();
  auto zone = thread->zone();

  const ArgumentsDescriptor args_desc(arguments_descriptor);
  const intptr_t receiver_index = args_desc.FirstArgIndex();
  const intptr_t type_args_len = args_desc.TypeArgsLen();
  const auto& getter_name = Symbols::GetCall();

  auto& instance = Instance::Handle(zone);
  auto& function = Function::Handle(zone);
  auto& cls = Class::Handle(zone);

  // The null instance cannot resolve to a callable, so we can stop there.
  for (instance ^= arguments.At(receiver_index); !instance.IsNull();
       instance ^= arguments.At(receiver_index)) {
    // The instance is a callable, so check that its function is compatible.
    if (instance.IsCallable(&function)) {
      bool matches = function.AreValidArguments(args_desc, nullptr);

      if (matches && type_args_len > 0 && function.IsClosureFunction()) {
        // Though the closure function is generic, the closure itself may
        // not be because it closes over delayed function type arguments.
        matches = Closure::Cast(instance).IsGeneric();
      }

      if (matches) {
        return function.ptr();
      }
    }

    // Special case: closures are implemented with a call getter instead of a
    // call method, so checking for a call getter would cause an infinite loop.
    if (instance.IsClosure()) {
      break;
    }

    cls = instance.clazz();
    // Find a call getter, if any, in the class hierarchy.
    function = Resolver::ResolveDynamicAnyArgs(zone, cls, getter_name,
                                               /*allow_add=*/false);
    if (function.IsNull()) {
      break;
    }
    if (!OSThread::Current()->HasStackHeadroom()) {
      const Instance& exception = Instance::Handle(
          zone, isolate_group->object_store()->stack_overflow());
      return UnhandledException::New(exception, StackTrace::Handle(zone));
    }

    const Array& getter_arguments = Array::Handle(zone, Array::New(1));
    getter_arguments.SetAt(0, instance);
    const Object& getter_result = Object::Handle(
        zone, DartEntry::InvokeFunction(function, getter_arguments));
    if (getter_result.IsError()) {
      return getter_result.ptr();
    }
    ASSERT(getter_result.IsNull() || getter_result.IsInstance());

    // We have a new possibly compatible callable, so set the first argument
    // accordingly so it gets picked up in the main loop.
    arguments.SetAt(receiver_index, getter_result);
  }

  // No compatible callable was found.
  return Function::null();
}

ObjectPtr DartEntry::InvokeCallable(Thread* thread,
                                    const Function& callable_function,
                                    const Array& arguments,
                                    const Array& arguments_descriptor) {
  auto const zone = thread->zone();
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  if (callable_function.IsNull()) {
    // No compatible callable was found, so invoke noSuchMethod.
    auto& instance =
        Instance::CheckedHandle(zone, arguments.At(args_desc.FirstArgIndex()));
    // For closures, use the name of the closure, not 'call'.
    const String* target_name = &Symbols::call();
    if (instance.IsClosure()) {
      auto const& function =
          Function::Handle(zone, Closure::Cast(instance).function());
      target_name = &String::Handle(function.QualifiedUserVisibleName());
    }
    return InvokeNoSuchMethod(thread, instance, *target_name, arguments,
                              arguments_descriptor);
  }

  const auto& result = Object::Handle(
      zone, callable_function.DoArgumentTypesMatch(arguments, args_desc));
  if (result.IsError()) {
    return result.ptr();
  }

  return InvokeFunction(callable_function, arguments, arguments_descriptor);
}

ObjectPtr DartEntry::InvokeClosure(Thread* thread, const Array& arguments) {
  auto const zone = thread->zone();
  const int kTypeArgsLen = 0;  // No support to pass type args to generic func.

  // Closures always have boxed parameters
  const Array& arguments_descriptor = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, arguments.Length()));
  return InvokeClosure(thread, arguments, arguments_descriptor);
}

ObjectPtr DartEntry::InvokeClosure(Thread* thread,
                                   const Array& arguments,
                                   const Array& arguments_descriptor) {
  auto const zone = thread->zone();
  const Object& resolved_result = Object::Handle(
      zone, ResolveCallable(thread, arguments, arguments_descriptor));
  if (resolved_result.IsError()) {
    return resolved_result.ptr();
  }

  const auto& function =
      Function::Handle(zone, Function::RawCast(resolved_result.ptr()));
  return InvokeCallable(thread, function, arguments, arguments_descriptor);
}

ObjectPtr DartEntry::InvokeNoSuchMethod(Thread* thread,
                                        const Instance& receiver,
                                        const String& target_name,
                                        const Array& arguments,
                                        const Array& arguments_descriptor) {
  auto const zone = thread->zone();
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  ASSERT(
      CompressedInstancePtr(receiver.ptr()).Decompress(thread->heap_base()) ==
      arguments.At(args_desc.FirstArgIndex()));
  // Allocate an Invocation object.
  const Library& core_lib = Library::Handle(zone, Library::CoreLibrary());

  Class& invocation_mirror_class = Class::Handle(
      zone, core_lib.LookupClass(String::Handle(
                zone, core_lib.PrivateName(Symbols::InvocationMirror()))));
  ASSERT(!invocation_mirror_class.IsNull());
  const auto& error = invocation_mirror_class.EnsureIsFinalized(thread);
  ASSERT(error == Error::null());
  const String& function_name = String::Handle(
      zone, core_lib.PrivateName(Symbols::AllocateInvocationMirror()));
  const Function& allocation_function = Function::Handle(
      zone, invocation_mirror_class.LookupStaticFunction(function_name));
  ASSERT(!allocation_function.IsNull());
  const int kNumAllocationArgs = 4;
  const Array& allocation_args =
      Array::Handle(zone, Array::New(kNumAllocationArgs));
  allocation_args.SetAt(0, target_name);
  allocation_args.SetAt(1, arguments_descriptor);
  allocation_args.SetAt(2, arguments);
  allocation_args.SetAt(3, Bool::False());  // Not a super invocation.
  const Object& invocation_mirror = Object::Handle(
      zone, InvokeFunction(allocation_function, allocation_args));
  if (invocation_mirror.IsError()) {
    Exceptions::PropagateError(Error::Cast(invocation_mirror));
    UNREACHABLE();
  }

  // Now use the invocation mirror object and invoke NoSuchMethod.
  const int kNumArguments = 2;
  const Function& function = Function::Handle(
      zone,
      core_lib.LookupFunctionAllowPrivate(Symbols::_objectNoSuchMethod()));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, receiver);
  args.SetAt(1, invocation_mirror);
  return InvokeFunction(function, args);
}

ArgumentsDescriptor::ArgumentsDescriptor(const Array& array) : array_(array) {}

intptr_t ArgumentsDescriptor::TypeArgsLen() const {
  return Smi::Value(Smi::RawCast(array_.At(kTypeArgsLenIndex)));
}

intptr_t ArgumentsDescriptor::Count() const {
  return Smi::Value(Smi::RawCast(array_.At(kCountIndex)));
}

intptr_t ArgumentsDescriptor::Size() const {
  return Smi::Value(Smi::RawCast(array_.At(kSizeIndex)));
}

intptr_t ArgumentsDescriptor::PositionalCount() const {
  return Smi::Value(Smi::RawCast(array_.At(kPositionalCountIndex)));
}

StringPtr ArgumentsDescriptor::NameAt(intptr_t index) const {
  const intptr_t offset =
      kFirstNamedEntryIndex + (index * kNamedEntrySize) + kNameOffset;
  String& result = String::Handle();
  result ^= array_.At(offset);
  return result.ptr();
}

intptr_t ArgumentsDescriptor::PositionAt(intptr_t index) const {
  const intptr_t offset =
      kFirstNamedEntryIndex + (index * kNamedEntrySize) + kPositionOffset;
  return Smi::Value(Smi::RawCast(array_.At(offset)));
}

bool ArgumentsDescriptor::MatchesNameAt(intptr_t index,
                                        const String& other) const {
  return NameAt(index) == other.ptr();
}

ArrayPtr ArgumentsDescriptor::GetArgumentNames() const {
  const intptr_t num_named_args = NamedCount();
  if (num_named_args == 0) {
    return Array::null();
  }

  Zone* zone = Thread::Current()->zone();
  const Array& names =
      Array::Handle(zone, Array::New(num_named_args, Heap::kOld));
  String& name = String::Handle(zone);
  const intptr_t num_pos_args = PositionalCount();
  for (intptr_t i = 0; i < num_named_args; ++i) {
    const intptr_t index = PositionAt(i) - num_pos_args;
    name = NameAt(i);
    ASSERT(names.At(index) == Object::null());
    names.SetAt(index, name);
  }
  return names.ptr();
}

void ArgumentsDescriptor::PrintTo(BaseTextBuffer* buffer,
                                  bool show_named_positions) const {
  if (TypeArgsLen() > 0) {
    buffer->Printf("<%" Pd ">", TypeArgsLen());
  }
  buffer->Printf("(%" Pd "", Count());
  if (NamedCount() > 0) {
    buffer->AddString(" {");
    auto& str = String::Handle();
    for (intptr_t i = 0; i < NamedCount(); i++) {
      if (i != 0) {
        buffer->AddString(", ");
      }
      str = NameAt(i);
      buffer->Printf("%s", str.ToCString());
      if (show_named_positions) {
        buffer->Printf(" (%" Pd ")", PositionAt(i));
      }
    }
    buffer->Printf("}");
  }
  buffer->Printf(")");
}

const char* ArgumentsDescriptor::ToCString() const {
  ZoneTextBuffer buf(Thread::Current()->zone());
  PrintTo(&buf);
  return buf.buffer();
}

ArrayPtr ArgumentsDescriptor::New(intptr_t type_args_len,
                                  intptr_t num_arguments,
                                  intptr_t size_arguments,
                                  const Array& optional_arguments_names,
                                  Heap::Space space) {
  const intptr_t num_named_args =
      optional_arguments_names.IsNull() ? 0 : optional_arguments_names.Length();
  if (num_named_args == 0) {
    return ArgumentsDescriptor::New(type_args_len, num_arguments,
                                    size_arguments, space);
  }
  ASSERT(type_args_len >= 0);
  ASSERT(num_arguments >= 0);
  const intptr_t num_pos_args = num_arguments - num_named_args;

  // Build the arguments descriptor array, which consists of the type
  // argument vector length (0 if none); total argument count; the positional
  // argument count; a sequence of (name, position) pairs, sorted by name, for
  // each named optional argument; and a terminating null to simplify iterating
  // in generated code.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const intptr_t descriptor_len = LengthFor(num_named_args);
  Array& descriptor = Array::Handle(zone, Array::New(descriptor_len, space));

  // Set length of type argument vector.
  descriptor.SetAt(kTypeArgsLenIndex, Smi::Handle(Smi::New(type_args_len)));
  // Set total number of passed arguments.
  descriptor.SetAt(kCountIndex, Smi::Handle(Smi::New(num_arguments)));
  // Set total number of passed arguments.
  descriptor.SetAt(kSizeIndex, Smi::Handle(Smi::New(size_arguments)));

  // Set number of positional arguments.
  descriptor.SetAt(kPositionalCountIndex, Smi::Handle(Smi::New(num_pos_args)));

  // Set alphabetically sorted entries for named arguments.
  String& name = String::Handle(zone);
  Smi& pos = Smi::Handle(zone);
  String& previous_name = String::Handle(zone);
  Smi& previous_pos = Smi::Handle(zone);
  for (intptr_t i = 0; i < num_named_args; i++) {
    name ^= optional_arguments_names.At(i);
    pos = Smi::New(num_pos_args + i);
    intptr_t insert_index = kFirstNamedEntryIndex + (kNamedEntrySize * i);
    // Shift already inserted pairs with "larger" names.
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
  descriptor ^= descriptor.Canonicalize(thread);
  ASSERT(!descriptor.IsNull());
  return descriptor.ptr();
}

ArrayPtr ArgumentsDescriptor::New(intptr_t type_args_len,
                                  intptr_t num_arguments,
                                  intptr_t size_arguments,
                                  Heap::Space space) {
  ASSERT(type_args_len >= 0);
  ASSERT(num_arguments >= 0);

  if ((type_args_len == 0) && (num_arguments < kCachedDescriptorCount) &&
      (num_arguments == size_arguments)) {
    return cached_args_descriptors_[num_arguments];
  }
  return NewNonCached(type_args_len, num_arguments, size_arguments, true,
                      space);
}

ArrayPtr ArgumentsDescriptor::NewNonCached(intptr_t type_args_len,
                                           intptr_t num_arguments,
                                           intptr_t size_arguments,
                                           bool canonicalize,
                                           Heap::Space space) {
  // Build the arguments descriptor array, which consists of the length of the
  // type argument vector, total argument count; the positional argument count;
  // and a terminating null to simplify iterating in generated code.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const intptr_t descriptor_len = LengthFor(0);
  Array& descriptor = Array::Handle(zone, Array::New(descriptor_len, space));
  const Smi& arg_count = Smi::Handle(zone, Smi::New(num_arguments));
  const Smi& arg_size = Smi::Handle(zone, Smi::New(size_arguments));

  // Set type argument vector length.
  descriptor.SetAt(kTypeArgsLenIndex,
                   Smi::Handle(zone, Smi::New(type_args_len)));

  // Set total number of passed arguments.
  descriptor.SetAt(kCountIndex, arg_count);

  // Set total size of passed arguments.
  descriptor.SetAt(kSizeIndex, arg_size);

  // Set number of positional arguments.
  descriptor.SetAt(kPositionalCountIndex, arg_count);

  // Set terminating null.
  descriptor.SetAt((descriptor_len - 1), Object::null_object());

  // Share the immutable descriptor when possible by canonicalizing it.
  descriptor.MakeImmutable();
  if (canonicalize) {
    descriptor ^= descriptor.Canonicalize(thread);
  }
  ASSERT(!descriptor.IsNull());
  return descriptor.ptr();
}

void ArgumentsDescriptor::Init() {
  for (int i = 0; i < kCachedDescriptorCount; i++) {
    cached_args_descriptors_[i] =
        NewNonCached(/*type_args_len=*/0, i, i, false, Heap::kOld);
  }
}

void ArgumentsDescriptor::Cleanup() {
  for (int i = 0; i < kCachedDescriptorCount; i++) {
    // Don't free pointers to RawArray objects managed by the VM.
    cached_args_descriptors_[i] = nullptr;
  }
}

ObjectPtr DartLibraryCalls::InstanceCreate(const Library& lib,
                                           const String& class_name,
                                           const String& constructor_name,
                                           const Array& arguments) {
  const Class& cls = Class::Handle(lib.LookupClassAllowPrivate(class_name));
  ASSERT(!cls.IsNull());
  // For now, we only support a non-parameterized or raw type.
  const int kNumExtraArgs = 1;  // implicit rcvr arg.
  const Instance& exception_object = Instance::Handle(Instance::New(cls));
  const Array& constructor_arguments =
      Array::Handle(Array::New(arguments.Length() + kNumExtraArgs));
  constructor_arguments.SetAt(0, exception_object);
  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < arguments.Length(); i++) {
    obj = arguments.At(i);
    constructor_arguments.SetAt((i + kNumExtraArgs), obj);
  }

  const String& function_name =
      String::Handle(String::Concat(class_name, constructor_name));
  const Function& constructor =
      Function::Handle(cls.LookupConstructorAllowPrivate(function_name));
  ASSERT(!constructor.IsNull());
  const Object& retval = Object::Handle(
      DartEntry::InvokeFunction(constructor, constructor_arguments));
  ASSERT(retval.IsNull() || retval.IsError());
  if (retval.IsError()) {
    return retval.ptr();
  }
  return exception_object.ptr();
}

ObjectPtr DartLibraryCalls::ToString(const Instance& receiver) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const auto& function = Function::Handle(
      zone,
      thread->isolate_group()->object_store()->_object_to_string_function());
  ASSERT(!function.IsNull());
  const int kNumArguments = 1;
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.ptr();
}

ObjectPtr DartLibraryCalls::HashCode(const Instance& receiver) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const auto& function = Function::Handle(
      zone,
      thread->isolate_group()->object_store()->_object_hash_code_function());
  ASSERT(!function.IsNull());
  const int kNumArguments = 1;
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.ptr();
}

ObjectPtr DartLibraryCalls::Equals(const Instance& left,
                                   const Instance& right) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const auto& function = Function::Handle(
      zone, thread->isolate_group()->object_store()->_object_equals_function());
  ASSERT(!function.IsNull());
  const int kNumArguments = 2;
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, left);
  args.SetAt(1, right);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.ptr();
}

ObjectPtr DartLibraryCalls::LookupHandler(Dart_Port port_id) {
  Thread* const thread = Thread::Current();
  Zone* const zone = thread->zone();
  const auto& function = Function::Handle(
      zone, thread->isolate_group()->object_store()->lookup_port_handler());
  ASSERT(!function.IsNull());
  Array& args = Array::Handle(
      zone, thread->isolate()->isolate_object_store()->dart_args_1());
  ASSERT(!args.IsNull());
  args.SetAt(0, Integer::Handle(zone, Integer::New(port_id)));
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  return result.ptr();
}

ObjectPtr DartLibraryCalls::LookupOpenPorts() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& function = Function::Handle(
      zone, thread->isolate_group()->object_store()->lookup_open_ports());
  ASSERT(!function.IsNull());
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeFunction(function, Object::empty_array()));
  return result.ptr();
}

static void DebuggerSetResumeIfStepping(Isolate* isolate) {
#if !defined(PRODUCT)
  if (isolate->debugger()->IsStepping()) {
    // If the isolate is being debugged and the debugger was stepping
    // through code, enable single stepping so debugger will stop
    // at the first location the user is interested in.
    isolate->debugger()->SetResumeAction(Debugger::kStepInto);
  }
#endif
}

ObjectPtr DartLibraryCalls::HandleMessage(Dart_Port port_id,
                                          const Instance& message) {
  auto* const thread = Thread::Current();
  auto* const zone = thread->zone();
  auto* const isolate = thread->isolate();
  auto* const object_store = thread->isolate_group()->object_store();
  const auto& function =
      Function::Handle(zone, object_store->handle_message_function());
  ASSERT(!function.IsNull());
  Array& args =
      Array::Handle(zone, isolate->isolate_object_store()->dart_args_2());
  ASSERT(!args.IsNull());
  args.SetAt(0, Integer::Handle(zone, Integer::New(port_id)));
  args.SetAt(1, message);
  DebuggerSetResumeIfStepping(isolate);
  const Object& handler =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  return handler.ptr();
}

ObjectPtr DartLibraryCalls::HandleFinalizerMessage(
    const FinalizerBase& finalizer) {
  if (FLAG_trace_finalizers) {
    THR_Print("Running finalizer %p callback on isolate %p\n",
              finalizer.ptr()->untag(), finalizer.isolate());
  }

  auto* const thread = Thread::Current();
  auto* const zone = thread->zone();
  auto* const isolate = thread->isolate();
  auto* const object_store = thread->isolate_group()->object_store();
  auto& function = Function::Handle(zone);
  if (finalizer.IsFinalizer()) {
    function ^= object_store->handle_finalizer_message_function();
  } else {
    ASSERT(finalizer.IsNativeFinalizer());
    function ^= object_store->handle_native_finalizer_message_function();
  }
  ASSERT(!function.IsNull());
  Array& args =
      Array::Handle(zone, isolate->isolate_object_store()->dart_args_1());
  ASSERT(!args.IsNull());
  args.SetAt(0, finalizer);
  DebuggerSetResumeIfStepping(isolate);
  const Object& handler =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  return handler.ptr();
}

ObjectPtr DartLibraryCalls::DrainMicrotaskQueue() {
  Zone* zone = Thread::Current()->zone();
  Library& isolate_lib = Library::Handle(zone, Library::IsolateLibrary());
  ASSERT(!isolate_lib.IsNull());
  Function& function =
      Function::Handle(zone, isolate_lib.LookupFunctionAllowPrivate(
                                 Symbols::_runPendingImmediateCallback()));
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeFunction(function, Object::empty_array()));
  ASSERT(result.IsNull() || result.IsError());
  return result.ptr();
}

ObjectPtr DartLibraryCalls::EnsureScheduleImmediate() {
  Zone* zone = Thread::Current()->zone();
  const Library& async_lib = Library::Handle(zone, Library::AsyncLibrary());
  ASSERT(!async_lib.IsNull());
  const Function& function =
      Function::Handle(zone, async_lib.LookupFunctionAllowPrivate(
                                 Symbols::_ensureScheduleImmediate()));
  ASSERT(!function.IsNull());
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeFunction(function, Object::empty_array()));
  ASSERT(result.IsNull() || result.IsError());
  return result.ptr();
}

static ObjectPtr RehashObjects(Zone* zone,
                               const Library& library,
                               const Object& array_or_growable_array) {
  ASSERT(array_or_growable_array.IsArray() ||
         array_or_growable_array.IsGrowableObjectArray());
  const auto& rehashing_function = Function::Handle(
      zone, library.LookupFunctionAllowPrivate(Symbols::_rehashObjects()));
  ASSERT(!rehashing_function.IsNull());

  const auto& arguments = Array::Handle(zone, Array::New(1));
  arguments.SetAt(0, array_or_growable_array);

  return DartEntry::InvokeFunction(rehashing_function, arguments);
}

ObjectPtr DartLibraryCalls::RehashObjectsInDartCollection(
    Thread* thread,
    const Object& array_or_growable_array) {
  auto zone = thread->zone();
  const auto& collections_lib =
      Library::Handle(zone, Library::CollectionLibrary());
  return RehashObjects(zone, collections_lib, array_or_growable_array);
}

ObjectPtr DartLibraryCalls::RehashObjectsInDartCore(
    Thread* thread,
    const Object& array_or_growable_array) {
  auto zone = thread->zone();
  const auto& core_lib = Library::Handle(zone, Library::CoreLibrary());
  return RehashObjects(zone, core_lib, array_or_growable_array);
}

}  // namespace dart
