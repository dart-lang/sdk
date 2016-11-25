// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "vm/bootstrap_natives.h"
#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"

namespace dart {

static void IterateFrames(const GrowableObjectArray& code_list,
                          const GrowableObjectArray& pc_offset_list,
                          int skip_frames) {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
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

// Creates a Stacktrace object from the current stack.
//
// Skips the first skip_frames Dart frames.
const Stacktrace& GetCurrentStacktrace(int skip_frames) {
  const GrowableObjectArray& code_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  const GrowableObjectArray& pc_offset_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  IterateFrames(code_list, pc_offset_list, skip_frames);
  const Array& code_array = Array::Handle(Array::MakeArray(code_list));
  const Array& pc_offset_array =
      Array::Handle(Array::MakeArray(pc_offset_list));
  const Stacktrace& stacktrace =
      Stacktrace::Handle(Stacktrace::New(code_array, pc_offset_array));
  return stacktrace;
}

// An utility method for convenient printing of dart stack traces when
// inside 'gdb'. Note: This function will only work when there is a
// valid exit frame information. It will not work when a breakpoint is
// set in dart code and control is got inside 'gdb' without going through
// the runtime or native transition stub.
void _printCurrentStacktrace() {
  const Stacktrace& stacktrace = GetCurrentStacktrace(0);
  OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());
}

// Like _printCurrentStacktrace, but works in a NoSafepointScope.
void _printCurrentStacktraceNoSafepoint() {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    OS::Print("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

DEFINE_NATIVE_ENTRY(StackTrace_current, 0) {
  const Stacktrace& stacktrace = GetCurrentStacktrace(1);
  return stacktrace.raw();
}

}  // namespace dart
