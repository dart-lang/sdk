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
//   const Type& arg1 = Type::CheckedHandle(arguments.GetArgument(0));
//   const Type& arg2 = Type::CheckedHandle(arguments.GetArgument(1));
// The return value is set as follows:
//   arguments.SetReturn(result);
// NOTE: Since we pass this as a pass by value argument in the stubs we don't
// have DISALLOW_COPY_AND_ASSIGN in the class definition and do not make it a
// subclass of ValueObject.
class NativeArguments {
 public:
  Isolate* isolate() const { return isolate_; }
  int Count() const { return argc_; }

  RawObject* At(int index) const {
    ASSERT(index >=0 && index < argc_);
    return (*argv_)[-index];
  }

  void SetReturn(const Object& value) const;

  static intptr_t isolate_offset() {
    return OFFSET_OF(NativeArguments, isolate_);
  }
  static intptr_t argc_offset() { return OFFSET_OF(NativeArguments, argc_); }
  static intptr_t argv_offset() { return OFFSET_OF(NativeArguments, argv_); }
  static intptr_t retval_offset() {
    return OFFSET_OF(NativeArguments, retval_);
  }

 private:
  friend class BootstrapNatives;
  friend void SetReturnValueHelper(Dart_NativeArguments, Dart_Handle);

  // Since this function is passed a RawObject directly, we need to be
  // exceedingly careful when we use it.  If there are any other side
  // effects in the statement that may cause GC, it could lead to
  // bugs.
  void SetReturnUnsafe(RawObject* value) const;

  Isolate* isolate_;  // Current isolate pointer.
  int argc_;  // Number of arguments passed to the runtime call.
  RawObject*(*argv_)[];  // Pointer to an array of arguments to runtime call.
  RawObject** retval_;  // Pointer to the return value area.
};

}  // namespace dart

#endif  // VM_NATIVE_ARGUMENTS_H_
