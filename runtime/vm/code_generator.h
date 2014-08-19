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
DECLARE_RUNTIME_ENTRY(AllocateContext);
DECLARE_RUNTIME_ENTRY(AllocateObject);
DECLARE_RUNTIME_ENTRY(BreakpointRuntimeHandler);
DECLARE_RUNTIME_ENTRY(SingleStepHandler);
DECLARE_RUNTIME_ENTRY(CloneContext);
DECLARE_RUNTIME_ENTRY(Deoptimize);
DECLARE_RUNTIME_ENTRY(FixCallersTarget);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerOneArg);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerTwoArgs);
DECLARE_RUNTIME_ENTRY(InlineCacheMissHandlerThreeArgs);
DECLARE_RUNTIME_ENTRY(StaticCallMissHandlerTwoArgs);
DECLARE_RUNTIME_ENTRY(Instanceof);
DECLARE_RUNTIME_ENTRY(TypeCheck);
DECLARE_RUNTIME_ENTRY(BadTypeError);
DECLARE_RUNTIME_ENTRY(NonBoolTypeError);
DECLARE_RUNTIME_ENTRY(InstantiateType);
DECLARE_RUNTIME_ENTRY(InstantiateTypeArguments);
DECLARE_RUNTIME_ENTRY(InvokeNoSuchMethodFunction);
DECLARE_RUNTIME_ENTRY(MegamorphicCacheMissHandler);
DECLARE_RUNTIME_ENTRY(OptimizeInvokedFunction);
DECLARE_RUNTIME_ENTRY(TraceICCall);
DECLARE_RUNTIME_ENTRY(PatchStaticCall);
DECLARE_RUNTIME_ENTRY(ReThrow);
DECLARE_RUNTIME_ENTRY(StackOverflow);
DECLARE_RUNTIME_ENTRY(Throw);
DECLARE_RUNTIME_ENTRY(TraceFunctionEntry);
DECLARE_RUNTIME_ENTRY(TraceFunctionExit);
DECLARE_RUNTIME_ENTRY(DeoptimizeMaterialize);
DECLARE_RUNTIME_ENTRY(UpdateFieldCid);
DECLARE_RUNTIME_ENTRY(InitStaticField);

const char* DeoptReasonToCString(ICData::DeoptReasonId deopt_reason);

void DeoptimizeAt(const Code& optimized_code, uword pc);
void DeoptimizeAll();

double DartModulo(double a, double b);
void SinCos(double arg, double* sin_res, double* cos_res);

}  // namespace dart

#endif  // VM_CODE_GENERATOR_H_
