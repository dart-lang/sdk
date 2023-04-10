// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_TRACE_H_
#define RUNTIME_VM_STACK_TRACE_H_

#include <functional>

#include "vm/allocation.h"
#include "vm/flag_list.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

// Helper class for finding the closure of the caller.
class CallerClosureFinder {
 public:
  explicit CallerClosureFinder(Zone* zone);

  // Recursively follow any `_FutureListener.result`.
  // If no `result`, then return (bottom) `_FutureListener.callback`
  ClosurePtr GetCallerInFutureImpl(const Object& future_);

  // Get caller closure from _FutureListener.
  // Returns closure found either via the `result` Future, or the `callback`.
  ClosurePtr GetCallerInFutureListener(const Object& future_listener);

  // Find caller closure from an _AsyncStarStreamController instance
  // corresponding to async* function.
  // Returns either the `onData` or the Future awaiter.
  ClosurePtr FindCallerInAsyncStarStreamController(
      const Object& async_star_stream_controller);

  // Find caller closure from a function receiver closure.
  // For async* functions, async functions, `Future.timeout` and `Future.wait`,
  // we can do this by finding and following their awaited Futures.
  ClosurePtr FindCaller(const Closure& receiver_closure);

  // Find caller closure from a SuspendState of a resumed async function.
  ClosurePtr FindCallerFromSuspendState(const SuspendState& suspend_state);

  // Returns true if given closure function is a Future callback
  // corresponding to an async/async* function or async* body callback.
  bool IsAsyncCallback(const Function& function);

  // Returns SuspendState from the given callback which corresponds
  // to an async/async* function.
  SuspendStatePtr GetSuspendStateFromAsyncCallback(const Closure& closure);

  // Get sdk/lib/async/future_impl.dart:_FutureListener.state.
  intptr_t GetFutureListenerState(const Object& future_listener);

  // Get sdk/lib/async/future_impl.dart:_FutureListener.callback.
  ClosurePtr GetFutureListenerCallback(const Object& future_listener);

  // Get sdk/lib/async/future_impl.dart:_FutureListener.result.
  ObjectPtr GetFutureListenerResult(const Object& future_listener);

  // Get sdk/lib/async/future_impl.dart:_Future._resultOrListeners.
  ObjectPtr GetFutureFutureListener(const Object& future);

  bool HasCatchError(const Object& future_listener);

  // Tests if given [function] with given value of :suspend_state variable
  // was suspended at least once and running asynchronously.
  static bool WasPreviouslySuspended(const Function& function,
                                     const Object& suspend_state_var);

 private:
  Closure& closure_;
  Context& receiver_context_;
  Function& receiver_function_;
  Function& parent_function_;
  SuspendState& suspend_state_;

  Object& context_entry_;
  Object& future_;
  Object& listener_;
  Object& callback_;
  Object& controller_;
  Object& state_;
  Object& var_data_;
  Object& callback_instance_;

  Class& future_impl_class;
  Class& future_listener_class;
  Class& async_star_stream_controller_class;
  Class& stream_controller_class;
  Class& sync_stream_controller_class;
  Class& controller_subscription_class;
  Class& buffering_stream_subscription_class;
  Class& stream_iterator_class;

  Field& future_result_or_listeners_field;
  Field& callback_field;
  Field& future_listener_state_field;
  Field& future_listener_result_field;
  Field& controller_controller_field;
  Field& var_data_field;
  Field& state_field;
  Field& on_data_field;
  Field& state_data_field;
  Field& has_value_field;

  DISALLOW_COPY_AND_ASSIGN(CallerClosureFinder);
};

class StackTraceUtils : public AllStatic {
 public:
  static ClosurePtr ClosureFromFrameFunction(
      Zone* zone,
      CallerClosureFinder* caller_closure_finder,
      const DartFrameIterator& frames,
      StackFrame* frame,
      bool* skip_frame,
      bool* is_async);

  static void UnwindAwaiterChain(Zone* zone,
                                 const GrowableObjectArray& code_array,
                                 GrowableArray<uword>* pc_offset_array,
                                 CallerClosureFinder* caller_closure_finder,
                                 const Closure& leaf_closure);

  /// Collects all frames on the current stack until an async/async* frame is
  /// hit which has yielded before (i.e. is not in sync-async case).
  ///
  /// From there on finds the closure of the async/async* frame and starts
  /// traversing the listeners.
  ///
  /// If [on_sync_frames] is non-null, it will be called for every
  /// synchronous frame which is collected.
  static void CollectFrames(
      Thread* thread,
      const GrowableObjectArray& code_array,
      GrowableArray<uword>* pc_offset_array,
      int skip_frames,
      std::function<void(StackFrame*)>* on_sync_frames = nullptr,
      bool* has_async = nullptr);
};

}  // namespace dart

#endif  // RUNTIME_VM_STACK_TRACE_H_
