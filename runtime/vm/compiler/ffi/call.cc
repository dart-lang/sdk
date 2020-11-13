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
FunctionPtr TrampolineFunction(const Function& dart_signature,
                               const Function& c_signature) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  String& name = String::Handle(zone, Symbols::New(thread, "FfiTrampoline"));
  const Library& lib = Library::Handle(zone, Library::FfiLibrary());
  const Class& owner_class = Class::Handle(zone, lib.toplevel_class());
  Function& function =
      Function::Handle(zone, Function::New(name, FunctionLayout::kFfiTrampoline,
                                           /*is_static=*/true,
                                           /*is_const=*/false,
                                           /*is_abstract=*/false,
                                           /*is_external=*/false,
                                           /*is_native=*/false, owner_class,
                                           TokenPosition::kMinSource));
  function.set_is_debuggable(false);
  function.set_num_fixed_parameters(dart_signature.num_fixed_parameters());
  function.set_result_type(
      AbstractType::Handle(zone, dart_signature.result_type()));
  function.set_parameter_types(
      Array::Handle(zone, dart_signature.parameter_types()));

  // The signature function won't have any names for the parameters. We need to
  // assign unique names for scope building and error messages.
  function.CreateNameArrayIncludingFlags(Heap::kNew);
  const intptr_t num_params = dart_signature.num_fixed_parameters();
  for (intptr_t i = 0; i < num_params; ++i) {
    if (i == 0) {
      name = Symbols::ClosureParameter().raw();
    } else {
      name = Symbols::NewFormatted(thread, ":ffi_param%" Pd, i);
    }
    function.SetParameterNameAt(i, name);
  }
  function.TruncateUnusedParameterFlags();
  function.SetFfiCSignature(c_signature);

  Type& type = Type::Handle(zone);
  type ^= function.SignatureType(Nullability::kLegacy);
  type ^= ClassFinalizer::FinalizeType(type);
  function.SetSignatureType(type);
  ASSERT(
      Type::Handle(function.SignatureType(Nullability::kLegacy)).IsFinalized());

  return function.raw();
}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
