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
// The cache is currently implemented as O(n) lookup in a growable list.
//
// Parts of the VM have certain requirements that are maintained:
//
//   * parent functions need to come before inner functions
//   * closure functions list can grow while iterating
//   * the index of closure function must be stable
//
// If the linear lookup turns out to be too expensive, the list of closures
// could be maintained in a hash map, with the key being the token position of
// the closure. There are almost no collisions with this simple hash value.
// However, iterating over all closure functions becomes more difficult,
// especially when the list/map changes while iterating over it (see
// requirements above).
class ClosureFunctionsCache : public AllStatic {
 public:
  static FunctionPtr LookupClosureFunction(const Class& owner,
                                           TokenPosition pos);
  static FunctionPtr LookupClosureFunctionLocked(const Class& owner,
                                                 TokenPosition pos);

  static FunctionPtr LookupClosureFunction(const Function& parent,
                                           TokenPosition token_pos);
  static FunctionPtr LookupClosureFunctionLocked(const Function& parent,
                                                 TokenPosition token_pos);

  // Normally implicit closure functions are not added to this cache, however
  // during AOT compilation we might add those implicit closure functions
  // that have their original functions shaken to allow ProgramWalker to
  // discover them.
  static void AddClosureFunctionLocked(
      const Function& function,
      bool allow_implicit_closure_functions = false);

  static intptr_t FindClosureIndex(const Function& needle);
  static FunctionPtr ClosureFunctionFromIndex(intptr_t idx);

  static FunctionPtr GetUniqueInnerClosure(const Function& outer);

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
