// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_TRACE_H_
#define RUNTIME_VM_STACK_TRACE_H_

#include "vm/allocation.h"
#include "vm/flag_list.h"
#include "vm/object.h"
#include "vm/symbols.h"

namespace dart {

class StackTraceUtils : public AllStatic {
 public:
  /// Collects all frames on the current stack until an async/async* frame is
  /// hit which has yielded before (i.e. is not in sync-async case).
  ///
  /// From there on finds the closure of the async/async* frame and starts
  /// traversing the listeners:
  ///     while (closure != null) {
  ///       yield_index = closure.context[Context::kAsyncJumpVarIndex]
  ///       pc = closure.function.code.pc_descriptors.LookupPcFromYieldIndex(
  ///           yield_index);
  ///       <emit pc in frame>
  ///       closure = closure.context[Context::kAsyncCompleterVarIndex]._future
  ///           ._resultOrListeners.callback;
  ///     }
  static void CollectFramesLazy(Thread* thread,
                                const GrowableObjectArray& code_array,
                                const GrowableObjectArray& pc_offset_array,
                                int skip_frames);

  /// Counts the number of stack frames.
  /// Skips over the first |skip_frames|.
  /// If |async_function| is not null, stops at the function that has
  /// |async_function| as its parent, and records in 'sync_async_end' whether
  /// |async_function| was called synchronously.
  static intptr_t CountFrames(Thread* thread,
                              int skip_frames,
                              const Function& async_function,
                              bool* sync_async_end);

  /// Collects |count| frames into |code_array| and |pc_offset_array|.
  /// Writing begins at |array_offset|.
  /// Skips over the first |skip_frames|.
  /// Returns the number of frames collected.
  static intptr_t CollectFrames(Thread* thread,
                                const Array& code_array,
                                const Array& pc_offset_array,
                                intptr_t array_offset,
                                intptr_t count,
                                int skip_frames);

  /// If |thread| has no async_stack_trace, does nothing.
  /// Populates |async_function| with the top function of the async stack
  /// trace. Populates |async_stack_trace|, |async_code_array|, and
  /// |async_pc_offset_array| with the thread's async_stack_trace.
  /// Returns the length of the asynchronous stack trace.
  static intptr_t ExtractAsyncStackTraceInfo(Thread* thread,
                                             Function* async_function,
                                             StackTrace* async_stack_trace,
                                             Array* async_code_array,
                                             Array* async_pc_offset_array);

  // Find the closure corresponding to `function` in (presumably) its parent
  // stack frame (based on the frame's SP).
  static RawClosure* FindClosureInFrame(RawObject** last_object_in_caller,
                                        const Function& function,
                                        bool is_interpreted) {
    NoSafepointScope nsp;

    // The callee has function signature
    //   :async_op([result, exception, stack])
    // So we are guaranteed to
    //   a) have only (up to three) tagged arguments on the stack until we find
    //      the :async_op closure, and
    //   b) find the async closure.
    auto& closure = Closure::Handle();
    for (intptr_t i = 0; i < 4; i++) {
      // KBC builds the stack upwards instead of the usual downwards stack.
      RawObject* arg = last_object_in_caller[(is_interpreted ? -i : i)];
      if (arg->IsHeapObject() && arg->GetClassId() == kClosureCid) {
        closure = Closure::RawCast(arg);
        if (closure.function() == function.raw()) {
          return closure.raw();
        }
      }
    }
    UNREACHABLE();
  }
};

// Helper class for finding the closure of the caller.
// This is done via the _AsyncAwaitCompleter which holds a
// FutureResultOrListeners which in turn holds a callback.
class CallerClosureFinder {
 public:
  // Instance caches library and field references.
  // This way we don't have to do the look-ups for every frame in the stack.
  explicit CallerClosureFinder(Zone* zone);

  RawClosure* FindCallerInAsyncClosure(const Context& receiver_context);

  RawClosure* FindCallerInAsyncGenClosure(const Context& receiver_context);

  RawClosure* FindCaller(const Closure& receiver_closure);

  bool IsRunningAsync(const Closure& receiver_closure);

 private:
  // Keep in sync with
  // sdk/lib/async/stream_controller.dart:_StreamController._STATE_SUBSCRIBED.
  const intptr_t kStreamController_StateSubscribed = 1;

  Context& receiver_context_;
  Function& receiver_function_;

  Object& context_entry_;
  Object& is_sync;
  Object& future_;
  Object& listener_;
  Object& callback_;
  Object& controller_;
  Object& state_;
  Object& var_data_;

  Class& future_impl_class;
  Class& async_await_completer_class;
  Class& future_listener_class;
  Class& async_start_stream_controller_class;
  Class& stream_controller_class;
  Class& controller_subscription_class;
  Class& buffering_stream_subscription_class;
  Class& async_stream_controller_class;

  Field& completer_is_sync_field;
  Field& completer_future_field;
  Field& future_result_or_listeners_field;
  Field& callback_field;
  Field& controller_controller_field;
  Field& var_data_field;
  Field& state_field;
  Field& on_data_field;
};

}  // namespace dart

#endif  // RUNTIME_VM_STACK_TRACE_H_
