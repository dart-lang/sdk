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
  ASSERT(Thread::Current()->IsMutatorThread());
  const int kTypeArgsLen = 0;  // No support to pass type args to generic func.
  const Array& arguments_descriptor = Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, arguments.Length()));
  return InvokeFunction(function, arguments, arguments_descriptor);
}

class ScopedIsolateStackLimits : public ValueObject {
 public:
  NO_SANITIZE_SAFE_STACK
  explicit ScopedIsolateStackLimits(Thread* thread, uword current_sp)
      : thread_(thread) {
    ASSERT(thread != NULL);
    // Save the Thread's current stack limit and adjust the stack limit.
    ASSERT(thread->isolate() == Isolate::Current());
    saved_stack_limit_ = thread->saved_stack_limit();
#if defined(USING_SIMULATOR)
    thread->SetStackLimit(Simulator::Current()->overflow_stack_limit());
#else
    thread->SetStackLimit(OSThread::Current()->overflow_stack_limit());
#endif

#if defined(USING_SAFE_STACK)
    saved_safestack_limit_ = OSThread::GetCurrentSafestackPointer();
    thread->set_saved_safestack_limit(saved_safestack_limit_);
#endif
  }

  ~ScopedIsolateStackLimits() {
    ASSERT(thread_->isolate() == Isolate::Current());
    // Since we started with a stack limit of 0 we should be getting back
    // to a stack limit of 0 when all nested invocations are done and
    // we have bottomed out.
    thread_->SetStackLimit(saved_stack_limit_);
#if defined(USING_SAFE_STACK)
    thread_->set_saved_safestack_limit(saved_safestack_limit_);
#endif
  }

 private:
  Thread* thread_;
#if defined(USING_SAFE_STACK)
  uword saved_safestack_limit_ = 0;
#endif
  uword saved_stack_limit_ = 0;
};

// Clears/restores Thread::long_jump_base on construction/destruction.
// Ensures that we do not attempt to long jump across Dart frames.
class SuspendLongJumpScope : public ThreadStackResource {
 public:
  explicit SuspendLongJumpScope(Thread* thread)
      : ThreadStackResource(thread),
        saved_long_jump_base_(thread->long_jump_base()) {
    thread->set_long_jump_base(NULL);
  }

  ~SuspendLongJumpScope() {
    ASSERT(thread()->long_jump_base() == NULL);
    thread()->set_long_jump_base(saved_long_jump_base_);
  }

 private:
  LongJumpScope* saved_long_jump_base_;
};

ObjectPtr DartEntry::InvokeFunction(const Function& function,
                                    const Array& arguments,
                                    const Array& arguments_descriptor,
                                    uword current_sp) {
  // We use a kernel2kernel constant evaluator in Dart 2.0 AOT compilation
  // and never start the VM service isolate. So we should never end up invoking
  // any dart code in the Dart 2.0 AOT compiler.
  if (FLAG_precompiled_mode) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    UNREACHABLE();
#else
    if (FLAG_use_bare_instructions) {
      Thread* thread = Thread::Current();
      thread->set_global_object_pool(
          thread->isolate()->object_store()->global_object_pool());
      const DispatchTable* dispatch_table = thread->isolate()->dispatch_table();
      if (dispatch_table != nullptr) {
        thread->set_dispatch_table_array(dispatch_table->ArrayOrigin());
      }
      ASSERT(thread->global_object_pool() != Object::null());
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }

  ASSERT(!function.IsNull());

  // Get the entrypoint corresponding to the function specified, this
  // will result in a compilation of the function if it is not already
  // compiled.
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(thread->IsMutatorThread());
  ScopedIsolateStackLimits stack_limit(thread, current_sp);
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (!function.HasCode()) {
    const Object& result =
        Object::Handle(zone, Compiler::CompileFunction(thread, function));
    if (result.IsError()) {
      return Error::Cast(result).raw();
    }

    // At this point we should have native code.
    ASSERT(function.HasCode());
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Now Call the invoke stub which will invoke the dart function.
  const Code& code = Code::Handle(zone, function.CurrentCode());
  return InvokeCode(code, arguments_descriptor, arguments, thread);
}

extern "C" {
// Note: The invocation stub follows the C ABI, so we cannot pass C++ struct
// values like ObjectPtr. In some calling conventions (IA32), ObjectPtr is
// passed/returned different from a pointer.
typedef uword /*ObjectPtr*/ (*invokestub)(const Code& target_code,
                                          const Array& arguments_descriptor,
                                          const Array& arguments,
                                          Thread* thread);
}

NO_SANITIZE_SAFE_STACK
ObjectPtr DartEntry::InvokeCode(const Code& code,
                                const Array& arguments_descriptor,
                                const Array& arguments,
                                Thread* thread) {
  ASSERT(!code.IsNull());
  ASSERT(thread->no_callback_scope_depth() == 0);
  ASSERT(!Isolate::Current()->null_safety_not_set());

  invokestub entrypoint =
      reinterpret_cast<invokestub>(StubCode::InvokeDartCode().EntryPoint());
  SuspendLongJumpScope suspend_long_jump_scope(thread);
  TransitionToGenerated transition(thread);
#if defined(USING_SIMULATOR)
  return bit_copy<ObjectPtr, int64_t>(Simulator::Current()->Call(
      reinterpret_cast<intptr_t>(entrypoint), reinterpret_cast<intptr_t>(&code),
      reinterpret_cast<intptr_t>(&arguments_descriptor),
      reinterpret_cast<intptr_t>(&arguments),
      reinterpret_cast<intptr_t>(thread)));
#else
  return static_cast<ObjectPtr>(
      entrypoint(code, arguments_descriptor, arguments, thread));
#endif
}

ObjectPtr DartEntry::ResolveCallable(Thread* thread,
                                     const Array& arguments,
                                     const Array& arguments_descriptor) {
  auto isolate = thread->isolate();
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
        matches = Closure::Cast(instance).IsGeneric(thread);
      }

      if (matches) {
        return function.raw();
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
      const Instance& exception =
          Instance::Handle(zone, isolate->object_store()->stack_overflow());
      return UnhandledException::New(exception, StackTrace::Handle(zone));
    }

    const Array& getter_arguments = Array::Handle(zone, Array::New(1));
    getter_arguments.SetAt(0, instance);
    const Object& getter_result = Object::Handle(
        zone, DartEntry::InvokeFunction(function, getter_arguments));
    if (getter_result.IsError()) {
      return getter_result.raw();
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
    const String* target_name = &Symbols::Call();
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
    Exceptions::PropagateError(Error::Cast(result));
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
    return resolved_result.raw();
  }

  const auto& function =
      Function::Handle(zone, Function::RawCast(resolved_result.raw()));
  return InvokeCallable(thread, function, arguments, arguments_descriptor);
}

ObjectPtr DartEntry::InvokeNoSuchMethod(Thread* thread,
                                        const Instance& receiver,
                                        const String& target_name,
                                        const Array& arguments,
                                        const Array& arguments_descriptor) {
  auto const zone = thread->zone();
  const ArgumentsDescriptor args_desc(arguments_descriptor);
  ASSERT(receiver.raw() == arguments.At(args_desc.FirstArgIndex()));
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
  const int kTypeArgsLen = 0;
  const int kNumArguments = 2;
  const ArgumentsDescriptor nsm_args_desc(Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  Function& function = Function::Handle(
      zone, Resolver::ResolveDynamic(receiver, Symbols::NoSuchMethod(),
                                     nsm_args_desc));
  if (function.IsNull()) {
    ASSERT(!FLAG_lazy_dispatchers);
    // If noSuchMethod(invocation) is not found, call Object::noSuchMethod.
    function = Resolver::ResolveDynamicForReceiverClass(
        Class::Handle(zone, thread->isolate()->object_store()->object_class()),
        Symbols::NoSuchMethod(), nsm_args_desc);
  }
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
  return result.raw();
}

intptr_t ArgumentsDescriptor::PositionAt(intptr_t index) const {
  const intptr_t offset =
      kFirstNamedEntryIndex + (index * kNamedEntrySize) + kPositionOffset;
  return Smi::Value(Smi::RawCast(array_.At(offset)));
}

bool ArgumentsDescriptor::MatchesNameAt(intptr_t index,
                                        const String& other) const {
  return NameAt(index) == other.raw();
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
  return names.raw();
}

void ArgumentsDescriptor::PrintTo(BaseTextBuffer* buffer) const {
  buffer->Printf("%" Pd " arg%s", Count(), Count() == 1 ? "" : "s");
  if (TypeArgsLen() > 0) {
    buffer->Printf(", %" Pd " type arg%s", TypeArgsLen(),
                   TypeArgsLen() == 1 ? "" : "s");
  }
  if (NamedCount() > 0) {
    buffer->AddString(", names [");
    auto& str = String::Handle();
    for (intptr_t i = 0; i < NamedCount(); i++) {
      if (i != 0) {
        buffer->AddString(", ");
      }
      str = NameAt(i);
      buffer->Printf("'%s' (%" Pd ")", str.ToCString(), PositionAt(i));
    }
    buffer->Printf("]");
  }
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

  // Build the arguments descriptor array, which consists of the the type
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
  return descriptor.raw();
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
  return descriptor.raw();
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
    cached_args_descriptors_[i] = NULL;
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
    return retval.raw();
  }
  return exception_object.raw();
}

ObjectPtr DartLibraryCalls::ToString(const Instance& receiver) {
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;  // Receiver.
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Class& receiver_class = Class::Handle(receiver.clazz());
  const auto& error = receiver_class.EnsureIsFinalized(Thread::Current());
  ASSERT(error == Error::null());
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver, Symbols::toString(), args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}

ObjectPtr DartLibraryCalls::HashCode(const Instance& receiver) {
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;  // Receiver.
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(receiver, Symbols::hashCode(), args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, receiver);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}

ObjectPtr DartLibraryCalls::Equals(const Instance& left,
                                   const Instance& right) {
  const int kTypeArgsLen = 0;
  const int kNumArguments = 2;
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(left, Symbols::EqualOperator(), args_desc));
  ASSERT(!function.IsNull());

  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, left);
  args.SetAt(1, right);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}

// On success, returns a RawInstance.  On failure, a RawError.
ObjectPtr DartLibraryCalls::IdentityHashCode(const Instance& object) {
  const int kNumArguments = 1;
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& libcore = Library::Handle(zone, Library::CoreLibrary());
  ASSERT(!libcore.IsNull());
  const Function& function = Function::Handle(
      zone, libcore.LookupFunctionAllowPrivate(Symbols::identityHashCode()));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(zone, Array::New(kNumArguments));
  args.SetAt(0, object);
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsInstance() || result.IsError());
  return result.raw();
}

ObjectPtr DartLibraryCalls::LookupHandler(Dart_Port port_id) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& function = Function::Handle(
      zone, thread->isolate()->object_store()->lookup_port_handler());
  const int kTypeArgsLen = 0;
  const int kNumArguments = 1;
  if (function.IsNull()) {
    Library& isolate_lib = Library::Handle(zone, Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_lookupHandler()));
    function = Resolver::ResolveStatic(isolate_lib, class_name, function_name,
                                       kTypeArgsLen, kNumArguments,
                                       Object::empty_array());
    ASSERT(!function.IsNull());
    thread->isolate()->object_store()->set_lookup_port_handler(function);
  }
  Array& args = Array::Handle(
      zone, thread->isolate()->isolate_object_store()->dart_args_1());
  if (args.IsNull()) {
    args = Array::New(kNumArguments);
    thread->isolate()->isolate_object_store()->set_dart_args_1(args);
  }
  args.SetAt(0, Integer::Handle(zone, Integer::New(port_id)));
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  return result.raw();
}

ObjectPtr DartLibraryCalls::LookupOpenPorts() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Function& function = Function::Handle(
      zone, thread->isolate()->object_store()->lookup_open_ports());
  const int kTypeArgsLen = 0;
  const int kNumArguments = 0;
  if (function.IsNull()) {
    Library& isolate_lib = Library::Handle(zone, Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_lookupOpenPorts()));
    function = Resolver::ResolveStatic(isolate_lib, class_name, function_name,
                                       kTypeArgsLen, kNumArguments,
                                       Object::empty_array());
    ASSERT(!function.IsNull());
    thread->isolate()->object_store()->set_lookup_open_ports(function);
  }
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeFunction(function, Object::empty_array()));
  return result.raw();
}

ObjectPtr DartLibraryCalls::HandleMessage(const Object& handler,
                                          const Instance& message) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  Function& function = Function::Handle(
      zone, isolate->object_store()->handle_message_function());
  const int kTypeArgsLen = 0;
  const int kNumArguments = 2;
  if (function.IsNull()) {
    Library& isolate_lib = Library::Handle(zone, Library::IsolateLibrary());
    ASSERT(!isolate_lib.IsNull());
    const String& class_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_RawReceivePortImpl()));
    const String& function_name = String::Handle(
        zone, isolate_lib.PrivateName(Symbols::_handleMessage()));
    function = Resolver::ResolveStatic(isolate_lib, class_name, function_name,
                                       kTypeArgsLen, kNumArguments,
                                       Object::empty_array());
    ASSERT(!function.IsNull());
    isolate->object_store()->set_handle_message_function(function);
  }
  Array& args = Array::Handle(
      zone, thread->isolate()->isolate_object_store()->dart_args_2());
  if (args.IsNull()) {
    args = Array::New(kNumArguments);
    thread->isolate()->isolate_object_store()->set_dart_args_2(args);
  }
  args.SetAt(0, handler);
  args.SetAt(1, message);
#if !defined(PRODUCT)
  if (isolate->debugger()->IsStepping()) {
    // If the isolate is being debugged and the debugger was stepping
    // through code, enable single stepping so debugger will stop
    // at the first location the user is interested in.
    isolate->debugger()->SetResumeAction(Debugger::kStepInto);
  }
#endif
  const Object& result =
      Object::Handle(zone, DartEntry::InvokeFunction(function, args));
  ASSERT(result.IsNull() || result.IsError());
  return result.raw();
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
  return result.raw();
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
  return result.raw();
}

ObjectPtr DartLibraryCalls::MapSetAt(const Instance& map,
                                     const Instance& key,
                                     const Instance& value) {
  const int kTypeArgsLen = 0;
  const int kNumArguments = 3;
  ArgumentsDescriptor args_desc(Array::Handle(
      ArgumentsDescriptor::NewBoxed(kTypeArgsLen, kNumArguments)));
  const Function& function = Function::Handle(
      Resolver::ResolveDynamic(map, Symbols::AssignIndexToken(), args_desc));
  ASSERT(!function.IsNull());
  const Array& args = Array::Handle(Array::New(kNumArguments));
  args.SetAt(0, map);
  args.SetAt(1, key);
  args.SetAt(2, value);
  const Object& result =
      Object::Handle(DartEntry::InvokeFunction(function, args));
  return result.raw();
}

}  // namespace dart
