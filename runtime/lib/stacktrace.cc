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

static const intptr_t kDefaultStackAllocation = 8;

static StackTracePtr CurrentSyncStackTraceLazy(Thread* thread,
                                               intptr_t skip_frames = 1) {
  Zone* zone = thread->zone();

  const auto& code_array = GrowableObjectArray::ZoneHandle(
      zone, GrowableObjectArray::New(kDefaultStackAllocation));
  const auto& pc_offset_array = GrowableObjectArray::ZoneHandle(
      zone, GrowableObjectArray::New(kDefaultStackAllocation));

  // Collect the frames.
  StackTraceUtils::CollectFramesLazy(thread, code_array, pc_offset_array,
                                     skip_frames);

  const auto& code_array_fixed =
      Array::Handle(zone, Array::MakeFixedLength(code_array));
  const auto& pc_offset_array_fixed =
      Array::Handle(zone, Array::MakeFixedLength(pc_offset_array));

  return StackTrace::New(code_array_fixed, pc_offset_array_fixed);
}

static StackTracePtr CurrentSyncStackTrace(Thread* thread,
                                           intptr_t skip_frames = 1) {
  Zone* zone = thread->zone();
  const Function& null_function = Function::ZoneHandle(zone);

  // Determine how big the stack trace is.
  const intptr_t stack_trace_length =
      StackTraceUtils::CountFrames(thread, skip_frames, null_function, nullptr);

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

// Gets current stack trace for `thread`.
// This functions itself handles the --causel-async-stacks case.
// For --lazy-async-stacks see `CurrentSyncStackTraceLazy`.
// For fallback see `CurrentSyncStackTrace`.
// Extracts the causal async stack from the thread if any set, then prepends
// the current sync. stack up until the current async function (if any).
static StackTracePtr CurrentStackTrace(Thread* thread,
                                       bool for_async_function,
                                       intptr_t skip_frames = 1) {
  if (FLAG_lazy_async_stacks) {
    return CurrentSyncStackTraceLazy(thread, skip_frames);
  }
  // Return the synchronous stack trace.
  return CurrentSyncStackTrace(thread, skip_frames);
}

StackTracePtr GetStackTraceForException() {
  Thread* thread = Thread::Current();
  return CurrentStackTrace(thread, false, 0);
}

DEFINE_NATIVE_ENTRY(StackTrace_current, 0, 0) {
  return CurrentStackTrace(thread, false);
}

static void AppendFrames(const GrowableObjectArray& code_list,
                         const GrowableObjectArray& pc_offset_list,
                         int skip_frames) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != NULL);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle(zone);
  Smi& offset = Smi::Handle(zone);
  for (; frame != NULL; frame = frames.NextFrame()) {
    if (!frame->IsDartFrame()) {
      continue;
    }
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }

    code = frame->LookupDartCode();
    offset = Smi::New(frame->pc() - code.PayloadStart());
    code_list.Add(code);
    pc_offset_list.Add(offset);
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
  const Array& code_array = Array::Handle(Array::MakeFixedLength(code_list));
  const Array& pc_offset_array =
      Array::Handle(Array::MakeFixedLength(pc_offset_list));
  const StackTrace& stacktrace =
      StackTrace::Handle(StackTrace::New(code_array, pc_offset_array));
  return stacktrace;
}

bool HasStack() {
  Thread* thread = Thread::Current();
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  return frame != nullptr;
}

}  // namespace dart
