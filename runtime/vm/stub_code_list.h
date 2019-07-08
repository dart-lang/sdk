// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STUB_CODE_LIST_H_
#define RUNTIME_VM_STUB_CODE_LIST_H_

namespace dart {

// List of stubs created in the VM isolate, these stubs are shared by different
// isolates running in this dart process.
#if !defined(TARGET_ARCH_DBC)
#define VM_STUB_CODE_LIST(V)                                                   \
  V(GetCStackPointer)                                                          \
  V(JumpToFrame)                                                               \
  V(RunExceptionHandler)                                                       \
  V(DeoptForRewind)                                                            \
  V(WriteBarrier)                                                              \
  V(WriteBarrierWrappers)                                                      \
  V(ArrayWriteBarrier)                                                         \
  V(PrintStopMessage)                                                          \
  V(AllocateArray)                                                             \
  V(AllocateContext)                                                           \
  V(CallToRuntime)                                                             \
  V(LazyCompile)                                                               \
  V(InterpretCall)                                                             \
  V(CallBootstrapNative)                                                       \
  V(CallNoScopeNative)                                                         \
  V(CallAutoScopeNative)                                                       \
  V(FixCallersTarget)                                                          \
  V(CallStaticFunction)                                                        \
  V(OptimizeFunction)                                                          \
  V(InvokeDartCode)                                                            \
  V(InvokeDartCodeFromBytecode)                                                \
  V(DebugStepCheck)                                                            \
  V(UnlinkedCall)                                                              \
  V(MonomorphicMiss)                                                           \
  V(SingleTargetCall)                                                          \
  V(ICCallThroughCode)                                                         \
  V(MegamorphicCall)                                                           \
  V(FixAllocationStubTarget)                                                   \
  V(Deoptimize)                                                                \
  V(DeoptimizeLazyFromReturn)                                                  \
  V(DeoptimizeLazyFromThrow)                                                   \
  V(UnoptimizedIdenticalWithNumberCheck)                                       \
  V(OptimizedIdenticalWithNumberCheck)                                         \
  V(ICCallBreakpoint)                                                          \
  V(UnoptStaticCallBreakpoint)                                                 \
  V(RuntimeCallBreakpoint)                                                     \
  V(OneArgCheckInlineCache)                                                    \
  V(TwoArgsCheckInlineCache)                                                   \
  V(SmiAddInlineCache)                                                         \
  V(SmiLessInlineCache)                                                        \
  V(SmiEqualInlineCache)                                                       \
  V(OneArgOptimizedCheckInlineCache)                                           \
  V(TwoArgsOptimizedCheckInlineCache)                                          \
  V(ZeroArgsUnoptimizedStaticCall)                                             \
  V(OneArgUnoptimizedStaticCall)                                               \
  V(TwoArgsUnoptimizedStaticCall)                                              \
  V(Subtype1TestCache)                                                         \
  V(Subtype2TestCache)                                                         \
  V(Subtype4TestCache)                                                         \
  V(Subtype6TestCache)                                                         \
  V(DefaultTypeTest)                                                           \
  V(TopTypeTypeTest)                                                           \
  V(TypeRefTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(CallClosureNoSuchMethod)                                                   \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(NullErrorSharedWithFPURegs)                                                \
  V(NullErrorSharedWithoutFPURegs)                                             \
  V(StackOverflowSharedWithFPURegs)                                            \
  V(StackOverflowSharedWithoutFPURegs)                                         \
  V(OneArgCheckInlineCacheWithExactnessCheck)                                  \
  V(OneArgOptimizedCheckInlineCacheWithExactnessCheck)                         \
  V(EnterSafepoint)                                                            \
  V(ExitSafepoint)                                                             \
  V(VerifyCallback)

#else
#define VM_STUB_CODE_LIST(V)                                                   \
  V(LazyCompile)                                                               \
  V(OptimizeFunction)                                                          \
  V(CallClosureNoSuchMethod)                                                   \
  V(RunExceptionHandler)                                                       \
  V(DeoptForRewind)                                                            \
  V(FixCallersTarget)                                                          \
  V(Deoptimize)                                                                \
  V(DeoptimizeLazyFromReturn)                                                  \
  V(DeoptimizeLazyFromThrow)                                                   \
  V(DefaultTypeTest)                                                           \
  V(TopTypeTypeTest)                                                           \
  V(TypeRefTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(InvokeDartCodeFromBytecode)                                                \
  V(InterpretCall)

#endif  // !defined(TARGET_ARCH_DBC)

}  // namespace dart

#endif  // RUNTIME_VM_STUB_CODE_LIST_H_
