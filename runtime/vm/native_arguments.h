// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_ARGUMENTS_H_
#define VM_NATIVE_ARGUMENTS_H_

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/stub_code.h"

namespace dart {

// Forward declarations.
class BootstrapNatives;
class Isolate;
class Object;
class RawObject;


#if defined(TESTING) || defined(DEBUG)

#if defined(TARGET_OS_WINDOWS)
// The compiler may dynamically align the stack on Windows, so do not check.
#define CHECK_STACK_ALIGNMENT { }
#else
#define CHECK_STACK_ALIGNMENT {                                                \
  uword (*func)() =                                                            \
      reinterpret_cast<uword (*)()>(StubCode::GetStackPointerEntryPoint());    \
  uword current_sp = func();                                                   \
  ASSERT((OS::ActivationFrameAlignment() == 0) ||                              \
         (Utils::IsAligned(current_sp, OS::ActivationFrameAlignment())));      \
}
#endif

#else

#define CHECK_STACK_ALIGNMENT { }

#endif

void SetReturnValueHelper(Dart_NativeArguments, Dart_Handle);


// Class NativeArguments is used to access arguments passed in from
// generated dart code to a runtime function or a dart library native
// function. It is also used to set the return value if any at the slot
// reserved for return values.
// All runtime function/dart library native functions have the
// following signature:
//   void function_name(NativeArguments arguments);
// Inside the function, arguments are accessed as follows:
//   const Instance& arg0 = Instance::CheckedHandle(arguments.At(0));
//   const Smi& arg1 = Smi::CheckedHandle(arguments.At(1));
// The return value is set as follows:
//   arguments.SetReturn(result);
// NOTE: Since we pass 'this' as a pass-by-value argument in the stubs we don't
// have DISALLOW_COPY_AND_ASSIGN in the class definition and do not make it a
// subclass of ValueObject.
class NativeArguments {
 public:
  Isolate* isolate() const { return isolate_; }
  int ArgCount() const { return ArgcBits::decode(argc_tag_); }

  // Returns true if the arguments are those of an instance function call.
  bool ToInstanceFunction() const {
    return InstanceFunctionBit::decode(argc_tag_);
  }

  // Returns true if the arguments are those of a closure function call.
  bool ToClosureFunction() const {
    return ClosureFunctionBit::decode(argc_tag_);
  }

  RawObject* ArgAt(int index) const {
    ASSERT((index >= 0) && (index < ArgCount()));
    return (*argv_)[-index];
  }

  int NumHiddenArgs() const {
    // For static closure functions, the closure at index 0 is hidden.
    // In the instance closure function case, the receiver is accessed from
    // the context and the closure at index 0 is hidden, so the apparent
    // argument count remains unchanged.
    if (ToClosureFunction() && !ToInstanceFunction()) {
      return 1;
    }
    return 0;
  }

  int NativeArgCount() const {
    return ArgCount() - NumHiddenArgs();
  }

  RawObject* NativeArgAt(int index) const {
    ASSERT((index >= 0) && (index < NativeArgCount()));
    if ((index == 0) && ToClosureFunction() && ToInstanceFunction()) {
      // Retrieve the receiver from the context.
      const Context& context = Context::Handle(isolate_->top_context());
      return context.At(0);
    } else {
      const int actual_index = index + NumHiddenArgs();
      return ArgAt(actual_index);
    }
  }

  void SetReturn(const Object& value) const;

  static intptr_t isolate_offset() {
    return OFFSET_OF(NativeArguments, isolate_);
  }
  static intptr_t argc_tag_offset() {
    return OFFSET_OF(NativeArguments, argc_tag_);
  }
  static intptr_t argv_offset() { return OFFSET_OF(NativeArguments, argv_); }
  static intptr_t retval_offset() {
    return OFFSET_OF(NativeArguments, retval_);
  }

  static int ParameterCountForResolution(const Function& function) {
    ASSERT(function.is_native());
    ASSERT(!function.IsConstructor());  // Not supported.
    int count = function.NumParameters();
    if (function.is_static() && function.IsClosureFunction()) {
      // The closure object is hidden and not accessible from native code.
      // However, if the function is an instance closure function, the captured
      // receiver located in the context is made accessible in native code at
      // index 0, thereby hidding the closure object at index 0.
      count--;
    }
    return count;
  }

  static int ComputeArgcTag(const Function& function) {
    ASSERT(function.is_native());
    ASSERT(!function.IsConstructor());  // Not supported.
    int tag = ArgcBits::encode(function.NumParameters());
    tag = InstanceFunctionBit::update(!function.is_static(), tag);
    tag = ClosureFunctionBit::update(function.IsClosureFunction(), tag);
    return tag;
  }

 private:
  enum ArgcTagBits {
    kArgcBit = 0,
    kArgcSize = 24,
    kInstanceFunctionBit = 24,
    kClosureFunctionBit = 25,
  };
  class ArgcBits : public BitField<int, kArgcBit, kArgcSize> {};
  class InstanceFunctionBit : public BitField<bool, kInstanceFunctionBit, 1> {};
  class ClosureFunctionBit : public BitField<bool, kClosureFunctionBit, 1> {};
  friend class BootstrapNatives;
  friend void SetReturnValueHelper(Dart_NativeArguments, Dart_Handle);

  // Since this function is passed a RawObject directly, we need to be
  // exceedingly careful when we use it.  If there are any other side
  // effects in the statement that may cause GC, it could lead to
  // bugs.
  void SetReturnUnsafe(RawObject* value) const;

  Isolate* isolate_;  // Current isolate pointer.
  int argc_tag_;  // Encodes argument count and invoked native call type.
  RawObject*(*argv_)[];  // Pointer to an array of arguments to runtime call.
  RawObject** retval_;  // Pointer to the return value area.
};

}  // namespace dart

#endif  // VM_NATIVE_ARGUMENTS_H_
