// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_frame.h"

#include "vm/code_index_table.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/raw_object.h"
#include "vm/stub_code.h"
#include "vm/visitor.h"

namespace dart {

void StackFrame::Print() const {
  OS::Print("[%-8s : sp(%p) ]\n", GetName(), sp());
}


void ExitFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // There are no objects to visit in this frame.
}


void EntryFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // Visit objects between SP and (FP - callee_save_area).
  ASSERT(visitor != NULL);
  RawObject** start = reinterpret_cast<RawObject**>(sp());
  RawObject** end = reinterpret_cast<RawObject**>(
      fp() - kWordSize + ExitLinkOffset());
  visitor->VisitPointers(start, end);
}


void DartFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // Visit objects between SP and FP.
  ASSERT(visitor != NULL);
  visitor->VisitPointers(reinterpret_cast<RawObject**>(sp()),
                         reinterpret_cast<RawObject**>(fp() - kWordSize));
}


RawFunction* DartFrame::LookupDartFunction() const {
  // Get access to the code index table.
  ASSERT(Isolate::Current() != NULL);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  return Code::Handle(code_index_table->LookupCode(pc())).function();
}


RawCode* DartFrame::LookupDartCode() const {
  // Get access to the code index table.
  ASSERT(Isolate::Current() != NULL);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  return code_index_table->LookupCode(pc());
}


bool DartFrame::FindExceptionHandler(uword* handler_pc) const {
  const Code& code = Code::Handle(LookupDartCode());
  ASSERT(!code.IsNull());

  // First try to find pc descriptor for the current pc.
  intptr_t try_index = -1;
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  for (intptr_t i = 0; i < descriptors.Length(); i++) {
    if (static_cast<uword>(descriptors.PC(i)) == pc() &&
        descriptors.TryIndex(i) != -1) {
      try_index = descriptors.TryIndex(i);
      break;
    }
  }
  if (try_index != -1) {
    // We found a pc descriptor, now try to see if we have an
    // exception catch handler for this try index.
    const ExceptionHandlers& handlers =
        ExceptionHandlers::Handle(code.exception_handlers());
    for (intptr_t j = 0; j < handlers.Length(); j++) {
      if (handlers.TryIndex(j) == try_index) {
        *handler_pc = handlers.HandlerPC(j);
        return true;
      }
    }
  }
  return false;
}


bool StubFrame::IsValid() const {
  // Get access to the code index table.
  ASSERT(Isolate::Current() != NULL);
  CodeIndexTable* code_index_table = Isolate::Current()->code_index_table();
  ASSERT(code_index_table != NULL);
  return Code::Handle(code_index_table->LookupCode(pc())).IsNull();
}


void StubFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // Visit objects between SP and FP.
  ASSERT(visitor != NULL);
  visitor->VisitPointers(reinterpret_cast<RawObject**>(sp()),
                         reinterpret_cast<RawObject**>(fp() - kWordSize));
}


StackFrameIterator::StackFrameIterator(bool validate)
    : validate_(validate), entry_(), exit_(), current_frame_(NULL) {
  SetupLastExitFrameData();  // Setup data for last exit frame.
}


StackFrame* StackFrameIterator::NextFrame() {
  // When we are at the start of iteration after having created an
  // iterator object current_frame_ will be NULL as we haven't seen
  // any frames yet. At this point if NextFrame is called it tries
  // to set up the next exit frame by reading the top_exit_frame_info
  // from the isolate. If we do not have any dart invocations yet
  // top_exit_frame_info will be 0 and so we would return NULL.

  // current_frame_ will also be NULL, when we are at the end of having
  // iterated through all the frames. if NextFrame is called at this
  // point we will try and set up the next exit frame but since we are
  // at the end of the iteration fp_ will be 0 and we would return NULL.
  if (current_frame_ == NULL) {
    if (!HasNextFrame()) {
      return NULL;
    }
    current_frame_ = NextExitFrame();
    return current_frame_;
  }
  ASSERT((validate_ == kDontValidateFrames) || current_frame_->IsValid());
  if (current_frame_->IsEntryFrame()) {
    if (HasNextFrame()) {  // We have another chained block.
      current_frame_ = NextExitFrame();
      return current_frame_;
    }
    current_frame_ = NULL;  // No more frames.
    return current_frame_;
  }
  ASSERT(current_frame_->IsExitFrame() ||
         current_frame_->IsDartFrame() ||
         current_frame_->IsStubFrame());

  // Consume dart/stub frames using StackFrameIterator::FrameSetIterator
  // until we are out of dart/stub frames at which point we return the
  // corresponding entry frame for that set of dart/stub frames.
  current_frame_ =
      (frames_.HasNext()) ? frames_.NextFrame(validate_) : NextEntryFrame();
  return current_frame_;
}


StackFrame* StackFrameIterator::FrameSetIterator::NextFrame(bool validate) {
  StackFrame* frame;
  ASSERT(HasNext());
  if (from_stub_exitframe_) {
    frame = &stub_frame_;
  } else {
    frame = &dart_frame_;
  }
  frame->sp_ = sp_;
  frame->fp_ = fp_;
  sp_ = frame->GetCallerSp();
  fp_ = frame->GetCallerFp();
  from_stub_exitframe_ = false;
  ASSERT((validate == kDontValidateFrames) || frame->IsValid());
  return frame;
}


ExitFrame* StackFrameIterator::NextExitFrame() {
  exit_.sp_ = frames_.sp_;
  exit_.fp_ = frames_.fp_;
  frames_.sp_ = exit_.GetCallerSp();
  frames_.fp_ = exit_.GetCallerFp();
  ASSERT(exit_.IsValid());
  return &exit_;
}


EntryFrame* StackFrameIterator::NextEntryFrame() {
  ASSERT(!frames_.HasNext());
  entry_.sp_ = frames_.sp_;
  entry_.fp_ = frames_.fp_;
  SetupNextExitFrameData();  // Setup data for next exit frame in chain.
  ASSERT(entry_.IsValid());
  return &entry_;
}

}  // namespace dart
