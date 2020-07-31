// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_SCOPE_BUILDER_H_
#define RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_SCOPE_BUILDER_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/object.h"
#include "vm/parser.h"  // For ParsedFunction.
#include "vm/scopes.h"

namespace dart {
namespace kernel {

// Builds scopes, populates parameters and local variables for
// certain functions declared in bytecode.
class BytecodeScopeBuilder : public ValueObject {
 public:
  explicit BytecodeScopeBuilder(ParsedFunction* parsed_function);

  void BuildScopes();

 private:
  void AddParameters(const Function& function,
                     LocalVariable::TypeCheckMode mode);
  LocalVariable* MakeVariable(const String& name, const AbstractType& type);
  LocalVariable* MakeReceiverVariable(bool is_parameter);

  ParsedFunction* parsed_function_;
  Zone* zone_;
  LocalScope* scope_;
};

}  // namespace kernel
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FRONTEND_BYTECODE_SCOPE_BUILDER_H_
