// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CLOSURE_FUNCTIONS_CACHE_H_
#define RUNTIME_VM_CLOSURE_FUNCTIONS_CACHE_H_

#include <functional>

#include "vm/allocation.h"
#include "vm/token_position.h"

namespace dart {

class Class;
class Function;
class FunctionPtr;

// Implementation of cache for inner closure functions.
//
// This cache is populated lazily by the compiler: When compiling a function,
// the flow graph builder will recursively traverse the kernel AST for the
// function and any inner functions. This will cause the lazy-creation of inner
// closure functions.
//
// The cache is currently implemented as a 2-level
// Map<OutermostMemberFunction, Map<FunctionNodeKernelOffset, Function>>.
//
// The function is also added to the growable list in order to
// satisfy the following requirements:
//   * closure functions list can grow while iterating
//   * the index of closure function must be stable
//
class ClosureFunctionsCache : public AllStatic {
 public:
  static FunctionPtr LookupClosureFunction(const Function& member_function,
                                           intptr_t kernel_offset);
  static FunctionPtr LookupClosureFunctionLocked(
      const Function& member_function,
      intptr_t kernel_offset);

  // Normally implicit closure functions are not added to this cache, however
  // during AOT compilation we might add those implicit closure functions
  // that have their original functions shaken to allow ProgramWalker to
  // discover them.
  static void AddClosureFunctionLocked(
      const Function& function,
      bool allow_implicit_closure_functions = false);

  static intptr_t FindClosureIndex(const Function& needle);
  static FunctionPtr ClosureFunctionFromIndex(intptr_t idx);

  // Visits all closure functions registered in the object store.
  //
  // Iterates in-order, thereby allowing new closures being added during the
  // iteration.
  //
  // The iteration continues until either [callback] returns `false` or all
  // closure functions have been visited.
  static void ForAllClosureFunctions(
      std::function<bool(const Function&)> callback);
};

}  // namespace dart

#endif  // RUNTIME_VM_CLOSURE_FUNCTIONS_CACHE_H_
