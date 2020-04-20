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
  ///
  /// If [on_sync_frames] is non-nullptr, it will be called for every
  /// synchronous frame which is collected.
  static void CollectFramesLazy(
      Thread* thread,
      const GrowableObjectArray& code_array,
      const GrowableObjectArray& pc_offset_array,
      int skip_frames,
      std::function<void(StackFrame*)>* on_sync_frames = nullptr,
      bool* has_async = nullptr);

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

  // The number of frames involved in a "sync-async" gap: a synchronous initial
  // invocation of an asynchronous function. See CheckAndSkipAsync.
  static constexpr intptr_t kSyncAsyncFrameGap = 2;

  // A synchronous invocation of an async function involves the following
  // frames:
  //   <async function>__<anonymous_closure>    (0)
  //   _Closure.call                            (1)
  //   _AsyncAwaitCompleter.start               (2)
  //   <async_function>                         (3)
  //
  // Alternatively, for bytecode or optimized frames, we may see:
  //   <async function>__<anonymous_closure>    (0)
  //   _AsyncAwaitCompleter.start               (1)
  //   <async_function>                         (2)
  static bool CheckAndSkipAsync(int* skip_sync_async_frames_count,
                                const String& function_name) {
    ASSERT(*skip_sync_async_frames_count > 0);
    // Make sure any function objects for methods used here are marked for
    // retention by the precompiler, even if otherwise not needed at runtime.
    //
    // _AsyncAwaitCompleter.start is marked with the vm:entry-point pragma.
    if (function_name.Equals(Symbols::_AsyncAwaitCompleterStart())) {
      *skip_sync_async_frames_count = 0;
      return true;
    }
    // _Closure.call is explicitly checked in Precompiler::MustRetainFunction.
    if (function_name.Equals(Symbols::_ClosureCall()) &&
        *skip_sync_async_frames_count == 2) {
      (*skip_sync_async_frames_count)--;
      return true;
    }
    return false;
  }
};

}  // namespace dart

#endif  // RUNTIME_VM_STACK_TRACE_H_
