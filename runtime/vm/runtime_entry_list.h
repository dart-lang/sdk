// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RUNTIME_ENTRY_LIST_H_
#define RUNTIME_VM_RUNTIME_ENTRY_LIST_H_

namespace dart {

#define RUNTIME_ENTRY_LIST(V)                                                  \
  V(AllocateArray)                                                             \
  V(AllocateContext)                                                           \
  V(AllocateObject)                                                            \
  V(AllocateSubtypeTestCache)                                                  \
  V(BreakpointRuntimeHandler)                                                  \
  V(SingleStepHandler)                                                         \
  V(CloneContext)                                                              \
  V(GetFieldForDispatch)                                                       \
  V(ResolveCallFunction)                                                       \
  V(FixCallersTarget)                                                          \
  V(FixCallersTargetMonomorphic)                                               \
  V(FixAllocationStubTarget)                                                   \
  V(InlineCacheMissHandlerOneArg)                                              \
  V(InlineCacheMissHandlerTwoArgs)                                             \
  V(StaticCallMissHandlerOneArg)                                               \
  V(StaticCallMissHandlerTwoArgs)                                              \
  V(InterpretedInstanceCallMissHandler)                                        \
  V(Instanceof)                                                                \
  V(SubtypeCheck)                                                              \
  V(TypeCheck)                                                                 \
  V(NonBoolTypeError)                                                          \
  V(InstantiateType)                                                           \
  V(InstantiateTypeArguments)                                                  \
  V(NoSuchMethodFromCallStub)                                                  \
  V(NoSuchMethodFromPrologue)                                                  \
  V(InvokeNoSuchMethod)                                                        \
  V(MegamorphicCacheMissHandler)                                               \
  V(OptimizeInvokedFunction)                                                   \
  V(TraceICCall)                                                               \
  V(PatchStaticCall)                                                           \
  V(RangeError)                                                                \
  V(NullError)                                                                 \
  V(NullErrorWithSelector)                                                     \
  V(ArgumentNullError)                                                         \
  V(ArgumentError)                                                             \
  V(ArgumentErrorUnboxedInt64)                                                 \
  V(IntegerDivisionByZeroException)                                            \
  V(ReThrow)                                                                   \
  V(StackOverflow)                                                             \
  V(AllocateMint)                                                              \
  V(Throw)                                                                     \
  V(DeoptimizeMaterialize)                                                     \
  V(RewindPostDeopt)                                                           \
  V(UpdateFieldCid)                                                            \
  V(InitInstanceField)                                                         \
  V(InitStaticField)                                                           \
  V(CompileFunction)                                                           \
  V(CompileInterpretedFunction)                                                \
  V(MonomorphicMiss)                                                           \
  V(SingleTargetMiss)                                                          \
  V(UnlinkedCall)

#define LEAF_RUNTIME_ENTRY_LIST(V)                                             \
  V(void, PrintStopMessage, const char*)                                       \
  V(intptr_t, DeoptimizeCopyFrame, uword, uword)                               \
  V(void, DeoptimizeFillFrame, uword)                                          \
  V(void, StoreBufferBlockProcess, Thread*)                                    \
  V(void, MarkingStackBlockProcess, Thread*)                                   \
  V(void, RememberCard, RawObject*, RawObject**)                               \
  V(RawObject*, AddAllocatedObjectToRememberedSet, RawObject* object,          \
    Thread* thread)                                                            \
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
  V(RawBool*, CaseInsensitiveCompareUCS2, RawString*, RawSmi*, RawSmi*,        \
    RawSmi*)                                                                   \
  V(RawBool*, CaseInsensitiveCompareUTF16, RawString*, RawSmi*, RawSmi*,       \
    RawSmi*)                                                                   \
  V(void, EnterSafepoint)                                                      \
  V(void, ExitSafepoint)                                                       \

}  // namespace dart

#endif  // RUNTIME_VM_RUNTIME_ENTRY_LIST_H_
