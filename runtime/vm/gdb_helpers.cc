// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "vm/object.h"
#include "vm/stack_frame.h"

namespace dart {

#if !defined(PRODUCT)

DART_EXPORT
void _printRawObject(RawObject* object) {
  OS::PrintErr("%s\n", Object::Handle(object).ToCString());
}


DART_EXPORT
Object* _handle(RawObject* object) {
  return &Object::Handle(object);
}


// An utility method for convenient printing of dart stack traces when
// inside 'gdb'. Note: This function will only work when there is a
// valid exit frame information. It will not work when a breakpoint is
// set in dart code and control is got inside 'gdb' without going through
// the runtime or native transition stub.
DART_EXPORT
void _printDartStackTrace() {
  const StackTrace& stacktrace = GetCurrentStackTrace(0);
  OS::PrintErr("=== Current Trace:\n%s===\n", stacktrace.ToCString());
}


// Like _printDartStackTrace, but works in a NoSafepointScope. Use it if you're
// in the middle of a GC or interested in stub frames.
DART_EXPORT
void _printStackTrace() {
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}


class PrintObjectPointersVisitor : public ObjectPointerVisitor {
 public:
  PrintObjectPointersVisitor() : ObjectPointerVisitor(Isolate::Current()) {}

  void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** p = first; p <= last; p++) {
      Object& obj = Object::Handle(*p);
      OS::PrintErr("%p: %s\n", p, obj.ToCString());
    }
  }
};


DART_EXPORT
void _printStackTraceWithLocals() {
  PrintObjectPointersVisitor visitor;
  StackFrameIterator frames(StackFrameIterator::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame->VisitObjectPointers(&visitor);
    frame = frames.NextFrame();
  }
}

#endif  // !PRODUCT

}  // namespace dart
