// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_H_
#define RUNTIME_VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/runtime_api.h"
#endif
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
               const void* function,
               intptr_t argument_count,
               bool is_leaf,
               bool is_float,
               bool can_lazy_deopt)
      :
#if !defined(DART_PRECOMPILED_RUNTIME)
        compiler::RuntimeEntry(this),
#endif
        name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf),
        is_float_(is_float),
        can_lazy_deopt_(can_lazy_deopt) {
  }

  const char* name() const { return name_; }
  const void* function() const { return function_; }
  intptr_t argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  bool is_float() const { return is_float_; }
  bool can_lazy_deopt() const { return can_lazy_deopt_; }
  uword GetEntryPoint() const;
  uword GetEntryPointNoRedirect() const {
    return reinterpret_cast<uword>(function());
  }

  static uword InterpretCallEntry();

  static constexpr const char* RuntimeEntryNames[] = {
#define RUNTIME_ENTRY_NAME(name) #name,
      RUNTIME_ENTRY_LIST(RUNTIME_ENTRY_NAME)
#undef RUNTIME_ENTRY_NAME
  };
  static constexpr const char* LeafRuntimeEntryNames[] = {
#define LEAF_RUNTIME_ENTRY_NAME(type, name, ...) #name,
      LEAF_RUNTIME_ENTRY_LIST(LEAF_RUNTIME_ENTRY_NAME)
#undef LEAF_RUNTIME_ENTRY_NAME
  };

 private:
  const char* const name_;
  const void* const function_;
  const intptr_t argument_count_;
  const bool is_leaf_;
  const bool is_float_;
  const bool can_lazy_deopt_;

  DISALLOW_COPY_AND_ASSIGN(RuntimeEntry);
};

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" void DRT_##name(NativeArguments arguments);

#define DECLARE_LEAF_RUNTIME_ENTRY(type, name, ...)                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" type DLRT_##name(__VA_ARGS__);

// Declare all runtime functions here.
RUNTIME_ENTRY_LIST(DECLARE_RUNTIME_ENTRY)
LEAF_RUNTIME_ENTRY_LIST(DECLARE_LEAF_RUNTIME_ENTRY)

#undef DECLARE_RUNTIME_ENTRY
#undef DECLARE_LEAF_RUNTIME_ENTRY

// Used for redirected FFI callbacks in the runtime when either simulating or
// interpreting FFI callbacks on ARM64. When dynamic modules are enabled, also
// needed for compiling both the first level trampoline stub and a shared second
// level trampoline stub for interpreted callbacks in the stub code compiler.
struct CallbackContext {
  static constexpr int kNumIntegerArguments = 8;
  static constexpr int kNumDoubleArguments = 8;

  uword integer_arguments[kNumIntegerArguments];
  uword double_arguments[kNumDoubleArguments];
  uword return_struct_pointer;
  uword sp;

  static intptr_t integer_arguments_offset() {
    return OFFSET_OF(CallbackContext, integer_arguments);
  }
  static intptr_t double_arguments_offset() {
    return OFFSET_OF(CallbackContext, double_arguments);
  }
  static intptr_t return_struct_pointer_offset() {
    return OFFSET_OF(CallbackContext, return_struct_pointer);
  }
  static intptr_t sp_offset() { return OFFSET_OF(CallbackContext, sp); }

  static intptr_t InstanceSize() { return sizeof(CallbackContext); }

  const char* ToCString(Zone* zone,
                        intptr_t stack_top_in_bytes = -1,
                        bool print_stack_as_words = false) const;
};

#if defined(HOST_ARCH_ARM64) && defined(SIMULATOR_FFI)
// Called by the first-level trampoline for simulated callbacks.
extern "C" void DoRedirectedFfiCallback(struct CallbackContext* ctxt,
                                        uword trampoline);
#endif

#if defined(HOST_ARCH_ARM64) && defined(DART_DYNAMIC_MODULES)
// Called by the second-level trampoline for interpreted callbacks.
extern "C" void DLRT_DoInterpretedFfiCallback(
    Thread* thread,
    struct CallbackContext* ctxt,
    const PersistentHandle* function_handle);
#endif

// Information derived from FfiCallbackMetadata by DLRT_GetFfiCallbackMetadata
// for the callback trampoline stubs.
//
// The latter two fields are only used when DART_DYNAMIC_MODULES is enabled,
// so the first-level trampoline can pass additional information to the
// InterpretedFfiCallbackTrampoline stub.
struct CallbackMetadata {
#define FOR_CALLBACK_METADATA_FIELDS(V)                                        \
  V(entry_point)                                                               \
  V(type)                                                                      \
  V(epilogue)                                                                  \
  V(caller_isolate)                                                            \
  V(caller_isolate_group)                                                      \
  V(function_handle)                                                           \
  V(interpreted_runtime_entry)

#define DEFINE_FIELD(Name)                                                     \
  uword Name;                                                                  \
  static intptr_t Name##_offset() {                                            \
    return OFFSET_OF(CallbackMetadata, Name);                                  \
  }
  FOR_CALLBACK_METADATA_FIELDS(DEFINE_FIELD)
#undef DEFINE_FIELD
#undef FOR_CALLBACK_METADATA_FIELDS

  static intptr_t InstanceSize() { return sizeof(CallbackMetadata); }
};

extern "C" Thread* DLRT_GetFfiCallbackMetadata(uword trampoline,
                                               CallbackMetadata* out);
#if defined(HOST_ARCH_IA32)
extern "C" void* DLRT_ExitTemporaryIsolate();
#else
extern "C" void* DLRT_ExitTemporaryIsolate(Thread*);
#endif
extern "C" void* DLRT_ExitIsolateGroupBoundIsolate(Thread*,
                                                   Isolate*,
                                                   IsolateGroup*);
extern "C" void* DLRT_ExitSyncCallbackTargetIsolate(Thread*,
                                                    Isolate*,
                                                    IsolateGroup*);
extern "C" void* DLRT_ExitSyncCallback(Thread*, Isolate*, IsolateGroup*);

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(Thread* mutator_thread,
                  const Code& optimized_code,
                  StackFrame* frame);
void DeoptimizeFunctionsOnStack();

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_H_
