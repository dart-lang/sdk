// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CODE_GENERATOR_H_
#define VM_CODE_GENERATOR_H_

#include "vm/globals.h"
#include "vm/runtime_entry.h"

namespace dart {

class Array;
template <typename T> class GrowableArray;
class ICData;
class Instance;

// Declaration of runtime entries called from stub or generated code.
DECLARE_RUNTIME_ENTRY(AllocateArray);
DECLARE_RUNTIME_ENTRY(AllocateClosure);
DECLARE_RUNTIME_ENTRY(AllocateImplicitInstanceClosure);
DECLARE_RUNTIME_ENTRY(AllocateImplicitStaticClosure);
DECLARE_RUNTIME_ENTRY(AllocateContext);
DECLARE_RUNTIME_ENTRY(AllocateObject);
DECLARE_RUNTIME_ENTRY(AllocateObjectWithBoundsCheck);
DECLARE_RUNTIME_ENTRY(ArgumentDefinitionTest);
DECLARE_RUNTIME_ENTRY(BreakpointStaticHandler);
DECLARE_RUNTIME_ENTRY(BreakpointReturnHandler);
DECLARE_RUNTIME_ENTRY(BreakpointDynamicHandler);
DECLARE_RUNTIME_ENTRY(CloneContext);
DECLARE_RUNTIME_ENTRY(Deoptimize);
DECLARE_RUNTIME_ENTRY(FixCallersTarget);
DECLARE_LEAF_RUNTIME_ENTRY(void, HeapTraceStore, RawObject*, uword, RawObject*);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerThreeArgs);
DECLARE_RUNTIME_ENTRY(InstanceFunctionLookup);
DECLARE_RUNTIME_ENTRY(Instanceof);
DECLARE_RUNTIME_ENTRY(InstantiateTypeArguments);
DECLARE_RUNTIME_ENTRY(InvokeNoSuchMethodFunction);
DECLARE_RUNTIME_ENTRY(MegamorphicCacheMissHandler);
DECLARE_RUNTIME_ENTRY(OptimizeInvokedFunction);
DECLARE_RUNTIME_ENTRY(TraceICCall);
DECLARE_RUNTIME_ENTRY(PatchStaticCall);
DECLARE_RUNTIME_ENTRY(InvokeNonClosure);
DECLARE_RUNTIME_ENTRY(ReThrow);
DECLARE_RUNTIME_ENTRY(StackOverflow);
DECLARE_RUNTIME_ENTRY(Throw);
DECLARE_RUNTIME_ENTRY(TraceFunctionEntry);
DECLARE_RUNTIME_ENTRY(TraceFunctionExit);
DECLARE_RUNTIME_ENTRY(DeoptimizeMaterializeDoubles);
DECLARE_RUNTIME_ENTRY(UpdateICDataTwoArgs);
DECLARE_RUNTIME_ENTRY(UpdateFieldCid);


#define DEOPT_REASONS(V)                                                       \
  V(Unknown)                                                                   \
  V(InstanceGetter)                                                            \
  V(PolymorphicInstanceCallTestFail)                                           \
  V(InstanceCallNoICData)                                                      \
  V(IntegerToDouble)                                                           \
  V(BinarySmiOp)                                                               \
  V(BinaryMintOp)                                                              \
  V(ShiftMintOp)                                                               \
  V(BinaryDoubleOp)                                                            \
  V(InstanceSetter)                                                            \
  V(Equality)                                                                  \
  V(RelationalOp)                                                              \
  V(EqualityClassCheck)                                                        \
  V(NoTypeFeedback)                                                            \
  V(UnaryOp)                                                                   \
  V(UnboxInteger)                                                              \
  V(CheckClass)                                                                \
  V(CheckSmi)                                                                  \
  V(CheckArrayBound)                                                           \
  V(AtCall)                                                                    \
  V(DoubleToSmi)                                                               \
  V(Int32Load)                                                                 \
  V(Uint32Load)                                                                \
  V(GuardField)                                                                \
  V(NumReasons)                                                                \

enum DeoptReasonId {
#define DEFINE_ENUM_LIST(name) kDeopt##name,
DEOPT_REASONS(DEFINE_ENUM_LIST)
#undef DEFINE_ENUM_LIST
};


const char* DeoptReasonToText(intptr_t deopt_id);


RawCode* ResolveCompileInstanceCallTarget(
    const Instance& receiver,
    const ICData& ic_data,
    const Array& arguments_descriptor);

void DeoptimizeAt(const Code& optimized_code, uword pc);
void DeoptimizeAll();
void DeoptimizeIfOwner(const GrowableArray<intptr_t>& classes);

double DartModulo(double a, double b);

}  // namespace dart

#endif  // VM_CODE_GENERATOR_H_
