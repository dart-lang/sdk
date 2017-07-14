// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_trace.h"
#include "vm/stack_frame.h"

namespace dart {

// Count the number of frames that are on the stack.
intptr_t StackTraceUtils::CountFrames(Thread* thread,
                                      int skip_frames,
                                      const Function& async_function) {
  Zone* zone = thread->zone();
  intptr_t frame_count = 0;
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle(zone);
  Function& function = Function::Handle(zone);
  const bool async_function_is_null = async_function.IsNull();
  while (frame != NULL) {
    if (frame->IsDartFrame()) {
      if (skip_frames > 0) {
        skip_frames--;
      } else {
        code = frame->LookupDartCode();
        function = code.function();
        frame_count++;
        if (!async_function_is_null &&
            (async_function.raw() == function.parent_function())) {
          return frame_count;
        }
      }
    }
    frame = frames.NextFrame();
  }
  // We hit the sentinel.
  ASSERT(async_function_is_null);
  return frame_count;
}

intptr_t StackTraceUtils::CollectFrames(Thread* thread,
                                        const Array& code_array,
                                        const Array& pc_offset_array,
                                        intptr_t array_offset,
                                        intptr_t count,
                                        int skip_frames) {
  Zone* zone = thread->zone();
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Function& function = Function::Handle(zone);
  Code& code = Code::Handle(zone);
  Smi& offset = Smi::Handle(zone);
  intptr_t collected_frames_count = 0;
  while ((frame != NULL) && (collected_frames_count < count)) {
    if (frame->IsDartFrame()) {
      if (skip_frames > 0) {
        skip_frames--;
      } else {
        code = frame->LookupDartCode();
        function = code.function();
        offset = Smi::New(frame->pc() - code.PayloadStart());
        code_array.SetAt(array_offset, code);
        pc_offset_array.SetAt(array_offset, offset);
        array_offset++;
        collected_frames_count++;
      }
    }
    frame = frames.NextFrame();
  }
  return collected_frames_count;
}

intptr_t StackTraceUtils::ExtractAsyncStackTraceInfo(
    Thread* thread,
    Function* async_function,
    StackTrace* async_stack_trace_out,
    Array* async_code_array,
    Array* async_pc_offset_array) {
  if (thread->async_stack_trace() == StackTrace::null()) {
    return 0;
  }
  *async_stack_trace_out = thread->async_stack_trace();
  ASSERT(!async_stack_trace_out->IsNull());
  const StackTrace& async_stack_trace =
      StackTrace::Handle(thread->async_stack_trace());
  const intptr_t async_stack_trace_length = async_stack_trace.Length();
  // At least two entries (0: gap marker, 1: async function).
  ASSERT(async_stack_trace_length >= 2);
  // Validate the structure of this stack trace.
  *async_code_array = async_stack_trace.code_array();
  ASSERT(!async_code_array->IsNull());
  *async_pc_offset_array = async_stack_trace.pc_offset_array();
  ASSERT(!async_pc_offset_array->IsNull());
  // We start with the asynchronous gap marker.
  ASSERT(async_code_array->At(0) != Code::null());
  ASSERT(async_code_array->At(0) ==
         StubCode::AsynchronousGapMarker_entry()->code());
  const Code& code = Code::Handle(Code::RawCast(async_code_array->At(1)));
  *async_function = code.function();
  ASSERT(!async_function->IsNull());
  ASSERT(async_function->IsAsyncFunction() ||
         async_function->IsAsyncGenerator());
  return async_stack_trace_length;
}

}  // namespace dart
