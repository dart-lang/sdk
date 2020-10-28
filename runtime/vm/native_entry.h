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

typedef ObjectPtr (*BootstrapNativeFunction)(Thread* thread,
                                             Zone* zone,
                                             NativeArguments* arguments);

#define NATIVE_ENTRY_FUNCTION(name) BootstrapNatives::DN_##name

#define DEFINE_NATIVE_ENTRY(name, type_argument_count, argument_count)         \
  static ObjectPtr DN_Helper##name(Isolate* isolate, Thread* thread,           \
                                   Zone* zone, NativeArguments* arguments);    \
  ObjectPtr NATIVE_ENTRY_FUNCTION(name)(Thread * thread, Zone * zone,          \
                                        NativeArguments * arguments) {         \
    TRACE_NATIVE_CALL("%s", "" #name);                                         \
    ASSERT(arguments->NativeArgCount() == argument_count);                     \
    /* Note: a longer type arguments vector may be passed */                   \
    ASSERT(arguments->NativeTypeArgCount() >= type_argument_count);            \
    return DN_Helper##name(thread->isolate(), thread, zone, arguments);        \
  }                                                                            \
  static ObjectPtr DN_Helper##name(Isolate* isolate, Thread* thread,           \
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
  static MethodRecognizer::Kind GetKind(TypedDataPtr data);

  NativeFunctionWrapper trampoline() const;
  void set_trampoline(NativeFunctionWrapper value) const;
  static NativeFunctionWrapper GetTrampoline(TypedDataPtr data);

  NativeFunction native_function() const;
  void set_native_function(NativeFunction value) const;
  static NativeFunction GetNativeFunction(TypedDataPtr data);

  intptr_t argc_tag() const;
  void set_argc_tag(intptr_t value) const;
  static intptr_t GetArgcTag(TypedDataPtr data);

  static TypedDataPtr New(MethodRecognizer::Kind kind,
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

  static Payload* FromTypedArray(TypedDataPtr data);

  const TypedData& data_;

  friend class ObjectPoolSerializationCluster;
  DISALLOW_COPY_AND_ASSIGN(NativeEntryData);
};

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_ENTRY_H_
