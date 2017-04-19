// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_H_
#define RUNTIME_VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/native_arguments.h"
#include "vm/runtime_entry_list.h"
#include "vm/safepoint.h"
#include "vm/tags.h"

namespace dart {

class Assembler;

DECLARE_FLAG(bool, trace_runtime_calls);

typedef void (*RuntimeFunction)(NativeArguments arguments);

enum RuntimeFunctionId {
  kNoRuntimeFunctionId = -1,
#define DECLARE_ENUM_VALUE(name) k##name##Id,
  RUNTIME_ENTRY_LIST(DECLARE_ENUM_VALUE)
#undef DECLARE_ENUM_VALUE

#define DECLARE_LEAF_ENUM_VALUE(type, name, ...) k##name##Id,
      LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_ENUM_VALUE)
#undef DECLARE_LEAF_ENUM_VALUE
};

// Class RuntimeEntry is used to encapsulate runtime functions, it includes
// the entry point for the runtime function and the number of arguments expected
// by the function.
class RuntimeEntry : public ValueObject {
 public:
  RuntimeEntry(const char* name,
               RuntimeFunction function,
               intptr_t argument_count,
               bool is_leaf,
               bool is_float)
      : name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf),
        is_float_(is_float),
        next_(NULL) {
    VMTag::RegisterRuntimeEntry(this);
  }

  const char* name() const { return name_; }
  RuntimeFunction function() const { return function_; }
  intptr_t argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  bool is_float() const { return is_float_; }
  uword GetEntryPoint() const;

  // Generate code to call the runtime entry.
  void Call(Assembler* assembler, intptr_t argument_count) const;

  void set_next(const RuntimeEntry* next) { next_ = next; }
  const RuntimeEntry* next() const { return next_; }

  static inline uword AddressFromId(RuntimeFunctionId id);
  static inline RuntimeFunctionId RuntimeFunctionIdFromAddress(uword address);

 private:
  const char* name_;
  const RuntimeFunction function_;
  const intptr_t argument_count_;
  const bool is_leaf_;
  const bool is_float_;
  const RuntimeEntry* next_;

  DISALLOW_COPY_AND_ASSIGN(RuntimeEntry);
};

#ifndef PRODUCT
#define TRACE_RUNTIME_CALL(format, name)                                       \
  if (FLAG_trace_runtime_calls) {                                              \
    THR_Print("Runtime call: " format "\n", name);                             \
  }
#else
#define TRACE_RUNTIME_CALL(format, name)                                       \
  do {                                                                         \
  } while (0)
#endif

// Helper macros for declaring and defining runtime entries.

#define DEFINE_RUNTIME_ENTRY(name, argument_count)                             \
  extern void DRT_##name(NativeArguments arguments);                           \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DRT_" #name, &DRT_##name, argument_count, false, false);                \
  static void DRT_Helper##name(Isolate* isolate, Thread* thread, Zone* zone,   \
                               NativeArguments arguments);                     \
  void DRT_##name(NativeArguments arguments) {                                 \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    ASSERT(arguments.ArgCount() == argument_count);                            \
    TRACE_RUNTIME_CALL("%s", "" #name);                                        \
    {                                                                          \
      Thread* thread = arguments.thread();                                     \
      ASSERT(thread == Thread::Current());                                     \
      Isolate* isolate = thread->isolate();                                    \
      TransitionGeneratedToVM transition(thread);                              \
      StackZone zone(thread);                                                  \
      HANDLESCOPE(thread);                                                     \
      DRT_Helper##name(isolate, thread, zone.GetZone(), arguments);            \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
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

// TODO(rmacnak): Fix alignment issue on simarm and simmips and use
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


uword RuntimeEntry::AddressFromId(RuntimeFunctionId id) {
  switch (id) {
#define DEFINE_RUNTIME_CASE(name)                                              \
  case k##name##Id:                                                            \
    return k##name##RuntimeEntry.GetEntryPoint();
    RUNTIME_ENTRY_LIST(DEFINE_RUNTIME_CASE)
#undef DEFINE_RUNTIME_CASE

#define DEFINE_LEAF_RUNTIME_CASE(type, name, ...)                              \
  case k##name##Id:                                                            \
    return k##name##RuntimeEntry.GetEntryPoint();
    LEAF_RUNTIME_ENTRY_LIST(DEFINE_LEAF_RUNTIME_CASE)
#undef DEFINE_LEAF_RUNTIME_CASE
    default:
      break;
  }
  return 0;
}


RuntimeFunctionId RuntimeEntry::RuntimeFunctionIdFromAddress(uword address) {
#define CHECK_RUNTIME_ADDRESS(name)                                            \
  if (address == k##name##RuntimeEntry.GetEntryPoint()) return k##name##Id;
  RUNTIME_ENTRY_LIST(CHECK_RUNTIME_ADDRESS)
#undef CHECK_RUNTIME_ADDRESS

#define CHECK_LEAF_RUNTIME_ADDRESS(type, name, ...)                            \
  if (address == k##name##RuntimeEntry.GetEntryPoint()) return k##name##Id;
  LEAF_RUNTIME_ENTRY_LIST(CHECK_LEAF_RUNTIME_ADDRESS)
#undef CHECK_LEAF_RUNTIME_ADDRESS
  return kNoRuntimeFunctionId;
}

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(const Code& optimized_code, StackFrame* frame);
void DeoptimizeFunctionsOnStack();

double DartModulo(double a, double b);

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_H_
