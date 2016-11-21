// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_NATIVE_ENTRY_H_
#define RUNTIME_VM_NATIVE_ENTRY_H_

#include "platform/memory_sanitizer.h"

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/code_generator.h"
#include "vm/exceptions.h"
#include "vm/native_arguments.h"
#include "vm/verifier.h"

#include "include/dart_api.h"

namespace dart {

// Forward declarations.
class Class;
class String;

typedef void (*NativeFunction)(NativeArguments* arguments);


#define NATIVE_ENTRY_FUNCTION(name) BootstrapNatives::DN_##name

#ifdef DEBUG
#define SET_NATIVE_RETVAL(args, value)                                         \
  RawObject* retval = value;                                                   \
  ASSERT(retval->IsDartInstance());                                            \
  arguments->SetReturnUnsafe(retval);
#else
#define SET_NATIVE_RETVAL(arguments, value) arguments->SetReturnUnsafe(value);
#endif

#define DEFINE_NATIVE_ENTRY(name, argument_count)                              \
  static RawObject* DN_Helper##name(Isolate* isolate, Thread* thread,          \
                                    Zone* zone, NativeArguments* arguments);   \
  void NATIVE_ENTRY_FUNCTION(name)(Dart_NativeArguments args) {                \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);     \
    /* Tell MemorySanitizer 'arguments' is initialized by generated code. */   \
    MSAN_UNPOISON(arguments, sizeof(*arguments));                              \
    ASSERT(arguments->NativeArgCount() == argument_count);                     \
    TRACE_NATIVE_CALL("%s", "" #name);                                         \
    {                                                                          \
      Thread* thread = arguments->thread();                                    \
      ASSERT(thread == Thread::Current());                                     \
      Isolate* isolate = thread->isolate();                                    \
      TransitionGeneratedToVM transition(thread);                              \
      StackZone zone(thread);                                                  \
      SET_NATIVE_RETVAL(                                                       \
          arguments,                                                           \
          DN_Helper##name(isolate, thread, zone.GetZone(), arguments));        \
      DEOPTIMIZE_ALOT;                                                         \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
  }                                                                            \
  static RawObject* DN_Helper##name(Isolate* isolate, Thread* thread,          \
                                    Zone* zone, NativeArguments* arguments)


// Helper that throws an argument exception.
void DartNativeThrowArgumentException(const Instance& instance);

// Natives should throw an exception if an illegal argument or null is passed.
// type name = value.
#define GET_NON_NULL_NATIVE_ARGUMENT(type, name, value)                        \
  const Instance& __##name##_instance__ =                                      \
      Instance::CheckedHandle(zone, value);                                    \
  if (!__##name##_instance__.Is##type()) {                                     \
    DartNativeThrowArgumentException(__##name##_instance__);                   \
  }                                                                            \
  const type& name = type::Cast(__##name##_instance__);


// Natives should throw an exception if an illegal argument is passed.
// type name = value.
#define GET_NATIVE_ARGUMENT(type, name, value)                                 \
  const Instance& __##name##_instance__ =                                      \
      Instance::CheckedHandle(zone, value);                                    \
  type& name = type::Handle(zone);                                             \
  if (!__##name##_instance__.IsNull()) {                                       \
    if (!__##name##_instance__.Is##type()) {                                   \
      DartNativeThrowArgumentException(__##name##_instance__);                 \
    }                                                                          \
  }                                                                            \
  name ^= value;


// Helper class for resolving and handling native functions.
class NativeEntry : public AllStatic {
 public:
  static const intptr_t kNumArguments = 1;
  static const intptr_t kNumCallWrapperArguments = 2;

  // Resolve specified dart native function to the actual native entrypoint.
  static NativeFunction ResolveNative(const Library& library,
                                      const String& function_name,
                                      int number_of_arguments,
                                      bool* auto_setup_scope);
  static const uint8_t* ResolveSymbolInLibrary(const Library& library,
                                               uword pc);
  static const uint8_t* ResolveSymbol(uword pc);

  static uword NativeCallWrapperEntry();
  static void NativeCallWrapper(Dart_NativeArguments args,
                                Dart_NativeFunction func);

// DBC does not support lazy native call linking.
#if !defined(TARGET_ARCH_DBC)
  static uword LinkNativeCallEntry();
  static void LinkNativeCall(Dart_NativeArguments args);
#endif

 private:
  static void NativeCallWrapperNoStackCheck(Dart_NativeArguments args,
                                            Dart_NativeFunction func);

  static bool ReturnValueIsError(NativeArguments* arguments);
  static void PropagateErrors(NativeArguments* arguments);
};

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_ENTRY_H_
