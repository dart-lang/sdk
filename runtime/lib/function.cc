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
  const auto& func_a = Function::Handle(zone, receiver.function());
  const auto& func_b = Function::Handle(zone, other_closure.function());
  // Check that functions match.
  if (func_a.ptr() != func_b.ptr()) {
    // Non-implicit closures taken from different functions are not equal.
    if (!func_a.IsImplicitClosureFunction() ||
        !func_b.IsImplicitClosureFunction()) {
      return false;
    }
    // If the closure functions are not the same, check the function's name and
    // owner, as multiple function objects could exist for the same function due
    // to hot reload.
    if ((func_a.name() != func_b.name() || func_a.Owner() != func_b.Owner() ||
         func_a.is_static() != func_b.is_static())) {
      return false;
    }
  }
  // Check that the delayed type argument vectors match.
  if (receiver.delayed_type_arguments() !=
      other_closure.delayed_type_arguments()) {
    // Mismatches should only happen when a generic function is involved.
    ASSERT(func_a.IsGeneric() || func_b.IsGeneric());
    const auto& type_args_a =
        TypeArguments::Handle(zone, receiver.delayed_type_arguments());
    const auto& type_args_b =
        TypeArguments::Handle(zone, other_closure.delayed_type_arguments());
    if (type_args_a.IsNull() || type_args_b.IsNull() ||
        (type_args_a.Length() != type_args_b.Length()) ||
        !type_args_a.IsEquivalent(type_args_b, TypeEquality::kSyntactical)) {
      return false;
    }
  }
  if (func_a.IsImplicitClosureFunction()) {
    ASSERT(func_b.IsImplicitClosureFunction());
    if (!func_a.is_static()) {
      ASSERT(!func_b.is_static());
      // Check that the both receiver instances are the same.
      const Instance& receiver_a =
          Instance::Handle(zone, receiver.GetImplicitClosureReceiver());
      const Instance& receiver_b =
          Instance::Handle(zone, other_closure.GetImplicitClosureReceiver());
      return receiver_a.ptr() == receiver_b.ptr();
    }
  } else {
    ASSERT(!func_b.IsImplicitClosureFunction());
    if (func_a.IsGeneric()) {
      // Additional constraints for closures of generic functions:
      // (1) Different instantiations of the same generic closure
      //     with the same type arguments should be equal.
      //     This means that instantiated generic closures are not unique
      //     and equality of instantiated generic closures should not be
      //     based on identity.
      // (2) Instantiations of non-equal generic closures should be non-equal.
      //     This means that equality of non-instantiated generic closures
      //     should not be based on identity too as it won't match equality
      //     after instantiation.
      if ((receiver.GetContext() != other_closure.GetContext()) ||
          (receiver.instantiator_type_arguments() !=
           other_closure.instantiator_type_arguments()) ||
          (receiver.function_type_arguments() !=
           other_closure.function_type_arguments())) {
        return false;
      }
    } else {
      // Closures of non-generic functions are unique.
      return false;
    }
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
