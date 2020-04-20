// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "lib/stacktrace.h"
#include "vm/heap/safepoint.h"
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
  StackFrame::DumpCurrentTrace();
}

// Like _printDartStackTrace, but works when stopped in generated code.
// Must be called with the current fp, sp, and pc.
DART_EXPORT
void _printGeneratedStackTrace(uword fp, uword sp, uword pc) {
  StackFrameIterator frames(fp, sp, pc, ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

// Like _printDartStackTrace, but works in the interpreter loop.
// Must be called with the current interpreter fp, sp, and pc.
// Note that sp[0] is not modified, but sp[1] will be trashed.
DART_EXPORT
void _printInterpreterStackTrace(RawObject** fp,
                                 RawObject** sp,
                                 const KBCInstr* pc) {
  Thread* thread = Thread::Current();
  sp[1] = Function::null();
  sp[2] = Bytecode::null();
  sp[3] = reinterpret_cast<RawObject*>(reinterpret_cast<uword>(pc));
  sp[4] = reinterpret_cast<RawObject*>(fp);
  RawObject** exit_fp = sp + 1 + kKBCDartFrameFixedSize;
  thread->set_top_exit_frame_info(reinterpret_cast<uword>(exit_fp));
  thread->set_execution_state(Thread::kThreadInVM);
  _printDartStackTrace();
  thread->set_execution_state(Thread::kThreadInGenerated);
  thread->set_top_exit_frame_info(0);
}

class PrintObjectPointersVisitor : public ObjectPointerVisitor {
 public:
  PrintObjectPointersVisitor()
      : ObjectPointerVisitor(IsolateGroup::Current()) {}

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
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame->VisitObjectPointers(&visitor);
    frame = frames.NextFrame();
  }
}

#endif  // !PRODUCT

}  // namespace dart
