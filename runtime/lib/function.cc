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
  return result.raw();
}

DEFINE_NATIVE_ENTRY(Closure_equals, 0, 2) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, other, arguments->NativeArgAt(1));
  ASSERT(!other.IsNull());
  // For implicit instance closures compare receiver instance and function's
  // name and owner (multiple function objects could exist for the same
  // function due to hot reload).
  // Objects of other closure kinds are unique, so use identity comparison.
  if (receiver.raw() == other.raw()) {
    return Bool::True().raw();
  }
  if (other.IsClosure()) {
    const Function& func_a = Function::Handle(zone, receiver.function());
    if (func_a.IsImplicitInstanceClosureFunction()) {
      const Closure& other_closure = Closure::Cast(other);
      const Function& func_b = Function::Handle(zone, other_closure.function());
      if (func_b.IsImplicitInstanceClosureFunction()) {
        const Context& context_a = Context::Handle(zone, receiver.context());
        const Context& context_b =
            Context::Handle(zone, other_closure.context());
        ObjectPtr receiver_a = context_a.At(0);
        ObjectPtr receiver_b = context_b.At(0);
        if ((receiver_a == receiver_b) &&
            ((func_a.raw() == func_b.raw()) ||
             ((func_a.name() == func_b.name()) &&
              (func_a.Owner() == func_b.Owner())))) {
          return Bool::True().raw();
        }
      }
    }
  }
  return Bool::False().raw();
}

DEFINE_NATIVE_ENTRY(Closure_computeHash, 0, 1) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  return Smi::New(receiver.ComputeHash());
}

}  // namespace dart
