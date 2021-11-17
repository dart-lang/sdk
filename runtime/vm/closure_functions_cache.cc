// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/closure_functions_cache.h"

#include "vm/compiler/jit/compiler.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

FunctionPtr ClosureFunctionsCache::LookupClosureFunction(
    const Class& owner,
    TokenPosition token_pos) {
  auto thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  return LookupClosureFunctionLocked(owner, token_pos);
}

FunctionPtr ClosureFunctionsCache::LookupClosureFunctionLocked(
    const Class& owner,
    TokenPosition token_pos) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  DEBUG_ASSERT(
      thread->isolate_group()->program_lock()->IsCurrentThreadReader());

  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  auto& closure = Function::Handle(zone);
  intptr_t num_closures = closures.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    if (closure.token_pos() == token_pos && closure.Owner() == owner.ptr()) {
      return closure.ptr();
    }
  }
  return Function::null();
}

FunctionPtr ClosureFunctionsCache::LookupClosureFunction(
    const Function& parent,
    TokenPosition token_pos) {
  auto thread = Thread::Current();
  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  return LookupClosureFunctionLocked(parent, token_pos);
}

FunctionPtr ClosureFunctionsCache::LookupClosureFunctionLocked(
    const Function& parent,
    TokenPosition token_pos) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  DEBUG_ASSERT(
      thread->isolate_group()->program_lock()->IsCurrentThreadReader());

  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  auto& closure = Function::Handle(zone);
  intptr_t num_closures = closures.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    closure ^= closures.At(i);
    if (closure.token_pos() == token_pos &&
        closure.parent_function() == parent.ptr()) {
      return closure.ptr();
    }
  }
  return Function::null();
}

void ClosureFunctionsCache::AddClosureFunctionLocked(
    const Function& function,
    bool allow_implicit_closure_functions /* = false */) {
  ASSERT(!Compiler::IsBackgroundCompilation());

  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  DEBUG_ASSERT(
      thread->isolate_group()->program_lock()->IsCurrentThreadWriter());

  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  ASSERT(!closures.IsNull());
  ASSERT(allow_implicit_closure_functions ||
         function.IsNonImplicitClosureFunction());
  closures.Add(function, Heap::kOld);
}

intptr_t ClosureFunctionsCache::FindClosureIndex(const Function& needle) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());

  const auto& closures_array =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  intptr_t num_closures = closures_array.Length();
  for (intptr_t i = 0; i < num_closures; i++) {
    if (closures_array.At(i) == needle.ptr()) {
      return i;
    }
  }
  return -1;
}

FunctionPtr ClosureFunctionsCache::ClosureFunctionFromIndex(intptr_t idx) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());

  const auto& closures_array =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  if (idx < 0 || idx >= closures_array.Length()) {
    return Function::null();
  }
  return Function::RawCast(closures_array.At(idx));
}

FunctionPtr ClosureFunctionsCache::GetUniqueInnerClosure(
    const Function& outer) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());

  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  auto& entry = Function::Handle(zone);
  for (intptr_t i = (closures.Length() - 1); i >= 0; i--) {
    entry ^= closures.At(i);
    if (entry.parent_function() == outer.ptr()) {
#if defined(DEBUG)
      auto& other = Function::Handle(zone);
      for (intptr_t j = i - 1; j >= 0; j--) {
        other ^= closures.At(j);
        ASSERT(other.parent_function() != outer.ptr());
      }
#endif
      return entry.ptr();
    }
  }
  return Function::null();
}

void ClosureFunctionsCache::ForAllClosureFunctions(
    std::function<bool(const Function&)> callback) {
  auto thread = Thread::Current();
  auto zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  auto& current_data = Array::Handle(zone);
  auto& entry = Function::Handle(zone);

  // NOTE: Inner functions may get added to the closures array while iterating -
  // we guarantee that any closure functions added on this thread by a
  // [callback] call will be visited as well.
  //
  // We avoid holding a lock while accessing the closures array, since often
  // times [callback] will do very heavy things (e.g. compiling the function).
  //
  // This means we can possibly miss a concurrently added closure function -
  // which the caller should be ok with (or it guarantees that this cannot
  // happen).
  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());

  if (!thread->IsInStoppedMutatorsScope()) {
    // The empty read locker scope will implicitly issue an acquire memory
    // fence, which means any closure functions added so far will be visible and
    // iterated further down.
    SafepointReadRwLocker ml(thread, thread->isolate_group()->program_lock());
  }

  // We have an outer loop to ensure any new closure functions added by
  // [callback] will be iterated as well.
  intptr_t i = 0;
  while (true) {
    intptr_t current_length = closures.Length();
    if (i == current_length) break;

    current_data = closures.data();
    if (current_data.Length() < current_length) {
      current_length = current_data.Length();
    }

    for (; i < current_length; ++i) {
      entry ^= current_data.At(i);
      if (!callback(entry)) {
        return;  // Stop iteration.
      }
    }
  }
}

}  // namespace dart
