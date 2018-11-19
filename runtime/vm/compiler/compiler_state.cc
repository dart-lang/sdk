// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/compiler_state.h"

#ifndef DART_PRECOMPILED_RUNTIME

#include <functional>

#include "vm/scopes.h"

namespace dart {

template <typename T>
T* PutIfAbsent(Thread* thread,
               ZoneGrowableArray<T*>** array_slot,
               intptr_t index,
               std::function<T*()> create) {
  auto array = *array_slot;

  if (array == nullptr) {
    Zone* const Z = thread->zone();
    *array_slot = array = new (Z) ZoneGrowableArray<T*>(Z, index + 1);
  }

  while (array->length() <= index) {
    array->Add(nullptr);
  }

  if (array->At(index) == nullptr) {
    (*array)[index] = create();
  }
  return array->At(index);
}

LocalVariable* CompilerState::GetDummyCapturedVariable(intptr_t context_id,
                                                       intptr_t index) {
  return PutIfAbsent<LocalVariable>(
      thread(), &dummy_captured_vars_, index, [&]() {
        Zone* const Z = thread()->zone();
        const AbstractType& dynamic_type =
            AbstractType::ZoneHandle(Z, Type::DynamicType());
        const String& name = String::ZoneHandle(
            Z, Symbols::NewFormatted(thread(), ":context_var%" Pd, index));
        LocalVariable* var = new (Z)
            LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                          name, dynamic_type, /*param_type=*/nullptr);
        var->set_is_captured();
        var->set_index(VariableIndex(index));
        return var;
      });
}

const GrowableArray<LocalVariable*>& CompilerState::GetDummyContextVariables(
    intptr_t context_id,
    intptr_t num_context_variables) {
  return PutIfAbsent<LocalScope>(
             thread(), &dummy_scopes_, num_context_variables,
             [&]() {
               Zone* const Z = thread()->zone();

               LocalScope* scope = new (Z) LocalScope(
                   /*parent=*/NULL, /*function_level=*/0, /*loop_level=*/0);
               scope->set_context_level(0);

               for (intptr_t i = 0; i < num_context_variables; i++) {
                 LocalVariable* var = GetDummyCapturedVariable(context_id, i);
                 scope->AddVariable(var);
                 scope->AddContextVariable(var);
               }

               return scope;
             })
      ->context_variables();
}

}  // namespace dart

#endif  // DART_PRECOMPILED_RUNTIME
