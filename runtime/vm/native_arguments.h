// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_NATIVE_ARGUMENTS_H_
#define RUNTIME_VM_NATIVE_ARGUMENTS_H_

#include "platform/assert.h"
#include "platform/memory_sanitizer.h"
#include "vm/globals.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

// Forward declarations.
class BootstrapNatives;
class Object;
class RawObject;
class Simulator;
class Thread;

#if defined(TESTING) || defined(DEBUG)

#if defined(TARGET_ARCH_DBC)
// C-stack is always aligned on DBC because we don't have any native code.
#define CHECK_STACK_ALIGNMENT
#elif defined(USING_SIMULATOR)
#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
    uword current_sp = Simulator::Current()->get_register(SPREG);              \
    ASSERT(Utils::IsAligned(current_sp, OS::ActivationFrameAlignment()));      \
  }
#elif defined(HOST_OS_WINDOWS)
// The compiler may dynamically align the stack on Windows, so do not check.
#define CHECK_STACK_ALIGNMENT                                                  \
  {}
#else
#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
    uword (*func)() = reinterpret_cast<uword (*)()>(                           \
        StubCode::GetCStackPointer().EntryPoint());                            \
    uword current_sp = func();                                                 \
    ASSERT(Utils::IsAligned(current_sp, OS::ActivationFrameAlignment()));      \
  }
#endif

void VerifyOnTransition();

#define VERIFY_ON_TRANSITION                                                   \
  if (FLAG_verify_on_transition) {                                             \
    VerifyOnTransition();                                                      \
  }
#define DEOPTIMIZE_ALOT                                                        \
  if (FLAG_deoptimize_alot) {                                                  \
    DeoptimizeFunctionsOnStack();                                              \
  }

#else

#define CHECK_STACK_ALIGNMENT                                                  \
  {}
#define VERIFY_ON_TRANSITION                                                   \
  {}
#define DEOPTIMIZE_ALOT                                                        \
  {}

#endif

// Class NativeArguments is used to access arguments passed in from
// generated dart code to a runtime function or a dart library native
// function. It is also used to set the return value if any at the slot
// reserved for return values.
// All runtime function/dart library native functions have the
// following signature:
//   void function_name(NativeArguments arguments);
// Inside the function, arguments are accessed as follows:
//   const Instance& arg0 = Instance::CheckedHandle(arguments.NativeArgAt(0));
//   const Smi& arg1 = Smi::CheckedHandle(arguments.NativeArgAt(1));
// If the function is generic, type arguments are accessed as follows:
//   const TypeArguments& type_args =
//       TypeArguments::Handle(arguments.NativeTypeArgs());
// The return value is set as follows:
//   arguments.SetReturn(result);
// NOTE: Since we pass 'this' as a pass-by-value argument in the stubs we don't
// have DISALLOW_COPY_AND_ASSIGN in the class definition and do not make it a
// subclass of ValueObject.
class NativeArguments {
 public:
  Thread* thread() const { return thread_; }

  // Includes type arguments vector.
  int ArgCount() const { return ArgcBits::decode(argc_tag_); }

  RawObject* ArgAt(int index) const {
    ASSERT((index >= 0) && (index < ArgCount()));
    RawObject** arg_ptr =
        &(argv_[ReverseArgOrderBit::decode(argc_tag_) ? index : -index]);
    // Tell MemorySanitizer the RawObject* was initialized (by generated code).
    MSAN_UNPOISON(arg_ptr, kWordSize);
    return *arg_ptr;
  }

  void SetArgAt(int index, const Object& value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    ASSERT((index >= 0) && (index < ArgCount()));
    RawObject** arg_ptr =
        &(argv_[ReverseArgOrderBit::decode(argc_tag_) ? index : -index]);
    *arg_ptr = value.raw();
  }

  // Does not include hidden type arguments vector.
  int NativeArgCount() const {
    int function_bits = FunctionBits::decode(argc_tag_);
    return ArgCount() - NumHiddenArgs(function_bits);
  }

  RawObject* NativeArg0() const {
    int function_bits = FunctionBits::decode(argc_tag_);
    if ((function_bits & (kClosureFunctionBit | kInstanceFunctionBit)) ==
        (kClosureFunctionBit | kInstanceFunctionBit)) {
      // Retrieve the receiver from the context.
      const int closure_index = (function_bits & kGenericFunctionBit) ? 1 : 0;
      const Object& closure = Object::Handle(ArgAt(closure_index));
      const Context& context =
          Context::Handle(Closure::Cast(closure).context());
      return context.At(0);
    }
    return ArgAt(NumHiddenArgs(function_bits));
  }

  RawObject* NativeArgAt(int index) const {
    ASSERT((index >= 0) && (index < NativeArgCount()));
    if (index == 0) {
      return NativeArg0();
    }
    int function_bits = FunctionBits::decode(argc_tag_);
    const int actual_index = index + NumHiddenArgs(function_bits);
    return ArgAt(actual_index);
  }

  RawTypeArguments* NativeTypeArgs() const {
    ASSERT(ToGenericFunction());
    return TypeArguments::RawCast(ArgAt(0));
  }

  int NativeTypeArgCount() const {
    if (ToGenericFunction()) {
      TypeArguments& type_args = TypeArguments::Handle(NativeTypeArgs());
      if (type_args.IsNull()) {
        // null vector represents infinite list of dynamics
        return INT_MAX;
      }
      return type_args.Length();
    }
    return 0;
  }

  RawAbstractType* NativeTypeArgAt(int index) const {
    ASSERT((index >= 0) && (index < NativeTypeArgCount()));
    TypeArguments& type_args = TypeArguments::Handle(NativeTypeArgs());
    if (type_args.IsNull()) {
      // null vector represents infinite list of dynamics
      return Type::dynamic_type().raw();
    }
    return type_args.TypeAt(index);
  }

  void SetReturn(const Object& value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    *retval_ = value.raw();
  }

  RawObject* ReturnValue() const {
    // Tell MemorySanitizer the retval_ was initialized (by generated code).
    MSAN_UNPOISON(retval_, kWordSize);
    return *retval_;
  }

  static intptr_t thread_offset() {
    return OFFSET_OF(NativeArguments, thread_);
  }
  static intptr_t argc_tag_offset() {
    return OFFSET_OF(NativeArguments, argc_tag_);
  }
  static intptr_t argv_offset() { return OFFSET_OF(NativeArguments, argv_); }
  static intptr_t retval_offset() {
    return OFFSET_OF(NativeArguments, retval_);
  }

  static intptr_t ParameterCountForResolution(const Function& function) {
    ASSERT(function.is_native());
    ASSERT(!function.IsGenerativeConstructor());  // Not supported.
    intptr_t count = function.NumParameters();
    if (function.is_static() && function.IsClosureFunction()) {
      // The closure object is hidden and not accessible from native code.
      // However, if the function is an instance closure function, the captured
      // receiver located in the context is made accessible in native code at
      // index 0, thereby hiding the closure object at index 0.
      count--;
    }
    return count;
  }

  static int ComputeArgcTag(const Function& function) {
    ASSERT(function.is_native());
    ASSERT(!function.IsGenerativeConstructor());  // Not supported.
    int argc = function.NumParameters();
    int function_bits = 0;
    if (!function.is_static()) {
      function_bits |= kInstanceFunctionBit;
    }
    if (function.IsClosureFunction()) {
      function_bits |= kClosureFunctionBit;
    }
    if (function.IsGeneric()) {
      function_bits |= kGenericFunctionBit;
      argc++;
    }
    int tag = ArgcBits::encode(argc);
    tag = FunctionBits::update(function_bits, tag);
    return tag;
  }

 private:
  enum {
    kInstanceFunctionBit = 1,
    kClosureFunctionBit = 2,
    kGenericFunctionBit = 4,
  };
  enum ArgcTagBits {
    kArgcBit = 0,
    kArgcSize = 24,
    kFunctionBit = kArgcBit + kArgcSize,
    kFunctionSize = 3,
    kReverseArgOrderBit = kFunctionBit + kFunctionSize,
    kReverseArgOrderSize = 1,
  };
  class ArgcBits : public BitField<intptr_t, int32_t, kArgcBit, kArgcSize> {};
  class FunctionBits
      : public BitField<intptr_t, int, kFunctionBit, kFunctionSize> {};
  class ReverseArgOrderBit
      : public BitField<intptr_t, bool, kReverseArgOrderBit, 1> {};
  friend class Api;
  friend class BootstrapNatives;
  friend class Interpreter;
  friend class Simulator;

  // Allow simulator and interpreter to create NativeArguments in reverse order
  // on the stack.
  NativeArguments(Thread* thread,
                  int argc_tag,
                  RawObject** argv,
                  RawObject** retval)
      : thread_(thread),
        argc_tag_(ReverseArgOrderBit::update(true, argc_tag)),
        argv_(argv),
        retval_(retval) {}

  // Since this function is passed a RawObject directly, we need to be
  // exceedingly careful when we use it.  If there are any other side
  // effects in the statement that may cause GC, it could lead to
  // bugs.
  void SetReturnUnsafe(RawObject* value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    *retval_ = value;
  }

  // Returns true if the arguments are those of an instance function call.
  bool ToInstanceFunction() const {
    return (FunctionBits::decode(argc_tag_) & kInstanceFunctionBit);
  }

  // Returns true if the arguments are those of a closure function call.
  bool ToClosureFunction() const {
    return (FunctionBits::decode(argc_tag_) & kClosureFunctionBit);
  }

  // Returns true if the arguments are those of a generic function call.
  bool ToGenericFunction() const {
    return (FunctionBits::decode(argc_tag_) & kGenericFunctionBit);
  }

  int NumHiddenArgs(int function_bits) const {
    int num_hidden_args = 0;
    // For static closure functions, the closure at index 0 is hidden.
    // In the instance closure function case, the receiver is accessed from
    // the context and the closure at index 0 is hidden, so the apparent
    // argument count remains unchanged.
    if ((function_bits & kClosureFunctionBit) == kClosureFunctionBit) {
      num_hidden_args++;
    }
    if ((function_bits & kGenericFunctionBit) == kGenericFunctionBit) {
      num_hidden_args++;
    }
    return num_hidden_args;
  }

  Thread* thread_;      // Current thread pointer.
  intptr_t argc_tag_;   // Encodes argument count and invoked native call type.
  RawObject** argv_;    // Pointer to an array of arguments to runtime call.
  RawObject** retval_;  // Pointer to the return value area.
};

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_ARGUMENTS_H_
