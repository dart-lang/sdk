// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STUB_CODE_LIST_H_
#define RUNTIME_VM_STUB_CODE_LIST_H_

namespace dart {

// List of stubs created in the VM isolate, these stubs are shared by different
// isolates running in this dart process.
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
  V(AllocateMintWithFPURegs)                                                   \
  V(AllocateMintWithoutFPURegs)                                                \
  V(AllocateContext)                                                           \
  V(CloneContext)                                                              \
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
  V(MonomorphicSmiableCheck)                                                   \
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
  V(DefaultNullableTypeTest)                                                   \
  V(TopTypeTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(LazySpecializeNullableTypeTest)                                            \
  V(CallClosureNoSuchMethod)                                                   \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(DispatchTableNullError)                                                    \
  V(NullErrorSharedWithFPURegs)                                                \
  V(NullErrorSharedWithoutFPURegs)                                             \
  V(NullArgErrorSharedWithFPURegs)                                             \
  V(NullArgErrorSharedWithoutFPURegs)                                          \
  V(StackOverflowSharedWithFPURegs)                                            \
  V(StackOverflowSharedWithoutFPURegs)                                         \
  V(OneArgCheckInlineCacheWithExactnessCheck)                                  \
  V(OneArgOptimizedCheckInlineCacheWithExactnessCheck)                         \
  V(EnterSafepoint)                                                            \
  V(ExitSafepoint)                                                             \
  V(CallNativeThroughSafepoint)                                                \
  V(InstantiateTypeArguments)                                                  \
  V(InstantiateTypeArgumentsMayShareInstantiatorTA)                            \
  V(InstantiateTypeArgumentsMayShareFunctionTA)

}  // namespace dart

#endif  // RUNTIME_VM_STUB_CODE_LIST_H_
