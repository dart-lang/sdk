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
  const Array& fun_args_desc =
      Array::Handle(ArgumentsDescriptor::New(fun_arguments.Length(),
                                             fun_arg_names));
  const Object& result =
      Object::Handle(DartEntry::InvokeClosure(fun_arguments, fun_args_desc));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  return result.raw();
}


DEFINE_NATIVE_ENTRY(FunctionImpl_equals, 2) {
  const Instance& receiver = Instance::CheckedHandle(
      isolate, arguments->NativeArgAt(0));
  ASSERT(receiver.IsClosure());
  GET_NATIVE_ARGUMENT(Instance, other, arguments->NativeArgAt(1));
  ASSERT(!other.IsNull());
  if (receiver.raw() == other.raw()) return Bool::True().raw();
  if (other.IsClosure()) {
    const Function& func_a = Function::Handle(Closure::function(receiver));
    const Function& func_b = Function::Handle(Closure::function(other));
    if (func_a.raw() == func_b.raw()) {
      ASSERT(!func_a.IsImplicitStaticClosureFunction());
      if (func_a.IsImplicitInstanceClosureFunction()) {
        const Context& context_a = Context::Handle(Closure::context(receiver));
        const Context& context_b = Context::Handle(Closure::context(other));
        const Object& receiver_a = Object::Handle(context_a.At(0));
        const Object& receiver_b = Object::Handle(context_b.At(0));
        if (receiver_a.raw() == receiver_b.raw()) return Bool::True().raw();
      }
    }
  }
  return Bool::False().raw();
}


DEFINE_NATIVE_ENTRY(FunctionImpl_hashCode, 1) {
  const Instance& receiver = Instance::CheckedHandle(
      isolate, arguments->NativeArgAt(0));
  if (receiver.IsClosure()) {
    const Function& func = Function::Handle(Closure::function(receiver));
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
  UNREACHABLE();
  return Object::null();
}

}  // namespace dart
