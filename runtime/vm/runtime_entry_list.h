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
  V(BoxDouble)                                                                 \
  V(BreakpointRuntimeHandler)                                                  \
  V(SingleStepHandler)                                                         \
  V(CloneContext)                                                              \
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
  V(NonBoolTypeError)                                                          \
  V(InstantiateType)                                                           \
  V(InstantiateTypeArguments)                                                  \
  V(NoSuchMethodFromCallStub)                                                  \
  V(NoSuchMethodFromPrologue)                                                  \
  V(OptimizeInvokedFunction)                                                   \
  V(TraceICCall)                                                               \
  V(PatchStaticCall)                                                           \
  V(RangeError)                                                                \
  V(NullError)                                                                 \
  V(NullErrorWithSelector)                                                     \
  V(NullCastError)                                                             \
  V(ArgumentNullError)                                                         \
  V(DispatchTableNullError)                                                    \
  V(ArgumentError)                                                             \
  V(ArgumentErrorUnboxedInt64)                                                 \
  V(IntegerDivisionByZeroException)                                            \
  V(ReThrow)                                                                   \
  V(StackOverflow)                                                             \
  V(Throw)                                                                     \
  V(DeoptimizeMaterialize)                                                     \
  V(RewindPostDeopt)                                                           \
  V(UpdateFieldCid)                                                            \
  V(InitInstanceField)                                                         \
  V(InitStaticField)                                                           \
  V(LateFieldAssignedDuringInitializationError)                                \
  V(LateFieldNotInitializedError)                                              \
  V(CompileFunction)                                                           \
  V(SwitchableCallMiss)                                                        \
  V(NotLoaded)

// Note: Leaf runtime function have C linkage, so they cannot pass C++ struct
// values like ObjectPtr.

#define LEAF_RUNTIME_ENTRY_LIST(V)                                             \
  V(intptr_t, DeoptimizeCopyFrame, uword, uword)                               \
  V(void, DeoptimizeFillFrame, uword)                                          \
  V(void, StoreBufferBlockProcess, Thread*)                                    \
  V(void, MarkingStackBlockProcess, Thread*)                                   \
  V(void, RememberCard, uword /*ObjectPtr*/, ObjectPtr*)                       \
  V(uword /*ObjectPtr*/, EnsureRememberedAndMarkingDeferred,                   \
    uword /*ObjectPtr*/ object, Thread* thread)                                \
  V(double, LibcPow, double, double)                                           \
  V(double, DartModulo, double, double)                                        \
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
  V(uword /*BoolPtr*/, CaseInsensitiveCompareUCS2, uword /*StringPtr*/,        \
    uword /*SmiPtr*/, uword /*SmiPtr*/, uword /*SmiPtr*/)                      \
  V(uword /*BoolPtr*/, CaseInsensitiveCompareUTF16, uword /*StringPtr*/,       \
    uword /*SmiPtr*/, uword /*SmiPtr*/, uword /*SmiPtr*/)                      \
  V(void, EnterSafepoint)                                                      \
  V(void, ExitSafepoint)                                                       \
  V(void, ExitSafepointIgnoreUnwindInProgress)                                 \
  V(ApiLocalScope*, EnterHandleScope, Thread*)                                 \
  V(void, ExitHandleScope, Thread*)                                            \
  V(LocalHandle*, AllocateHandle, ApiLocalScope*)                              \
  V(void, TsanLoadAcquire, uword /* address */)                                \
  V(void, TsanStoreRelease, uword /* address */)

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_LIST_H_
