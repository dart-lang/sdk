// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STUB_CODE_H_
#define VM_STUB_CODE_H_

#include "vm/allocation.h"
#include "vm/assembler.h"

namespace dart {

// Forward declarations.
class Code;
class Isolate;
class ObjectPointerVisitor;
class RawCode;


// List of stubs created in the VM isolate, these stubs are shared by different
// isolates running in this dart process.
#define VM_STUB_CODE_LIST(V)                                                   \
  V(PrintStopMessage)                                                          \
  V(CallToRuntime)                                                             \
  V(LazyCompile)                                                               \
  V(CallBootstrapCFunction)                                                    \
  V(CallNativeCFunction)                                                       \
  V(CallStaticFunction)                                                        \
  V(FixCallersTarget)                                                          \
  V(Deoptimize)                                                                \
  V(DeoptimizeLazy)                                                            \
  V(ICCallBreakpoint)                                                          \
  V(ClosureCallBreakpoint)                                                     \
  V(RuntimeCallBreakpoint)                                                     \
  V(DebugStepCheck)                                                            \
  V(Subtype1TestCache)                                                         \
  V(Subtype2TestCache)                                                         \
  V(Subtype3TestCache)                                                         \
  V(GetStackPointer)                                                           \
  V(JumpToExceptionHandler)                                                    \
  V(UnoptimizedIdenticalWithNumberCheck)                                       \
  V(OptimizedIdenticalWithNumberCheck)                                         \

// Is it permitted for the stubs above to refer to Object::null(), which is
// allocated in the VM isolate and shared across all isolates.
// However, in cases where a simple GC-safe placeholder is needed on the stack,
// using Smi 0 instead of Object::null() is slightly more efficient, since a Smi
// does not require relocation.

// List of stubs created per isolate, these stubs could potentially contain
// embedded objects and hence cannot be shared across isolates.
#define STUB_CODE_LIST(V)                                                      \
  V(AllocateArray)                                                             \
  V(CallNoSuchMethodFunction)                                                  \
  V(AllocateContext)                                                           \
  V(UpdateStoreBuffer)                                                         \
  V(OneArgCheckInlineCache)                                                    \
  V(TwoArgsCheckInlineCache)                                                   \
  V(ThreeArgsCheckInlineCache)                                                 \
  V(OneArgOptimizedCheckInlineCache)                                           \
  V(TwoArgsOptimizedCheckInlineCache)                                          \
  V(ThreeArgsOptimizedCheckInlineCache)                                        \
  V(ClosureCallInlineCache)                                                    \
  V(ZeroArgsUnoptimizedStaticCall)                                             \
  V(OneArgUnoptimizedStaticCall)                                               \
  V(TwoArgsUnoptimizedStaticCall)                                              \
  V(OptimizeFunction)                                                          \
  V(InvokeDartCode)                                                            \

// class StubEntry is used to describe stub methods generated in dart to
// abstract out common code executed from generated dart code.
class StubEntry {
 public:
  explicit StubEntry(const Code& code);
  ~StubEntry() {}

  const ExternalLabel& label() const { return label_; }
  uword EntryPoint() const { return entry_point_; }
  RawCode* code() const { return code_; }
  intptr_t Size() const { return size_; }

  // Visit all object pointers.
  void VisitObjectPointers(ObjectPointerVisitor* visitor);

 private:
  RawCode* code_;
  uword entry_point_;
  intptr_t size_;
  ExternalLabel label_;

  DISALLOW_COPY_AND_ASSIGN(StubEntry);
};


// class StubCode is used to maintain the lifecycle of stubs.
class StubCode {
 public:
  StubCode()
    :
#define STUB_CODE_INITIALIZER(name)                                            \
        name##_entry_(NULL),
  STUB_CODE_LIST(STUB_CODE_INITIALIZER)
        dummy_(NULL) {}
  ~StubCode();

  void GenerateFor(Isolate* isolate);

  // Generate all stubs which are shared across all isolates, this is done
  // only once and the stub code resides in the vm_isolate heap.
  static void InitOnce();

  // Generate all stubs which are generated on a per isolate basis as they
  // have embedded objects which are isolate specific.
  static void Init(Isolate* isolate);

  static void VisitObjectPointers(ObjectPointerVisitor* visitor);

  // Check if specified pc is in the dart invocation stub used for
  // transitioning into dart code.
  static bool InInvocationStub(uword pc);

  static bool InInvocationStubForIsolate(Isolate* isolate, uword pc);

  // Check if the specified pc is in the jump to exception handler stub.
  static bool InJumpToExceptionHandlerStub(uword pc);

  // Returns NULL if no stub found.
  static const char* NameOfStub(uword entry_point);

  // Define the shared stub code accessors.
#define STUB_CODE_ACCESSOR(name)                                               \
  static StubEntry* name##_entry() {                                           \
    return name##_entry_;                                                      \
  }                                                                            \
  static const ExternalLabel& name##Label() {                                  \
    return name##_entry()->label();                                            \
  }                                                                            \
  static uword name##EntryPoint() {                                            \
    return name##_entry()->EntryPoint();                                       \
  }                                                                            \
  static intptr_t name##Size() {                                               \
    return name##_entry()->Size();                                             \
  }
  VM_STUB_CODE_LIST(STUB_CODE_ACCESSOR);
#undef STUB_CODE_ACCESSOR

  // Define the per-isolate stub code accessors.
#define STUB_CODE_ACCESSOR(name)                                               \
  StubEntry* name##_entry() {                                                  \
    return name##_entry_;                                                      \
  }                                                                            \
  const ExternalLabel& name##Label() {                                         \
    return name##_entry()->label();                                            \
  }                                                                            \
  uword name##EntryPoint() {                                                   \
    return name##_entry()->EntryPoint();                                       \
  }                                                                            \
  intptr_t name##Size() {                                                      \
    return name##_entry()->Size();                                             \
  }
  STUB_CODE_LIST(STUB_CODE_ACCESSOR);
#undef STUB_CODE_ACCESSOR

  static RawCode* GetAllocationStubForClass(const Class& cls);

  uword UnoptimizedStaticCallEntryPoint(intptr_t num_args_tested);

  static const intptr_t kNoInstantiator = 0;

 private:
  friend class MegamorphicCacheTable;

  static const intptr_t kStubCodeSize = 4 * KB;

#define STUB_CODE_GENERATE(name)                                               \
  static void Generate##name##Stub(Assembler* assembler);
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE);
  STUB_CODE_LIST(STUB_CODE_GENERATE);
#undef STUB_CODE_GENERATE

#define STUB_CODE_ENTRY(name)                                                  \
  static StubEntry* name##_entry_;
  VM_STUB_CODE_LIST(STUB_CODE_ENTRY);
#undef STUB_CODE_ENTRY

#define STUB_CODE_ENTRY(name)                                                  \
  StubEntry* name##_entry_;
  STUB_CODE_LIST(STUB_CODE_ENTRY);
#undef STUB_CODE_ENTRY
  // This dummy field is needed so that we can initialize
  // the stubs from a macro.
  void* dummy_;

  // Generate the stub and finalize the generated code into the stub
  // code executable area.
  static RawCode* Generate(const char* name,
                           void (*GenerateStub)(Assembler* assembler));

  static void GenerateMegamorphicMissStub(Assembler* assembler);
  static void GenerateAllocationStubForClass(Assembler* assembler,
                                             const Class& cls);
  static void GenerateNArgsCheckInlineCacheStub(
      Assembler* assembler,
      intptr_t num_args,
      const RuntimeEntry& handle_ic_miss);
  static void GenerateUsageCounterIncrement(Assembler* assembler,
                                            Register temp_reg);
  static void GenerateOptimizedUsageCounterIncrement(Assembler* assembler);

  static void GenerateIdenticalWithNumberCheckStub(
      Assembler* assembler,
      const Register left,
      const Register right,
      const Register temp1 = kNoRegister,
      const Register temp2 = kNoRegister);
};

}  // namespace dart

#endif  // VM_STUB_CODE_H_
