// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Function_apply, 0, 2) {
  const int kTypeArgsLen = 0;  // TODO(regis): Add support for generic function.
  const Array& fun_arguments =
      Array::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Array& fun_arg_names =
      Array::CheckedHandle(zone, arguments->NativeArgAt(1));
  const Array& fun_args_desc = Array::Handle(
      zone, ArgumentsDescriptor::NewBoxed(kTypeArgsLen, fun_arguments.Length(),
                                          fun_arg_names));
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeClosure(thread, fun_arguments, fun_args_desc));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.ptr();
}

static bool ClosureEqualsHelper(Zone* zone,
                                const Closure& receiver,
                                const Object& other) {
  if (receiver.ptr() == other.ptr()) {
    return true;
  }
  if (!other.IsClosure()) {
    return false;
  }
  const auto& other_closure = Closure::Cast(other);
  // Check that the delayed type argument vectors match.
  if (receiver.delayed_type_arguments() !=
      other_closure.delayed_type_arguments()) {
    // Mismatches should only happen when a generic function is involved.
    ASSERT(Function::Handle(receiver.function()).IsGeneric() ||
           Function::Handle(other_closure.function()).IsGeneric());
    return false;
  }
  // Closures that are not implicit instance closures are unique.
  const auto& func_a = Function::Handle(zone, receiver.function());
  if (!func_a.IsImplicitClosureFunction()) {
    return false;
  }
  const auto& func_b = Function::Handle(zone, other_closure.function());
  if (!func_b.IsImplicitClosureFunction()) {
    return false;
  }
  // If the closure functions are not the same, check the function's name and
  // owner, as multiple function objects could exist for the same function due
  // to hot reload.
  if (func_a.ptr() != func_b.ptr() &&
      (func_a.name() != func_b.name() || func_a.Owner() != func_b.Owner() ||
       func_a.is_static() != func_b.is_static())) {
    return false;
  }
  if (!func_a.is_static()) {
    // Check that the both receiver instances are the same.
    const Context& context_a = Context::Handle(zone, receiver.context());
    const Context& context_b = Context::Handle(zone, other_closure.context());
    return context_a.At(0) == context_b.At(0);
  }
  return true;
}

DEFINE_NATIVE_ENTRY(Closure_equals, 0, 2) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, other, arguments->NativeArgAt(1));
  ASSERT(!other.IsNull());
  return Bool::Get(ClosureEqualsHelper(zone, receiver, other)).ptr();
}

DEFINE_NATIVE_ENTRY(Closure_computeHash, 0, 1) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Smi::New(receiver.ComputeHash());
}

}  // namespace dart
