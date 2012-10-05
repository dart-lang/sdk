// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RUNTIME_ENTRY_H_
#define VM_RUNTIME_ENTRY_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/flags.h"
#include "vm/native_arguments.h"

namespace dart {

DECLARE_FLAG(bool, trace_runtime_calls);

typedef void (*RuntimeFunction)(NativeArguments arguments);


// Class RuntimeEntry is used to encapsulate runtime functions, it includes
// the entry point for the runtime function and the number of arguments expected
// by the function.
class RuntimeEntry : public ValueObject {
 public:
  RuntimeEntry(const char* name, RuntimeFunction function,
               int argument_count, bool is_leaf)
      : name_(name),
        function_(function),
        argument_count_(argument_count),
        is_leaf_(is_leaf) { }
  ~RuntimeEntry() {}

  const char* name() const { return name_; }
  RuntimeFunction function() const { return function_; }
  int argument_count() const { return argument_count_; }
  bool is_leaf() const { return is_leaf_; }
  uword GetEntryPoint() const { return reinterpret_cast<uword>(function()); }

  // Generate code to call the runtime entry.
  void Call(Assembler* assembler) const;

 private:
  const char* name_;
  const RuntimeFunction function_;
  const int argument_count_;
  const bool is_leaf_;

  DISALLOW_COPY_AND_ASSIGN(RuntimeEntry);
};


// Helper macros for declaring and defining runtime entries.

#define DEFINE_RUNTIME_ENTRY(name, argument_count)                             \
  extern void DRT_##name(NativeArguments arguments);                           \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DRT_"#name, &DRT_##name, argument_count, false);                        \
  static void DRT_Helper##name(Isolate* isolate, NativeArguments arguments);   \
  void DRT_##name(NativeArguments arguments) {                                 \
    CHECK_STACK_ALIGNMENT;                                                     \
    VERIFY_ON_TRANSITION;                                                      \
    if (FLAG_trace_runtime_calls) OS::Print("Runtime call: %s\n", ""#name);    \
    {                                                                          \
      StackZone zone(arguments.isolate());                                     \
      HANDLESCOPE(arguments.isolate());                                        \
      DRT_Helper##name(arguments.isolate(), arguments);                        \
    }                                                                          \
    VERIFY_ON_TRANSITION;                                                      \
  }                                                                            \
  static void DRT_Helper##name(Isolate* isolate, NativeArguments arguments)

#define DECLARE_RUNTIME_ENTRY(name)                                            \
  extern const RuntimeEntry k##name##RuntimeEntry

#define DEFINE_LEAF_RUNTIME_ENTRY(type, name, ...)                             \
  extern "C" type DLRT_##name(__VA_ARGS__);                                    \
  extern const RuntimeEntry k##name##RuntimeEntry(                             \
      "DLRT_"#name, reinterpret_cast<RuntimeFunction>(&DLRT_##name), 0, true); \
  type DLRT_##name(__VA_ARGS__) {                                              \
    CHECK_STACK_ALIGNMENT;                                                     \
    NoGCScope no_gc_scope;                                                     \

#define END_LEAF_RUNTIME_ENTRY }

#define DECLARE_LEAF_RUNTIME_ENTRY(type, name, ...)                            \
  extern const RuntimeEntry k##name##RuntimeEntry;                             \
  extern "C" type DLRT_##name(__VA_ARGS__)

}  // namespace dart

#endif  // VM_RUNTIME_ENTRY_H_
