// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_frame.h"

#include "vm/assembler_macros.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/raw_object.h"
#include "vm/stub_code.h"
#include "vm/visitor.h"

namespace dart {


bool StackFrame::IsStubFrame() const {
  ASSERT(!(IsEntryFrame() || IsExitFrame()));
  uword saved_pc = *(reinterpret_cast<uword*>(fp() - kWordSize));
  return (saved_pc == 0);
}


void StackFrame::Print() const {
  OS::Print("[%-8s : sp(%#"Px") ]\n", GetName(), sp());
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


void StackFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  // NOTE: This code runs while GC is in progress and runs within
  // a NoHandleScope block. Hence it is not ok to use regular Zone or
  // Scope handles. We use direct stack handles, the raw pointers in
  // these handles are not traversed. The use of handles is mainly to
  // be able to reuse the handle based code and avoid having to add
  // helper functions to the raw object interface.
  ASSERT(visitor != NULL);
  NoGCScope no_gc;
  RawObject** start_addr = reinterpret_cast<RawObject**>(sp());
  RawObject** end_addr = reinterpret_cast<RawObject**>(fp()) +
      ParsedFunction::kFirstLocalSlotIndex;
  Code code;
  code = LookupDartCode();
  if (!code.IsNull()) {
    // Visit the code object.
    RawObject* raw_code = code.raw();
    visitor->VisitPointer(&raw_code);
    // Visit stack based on stack maps.
    Array maps;
    maps = Array::null();
    Stackmap map;
    map = code.GetStackmap(pc(), &maps, &map);
    if (!map.IsNull()) {
      // A stack map is present in the code object, use the stack map to
      // visit frame slots which are marked as having objects.
      //
      // The layout of the frame is (lower addresses to the right):
      // | spill slots | outgoing arguments | saved registers |
      // |XXXXXXXXXXXXX|--------------------|XXXXXXXXXXXXXXXXX|
      //
      // The splill slots and any saved registers are described in the stack
      // map.  The outgoing arguments are assumed to be tagged; the number
      // of outgoing arguments is not explicitly tracked.
      //
      // TODO(kmillikin): This does not handle slow path calls with
      // arguments, where the arguments are pushed after the live registers.
      // Enable such calls.
      intptr_t length = map.Length();
      // Spill slots are at the 'bottom' of the frame.
      intptr_t spill_slot_count = length - map.RegisterBitCount();
      for (intptr_t bit = 0; bit < spill_slot_count; ++bit) {
        if (map.IsObject(bit)) visitor->VisitPointer(end_addr);
        --end_addr;
      }

      // The live registers at the 'top' of the frame comprise the rest of the
      // stack map.
      for (intptr_t bit = length - 1; bit >= spill_slot_count; --bit) {
        if (map.IsObject(bit)) visitor->VisitPointer(start_addr);
        ++start_addr;
      }

      // The end address can be one slot (but not more) past the start
      // address in the case that all slots were covered by the stack map.
      ASSERT((end_addr + 1) >= start_addr);
    }
  }
  // Each slot between the start and end address are tagged objects.
  visitor->VisitPointers(start_addr, end_addr);
}


RawFunction* StackFrame::LookupDartFunction() const {
  const Code& code = Code::Handle(LookupDartCode());
  if (!code.IsNull()) {
    return code.function();
  }
  return Function::null();
}


RawCode* StackFrame::LookupDartCode() const {
  // We add a no gc scope to ensure that the code below does not trigger
  // a GC as we are handling raw object references here. It is possible
  // that the code is called while a GC is in progress, that is ok.
  NoGCScope no_gc;
  RawCode* code = GetCodeObject();
  ASSERT(code == Code::null() || code->ptr()->function_ != Function::null());
  return code;
}


RawCode* StackFrame::GetCodeObject() const {
  // We add a no gc scope to ensure that the code below does not trigger
  // a GC as we are handling raw object references here. It is possible
  // that the code is called while a GC is in progress, that is ok.
  NoGCScope no_gc;
  uword saved_pc = *(reinterpret_cast<uword*>(fp() - kWordSize));
  if (saved_pc != 0) {
    uword entry_point =
        (saved_pc - AssemblerMacros::kOffsetOfSavedPCfromEntrypoint);
    RawInstructions* instr = Instructions::FromEntryPoint(entry_point);
    if (instr != Instructions::null()) {
      return instr->ptr()->code_;
    }
  }
  return Code::null();
}


bool StackFrame::FindExceptionHandler(uword* handler_pc) const {
  const Code& code = Code::Handle(LookupDartCode());
  if (code.IsNull()) {
    return false;  // Stub frames do not have exception handlers.
  }

  // First try to find pc descriptor for the current pc.
  intptr_t try_index = -1;
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  for (intptr_t i = 0; i < descriptors.Length(); i++) {
    if ((static_cast<uword>(descriptors.PC(i)) == pc()) &&
        (descriptors.TryIndex(i) != -1)) {
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


bool StackFrame::IsValid() const {
  if (IsEntryFrame() || IsExitFrame() || IsStubFrame()) {
    return true;
  }
  return (LookupDartCode() != Code::null());
}


StackFrameIterator::StackFrameIterator(bool validate)
    : validate_(validate), entry_(), exit_(), current_frame_(NULL) {
  SetupLastExitFrameData();  // Setup data for last exit frame.
}

StackFrameIterator::StackFrameIterator(uword last_fp, bool validate)
    : validate_(validate), entry_(), exit_(), current_frame_(NULL) {
  frames_.fp_ = last_fp;
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
  frame = &stack_frame_;
  frame->sp_ = sp_;
  frame->fp_ = fp_;
  sp_ = frame->GetCallerSp();
  fp_ = frame->GetCallerFp();
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
