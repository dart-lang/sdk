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

static constexpr intptr_t kDefaultStackAllocation = 8;

static StackTracePtr CreateStackTraceObject(
    Zone* zone,
    const GrowableObjectArray& code_list,
    const GrowableArray<uword>& pc_offset_list) {
  const auto& code_array =
      Array::Handle(zone, Array::MakeFixedLength(code_list));
  const auto& pc_offset_array = TypedData::Handle(
      zone, TypedData::New(kUintPtrCid, pc_offset_list.length()));
  {
    NoSafepointScope no_safepoint;
    memmove(pc_offset_array.DataAddr(0), pc_offset_list.data(),
            pc_offset_list.length() * kWordSize);
  }
  return StackTrace::New(code_array, pc_offset_array);
}

// Gets current stack trace for `thread`.
static StackTracePtr CurrentStackTrace(Thread* thread,
                                       intptr_t skip_frames = 1) {
  Zone* zone = thread->zone();

  const auto& code_array = GrowableObjectArray::ZoneHandle(
      zone, GrowableObjectArray::New(kDefaultStackAllocation));
  GrowableArray<uword> pc_offset_array(kDefaultStackAllocation);

  // Collect the frames.
  StackTraceUtils::CollectFrames(thread, skip_frames,
                                 [&](const StackTraceUtils::Frame& frame) {
                                   code_array.Add(frame.code);
                                   pc_offset_array.Add(frame.pc_offset);
                                 });

  return CreateStackTraceObject(zone, code_array, pc_offset_array);
}

StackTracePtr GetStackTraceForException() {
  Thread* thread = Thread::Current();
  return CurrentStackTrace(thread, 0);
}

DEFINE_NATIVE_ENTRY(StackTrace_current, 0, 0) {
  return CurrentStackTrace(thread);
}

static void AppendFrames(const GrowableObjectArray& code_list,
                         GrowableArray<uword>* pc_offset_list,
                         int skip_frames) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames, thread,
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  ASSERT(frame != nullptr);  // We expect to find a dart invocation frame.
  Code& code = Code::Handle(zone);
  for (; frame != nullptr; frame = frames.NextFrame()) {
    if (!frame->IsDartFrame()) {
      continue;
    }
    if (skip_frames > 0) {
      skip_frames--;
      continue;
    }

    code = frame->LookupDartCode();
    const intptr_t pc_offset = frame->pc() - code.PayloadStart();
    code_list.Add(code);
    pc_offset_list->Add(pc_offset);
  }
}

// Creates a StackTrace object from the current stack.
//
// Skips the first skip_frames Dart frames.
const StackTrace& GetCurrentStackTrace(int skip_frames) {
  Zone* zone = Thread::Current()->zone();
  const GrowableObjectArray& code_list =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  GrowableArray<uword> pc_offset_list;
  AppendFrames(code_list, &pc_offset_list, skip_frames);

  const StackTrace& stacktrace = StackTrace::Handle(
      zone, CreateStackTraceObject(zone, code_list, pc_offset_list));
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
