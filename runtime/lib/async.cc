// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"

namespace dart {

DEFINE_NATIVE_ENTRY(AsyncStarMoveNext_debuggerStepCheck, 0, 1) {
#if !defined(PRODUCT)
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, async_op, arguments->NativeArgAt(0));
  Debugger* debugger = isolate->debugger();
  if (debugger != NULL) {
    debugger->MaybeAsyncStepInto(async_op);
  }
#endif
  return Object::null();
}

// Instantiate generic [closure] using the type argument T
// corresponding to Future<T> in the given [future] instance
// (which may extend or implement Future).
DEFINE_NATIVE_ENTRY(SuspendState_instantiateClosureWithFutureTypeArgument,
                    0,
                    2) {
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, future, arguments->NativeArgAt(1));
  IsolateGroup* isolate_group = thread->isolate_group();

  const auto& future_class =
      Class::Handle(zone, isolate_group->object_store()->future_class());
  ASSERT(future_class.NumTypeArguments() == 1);

  const auto& cls = Class::Handle(zone, future.clazz());
  auto& type =
      AbstractType::Handle(zone, cls.GetInstantiationOf(zone, future_class));
  ASSERT(!type.IsNull());
  if (!type.IsInstantiated()) {
    const auto& instance_type_args =
        TypeArguments::Handle(zone, future.GetTypeArguments());
    type =
        type.InstantiateFrom(instance_type_args, Object::null_type_arguments(),
                             kNoneFree, Heap::kNew);
  }
  auto& type_args = TypeArguments::Handle(zone, type.arguments());
  if (type_args.Length() != 1) {
    // Create a new TypeArguments vector of length 1.
    type = type_args.TypeAtNullSafe(0);
    type_args = TypeArguments::New(1);
    type_args.SetTypeAt(0, type);
  }
  type_args = type_args.Canonicalize(thread, nullptr);

  ASSERT(closure.delayed_type_arguments() ==
         Object::empty_type_arguments().ptr());
  closure.set_delayed_type_arguments(type_args);
  return closure.ptr();
}

}  // namespace dart
