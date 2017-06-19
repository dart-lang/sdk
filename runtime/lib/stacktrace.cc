// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "vm/bootstrap_natives.h"
#include "vm/debugger.h"
#include "vm/exceptions.h"
#include "vm/native_entry.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"
#include "vm/stack_trace.h"

namespace dart {

DECLARE_FLAG(bool, show_invisible_frames);

static RawStackTrace* CurrentSyncStackTrace(Thread* thread,
                                            intptr_t skip_frames = 1) {
  Zone* zone = thread->zone();
  const Function& null_function = Function::ZoneHandle(zone);

  // Determine how big the stack trace is.
  const intptr_t stack_trace_length =
      StackTraceUtils::CountFrames(thread, skip_frames, null_function);

  // Allocate once.
  const Array& code_array =
      Array::ZoneHandle(zone, Array::New(stack_trace_length));
  const Array& pc_offset_array =
      Array::ZoneHandle(zone, Array::New(stack_trace_length));

  // Collect the frames.
  const intptr_t collected_frames_count = StackTraceUtils::CollectFrames(
      thread, code_array, pc_offset_array, 0, stack_trace_length, skip_frames);

  ASSERT(collected_frames_count == stack_trace_length);

  return StackTrace::New(code_array, pc_offset_array);
}


static RawStackTrace* CurrentStackTrace(
    Thread* thread,
    bool for_async_function,
    intptr_t skip_frames = 1,
    bool causal_async_stacks = FLAG_causal_async_stacks) {
  if (!causal_async_stacks) {
    // Return the synchronous stack trace.
    return CurrentSyncStackTrace(thread, skip_frames);
  }

  Zone* zone = thread->zone();
  Code& code = Code::ZoneHandle(zone);
  Smi& offset = Smi::ZoneHandle(zone);
  Function& async_function = Function::ZoneHandle(zone);
  StackTrace& async_stack_trace = StackTrace::ZoneHandle(zone);
  Array& async_code_array = Array::ZoneHandle(zone);
  Array& async_pc_offset_array = Array::ZoneHandle(zone);

  StackTraceUtils::ExtractAsyncStackTraceInfo(
      thread, &async_function, &async_stack_trace, &async_code_array,
      &async_pc_offset_array);

  // Determine the size of the stack trace.
  const intptr_t extra_frames = for_async_function ? 1 : 0;
  const intptr_t synchronous_stack_trace_length =
      StackTraceUtils::CountFrames(thread, skip_frames, async_function);

  const intptr_t capacity = synchronous_stack_trace_length +
                            extra_frames;  // For the asynchronous gap.

  // Allocate memory for the stack trace.
  const Array& code_array = Array::ZoneHandle(zone, Array::New(capacity));
  const Array& pc_offset_array = Array::ZoneHandle(zone, Array::New(capacity));

  intptr_t write_cursor = 0;
  if (for_async_function) {
    // Place the asynchronous gap marker at the top of the stack trace.
    code = StubCode::AsynchronousGapMarker_entry()->code();
    ASSERT(!code.IsNull());
    offset = Smi::New(0);
    code_array.SetAt(write_cursor, code);
    pc_offset_array.SetAt(write_cursor, offset);
    write_cursor++;
  }

  // Append the synchronous stack trace.
  const intptr_t collected_frames_count = StackTraceUtils::CollectFrames(
      thread, code_array, pc_offset_array, write_cursor,
      synchronous_stack_trace_length, skip_frames);

  write_cursor += collected_frames_count;

  ASSERT(write_cursor == capacity);

  return StackTrace::New(code_array, pc_offset_array, async_stack_trace);
}


RawStackTrace* GetStackTraceForException() {
  Thread* thread = Thread::Current();
  return CurrentStackTrace(thread, false, 0);
}


DEFINE_NATIVE_ENTRY(StackTrace_current, 0) {
  return CurrentStackTrace(thread, false);
}


DEFINE_NATIVE_ENTRY(StackTrace_asyncStackTraceHelper, 1) {
  if (!FLAG_causal_async_stacks) return Object::null();

  GET_NATIVE_ARGUMENT(Closure, async_op, arguments->NativeArgAt(0));
  if (FLAG_support_debugger) {
    Debugger* debugger = isolate->debugger();
    if (debugger != NULL) {
      debugger->MaybeAsyncStepInto(async_op);
    }
  }
  return CurrentStackTrace(thread, true);
}


DEFINE_NATIVE_ENTRY(StackTrace_clearAsyncThreadStackTrace, 0) {
  thread->clear_async_stack_trace();
  return Object::null();
}


DEFINE_NATIVE_ENTRY(StackTrace_setAsyncThreadStackTrace, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(StackTrace, stack_trace,
                               arguments->NativeArgAt(0));
  thread->set_async_stack_trace(stack_trace);
  return Object::null();
}


static void AppendFrames(const GrowableObjectArray& code_list,
                         const GrowableObjectArray& pc_offset_list,
                         int skip_frames) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle();
  Smi& offset = Smi::Handle();
  while (frame != NULL) {
    if (frame->IsDartFrame()) {
      if (skip_frames > 0) {
        skip_frames--;
      } else {
        code = frame->LookupDartCode();
        offset = Smi::New(frame->pc() - code.PayloadStart());
        code_list.Add(code);
        pc_offset_list.Add(offset);
      }
    }
    frame = frames.NextFrame();
  }
}


// Creates a StackTrace object from the current stack.
//
// Skips the first skip_frames Dart frames.
const StackTrace& GetCurrentStackTrace(int skip_frames) {
  const GrowableObjectArray& code_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const GrowableObjectArray& pc_offset_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  AppendFrames(code_list, pc_offset_list, skip_frames);
  const Array& code_array = Array::Handle(Array::MakeArray(code_list));
  const Array& pc_offset_array =
      Array::Handle(Array::MakeArray(pc_offset_list));
  const StackTrace& stacktrace =
      StackTrace::Handle(StackTrace::New(code_array, pc_offset_array));
  return stacktrace;
}


// An utility method for convenient printing of dart stack traces when
// inside 'gdb'. Note: This function will only work when there is a
// valid exit frame information. It will not work when a breakpoint is
// set in dart code and control is got inside 'gdb' without going through
// the runtime or native transition stub.
void _printCurrentStackTrace() {
  const StackTrace& stacktrace = GetCurrentStackTrace(0);
  OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());
}


// Like _printCurrentStackTrace, but works in a NoSafepointScope.
void _printCurrentStackTraceNoSafepoint() {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

}  // namespace dart
