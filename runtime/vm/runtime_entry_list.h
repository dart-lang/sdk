// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RUNTIME_ENTRY_LIST_H_
#define VM_RUNTIME_ENTRY_LIST_H_

namespace dart {

#define RUNTIME_ENTRY_LIST(V)                                                  \
  V(AllocateArray)                                                             \
  V(AllocateContext)                                                           \
  V(AllocateObject)                                                            \
  V(BreakpointRuntimeHandler)                                                  \
  V(SingleStepHandler)                                                         \
  V(CloneContext)                                                              \
  V(FixCallersTarget)                                                          \
  V(FixAllocationStubTarget)                                                   \
  V(InlineCacheMissHandlerOneArg)                                              \
  V(InlineCacheMissHandlerTwoArgs)                                             \
  V(InlineCacheMissHandlerThreeArgs)                                           \
  V(StaticCallMissHandlerOneArg)                                               \
  V(StaticCallMissHandlerTwoArgs)                                              \
  V(Instanceof)                                                                \
  V(TypeCheck)                                                                 \
  V(BadTypeError)                                                              \
  V(NonBoolTypeError)                                                          \
  V(InstantiateType)                                                           \
  V(InstantiateTypeArguments)                                                  \
  V(InvokeClosureNoSuchMethod)                                                 \
  V(InvokeNoSuchMethodDispatcher)                                              \
  V(MegamorphicCacheMissHandler)                                               \
  V(OptimizeInvokedFunction)                                                   \
  V(TraceICCall)                                                               \
  V(PatchStaticCall)                                                           \
  V(ReThrow)                                                                   \
  V(StackOverflow)                                                             \
  V(Throw)                                                                     \
  V(TraceFunctionEntry)                                                        \
  V(TraceFunctionExit)                                                         \
  V(DeoptimizeMaterialize)                                                     \
  V(UpdateFieldCid)                                                            \
  V(InitStaticField)                                                           \
  V(GrowRegExpStack)                                                           \
  V(CompileFunction)                                                           \

#define LEAF_RUNTIME_ENTRY_LIST(V)                                             \
  V(void, PrintStopMessage, const char*)                                       \
  V(intptr_t, DeoptimizeCopyFrame, uword, uword)                               \
  V(void, DeoptimizeFillFrame, uword)                                          \
  V(void, StoreBufferBlockProcess, Thread*)                                    \
  V(intptr_t, BigintCompare, RawBigint*, RawBigint*)                           \
  V(double, LibcPow, double, double)                                           \
  V(double, DartModulo, double, double)                                        \
  V(double, LibcFloor, double)                                                 \
  V(double, LibcCeil, double)                                                  \
  V(double, LibcTrunc, double)                                                 \
  V(double, LibcRound, double)                                                 \
  V(double, LibcCos, double)                                                   \
  V(double, LibcSin, double)                                                   \
  V(RawBool*, CaseInsensitiveCompareUC16,                                      \
    RawString*, RawSmi*, RawSmi*, RawSmi*)                                     \

}  // namespace dart

#endif  // VM_RUNTIME_ENTRY_LIST_H_
