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
class Simulator;
class Thread;

#if defined(TESTING) || defined(DEBUG)

#if defined(USING_SIMULATOR)
#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
    uword current_sp = Simulator::Current()->get_register(SPREG);              \
    ASSERT(Utils::IsAligned(current_sp, OS::ActivationFrameAlignment()));      \
  }
#elif defined(DART_HOST_OS_WINDOWS)
// The compiler may dynamically align the stack on Windows, so do not check.
#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
  }
#else
#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
    uword (*func)() = reinterpret_cast<uword (*)()>(                           \
        StubCode::GetCStackPointer().EntryPoint());                            \
    uword current_sp = func();                                                 \
    ASSERT(Utils::IsAligned(current_sp, OS::ActivationFrameAlignment()));      \
  }
#endif

#define DEOPTIMIZE_ALOT                                                        \
  if (FLAG_deoptimize_alot) {                                                  \
    DeoptimizeFunctionsOnStack();                                              \
  }

#else

#define CHECK_STACK_ALIGNMENT                                                  \
  {                                                                            \
  }
#define DEOPTIMIZE_ALOT                                                        \
  {                                                                            \
  }

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
 private:
  using ArgcBits = BitField<intptr_t, int32_t, 0, 24>;
  using GenericFunctionBit = BitField<intptr_t, bool, ArgcBits::kNextBit>;
  using ReverseArgOrderBit =
      BitField<intptr_t, bool, GenericFunctionBit::kNextBit>;

 public:
  Thread* thread() const { return thread_; }

  // Includes type arguments vector.
  int ArgCount() const { return ArgcBits::decode(argc_tag_); }

  ObjectPtr ArgAt(int index) const {
    ASSERT((index >= 0) && (index < ArgCount()));
    ObjectPtr* arg_ptr =
        &(argv_[ReverseArgOrderBit::decode(argc_tag_) ? index : -index]);
    // Tell MemorySanitizer the ObjectPtr was initialized (by generated code).
    MSAN_UNPOISON(arg_ptr, kWordSize);
    return *arg_ptr;
  }

  void SetArgAt(int index, const Object& value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    ASSERT((index >= 0) && (index < ArgCount()));
    argv_[ReverseArgOrderBit::decode(argc_tag_) ? index : -index] = value.ptr();
  }

  // Does not include hidden type arguments vector.
  int NativeArgCount() const { return ArgCount() - NumHiddenArgs(); }

  ObjectPtr NativeArg0() const { return ArgAt(NumHiddenArgs()); }

  ObjectPtr NativeArgAt(int index) const {
    ASSERT((index >= 0) && (index < NativeArgCount()));
    return ArgAt(index + NumHiddenArgs());
  }

  TypeArgumentsPtr NativeTypeArgs() const {
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

  AbstractTypePtr NativeTypeArgAt(int index) const {
    ASSERT((index >= 0) && (index < NativeTypeArgCount()));
    TypeArguments& type_args = TypeArguments::Handle(NativeTypeArgs());
    if (type_args.IsNull()) {
      // null vector represents infinite list of dynamics
      return Type::dynamic_type().ptr();
    }
    return type_args.TypeAt(index);
  }

  void SetReturn(const Object& value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    *retval_ = value.ptr();
  }

  ObjectPtr ReturnValue() const {
    // Tell MemorySanitizer the retval_ was initialized (by generated code).
    MSAN_UNPOISON(retval_, kWordSize);
    return *retval_;
  }

  uword GetCallerSP() const { return reinterpret_cast<uword>(retval_ + 1); }

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
    ASSERT(function.is_old_native());
    ASSERT(!function.IsGenerativeConstructor());  // Not supported.
    ASSERT(!function.IsClosureFunction());        // Not supported.
    return function.NumParameters();
  }

  static int ComputeArgcTag(const Function& function) {
    ASSERT(function.is_old_native());
    ASSERT(!function.IsGenerativeConstructor());  // Not supported.
    ASSERT(!function.IsClosureFunction());        // Not supported.
    bool is_generic = function.IsGeneric();
    return ArgcBits::encode(function.NumParameters() + (is_generic ? 1 : 0)) |
           GenericFunctionBit::encode(is_generic);
  }

 private:
  friend class Api;
  friend class Interpreter;
  friend class NativeEntry;
  friend class Simulator;

#if defined(DART_DYNAMIC_MODULES)
  NativeArguments(Thread* thread,
                  int argc_tag,
                  ObjectPtr* argv,
                  ObjectPtr* retval)
      : thread_(thread),
        argc_tag_(ReverseArgOrderBit::update(true, argc_tag)),
        argv_(argv),
        retval_(retval) {}
#endif  // defined(DART_DYNAMIC_MODULES)

  // Since this function is passed an ObjectPtr directly, we need to be
  // exceedingly careful when we use it.  If there are any other side
  // effects in the statement that may cause GC, it could lead to
  // bugs.
  void SetReturnUnsafe(ObjectPtr value) const {
    ASSERT(thread_->execution_state() == Thread::kThreadInVM);
    *retval_ = value;
  }

  // Returns true if the arguments are those of a generic function call.
  bool ToGenericFunction() const {
    return GenericFunctionBit::decode(argc_tag_);
  }

  int NumHiddenArgs() const {
    return GenericFunctionBit::decode(argc_tag_) ? 1 : 0;
  }

  Thread* thread_;     // Current thread pointer.
  intptr_t argc_tag_;  // Encodes argument count and invoked native call type.
  ObjectPtr* argv_;    // Pointer to an array of arguments to runtime call.
  ObjectPtr* retval_;  // Pointer to the return value area.
};

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_ARGUMENTS_H_
