// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RUNTIME_ENTRY_H_
#define VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/native_arguments.h"
#include "vm/tags.h"

namespace dart {

class Assembler;

DECLARE_FLAG(bool, trace_runtime_calls);

typedef void (*RuntimeFunction)(NativeArguments arguments);

#define RUNTIME_ENTRY_LIST(V)                                                  \
  V(AllocateArray)                                                             \
  V(AllocateContext)                                                           \
  V(AllocateObject)                                                            \
  V(BreakpointRuntimeHandler)                                                  \
  V(SingleStepHandler)                                                         \
  V(CloneContext)                                                              \
  V(Deoptimize)                                                                \
  V(FixCallersTarget)                                                          \
  V(FixAllocationStubTarget)                                                   \
  V(InlineCacheMissHandlerOneArg)                                              \
  V(InlineCacheMissHandlerTwoArgs)                                             \
  V(InlineCacheMissHandlerThreeArgs)                                           \
  V(StaticCallMissHandlerOneArg)                                               \
  V(StaticCallMissHandlerTwoArgs)                                              \
  V(Instanceof)                                                                \
  V(TypeCheck)                                                                 \
  V(BadTypeError)                                                              \
  V(NonBoolTypeError)                                                          \
  V(InstantiateType)                                                           \
  V(InstantiateTypeArguments)                                                  \
  V(InvokeClosureNoSuchMethod)                                                 \
  V(InvokeNoSuchMethodDispatcher)                                              \
  V(MegamorphicCacheMissHandler)                                               \
  V(OptimizeInvokedFunction)                                                   \
  V(TraceICCall)                                                               \
  V(PatchStaticCall)                                                           \
  V(ReThrow)                                                                   \
  V(StackOverflow)                                                             \
  V(Throw)                                                                     \
  V(TraceFunctionEntry)                                                        \
  V(TraceFunctionExit)                                                         \
  V(DeoptimizeMaterialize)                                                     \
  V(UpdateFieldCid)                                                            \
  V(InitStaticField)                                                           \
  V(GrowRegExpStack)                                                           \
  V(CompileFunction)                                                           \

#define LEAF_RUNTIME_ENTRY_LIST(V)                                             \
  V(void, PrintStopMessage, const char*)                                       \
  V(intptr_t, DeoptimizeCopyFrame, uword)                                      \
  V(void, DeoptimizeFillFrame, uword)                                          \
  V(void, StoreBufferBlockProcess, Thread*)                                    \
  V(intptr_t, BigintCompare, RawBigint*, RawBigint*)                           \


enum RuntimeFunctionId {
  kNoRuntimeFunctionId = -1,
#define DECLARE_ENUM_VALUE(name) \
  k##name##Id,
  RUNTIME_ENTRY_LIST(DECLARE_ENUM_VALUE)
#undef DECLARE_ENUM_VALUE

#define DECLARE_LEAF_ENUM_VALUE(type, name, ...) \
  k##name##Id,
  LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_ENUM_VALUE)
#undef DECLARE_LEAF_ENUM_VALUE
};

// Class RuntimeEntry is used to encapsulate runtime functions, it includes
// the entry point for the runtime function and the number of arguments expected
// by the function.
class RuntimeEntry : public ValueObject {
 public:
  RuntimeEntry(const char* name, RuntimeFunction function,
               intptr_t argument_count, bool is_leaf, bool is_float)
      : name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf),
        is_float_(is_float),
        next_(NULL) {
    // Strip off const for registration.
    VMTag::RegisterRuntimeEntry(const_cast<RuntimeEntry*>(this));
  }
  ~RuntimeEntry() {}

  const char* name() const { return name_; }
  RuntimeFunction function() const { return function_; }
  intptr_t argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  bool is_float() const { return is_float_; }
  uword GetEntryPoint() const { return reinterpret_cast<uword>(function()); }

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


// Helper macros for declaring and defining runtime entries.

#define DEFINE_RUNTIME_ENTRY(name, argument_count)                             \
  extern void DRT_##name(NativeArguments arguments);                           \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DRT_"#name, &DRT_##name, argument_count, false, false);                 \
  static void DRT_Helper##name(Isolate* isolate,                               \
                               Thread* thread,                                 \
                               Zone* zone,                                     \
                               NativeArguments arguments);                     \
  void DRT_##name(NativeArguments arguments) {                                 \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    ASSERT(arguments.ArgCount() == argument_count);                            \
    if (FLAG_trace_runtime_calls) OS::Print("Runtime call: %s\n", ""#name);    \
    {                                                                          \
      Thread* thread = arguments.thread();                                     \
      ASSERT(thread == Thread::Current());                                     \
      Isolate* isolate = thread->isolate();                                    \
      StackZone zone(thread);                                                  \
      HANDLESCOPE(isolate);                                                    \
      DRT_Helper##name(isolate, thread, zone.GetZone(), arguments);            \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
  }                                                                            \
  static void DRT_Helper##name(Isolate* isolate,                               \
                               Thread* thread,                                 \
                               Zone* zone,                                     \
                               NativeArguments arguments)

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern void DRT_##name(NativeArguments arguments);                           \

#define DEFINE_LEAF_RUNTIME_ENTRY(type, name, argument_count, ...)             \
  extern "C" type DLRT_##name(__VA_ARGS__);                                    \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DLRT_"#name, reinterpret_cast<RuntimeFunction>(&DLRT_##name),           \
      argument_count, true, false);                                            \
  type DLRT_##name(__VA_ARGS__) {                                              \
    CHECK_STACK_ALIGNMENT;                                                     \
    NoSafepointScope no_safepoint_scope;                                       \

#define END_LEAF_RUNTIME_ENTRY }

#define DECLARE_LEAF_RUNTIME_ENTRY(type, name, ...)                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" type DLRT_##name(__VA_ARGS__);                                    \


// Declare all runtime functions here.
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_RUNTIME_ENTRY)


// Declare all runtime functions here.
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_RUNTIME_ENTRY)


uword RuntimeEntry::AddressFromId(RuntimeFunctionId id) {
    switch (id) {
#define DEFINE_RUNTIME_CASE(name)                                              \
    case k##name##Id: return reinterpret_cast<uword>(&DRT_##name);
    RUNTIME_ENTRY_LIST(DEFINE_RUNTIME_CASE)
#undef DEFINE_RUNTIME_CASE

#define DEFINE_LEAF_RUNTIME_CASE(type, name, ...)                              \
    case k##name##Id: return reinterpret_cast<uword>(&DLRT_##name);
    LEAF_RUNTIME_ENTRY_LIST(DEFINE_LEAF_RUNTIME_CASE)
#undef DEFINE_LEAF_RUNTIME_CASE
    default:
      break;
  }
  return 0;
}


RuntimeFunctionId RuntimeEntry::RuntimeFunctionIdFromAddress(uword address) {
#define CHECK_RUNTIME_ADDRESS(name)                                            \
  if (address == reinterpret_cast<uword>(&DRT_##name)) return k##name##Id;
  RUNTIME_ENTRY_LIST(CHECK_RUNTIME_ADDRESS)
#undef CHECK_RUNTIME_ADDRESS

#define CHECK_LEAF_RUNTIME_ADDRESS(type, name, ...)                            \
  if (address == reinterpret_cast<uword>(&DLRT_##name)) return k##name##Id;
  LEAF_RUNTIME_ENTRY_LIST(CHECK_LEAF_RUNTIME_ADDRESS)
#undef CHECK_LEAF_RUNTIME_ADDRESS
  return kNoRuntimeFunctionId;
}

}  // namespace dart

#endif  // VM_RUNTIME_ENTRY_H_
