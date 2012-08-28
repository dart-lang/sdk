// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_H_
#define VM_CODE_GENERATOR_H_

#include "vm/globals.h"
#include "vm/runtime_entry.h"

namespace dart {

// Declaration of runtime entries called from stub or generated code.
DECLARE_RUNTIME_ENTRY(AllocateArray);
DECLARE_RUNTIME_ENTRY(AllocateClosure);
DECLARE_RUNTIME_ENTRY(AllocateImplicitInstanceClosure);
DECLARE_RUNTIME_ENTRY(AllocateImplicitStaticClosure);
DECLARE_RUNTIME_ENTRY(AllocateContext);
DECLARE_RUNTIME_ENTRY(AllocateObject);
DECLARE_RUNTIME_ENTRY(AllocateObjectWithBoundsCheck);
DECLARE_RUNTIME_ENTRY(BreakpointStaticHandler);
DECLARE_RUNTIME_ENTRY(BreakpointReturnHandler);
DECLARE_RUNTIME_ENTRY(BreakpointDynamicHandler);
DECLARE_RUNTIME_ENTRY(CloneContext);
DECLARE_RUNTIME_ENTRY(ClosureArgumentMismatch);
DECLARE_RUNTIME_ENTRY(Deoptimize);
DECLARE_RUNTIME_ENTRY(FixCallersTarget);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs);
DECLARE_RUNTIME_ENTRY(Instanceof);
DECLARE_RUNTIME_ENTRY(InstantiateTypeArguments);
DECLARE_RUNTIME_ENTRY(InvokeImplicitClosureFunction);
DECLARE_RUNTIME_ENTRY(InvokeNoSuchMethodFunction);
DECLARE_RUNTIME_ENTRY(OptimizeInvokedFunction);
DECLARE_RUNTIME_ENTRY(PatchStaticCall);
DECLARE_RUNTIME_ENTRY(ReportObjectNotClosure);
DECLARE_RUNTIME_ENTRY(ResolveCompileInstanceFunction);
DECLARE_RUNTIME_ENTRY(ResolveImplicitClosureFunction);
DECLARE_RUNTIME_ENTRY(ResolveImplicitClosureThroughGetter);
DECLARE_RUNTIME_ENTRY(ReThrow);
DECLARE_RUNTIME_ENTRY(StackOverflow);
DECLARE_RUNTIME_ENTRY(Throw);
DECLARE_RUNTIME_ENTRY(TraceFunctionEntry);
DECLARE_RUNTIME_ENTRY(TraceFunctionExit);

#define DEOPT_REASONS(V)                                                       \
  V(DeoptUnknown)                                                              \
  V(DeoptIncrLocal)                                                            \
  V(DeoptIncrInstance)                                                         \
  V(DeoptIncrInstanceOneClass)                                                 \
  V(DeoptInstanceGetterSameTarget)                                             \
  V(DeoptInstanceGetter)                                                       \
  V(DeoptStoreIndexed)                                                         \
  V(DeoptStoreIndexedPolymorphic)                                              \
  V(DeoptPolymorphicInstanceCallSmiOnly)                                       \
  V(DeoptPolymorphicInstanceCallSmiFail)                                       \
  V(DeoptPolymorphicInstanceCallTestFail)                                      \
  V(DeoptIntegerToDouble)                                                      \
  V(DeoptDoubleToDouble)                                                       \
  V(DeoptBinarySmiOp)                                                          \
  V(DeoptBinaryMintOp)                                                         \
  V(DeoptBinaryDoubleOp)                                                       \
  V(DeoptInstanceSetterSameTarget)                                             \
  V(DeoptInstanceSetter)                                                       \
  V(DeoptSmiEquality)                                                          \
  V(DeoptEquality)                                                             \
  V(DeoptRelationalOp)                                                         \
  V(DeoptSmiCompareSmi)                                                        \
  V(DeoptSmiCompareAny)                                                        \
  V(DeoptDoubleCompareDouble)                                                  \
  V(DeoptEqualityNoFeedback)                                                   \
  V(DeoptEqualityClassCheck)                                                   \
  V(DeoptDoubleComparison)                                                     \
  V(DeoptLoadIndexedFixedArray)                                                \
  V(DeoptLoadIndexedGrowableArray)                                             \
  V(DeoptLoadIndexedPolymorphic)                                               \
  V(DeoptNoTypeFeedback)                                                       \
  V(DeoptSAR)                                                                  \
  V(DeoptUnaryOp)                                                              \
  V(DeoptCheckClass)                                                           \
  V(DeoptCheckSmi)                                                             \
  V(DeoptAtCall)                                                               \

enum DeoptReasonId {
#define DEFINE_ENUM_LIST(name) k##name,
DEOPT_REASONS(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
};


RawCode* ResolveCompileInstanceCallTarget(Isolate* isolate,
                                          const Instance& receiver);

}  // namespace dart

#endif  // VM_CODE_GENERATOR_H_
