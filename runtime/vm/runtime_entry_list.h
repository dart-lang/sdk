// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_LIST_H_
#define RUNTIME_VM_RUNTIME_ENTRY_LIST_H_

namespace dart {

#define RUNTIME_ENTRY_LIST(V)                                                  \
  V(AllocateArray)                                                             \
  V(AllocateMint)                                                              \
  V(AllocateDouble)                                                            \
  V(AllocateFloat32x4)                                                         \
  V(AllocateFloat64x2)                                                         \
  V(AllocateInt32x4)                                                           \
  V(AllocateTypedData)                                                         \
  V(AllocateClosure)                                                           \
  V(AllocateContext)                                                           \
  V(AllocateObject)                                                            \
  V(AllocateRecord)                                                            \
  V(AllocateSmallRecord)                                                       \
  V(AllocateSuspendState)                                                      \
  V(BoxDouble)                                                                 \
  V(BoxFloat32x4)                                                              \
  V(BoxFloat64x2)                                                              \
  V(BreakpointRuntimeHandler)                                                  \
  V(SingleStepHandler)                                                         \
  V(ResumptionBreakpointHandler)                                               \
  V(CloneContext)                                                              \
  V(CloneSuspendState)                                                         \
  V(DoubleToInteger)                                                           \
  V(FixCallersTarget)                                                          \
  V(FixCallersTargetMonomorphic)                                               \
  V(FixAllocationStubTarget)                                                   \
  V(InlineCacheMissHandlerOneArg)                                              \
  V(InlineCacheMissHandlerTwoArgs)                                             \
  V(StaticCallMissHandlerOneArg)                                               \
  V(StaticCallMissHandlerTwoArgs)                                              \
  V(Instanceof)                                                                \
  V(SubtypeCheck)                                                              \
  V(TypeCheck)                                                                 \
  V(InstantiateType)                                                           \
  V(InstantiateTypeArguments)                                                  \
  V(NoSuchMethodFromCallStub)                                                  \
  V(NoSuchMethodFromPrologue)                                                  \
  V(NoSuchMethodError)                                                         \
  V(OptimizeInvokedFunction)                                                   \
  V(PatchStaticCall)                                                           \
  V(RangeError)                                                                \
  V(RangeErrorUnboxedInt64)                                                    \
  V(WriteError)                                                                \
  V(NullError)                                                                 \
  V(NullErrorWithSelector)                                                     \
  V(NullCastError)                                                             \
  V(ArgumentNullError)                                                         \
  V(DispatchTableNullError)                                                    \
  V(ArgumentError)                                                             \
  V(ArgumentErrorUnboxedInt64)                                                 \
  V(IntegerDivisionByZeroException)                                            \
  V(ReThrow)                                                                   \
  V(InterruptOrStackOverflow)                                                  \
  V(Throw)                                                                     \
  V(DeoptimizeMaterialize)                                                     \
  V(RewindPostDeopt)                                                           \
  V(UpdateFieldCid)                                                            \
  V(InitInstanceField)                                                         \
  V(InitStaticField)                                                           \
  V(StaticFieldAccessedWithoutIsolateError)                                    \
  V(CheckedStoreIntoShared)                                                    \
  V(LateFieldAlreadyInitializedError)                                          \
  V(LateFieldAssignedDuringInitializationError)                                \
  V(LateFieldNotInitializedError)                                              \
  V(CompileFunction)                                                           \
  V(ResumeFrame)                                                               \
  V(SwitchableCallMiss)                                                        \
  V(NotLoaded)                                                                 \
  V(FfiAsyncCallbackSend)                                                      \
  V(AllocateSubtypeTestCache)                                                  \
  V(GetFieldForDispatch)                                                       \
  V(AdjustArgumentsDesciptorForImplicitClosure)                                \
  V(ConvertToInstanceTypeArguments)                                            \
  V(ClosureArgumentsValid)                                                     \
  V(ResolveCallFunction)                                                       \
  V(ResolveExternalCall)                                                       \
  V(FfiCall)                                                                   \
  V(CheckFunctionArgumentTypes)                                                \
  V(InterpretedInstanceCallMissHandler)                                        \
  V(InvokeNoSuchMethod)                                                        \
  V(ResumeInterpreter)                                                         \
  V(InitializeSharedField)                                                     \
  V(FatalError)                                                                \
  V(EnsureDeeplyImmutable)

// Note: Leaf runtime function have C linkage, so they cannot pass C++ struct
// values like ObjectPtr.

#define LEAF_RUNTIME_ENTRY_LIST(V)                                             \
  V(intptr_t, DeoptimizeCopyFrame, uword, uword)                               \
  V(intptr_t, DeoptimizeFillFrame, uword)                                      \
  V(void, StoreBufferBlockProcess, Thread*)                                    \
  V(void, OldMarkingStackBlockProcess, Thread*)                                \
  V(void, NewMarkingStackBlockProcess, Thread*)                                \
  V(uword /*ObjectPtr*/, EnsureRememberedAndMarkingDeferred,                   \
    uword /*ObjectPtr*/ object, Thread* thread)                                \
  V(double, LibcPow, double, double)                                           \
  V(double, DartModulo, double, double)                                        \
  V(double, LibcFmod, double, double)                                          \
  V(double, LibcFloor, double)                                                 \
  V(double, LibcCeil, double)                                                  \
  V(double, LibcTrunc, double)                                                 \
  V(double, LibcRound, double)                                                 \
  V(double, LibcCos, double)                                                   \
  V(double, LibcSin, double)                                                   \
  V(double, LibcTan, double)                                                   \
  V(double, LibcAcos, double)                                                  \
  V(double, LibcAsin, double)                                                  \
  V(double, LibcAtan, double)                                                  \
  V(double, LibcAtan2, double, double)                                         \
  V(double, LibcExp, double)                                                   \
  V(double, LibcLog, double)                                                   \
  V(void, EnterSafepoint)                                                      \
  V(void, ExitSafepoint)                                                       \
  V(ApiLocalScope*, EnterHandleScope, Thread*)                                 \
  V(void, ExitHandleScope, Thread*)                                            \
  V(LocalHandle*, AllocateHandle, ApiLocalScope*)                              \
  V(void, PropagateError, Dart_Handle)                                         \
  V(void, MsanUnpoison, void*, size_t)                                         \
  V(void, MsanUnpoisonParam, size_t)                                           \
  V(uint32_t, TsanAtomic32Load, void*, int)                                    \
  V(void, TsanAtomic32Store, void*, uint32_t, int)                             \
  V(uint64_t, TsanAtomic64Load, void*, int)                                    \
  V(void, TsanAtomic64Store, void*, uint64_t, int)                             \
  V(void, SanRead1, void*)                                                     \
  V(void, SanRead2, void*)                                                     \
  V(void, SanRead4, void*)                                                     \
  V(void, SanRead8, void*)                                                     \
  V(void, SanRead16, void*)                                                    \
  V(void, SanWrite1, void*)                                                    \
  V(void, SanWrite2, void*)                                                    \
  V(void, SanWrite4, void*)                                                    \
  V(void, SanWrite8, void*)                                                    \
  V(void, SanWrite16, void*)                                                   \
  V(void, TsanFuncEntry, void*)                                                \
  V(void, TsanFuncExit)                                                        \
  V(bool, TryDoubleAsInteger, Thread*)                                         \
  V(void*, MemoryMove, void*, const void*, size_t)

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_LIST_H_
