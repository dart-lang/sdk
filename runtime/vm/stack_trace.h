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
  static constexpr uword kFutureListenerPcOffset = 1;

  struct Frame {
    // Corresponding on stack frame or |nullptr| if this is an awaiter frame
    // or a gap.
    StackFrame* frame;

    // Code object corresponding to this frame.
    const Code& code;

    // Offset into the code object corresponding to this frame.
    //
    // Will be set to |kFutureListenerPcOffset| if this frame corresponds to
    // future listener that is not yet executing.
    uword pc_offset;

    // Closure corresponding to the awaiter frame or |null| if this is
    // a synchronous frame or a gap.
    const Closure& closure;

    // |true| if an asynchronous exception would be caught by a |catchError|
    // listener somewhere between the previous frame and this frame.
    bool has_async_catch_error;
  };

  // Returns |true| if this function is needed to correctly unwind through
  // awaiter chains. This means AOT compiler should retain |Function| object,
  // its signature and the corresponding |Code| object (so that we could
  // perform the reverse lookup).
  static bool IsNeededForAsyncAwareUnwinding(const Function& function);

  /// Collects all frames on the current stack until an async/async* frame is
  /// hit which has yielded before (i.e. is not in sync-async case).
  ///
  /// From there on finds the closure of the async/async* frame and starts
  /// traversing the listeners.
  static void CollectFrames(
      Thread* thread,
      int skip_frames,
      const std::function<void(const Frame&)>& handle_frame);

  // If |closure| has an awaiter-link pointing to the |SuspendState|
  // the return that object.
  static bool GetSuspendState(const Closure& closure, Object* suspend_state);
};

}  // namespace dart

#endif  // RUNTIME_VM_STACK_TRACE_H_
