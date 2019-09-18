// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_NATIVE_ENTRY_H_
#define RUNTIME_VM_NATIVE_ENTRY_H_

#include "platform/memory_sanitizer.h"

#include "vm/allocation.h"
#include "vm/exceptions.h"
#include "vm/heap/verifier.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/native_function.h"
#include "vm/runtime_entry.h"


namespace dart {

// Forward declarations.
class Class;
class String;

#ifdef DEBUG
#define TRACE_NATIVE_CALL(format, name)                                        \
  if (FLAG_trace_natives) {                                                    \
    THR_Print("Calling native: " format "\n", name);                           \
  }
#else
#define TRACE_NATIVE_CALL(format, name)                                        \
  do {                                                                         \
  } while (0)
#endif

#define NATIVE_ENTRY_FUNCTION(name) BootstrapNatives::DN_##name

#define DEFINE_NATIVE_ENTRY(name, type_argument_count, argument_count)         \
  static RawObject* DN_Helper##name(Isolate* isolate, Thread* thread,          \
                                    Zone* zone, NativeArguments* arguments);   \
  void NATIVE_ENTRY_FUNCTION(name)(Dart_NativeArguments args) {                \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);     \
    /* Tell MemorySanitizer 'arguments' is initialized by generated code. */   \
    MSAN_UNPOISON(arguments, sizeof(*arguments));                              \
    ASSERT(arguments->NativeArgCount() == argument_count);                     \
    /* Note: a longer type arguments vector may be passed */                   \
    ASSERT(arguments->NativeTypeArgCount() >= type_argument_count);            \
    TRACE_NATIVE_CALL("%s", "" #name);                                         \
    {                                                                          \
      Thread* thread = arguments->thread();                                    \
      ASSERT(thread == Thread::Current());                                     \
      Isolate* isolate = thread->isolate();                                    \
      TransitionGeneratedToVM transition(thread);                              \
      StackZone zone(thread);                                                  \
      /* Be careful holding return_value_unsafe without a handle here. */      \
      /* A return of Object::sentinel means the return value has already */    \
      /* been set. */                                                          \
      RawObject* return_value_unsafe =                                         \
          DN_Helper##name(isolate, thread, zone.GetZone(), arguments);         \
      if (return_value_unsafe != Object::sentinel().raw()) {                   \
        ASSERT(return_value_unsafe->IsDartInstance());                         \
        arguments->SetReturnUnsafe(return_value_unsafe);                       \
      }                                                                        \
      DEOPTIMIZE_ALOT;                                                         \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
  }                                                                            \
  static RawObject* DN_Helper##name(Isolate* isolate, Thread* thread,          \
                                    Zone* zone, NativeArguments* arguments)

// Helpers that throw an argument exception.
void DartNativeThrowTypeArgumentCountException(int num_type_args,
                                               int num_type_args_expected);
void DartNativeThrowArgumentException(const Instance& instance);

// Native should throw an exception if the wrong number of type arguments is
// passed.
#define NATIVE_TYPE_ARGUMENT_COUNT(expected)                                   \
  int __num_type_arguments = arguments->NativeTypeArgCount();                  \
  if (__num_type_arguments != expected) {                                      \
    DartNativeThrowTypeArgumentCountException(__num_type_arguments, expected); \
  }

#define GET_NATIVE_TYPE_ARGUMENT(name, value)                                  \
  AbstractType& name = AbstractType::Handle(value);

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

  static uword BootstrapNativeCallWrapperEntry();
  static void BootstrapNativeCallWrapper(Dart_NativeArguments args,
                                         Dart_NativeFunction func);

  static uword NoScopeNativeCallWrapperEntry();
  static void NoScopeNativeCallWrapper(Dart_NativeArguments args,
                                       Dart_NativeFunction func);

  static uword AutoScopeNativeCallWrapperEntry();
  static void AutoScopeNativeCallWrapper(Dart_NativeArguments args,
                                         Dart_NativeFunction func);

  static uword LinkNativeCallEntry();
  static void LinkNativeCall(Dart_NativeArguments args);

 private:
  static void NoScopeNativeCallWrapperNoStackCheck(Dart_NativeArguments args,
                                                   Dart_NativeFunction func);
  static void AutoScopeNativeCallWrapperNoStackCheck(Dart_NativeArguments args,
                                                     Dart_NativeFunction func);

  static bool ReturnValueIsError(NativeArguments* arguments);
  static void PropagateErrors(NativeArguments* arguments);
};

#if !defined(DART_PRECOMPILED_RUNTIME)

class NativeEntryData : public ValueObject {
 public:
  explicit NativeEntryData(const TypedData& data) : data_(data) {}

  MethodRecognizer::Kind kind() const;
  void set_kind(MethodRecognizer::Kind value) const;
  static MethodRecognizer::Kind GetKind(RawTypedData* data);

  NativeFunctionWrapper trampoline() const;
  void set_trampoline(NativeFunctionWrapper value) const;
  static NativeFunctionWrapper GetTrampoline(RawTypedData* data);

  NativeFunction native_function() const;
  void set_native_function(NativeFunction value) const;
  static NativeFunction GetNativeFunction(RawTypedData* data);

  intptr_t argc_tag() const;
  void set_argc_tag(intptr_t value) const;
  static intptr_t GetArgcTag(RawTypedData* data);

  static RawTypedData* New(MethodRecognizer::Kind kind,
                           NativeFunctionWrapper trampoline,
                           NativeFunction native_function,
                           intptr_t argc_tag);

 private:
  struct Payload {
    NativeFunctionWrapper trampoline;
    NativeFunction native_function;
    intptr_t argc_tag;
    MethodRecognizer::Kind kind;
  };

  static Payload* FromTypedArray(RawTypedData* data);

  const TypedData& data_;

  friend class Interpreter;
  friend class ObjectPoolSerializationCluster;
  DISALLOW_COPY_AND_ASSIGN(NativeEntryData);
};

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_ENTRY_H_
