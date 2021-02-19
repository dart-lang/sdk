// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STUB_CODE_LIST_H_
#define RUNTIME_VM_STUB_CODE_LIST_H_

namespace dart {

#define VM_TYPE_TESTING_STUB_CODE_LIST(V)                                      \
  V(DefaultTypeTest)                                                           \
  V(DefaultNullableTypeTest)                                                   \
  V(TopTypeTypeTest)                                                           \
  V(UnreachableTypeTest)                                                       \
  V(TypeParameterTypeTest)                                                     \
  V(NullableTypeParameterTypeTest)                                             \
  V(SlowTypeTest)                                                              \
  V(LazySpecializeTypeTest)                                                    \
  V(LazySpecializeNullableTypeTest)

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
  V(AllocateArray)                                                             \
  V(AllocateInt8Array)                                                         \
  V(AllocateUint8Array)                                                        \
  V(AllocateUint8ClampedArray)                                                 \
  V(AllocateInt16Array)                                                        \
  V(AllocateUint16Array)                                                       \
  V(AllocateInt32Array)                                                        \
  V(AllocateUint32Array)                                                       \
  V(AllocateInt64Array)                                                        \
  V(AllocateUint64Array)                                                       \
  V(AllocateFloat32Array)                                                      \
  V(AllocateFloat64Array)                                                      \
  V(AllocateFloat32x4Array)                                                    \
  V(AllocateInt32x4Array)                                                      \
  V(AllocateFloat64x2Array)                                                    \
  V(AllocateMintSharedWithFPURegs)                                             \
  V(AllocateMintSharedWithoutFPURegs)                                          \
  V(AllocateContext)                                                           \
  V(AllocateObject)                                                            \
  V(AllocateObjectParameterized)                                               \
  V(AllocateObjectSlow)                                                        \
  V(AllocateUnhandledException)                                                \
  V(CloneContext)                                                              \
  V(CallToRuntime)                                                             \
  V(LazyCompile)                                                               \
  V(CallBootstrapNative)                                                       \
  V(CallNoScopeNative)                                                         \
  V(CallAutoScopeNative)                                                       \
  V(FixCallersTarget)                                                          \
  V(CallStaticFunction)                                                        \
  V(OptimizeFunction)                                                          \
  V(InvokeDartCode)                                                            \
  V(DebugStepCheck)                                                            \
  V(SwitchableCallMiss)                                                        \
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
  V(AssertSubtype)                                                             \
  V(TypeIsTopTypeForSubtyping)                                                 \
  V(TypeIsTopTypeForSubtypingNullSafe)                                         \
  V(NullIsAssignableToType)                                                    \
  V(NullIsAssignableToTypeNullSafe)                                            \
  V(Subtype1TestCache)                                                         \
  V(Subtype3TestCache)                                                         \
  V(Subtype5TestCache)                                                         \
  V(Subtype7TestCache)                                                         \
  VM_TYPE_TESTING_STUB_CODE_LIST(V)                                            \
  V(CallClosureNoSuchMethod)                                                   \
  V(FrameAwaitingMaterialization)                                              \
  V(AsynchronousGapMarker)                                                     \
  V(NotLoaded)                                                                 \
  V(DispatchTableNullError)                                                    \
  V(LateInitializationErrorSharedWithFPURegs)                                  \
  V(LateInitializationErrorSharedWithoutFPURegs)                               \
  V(NullErrorSharedWithFPURegs)                                                \
  V(NullErrorSharedWithoutFPURegs)                                             \
  V(NullArgErrorSharedWithFPURegs)                                             \
  V(NullArgErrorSharedWithoutFPURegs)                                          \
  V(NullCastErrorSharedWithFPURegs)                                            \
  V(NullCastErrorSharedWithoutFPURegs)                                         \
  V(RangeErrorSharedWithFPURegs)                                               \
  V(RangeErrorSharedWithoutFPURegs)                                            \
  V(StackOverflowSharedWithFPURegs)                                            \
  V(StackOverflowSharedWithoutFPURegs)                                         \
  V(OneArgCheckInlineCacheWithExactnessCheck)                                  \
  V(OneArgOptimizedCheckInlineCacheWithExactnessCheck)                         \
  V(EnterSafepoint)                                                            \
  V(ExitSafepoint)                                                             \
  V(CallNativeThroughSafepoint)                                                \
  V(InitStaticField)                                                           \
  V(InitInstanceField)                                                         \
  V(InitLateInstanceField)                                                     \
  V(InitLateFinalInstanceField)                                                \
  V(Throw)                                                                     \
  V(ReThrow)                                                                   \
  V(AssertBoolean)                                                             \
  V(InstanceOf)                                                                \
  V(InstantiateTypeArguments)                                                  \
  V(InstantiateTypeArgumentsMayShareInstantiatorTA)                            \
  V(InstantiateTypeArgumentsMayShareFunctionTA)                                \
  V(NoSuchMethodDispatcher)

}  // namespace dart

#endif  // RUNTIME_VM_STUB_CODE_LIST_H_
