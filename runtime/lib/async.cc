// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "platform/assert.h"
#include "vm/bootstrap_natives.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/microtask_mirror_queues.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"

namespace dart {

// This flag is defined in "runtime/vm/microtask_mirror_queues.cc".
DECLARE_FLAG(bool, profile_microtasks);

DEFINE_NATIVE_ENTRY(AsyncStarMoveNext_debuggerStepCheck, 0, 1) {
#if !defined(PRODUCT)
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, generator, arguments->NativeArgAt(0));
  Debugger* debugger = isolate->debugger();
  if (debugger != nullptr && debugger->IsSingleStepping()) {
    debugger->AsyncStepInto(generator);
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
  auto& type = Type::Handle(zone, cls.GetInstantiationOf(zone, future_class));
  ASSERT(!type.IsNull());
  if (!type.IsInstantiated()) {
    const auto& instance_type_args =
        TypeArguments::Handle(zone, future.GetTypeArguments());
    type ^=
        type.InstantiateFrom(instance_type_args, Object::null_type_arguments(),
                             kNoneFree, Heap::kOld);
  }
  auto& type_args = TypeArguments::Handle(zone, type.arguments());
  ASSERT(type_args.IsNull() || type_args.Length() == 1);
  type_args = type_args.Canonicalize(thread);

  ASSERT(closure.delayed_type_arguments() ==
         Object::empty_type_arguments().ptr());
  closure.set_delayed_type_arguments(type_args);
  return closure.ptr();
}

DEFINE_NATIVE_ENTRY(MicrotaskMirrorQueue_onScheduleAsyncCallback, 0, 0) {
  // There is logic in `sdk/lib/async/schedule_microtask.dart` that ensures that
  // this function can only ever be called when the `--profile-microtasks` CLI
  // flag is set in non-PRODUCT modes.
#if !defined(PRODUCT)
  ASSERT(FLAG_profile_microtasks);
  const StackTrace& stack_trace = GetCurrentStackTrace(
      // We pass a `skip_frames` argument of 1 to skip the
      // `_MicrotaskMirrorQueue._onScheduleAsyncCallback` frame.
      1);
  MicrotaskMirrorQueues::GetQueue(static_cast<int64_t>(isolate->main_port()))
      ->OnScheduleAsyncCallback(stack_trace);
  return Object::null();
#else
  UNREACHABLE();
#endif  // !defined(PRODUCT)
}

DEFINE_NATIVE_ENTRY(MicrotaskMirrorQueue_onSchedulePriorityAsyncCallback,
                    0,
                    0) {
  // There is logic in `sdk/lib/async/schedule_microtask.dart` that ensures that
  // this function can only ever be called when the `--profile-microtasks` CLI
  // flag is set in non-PRODUCT modes.
#if !defined(PRODUCT)
  ASSERT(FLAG_profile_microtasks);
  MicrotaskMirrorQueues::GetQueue(static_cast<int64_t>(isolate->main_port()))
      ->OnSchedulePriorityAsyncCallback();
  return Object::null();
#else
  UNREACHABLE();
#endif  // !defined(PRODUCT)
}

DEFINE_NATIVE_ENTRY(MicrotaskMirrorQueue_onAsyncCallbackComplete, 0, 2) {
  // There is logic in `sdk/lib/async/schedule_microtask.dart` that ensures that
  // this function can only ever be called when the `--profile-microtasks` CLI
  // flag is set in non-PRODUCT modes.
#if !defined(PRODUCT)
  ASSERT(FLAG_profile_microtasks);
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, start_time, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, end_time, arguments->NativeArgAt(1));
  MicrotaskMirrorQueues::GetQueue(static_cast<int64_t>(isolate->main_port()))
      ->OnAsyncCallbackComplete(start_time.Value(), end_time.Value());
  return Object::null();
#else
  UNREACHABLE();
#endif  // !defined(PRODUCT)
}

}  // namespace dart
