// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_TRACE_H_
#define RUNTIME_VM_STACK_TRACE_H_

#include "vm/allocation.h"
#include "vm/flag_list.h"
#include "vm/object.h"

namespace dart {

class StackTraceUtils : public AllStatic {
 public:
  /// Counts the number of stack frames.
  /// Skips over the first |skip_frames|.
  /// If |async_function| is not null, stops at the function that has
  /// |async_function| as its parent.
  static intptr_t CountFrames(Thread* thread,
                              int skip_frames,
                              const Function& async_function);

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
};

}  // namespace dart

#endif  // RUNTIME_VM_STACK_TRACE_H_
