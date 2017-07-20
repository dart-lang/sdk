// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/compiler.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_NATIVE_ENTRY(Function_apply, 2) {
  const int kTypeArgsLen = 0;  // TODO(regis): Add support for generic function.
  const Array& fun_arguments =
      Array::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Array& fun_arg_names =
      Array::CheckedHandle(zone, arguments->NativeArgAt(1));
  const Array& fun_args_desc = Array::Handle(
      zone, ArgumentsDescriptor::New(kTypeArgsLen, fun_arguments.Length(),
                                     fun_arg_names));
  const Object& result = Object::Handle(
      zone, DartEntry::InvokeClosure(fun_arguments, fun_args_desc));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}

DEFINE_NATIVE_ENTRY(Closure_equals, 2) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  GET_NATIVE_ARGUMENT(Instance, other, arguments->NativeArgAt(1));
  ASSERT(!other.IsNull());
  if (receiver.raw() == other.raw()) return Bool::True().raw();
  if (other.IsClosure()) {
    const Function& func_a = Function::Handle(zone, receiver.function());
    const Function& func_b =
        Function::Handle(zone, Closure::Cast(other).function());
    if (func_a.raw() == func_b.raw()) {
      ASSERT(!func_a.IsImplicitStaticClosureFunction());
      if (func_a.IsImplicitInstanceClosureFunction()) {
        const Context& context_a = Context::Handle(zone, receiver.context());
        const Context& context_b =
            Context::Handle(zone, Closure::Cast(other).context());
        const Object& receiver_a = Object::Handle(zone, context_a.At(0));
        const Object& receiver_b = Object::Handle(zone, context_b.At(0));
        if (receiver_a.raw() == receiver_b.raw()) return Bool::True().raw();
      }
    } else if (func_a.IsImplicitInstanceClosureFunction() &&
               func_b.IsImplicitInstanceClosureFunction()) {
      // TODO(rmacnak): Patch existing tears off during reload instead.
      const Context& context_a = Context::Handle(zone, receiver.context());
      const Context& context_b =
          Context::Handle(zone, Closure::Cast(other).context());
      const Object& receiver_a = Object::Handle(zone, context_a.At(0));
      const Object& receiver_b = Object::Handle(zone, context_b.At(0));
      if ((receiver_a.raw() == receiver_b.raw()) &&
          (func_a.name() == func_b.name()) &&
          (func_a.Owner() == func_b.Owner())) {
        return Bool::True().raw();
      }
    }
  }
  return Bool::False().raw();
}

DEFINE_NATIVE_ENTRY(Closure_hashCode, 1) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(zone, receiver.function());
  return func.GetClosureHashCode();
}

DEFINE_NATIVE_ENTRY(Closure_clone, 1) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  const TypeArguments& instantiator_type_arguments =
      TypeArguments::Handle(zone, receiver.instantiator_type_arguments());
  const TypeArguments& function_type_arguments =
      TypeArguments::Handle(zone, receiver.function_type_arguments());
  const Function& function = Function::Handle(zone, receiver.function());
  const Context& context = Context::Handle(zone, receiver.context());
  Context& cloned_context =
      Context::Handle(zone, Context::New(context.num_variables()));
  cloned_context.set_parent(Context::Handle(zone, context.parent()));
  Object& instance = Object::Handle(zone);
  for (int i = 0; i < context.num_variables(); i++) {
    instance = context.At(i);
    cloned_context.SetAt(i, instance);
  }
  return Closure::New(instantiator_type_arguments, function_type_arguments,
                      function, cloned_context);
}

}  // namespace dart
