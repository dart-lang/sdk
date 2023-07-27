// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/call.h"

#include "vm/class_finalizer.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

// TODO(dartbug.com/36607): Cache the trampolines.
FunctionPtr TrampolineFunction(const String& name,
                               const FunctionType& signature,
                               const FunctionType& c_signature,
                               bool is_leaf) {
  ASSERT(signature.num_implicit_parameters() == 1);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Library& lib = Library::Handle(zone, Library::FfiLibrary());
  const Class& owner_class = Class::Handle(zone, lib.toplevel_class());
  Function& function = Function::Handle(
      zone, Function::New(signature, name, UntaggedFunction::kFfiTrampoline,
                          /*is_static=*/true,
                          /*is_const=*/false,
                          /*is_abstract=*/false,
                          /*is_external=*/false,
                          /*is_native=*/false, owner_class,
                          TokenPosition::kMinSource));
  function.set_is_debuggable(false);

  // Create unique names for the parameters, as they are used in scope building
  // and error messages.
  if (signature.num_fixed_parameters() > 0) {
    function.CreateNameArray();
    function.SetParameterNameAt(0, Symbols::ClosureParameter());
    auto& param_name = String::Handle(zone);
    for (intptr_t i = 1, n = signature.num_fixed_parameters(); i < n; ++i) {
      param_name = Symbols::NewFormatted(thread, ":ffi_param%" Pd, i);
      function.SetParameterNameAt(i, param_name);
    }
  }

  function.SetFfiCSignature(c_signature);
  function.SetFfiIsLeaf(is_leaf);
  function.SetFfiTrampolineKind(FfiTrampolineKind::kCall);

  return function.ptr();
}

FunctionPtr TrampolineFunction(const FunctionType& dart_signature,
                               const FunctionType& c_signature,
                               bool is_leaf,
                               const String& function_name) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  String& name =
      String::Handle(zone, Symbols::NewFormatted(thread, "FfiTrampoline_%s",
                                                 function_name.ToCString()));

  // Trampolines have no optional arguments.
  FunctionType& signature = FunctionType::Handle(zone, FunctionType::New());
  const intptr_t num_fixed = dart_signature.num_fixed_parameters();
  signature.set_num_implicit_parameters(1);
  signature.set_num_fixed_parameters(num_fixed);
  signature.set_result_type(
      AbstractType::Handle(zone, dart_signature.result_type()));
  signature.set_parameter_types(
      Array::Handle(zone, dart_signature.parameter_types()));
  signature ^= ClassFinalizer::FinalizeType(signature);

  return TrampolineFunction(name, signature, c_signature, is_leaf);
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
