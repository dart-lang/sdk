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

#if (defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID)) &&      \
    (defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64))
// Currently we support probe points only Linux and Android (X64 and ARM64).
#define DART_TARGET_SUPPORTS_PROBE_POINTS 1
#endif

#define PROBE_POINT_STUBS_LIST(V) V(AllocationProbePoint)

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
  PROBE_POINT_STUBS_LIST(V)                                                    \
  V(AllocateArray)                                                             \
  V(AllocateMint)                                                              \
  V(AllocateDouble)                                                            \
  V(AllocateFloat32x4)                                                         \
  V(AllocateFloat64x2)                                                         \
  V(AllocateInt32x4)                                                           \
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
  V(AllocateClosure)                                                           \
  V(AllocateClosureGeneric)                                                    \
  V(AllocateClosureTA)                                                         \
  V(AllocateClosureTAGeneric)                                                  \
  V(AllocateContext)                                                           \
  V(AllocateGrowableArray)                                                     \
  V(AllocateObject)                                                            \
  V(AllocateObjectParameterized)                                               \
  V(AllocateObjectSlow)                                                        \
  V(AllocateRecord)                                                            \
  V(AllocateRecord2)                                                           \
  V(AllocateRecord2Named)                                                      \
  V(AllocateRecord3)                                                           \
  V(AllocateRecord3Named)                                                      \
  V(AllocateUnhandledException)                                                \
  V(BoxDouble)                                                                 \
  V(BoxFloat32x4)                                                              \
  V(BoxFloat64x2)                                                              \
  V(CloneContext)                                                              \
  V(CallToRuntime)                                                             \
  V(LazyCompile)                                                               \
  V(InterpretCall)                                                             \
  V(ResumeInterpreter)                                                         \
  V(CallBootstrapNative)                                                       \
  V(CallNoScopeNative)                                                         \
  V(CallAutoScopeNative)                                                       \
  V(FixCallersTarget)                                                          \
  V(CallStaticFunction)                                                        \
  V(OptimizeFunction)                                                          \
  V(InvokeDartCode)                                                            \
  V(InvokeDartCodeFromBytecode)                                                \
  V(DebugStepCheck)                                                            \
  V(SwitchableCallMiss)                                                        \
  V(MonomorphicSmiableCheck)                                                   \
  V(SingleTargetCall)                                                          \
  V(ICCallThroughCode)                                                         \
  V(MegamorphicCall)                                                           \
  V(FixAllocationStubTarget)                                                   \
  V(FixParameterizedAllocationStubTarget)                                      \
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
  V(AssertAssignable)                                                          \
  V(TypeIsTopTypeForSubtyping)                                                 \
  V(NullIsAssignableToType)                                                    \
  V(Subtype1TestCache)                                                         \
  V(Subtype2TestCache)                                                         \
  V(Subtype3TestCache)                                                         \
  V(Subtype4TestCache)                                                         \
  V(Subtype6TestCache)                                                         \
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
  V(WriteErrorSharedWithFPURegs)                                               \
  V(WriteErrorSharedWithoutFPURegs)                                            \
  V(StackOverflowSharedWithFPURegs)                                            \
  V(StackOverflowSharedWithoutFPURegs)                                         \
  V(DoubleToInteger)                                                           \
  V(OneArgCheckInlineCacheWithExactnessCheck)                                  \
  V(OneArgOptimizedCheckInlineCacheWithExactnessCheck)                         \
  V(EnterSafepoint)                                                            \
  V(ExitSafepoint)                                                             \
  V(ExitSafepointIgnoreUnwindInProgress)                                       \
  V(CallNativeThroughSafepoint)                                                \
  V(FfiCallbackTrampoline)                                                     \
  V(InitStaticField)                                                           \
  V(InitLateStaticField)                                                       \
  V(InitLateFinalStaticField)                                                  \
  V(InitInstanceField)                                                         \
  V(InitLateInstanceField)                                                     \
  V(InitLateFinalInstanceField)                                                \
  V(InitSharedLateStaticField)                                                 \
  V(InitSharedLateFinalStaticField)                                            \
  V(Throw)                                                                     \
  V(ReThrow)                                                                   \
  V(InstanceOf)                                                                \
  V(InstantiateType)                                                           \
  V(InstantiateTypeNonNullableClassTypeParameter)                              \
  V(InstantiateTypeNullableClassTypeParameter)                                 \
  V(InstantiateTypeNonNullableFunctionTypeParameter)                           \
  V(InstantiateTypeNullableFunctionTypeParameter)                              \
  V(InstantiateTypeArguments)                                                  \
  V(InstantiateTypeArgumentsMayShareInstantiatorTA)                            \
  V(InstantiateTypeArgumentsMayShareFunctionTA)                                \
  V(NoSuchMethodDispatcher)                                                    \
  V(Await)                                                                     \
  V(AwaitWithTypeCheck)                                                        \
  V(InitAsync)                                                                 \
  V(Resume)                                                                    \
  V(ReturnAsync)                                                               \
  V(ReturnAsyncNotFuture)                                                      \
  V(InitAsyncStar)                                                             \
  V(YieldAsyncStar)                                                            \
  V(ReturnAsyncStar)                                                           \
  V(InitSyncStar)                                                              \
  V(SuspendSyncStarAtStart)                                                    \
  V(SuspendSyncStarAtYield)                                                    \
  V(AsyncExceptionHandler)                                                     \
  V(CloneSuspendState)                                                         \
  V(FfiAsyncCallbackSend)                                                      \
  V(UnknownDartCode)

}  // namespace dart

#endif  // RUNTIME_VM_STUB_CODE_LIST_H_
