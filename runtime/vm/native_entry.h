// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_ENTRY_H_
#define VM_NATIVE_ENTRY_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/native_arguments.h"
#include "vm/verifier.h"

#include "include/dart_api.h"

namespace dart {

DECLARE_FLAG(bool, trace_natives);

// Forward declarations.
class Class;
class String;

typedef void (*NativeFunction)(NativeArguments* arguments);


#define NATIVE_ENTRY_FUNCTION(name) DN_##name


// Helper macros for declaring and defining native entries.
#define REGISTER_NATIVE_ENTRY(name, count)                                     \
  { ""#name, NATIVE_ENTRY_FUNCTION(name), count },


#define DEFINE_NATIVE_ENTRY(name, argument_count)                              \
  static void DN_Helper##name(NativeArguments* arguments);                     \
  void NATIVE_ENTRY_FUNCTION(name)(Dart_NativeArguments args) {                \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);     \
    ASSERT(arguments->Count() == argument_count);                              \
    if (FLAG_trace_natives) OS::Print("Calling native: %s\n", ""#name);        \
    {                                                                          \
      Zone zone;                                                               \
      HANDLESCOPE();                                                           \
      DN_Helper##name(arguments);                                              \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
  }                                                                            \
  static void DN_Helper##name(NativeArguments* arguments)


#define DECLARE_NATIVE_ENTRY(name, argument_count)                             \
  extern void NATIVE_ENTRY_FUNCTION(name)(Dart_NativeArguments arguments);

// Natives should throw an exception if an illegal argument is passed.
// type name = value.
#define GET_NATIVE_ARGUMENT(type, name, value)                                 \
  type& name = type::Handle();                                                 \
  {                                                                            \
    const Instance& __instance__ = Instance::CheckedHandle(value);             \
    if (!__instance__.Is##type()) {                                            \
      GrowableArray<const Object*> __args__;                                   \
      __args__.Add(&__instance__);                                             \
      Exceptions::ThrowByType(Exceptions::kIllegalArgument, __args__);         \
    }                                                                          \
    name ^= __instance__.raw();                                                \
  }



// Helper class for resolving and handling native functions.
class NativeEntry : public AllStatic {
 public:
  // Resolve specified dart native function to the actual native entrypoint.
  static NativeFunction ResolveNative(const Class& cls,
                                      const String& function_name,
                                      int number_of_arguments);
};

}  // namespace dart

#endif  // VM_NATIVE_ENTRY_H_
