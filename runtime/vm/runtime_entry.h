// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_H_
#define RUNTIME_VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/runtime_api.h"
#endif
#include "vm/flags.h"
#include "vm/heap/safepoint.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/runtime_entry_list.h"

namespace dart {

typedef void (*RuntimeFunction)(NativeArguments arguments);

#if !defined(DART_PRECOMPILED_RUNTIME)
using BaseRuntimeEntry = compiler::RuntimeEntry;
#else
using BaseRuntimeEntry = ValueObject;
#endif

// Class RuntimeEntry is used to encapsulate runtime functions, it includes
// the entry point for the runtime function and the number of arguments expected
// by the function.
class RuntimeEntry : public BaseRuntimeEntry {
 public:
  RuntimeEntry(const char* name,
               RuntimeFunction function,
               intptr_t argument_count,
               bool is_leaf,
               bool is_float)
      :
#if !defined(DART_PRECOMPILED_RUNTIME)
        compiler::RuntimeEntry(this, &CallInternal),
#endif
        name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf),
        is_float_(is_float) {
  }

  const char* name() const { return name_; }
  RuntimeFunction function() const { return function_; }
  intptr_t argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  bool is_float() const { return is_float_; }
  uword GetEntryPoint() const;

  // Generate code to call the runtime entry.
  NOT_IN_PRECOMPILED(void Call(compiler::Assembler* assembler,
                               intptr_t argument_count) const);

 protected:
  NOT_IN_PRECOMPILED(static void CallInternal(const RuntimeEntry* runtime_entry,
                                              compiler::Assembler* assembler,
                                              intptr_t argument_count));

 private:
  const char* const name_;
  const RuntimeFunction function_;
  const intptr_t argument_count_;
  const bool is_leaf_;
  const bool is_float_;

  DISALLOW_COPY_AND_ASSIGN(RuntimeEntry);
};

#ifdef DEBUG
#define TRACE_RUNTIME_CALL(format, name)                                       \
  if (FLAG_trace_runtime_calls) {                                              \
    THR_Print("Runtime call: " format "\n", name);                             \
  }
#else
#define TRACE_RUNTIME_CALL(format, name)                                       \
  do {                                                                         \
  } while (0)
#endif

#if defined(USING_SIMULATOR)
#define CHECK_SIMULATOR_STACK_OVERFLOW()                                       \
  if (!OSThread::Current()->HasStackHeadroom()) {                              \
    Exceptions::ThrowStackOverflow();                                          \
  }
#else
#define CHECK_SIMULATOR_STACK_OVERFLOW()
#endif  // defined(USING_SIMULATOR)

// Helper macros for declaring and defining runtime entries.

#define DEFINE_RUNTIME_ENTRY(name, argument_count)                             \
  extern void DRT_##name(NativeArguments arguments);                           \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DRT_" #name, &DRT_##name, argument_count, false, false);                \
  static void DRT_Helper##name(Isolate* isolate, Thread* thread, Zone* zone,   \
                               NativeArguments arguments);                     \
  void DRT_##name(NativeArguments arguments) {                                 \
    CHECK_STACK_ALIGNMENT;                                                     \
    /* Tell MemorySanitizer 'arguments' is initialized by generated code. */   \
    MSAN_UNPOISON(&arguments, sizeof(arguments));                              \
    ASSERT(arguments.ArgCount() == argument_count);                            \
    TRACE_RUNTIME_CALL("%s", "" #name);                                        \
    {                                                                          \
      Thread* thread = arguments.thread();                                     \
      ASSERT(thread == Thread::Current());                                     \
      Isolate* isolate = thread->isolate();                                    \
      TransitionGeneratedToVM transition(thread);                              \
      StackZone zone(thread);                                                  \
      HANDLESCOPE(thread);                                                     \
      CHECK_SIMULATOR_STACK_OVERFLOW();                                        \
      DRT_Helper##name(isolate, thread, zone.GetZone(), arguments);            \
    }                                                                          \
  }                                                                            \
  static void DRT_Helper##name(Isolate* isolate, Thread* thread, Zone* zone,   \
                               NativeArguments arguments)

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern void DRT_##name(NativeArguments arguments);

#define DEFINE_LEAF_RUNTIME_ENTRY(type, name, argument_count, ...)             \
  extern "C" type DLRT_##name(__VA_ARGS__);                                    \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DLRT_" #name, reinterpret_cast<RuntimeFunction>(&DLRT_##name),          \
      argument_count, true, false);                                            \
  type DLRT_##name(__VA_ARGS__) {                                              \
    CHECK_STACK_ALIGNMENT;                                                     \
    NoSafepointScope no_safepoint_scope;

#define END_LEAF_RUNTIME_ENTRY }

// TODO(rmacnak): Fix alignment issue on simarm and use
// DEFINE_LEAF_RUNTIME_ENTRY instead.
#define DEFINE_RAW_LEAF_RUNTIME_ENTRY(name, argument_count, is_float, func)    \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DFLRT_" #name, func, argument_count, true, is_float)

#define DECLARE_LEAF_RUNTIME_ENTRY(type, name, ...)                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" type DLRT_##name(__VA_ARGS__);

// Declare all runtime functions here.
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_RUNTIME_ENTRY)

// Expected to be called inside a safepoint.
extern "C" Thread* DLRT_GetThreadForNativeCallback(uword callback_id);
extern "C" Thread* DLRT_GetThreadForNativeCallbackTrampoline(uword callback_id);

// For creating scoped handles in FFI trampolines.
extern "C" ApiLocalScope* DLRT_EnterHandleScope(Thread* thread);
extern "C" void DLRT_ExitHandleScope(Thread* thread);
extern "C" LocalHandle* DLRT_AllocateHandle(ApiLocalScope* scope);

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(const Code& optimized_code, StackFrame* frame);
void DeoptimizeFunctionsOnStack();

double DartModulo(double a, double b);

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_H_
