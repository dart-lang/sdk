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
  const Array& fun_arguments = Array::CheckedHandle(arguments->NativeArgAt(0));
  const Array& fun_arg_names = Array::CheckedHandle(arguments->NativeArgAt(1));
  const Array& fun_args_desc = Array::Handle(
      ArgumentsDescriptor::New(fun_arguments.Length(), fun_arg_names));
  const Object& result =
      Object::Handle(DartEntry::InvokeClosure(fun_arguments, fun_args_desc));
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
    const Function& func_a = Function::Handle(receiver.function());
    const Function& func_b = Function::Handle(Closure::Cast(other).function());
    if (func_a.raw() == func_b.raw()) {
      ASSERT(!func_a.IsImplicitStaticClosureFunction());
      if (func_a.IsImplicitInstanceClosureFunction()) {
        const Context& context_a = Context::Handle(receiver.context());
        const Context& context_b =
            Context::Handle(Closure::Cast(other).context());
        const Object& receiver_a = Object::Handle(context_a.At(0));
        const Object& receiver_b = Object::Handle(context_b.At(0));
        if (receiver_a.raw() == receiver_b.raw()) return Bool::True().raw();
      }
    } else if (func_a.IsImplicitInstanceClosureFunction() &&
               func_b.IsImplicitInstanceClosureFunction()) {
      // TODO(rmacnak): Patch existing tears off during reload instead.
      const Context& context_a = Context::Handle(receiver.context());
      const Context& context_b =
          Context::Handle(Closure::Cast(other).context());
      const Object& receiver_a = Object::Handle(context_a.At(0));
      const Object& receiver_b = Object::Handle(context_b.At(0));
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
  const Function& func = Function::Handle(receiver.function());
  // Hash together name, class name and signature.
  const Class& cls = Class::Handle(func.Owner());
  intptr_t result = String::Handle(func.name()).Hash();
  result += String::Handle(func.Signature()).Hash();
  result += String::Handle(cls.Name()).Hash();
  // Finalize hash value like for strings so that it fits into a smi.
  result += result << 3;
  result ^= result >> 11;
  result += result << 15;
  result &= ((static_cast<intptr_t>(1) << String::kHashBits) - 1);
  return Smi::New(result);
}


DEFINE_NATIVE_ENTRY(Closure_clone, 1) {
  const Closure& receiver =
      Closure::CheckedHandle(zone, arguments->NativeArgAt(0));
  const Function& func = Function::Handle(zone, receiver.function());
  const Context& ctx = Context::Handle(zone, receiver.context());
  Context& cloned_ctx =
      Context::Handle(zone, Context::New(ctx.num_variables()));
  cloned_ctx.set_parent(Context::Handle(zone, ctx.parent()));
  Object& inst = Object::Handle(zone);
  for (int i = 0; i < ctx.num_variables(); i++) {
    inst = ctx.At(i);
    cloned_ctx.SetAt(i, inst);
  }
  return Closure::New(func, cloned_ctx);
}


}  // namespace dart
