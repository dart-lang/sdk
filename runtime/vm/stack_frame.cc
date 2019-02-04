// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_frame.h"

#include "platform/memory_sanitizer.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/runtime_api.h"
#include "vm/deopt_instructions.h"
#include "vm/heap/become.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/parser.h"
#include "vm/raw_object.h"
#include "vm/reusable_handles.h"
#include "vm/reverse_pc_lookup_cache.h"
#include "vm/scopes.h"
#include "vm/stub_code.h"
#include "vm/visitor.h"

namespace dart {

DECLARE_FLAG(bool, enable_interpreter);

const FrameLayout invalid_frame_layout = {
    /*.first_object_from_fp = */ -1,
    /*.last_fixed_object_from_fp = */ -1,
    /*.param_end_from_fp = */ -1,
    /*.first_local_from_fp = */ -1,
    /*.dart_fixed_frame_size = */ -1,
    /*.saved_caller_pp_from_fp = */ -1,
    /*.code_from_fp = */ -1,
};

const FrameLayout default_frame_layout = {
    /*.first_object_from_fp = */ kFirstObjectSlotFromFp,
    /*.last_fixed_object_from_fp = */ kLastFixedObjectSlotFromFp,
    /*.param_end_from_fp = */ kParamEndSlotFromFp,
    /*.first_local_from_fp = */ kFirstLocalSlotFromFp,
    /*.dart_fixed_frame_size = */ kDartFrameFixedSize,
    /*.saved_caller_pp_from_fp = */ kSavedCallerPpSlotFromFp,
    /*.code_from_fp = */ kPcMarkerSlotFromFp,
};
const FrameLayout bare_instructions_frame_layout = {
    /*.first_object_from_pc =*/kFirstObjectSlotFromFp,  // No saved PP slot.
    /*.last_fixed_object_from_fp = */ kLastFixedObjectSlotFromFp +
        2,  // No saved CODE, PP slots
    /*.param_end_from_fp = */ kParamEndSlotFromFp,
    /*.first_local_from_fp =*/kFirstLocalSlotFromFp +
        2,  // No saved CODE, PP slots.
    /*.dart_fixed_frame_size =*/kDartFrameFixedSize -
        2,                              // No saved CODE, PP slots.
    /*.saved_caller_pp_from_fp = */ 0,  // No saved PP slot.
    /*.code_from_fp = */ 0,             // No saved CODE
};

namespace compiler {

namespace target {
FrameLayout frame_layout = invalid_frame_layout;
}

}  // namespace compiler

FrameLayout runtime_frame_layout = invalid_frame_layout;

int FrameLayout::FrameSlotForVariable(const LocalVariable* variable) const {
  ASSERT(!variable->is_captured());
  return this->FrameSlotForVariableIndex(variable->index().value());
}

int FrameLayout::FrameSlotForVariableIndex(int variable_index) const {
  // Variable indices are:
  //    [1, 2, ..., M] for the M parameters.
  //    [0, -1, -2, ... -(N-1)] for the N [LocalVariable]s
  // See (runtime/vm/scopes.h)
  return variable_index <= 0 ? (variable_index + first_local_from_fp)
                             : (variable_index + param_end_from_fp);
}

void FrameLayout::Init() {
  // By default we use frames with CODE_REG/PP in the frame.
  compiler::target::frame_layout = default_frame_layout;
  runtime_frame_layout = default_frame_layout;

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    compiler::target::frame_layout = bare_instructions_frame_layout;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    compiler::target::frame_layout = invalid_frame_layout;
    runtime_frame_layout = bare_instructions_frame_layout;
  }
#endif
}

Isolate* StackFrame::IsolateOfBareInstructionsFrame() const {
  auto isolate = this->isolate();

  if (isolate->object_store()->code_order_table() != Object::null()) {
    auto rct = isolate->reverse_pc_lookup_cache();
    if (rct->Contains(pc())) return isolate;
  }

  isolate = Dart::vm_isolate();
  if (isolate->object_store()->code_order_table() != Object::null()) {
    auto rct = isolate->reverse_pc_lookup_cache();
    if (rct->Contains(pc())) return isolate;
  }

  return nullptr;
}

bool StackFrame::IsBareInstructionsDartFrame() const {
  NoSafepointScope no_safepoint;

  if (auto isolate = IsolateOfBareInstructionsFrame()) {
    Code code;
    auto rct = isolate->reverse_pc_lookup_cache();
    code = rct->Lookup(pc());

    const intptr_t cid = code.owner()->GetClassId();
    ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
    return cid == kFunctionCid;
  }
  return false;
}

bool StackFrame::IsBareInstructionsStubFrame() const {
  NoSafepointScope no_safepoint;

  if (auto isolate = IsolateOfBareInstructionsFrame()) {
    Code code;
    auto rct = isolate->reverse_pc_lookup_cache();
    code = rct->Lookup(pc());

    const intptr_t cid = code.owner()->GetClassId();
    ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
    return cid == kNullCid || cid == kClassCid;
  }
  return false;
}

bool StackFrame::IsStubFrame() const {
  if (is_interpreted()) {
    return false;
  }

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    return IsBareInstructionsStubFrame();
  }

  ASSERT(!(IsEntryFrame() || IsExitFrame()));
#if !defined(HOST_OS_WINDOWS) && !defined(HOST_OS_FUCHSIA)
  // On Windows and Fuchsia, the profiler calls this from a separate thread
  // where Thread::Current() is NULL, so we cannot create a NoSafepointScope.
  NoSafepointScope no_safepoint;
#endif

  RawCode* code = GetCodeObject();
  ASSERT(code != Object::null());
  const intptr_t cid = code->ptr()->owner_->GetClassId();
  ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
  return cid == kNullCid || cid == kClassCid;
}

const char* StackFrame::ToCString() const {
  ASSERT(thread_ == Thread::Current());
  Zone* zone = Thread::Current()->zone();
  if (IsDartFrame()) {
    if (is_interpreted()) {
      const Bytecode& bytecode = Bytecode::Handle(zone, LookupDartBytecode());
      ASSERT(!bytecode.IsNull());
      const Function& function = Function::Handle(zone, bytecode.function());
      ASSERT(!function.IsNull());
      return zone->PrintToString(
          "[%-8s : sp(%#" Px ") fp(%#" Px ") pc(%#" Px ") bytecode %s ]",
          GetName(), sp(), fp(), pc(), function.ToFullyQualifiedCString());
    }
    const Code& code = Code::Handle(zone, LookupDartCode());
    ASSERT(!code.IsNull());
    const Object& owner = Object::Handle(zone, code.owner());
    ASSERT(!owner.IsNull());
    if (owner.IsFunction()) {
      const char* opt = code.is_optimized() ? "*" : "";
      const Function& function = Function::Cast(owner);
      return zone->PrintToString(
          "[%-8s : sp(%#" Px ") fp(%#" Px ") pc(%#" Px ") %s%s ]", GetName(),
          sp(), fp(), pc(), opt, function.ToFullyQualifiedCString());
    } else {
      return zone->PrintToString(
          "[%-8s : sp(%#" Px ") fp(%#" Px ") pc(%#" Px ") %s ]", GetName(),
          sp(), fp(), pc(), owner.ToCString());
    }
  } else {
    return zone->PrintToString("[%-8s : sp(%#" Px ") fp(%#" Px ") pc(%#" Px
                               ")]",
                               GetName(), sp(), fp(), pc());
  }
}

void ExitFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  // Visit pc marker and saved pool pointer, or, for interpreted frame, code
  // object and function object.
  RawObject** last_fixed =
      reinterpret_cast<RawObject**>(fp()) +
      (is_interpreted() ? kKBCLastFixedObjectSlotFromFp
                        : runtime_frame_layout.first_object_from_fp);
  RawObject** first_fixed =
      reinterpret_cast<RawObject**>(fp()) +
      (is_interpreted() ? kKBCFirstObjectSlotFromFp
                        : runtime_frame_layout.last_fixed_object_from_fp);
#if !defined(TARGET_ARCH_DBC)
  if (first_fixed <= last_fixed) {
    visitor->VisitPointers(first_fixed, last_fixed);
  } else {
    ASSERT(runtime_frame_layout.first_object_from_fp ==
           runtime_frame_layout.first_local_from_fp);
  }
#else
  ASSERT(last_fixed <= first_fixed);
  visitor->VisitPointers(last_fixed, first_fixed);
#endif
}

void EntryFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  // Visit objects between SP and (FP - callee_save_area).
#if !defined(TARGET_ARCH_DBC)
  RawObject** first = is_interpreted() ? reinterpret_cast<RawObject**>(fp()) +
                                             kKBCSavedArgDescSlotFromEntryFp
                                       : reinterpret_cast<RawObject**>(sp());
  RawObject** last = is_interpreted() ? reinterpret_cast<RawObject**>(sp())
                                      : reinterpret_cast<RawObject**>(fp()) +
                                            kExitLinkSlotFromEntryFp - 1;
  // There may not be any pointer to visit; in this case, first > last.
  visitor->VisitPointers(first, last);
#else
  // On DBC stack is growing upwards which implies fp() <= sp().
  RawObject** first = reinterpret_cast<RawObject**>(fp());
  RawObject** last = reinterpret_cast<RawObject**>(sp());
  ASSERT(first <= last);
  visitor->VisitPointers(first, last);
#endif
}

void StackFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  // NOTE: This code runs while GC is in progress and runs within
  // a NoHandleScope block. Hence it is not ok to use regular Zone or
  // Scope handles. We use direct stack handles, the raw pointers in
  // these handles are not traversed. The use of handles is mainly to
  // be able to reuse the handle based code and avoid having to add
  // helper functions to the raw object interface.
  NoSafepointScope no_safepoint;
  Code code;

  if (auto isolate = IsolateOfBareInstructionsFrame()) {
    code = isolate->reverse_pc_lookup_cache()->Lookup(pc());
  } else {
    RawObject* pc_marker = *(reinterpret_cast<RawObject**>(
        fp() + ((is_interpreted() ? kKBCPcMarkerSlotFromFp
                                  : runtime_frame_layout.code_from_fp) *
                kWordSize)));
    // May forward raw code. Note we don't just visit the pc marker slot first
    // because the visitor's forwarding might not be idempotent.
    visitor->VisitPointer(&pc_marker);
    if (pc_marker->IsHeapObject() && (pc_marker->GetClassId() == kCodeCid)) {
      code ^= pc_marker;
    } else {
      ASSERT(pc_marker == Object::null() ||
             (is_interpreted() && (!pc_marker->IsHeapObject() ||
                                   (pc_marker->GetClassId() == kBytecodeCid))));
    }
  }

  if (!code.IsNull()) {
    // Optimized frames have a stack map. We need to visit the frame based
    // on the stack map.
    Array maps;
    maps = Array::null();
    StackMap map;
    const uword start = Instructions::PayloadStart(code.instructions());
    map = code.GetStackMap(pc() - start, &maps, &map);
    if (!map.IsNull()) {
#if !defined(TARGET_ARCH_DBC)
      if (is_interpreted()) {
        UNIMPLEMENTED();
      }
      RawObject** first = reinterpret_cast<RawObject**>(sp());
      RawObject** last = reinterpret_cast<RawObject**>(
          fp() + (runtime_frame_layout.first_local_from_fp * kWordSize));

      // A stack map is present in the code object, use the stack map to
      // visit frame slots which are marked as having objects.
      //
      // The layout of the frame is (lower addresses to the right):
      // | spill slots | outgoing arguments | saved registers | slow-path args |
      // |XXXXXXXXXXXXX|--------------------|XXXXXXXXXXXXXXXXX|XXXXXXXXXXXXXXXX|
      //
      // The spill slots and any saved registers are described in the stack
      // map.  The outgoing arguments are assumed to be tagged; the number
      // of outgoing arguments is not explicitly tracked.
      intptr_t length = map.Length();
      // Spill slots are at the 'bottom' of the frame.
      intptr_t spill_slot_count = length - map.SlowPathBitCount();
      for (intptr_t bit = 0; bit < spill_slot_count; ++bit) {
        if (map.IsObject(bit)) {
          visitor->VisitPointer(last);
        }
        --last;
      }

      // The live registers at the 'top' of the frame comprise the rest of the
      // stack map.
      for (intptr_t bit = length - 1; bit >= spill_slot_count; --bit) {
        if (map.IsObject(bit)) {
          visitor->VisitPointer(first);
        }
        ++first;
      }

      // The last slot can be one slot (but not more) past the last slot
      // in the case that all slots were covered by the stack map.
      ASSERT((last + 1) >= first);
      visitor->VisitPointers(first, last);

      // Now visit other slots which might be part of the calling convention.
      first = reinterpret_cast<RawObject**>(
          fp() + ((runtime_frame_layout.first_local_from_fp + 1) * kWordSize));
      last = reinterpret_cast<RawObject**>(
          fp() + (runtime_frame_layout.first_object_from_fp * kWordSize));
      visitor->VisitPointers(first, last);
#else
      RawObject** first = reinterpret_cast<RawObject**>(fp());
      RawObject** last = reinterpret_cast<RawObject**>(sp());

      // Visit fixed prefix of the frame.
      RawObject** first_fixed =
          first + runtime_frame_layout.first_object_from_fp;
      RawObject** last_fixed =
          first + (runtime_frame_layout.first_object_from_fp + 1);
      ASSERT(first_fixed <= last_fixed);
      visitor->VisitPointers(first_fixed, last_fixed);

      // A stack map is present in the code object, use the stack map to
      // visit frame slots which are marked as having objects.
      //
      // The layout of the frame is (lower addresses to the left):
      // | registers | outgoing arguments |
      // |XXXXXXXXXXX|--------------------|
      //
      // The DBC registers are described in the stack map.
      // The outgoing arguments are assumed to be tagged; the number
      // of outgoing arguments is not explicitly tracked.
      ASSERT(map.SlowPathBitCount() == 0);

      // Visit DBC registers that contain tagged values.
      intptr_t length = map.Length();
      for (intptr_t bit = 0; bit < length; ++bit) {
        if (map.IsObject(bit)) {
          visitor->VisitPointer(first + bit);
        }
      }

      // Visit outgoing arguments.
      if ((first + length) <= last) {
        visitor->VisitPointers(first + length, last);
      }
#endif  // !defined(TARGET_ARCH_DBC)
      return;
    }

    // No stack map, fall through.
  }

#if !defined(TARGET_ARCH_DBC)
  // For normal unoptimized Dart frames and Stub frames each slot
  // between the first and last included are tagged objects.
  RawObject** first = reinterpret_cast<RawObject**>(
      is_interpreted() ? fp() + (kKBCFirstObjectSlotFromFp * kWordSize) : sp());
  RawObject** last = reinterpret_cast<RawObject**>(
      is_interpreted()
          ? sp()
          : fp() + (runtime_frame_layout.first_object_from_fp * kWordSize));
#else
  // On DBC stack grows upwards: fp() <= sp().
  RawObject** first = reinterpret_cast<RawObject**>(
      fp() + (runtime_frame_layout.first_object_from_fp * kWordSize));
  RawObject** last = reinterpret_cast<RawObject**>(sp());
#endif  // !defined(TARGET_ARCH_DBC)

  visitor->VisitPointers(first, last);
}

RawFunction* StackFrame::LookupDartFunction() const {
  if (is_interpreted()) {
    const Bytecode& bytecode = Bytecode::Handle(LookupDartBytecode());
    ASSERT(!bytecode.IsNull());
    return bytecode.function();
  }
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
#if !defined(HOST_OS_WINDOWS) && !defined(HOST_OS_FUCHSIA)
  // On Windows and Fuchsia, the profiler calls this from a separate thread
  // where Thread::Current() is NULL, so we cannot create a NoSafepointScope.
  NoSafepointScope no_safepoint;
#endif
  if (auto isolate = IsolateOfBareInstructionsFrame()) {
    return isolate->reverse_pc_lookup_cache()->Lookup(pc());
  }

  RawCode* code = GetCodeObject();
  if ((code != Code::null()) &&
      (code->ptr()->owner_->GetClassId() == kFunctionCid)) {
    return code;
  }
  return Code::null();
}

RawCode* StackFrame::GetCodeObject() const {
  ASSERT(!is_interpreted());
  if (auto isolate = IsolateOfBareInstructionsFrame()) {
    return isolate->reverse_pc_lookup_cache()->Lookup(pc());
  } else {
    RawObject* pc_marker = *(reinterpret_cast<RawObject**>(
        fp() + runtime_frame_layout.code_from_fp * kWordSize));
    ASSERT((pc_marker == Object::null()) ||
           (pc_marker->GetClassId() == kCodeCid));
    return reinterpret_cast<RawCode*>(pc_marker);
  }
}

RawBytecode* StackFrame::LookupDartBytecode() const {
// We add a no gc scope to ensure that the code below does not trigger
// a GC as we are handling raw object references here. It is possible
// that the code is called while a GC is in progress, that is ok.
#if !defined(HOST_OS_WINDOWS) && !defined(HOST_OS_FUCHSIA)
  // On Windows and Fuchsia, the profiler calls this from a separate thread
  // where Thread::Current() is NULL, so we cannot create a NoSafepointScope.
  NoSafepointScope no_safepoint;
#endif
  return GetBytecodeObject();
}

RawBytecode* StackFrame::GetBytecodeObject() const {
  ASSERT(is_interpreted());
  RawObject* pc_marker = *(
      reinterpret_cast<RawObject**>(fp() + kKBCPcMarkerSlotFromFp * kWordSize));
  ASSERT((pc_marker == Object::null()) ||
         (pc_marker->GetClassId() == kBytecodeCid));
  return reinterpret_cast<RawBytecode*>(pc_marker);
}

bool StackFrame::FindExceptionHandler(Thread* thread,
                                      uword* handler_pc,
                                      bool* needs_stacktrace,
                                      bool* has_catch_all,
                                      bool* is_optimized) const {
  REUSABLE_CODE_HANDLESCOPE(thread);
  Code& code = reused_code_handle.Handle();
  REUSABLE_BYTECODE_HANDLESCOPE(thread);
  Bytecode& bytecode = reused_bytecode_handle.Handle();
  REUSABLE_EXCEPTION_HANDLERS_HANDLESCOPE(thread);
  ExceptionHandlers& handlers = reused_exception_handlers_handle.Handle();
  REUSABLE_PC_DESCRIPTORS_HANDLESCOPE(thread);
  PcDescriptors& descriptors = reused_pc_descriptors_handle.Handle();
  uword start;
  if (is_interpreted()) {
    bytecode = LookupDartBytecode();
    ASSERT(!bytecode.IsNull());
    start = bytecode.PayloadStart();
    handlers = bytecode.exception_handlers();
    descriptors = bytecode.pc_descriptors();
  } else {
    code = LookupDartCode();
    if (code.IsNull()) {
      return false;  // Stub frames do not have exception handlers.
    }
    start = code.PayloadStart();
    handlers = code.exception_handlers();
    descriptors = code.pc_descriptors();
    *is_optimized = code.is_optimized();
  }
  HandlerInfoCache* cache = thread->isolate()->handler_info_cache();
  ExceptionHandlerInfo* info = cache->Lookup(pc());
  if (info != NULL) {
    *handler_pc = start + info->handler_pc_offset;
    *needs_stacktrace = info->needs_stacktrace;
    *has_catch_all = info->has_catch_all;
    return true;
  }
  uword pc_offset = pc() - start;

  if (handlers.num_entries() == 0) {
    return false;
  }

  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  intptr_t try_index = -1;
  if (is_interpreted()) {
    while (iter.MoveNext()) {
      // PC descriptors for try blocks in bytecode are generated in pairs,
      // marking start and end of a try block.
      // See BytecodeMetadataHelper::ReadExceptionsTable for details.
      const intptr_t current_try_index = iter.TryIndex();
      const uword start_pc = iter.PcOffset();
      if (pc_offset < start_pc) {
        break;
      }
      const bool has_next = iter.MoveNext();
      ASSERT(has_next);
      const uword end_pc = iter.PcOffset();
      if (start_pc <= pc_offset && pc_offset < end_pc) {
        ASSERT(try_index < current_try_index);
        try_index = current_try_index;
      }
    }
  } else {
    while (iter.MoveNext()) {
      const intptr_t current_try_index = iter.TryIndex();
      if ((iter.PcOffset() == pc_offset) && (current_try_index != -1)) {
        try_index = current_try_index;
        break;
      }
    }
  }
  if (try_index == -1) {
    return false;
  }
  ExceptionHandlerInfo handler_info;
  handlers.GetHandlerInfo(try_index, &handler_info);
  *handler_pc = start + handler_info.handler_pc_offset;
  *needs_stacktrace = handler_info.needs_stacktrace;
  *has_catch_all = handler_info.has_catch_all;
  cache->Insert(pc(), handler_info);
  return true;
}

TokenPosition StackFrame::GetTokenPos() const {
  if (is_interpreted()) {
    const Bytecode& bytecode = Bytecode::Handle(LookupDartBytecode());
    if (bytecode.IsNull()) {
      return TokenPosition::kNoSource;  // Stub frames do not have token_pos.
    }
    return bytecode.GetTokenIndexOfPC(pc());
  }
  const Code& code = Code::Handle(LookupDartCode());
  if (code.IsNull()) {
    return TokenPosition::kNoSource;  // Stub frames do not have token_pos.
  }
  uword pc_offset = pc() - code.PayloadStart();
  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code.pc_descriptors());
  ASSERT(!descriptors.IsNull());
  PcDescriptors::Iterator iter(descriptors, RawPcDescriptors::kAnyKind);
  while (iter.MoveNext()) {
    if (iter.PcOffset() == pc_offset) {
      return TokenPosition(iter.TokenPos());
    }
  }
  return TokenPosition::kNoSource;
}

bool StackFrame::IsValid() const {
  if (IsEntryFrame() || IsExitFrame() || IsStubFrame()) {
    return true;
  }
  if (is_interpreted()) {
    return (LookupDartBytecode() != Bytecode::null());
  }
  return (LookupDartCode() != Code::null());
}

void StackFrameIterator::SetupLastExitFrameData() {
  ASSERT(thread_ != NULL);
  uword exit_marker = thread_->top_exit_frame_info();
  frames_.fp_ = exit_marker;
  if (FLAG_enable_interpreter) {
    frames_.CheckIfInterpreted(exit_marker);
  }
}

void StackFrameIterator::SetupNextExitFrameData() {
  ASSERT(entry_.fp() != 0);
  uword exit_address =
      entry_.fp() + ((entry_.is_interpreted() ? kKBCExitLinkSlotFromEntryFp
                                              : kExitLinkSlotFromEntryFp) *
                     kWordSize);
  uword exit_marker = *reinterpret_cast<uword*>(exit_address);
  frames_.fp_ = exit_marker;
  frames_.sp_ = 0;
  frames_.pc_ = 0;
  if (FLAG_enable_interpreter) {
    frames_.CheckIfInterpreted(exit_marker);
  }
}

// Tell MemorySanitizer that generated code initializes part of the stack.
// TODO(koda): Limit to frames that are actually written by generated code.
static void UnpoisonStack(uword fp) {
  ASSERT(fp != 0);
  uword size = OSThread::GetSpecifiedStackSize();
  MSAN_UNPOISON(reinterpret_cast<void*>(fp - size), 2 * size);
}

StackFrameIterator::StackFrameIterator(ValidationPolicy validation_policy,
                                       Thread* thread,
                                       CrossThreadPolicy cross_thread_policy)
    : validate_(validation_policy == ValidationPolicy::kValidateFrames),
      entry_(thread),
      exit_(thread),
      frames_(thread),
      current_frame_(NULL),
      thread_(thread) {
  ASSERT(cross_thread_policy == kAllowCrossThreadIteration ||
         thread_ == Thread::Current());
  SetupLastExitFrameData();  // Setup data for last exit frame.
}

StackFrameIterator::StackFrameIterator(uword last_fp,
                                       ValidationPolicy validation_policy,
                                       Thread* thread,
                                       CrossThreadPolicy cross_thread_policy)
    : validate_(validation_policy == ValidationPolicy::kValidateFrames),
      entry_(thread),
      exit_(thread),
      frames_(thread),
      current_frame_(NULL),
      thread_(thread) {
  ASSERT(cross_thread_policy == kAllowCrossThreadIteration ||
         thread_ == Thread::Current());
  frames_.fp_ = last_fp;
  frames_.sp_ = 0;
  frames_.pc_ = 0;
  if (FLAG_enable_interpreter) {
    frames_.CheckIfInterpreted(last_fp);
  }
}

#if !defined(TARGET_ARCH_DBC)
StackFrameIterator::StackFrameIterator(uword fp,
                                       uword sp,
                                       uword pc,
                                       ValidationPolicy validation_policy,
                                       Thread* thread,
                                       CrossThreadPolicy cross_thread_policy)
    : validate_(validation_policy == ValidationPolicy::kValidateFrames),
      entry_(thread),
      exit_(thread),
      frames_(thread),
      current_frame_(NULL),
      thread_(thread) {
  ASSERT(cross_thread_policy == kAllowCrossThreadIteration ||
         thread_ == Thread::Current());
  frames_.fp_ = fp;
  frames_.sp_ = sp;
  frames_.pc_ = pc;
  if (FLAG_enable_interpreter) {
    frames_.CheckIfInterpreted(fp);
  }
}
#endif

StackFrame* StackFrameIterator::NextFrame() {
  // When we are at the start of iteration after having created an
  // iterator object, current_frame_ will be NULL as we haven't seen
  // any frames yet (unless we start iterating in the simulator from a given
  // triplet of fp, sp, and pc). At this point, if NextFrame is called, it tries
  // to set up the next exit frame by reading the top_exit_frame_info
  // from the isolate. If we do not have any dart invocations yet,
  // top_exit_frame_info will be 0 and so we would return NULL.

  // current_frame_ will also be NULL, when we are at the end of having
  // iterated through all the frames. If NextFrame is called at this
  // point, we will try and set up the next exit frame, but since we are
  // at the end of the iteration, fp_ will be 0 and we would return NULL.
  if (current_frame_ == NULL) {
    if (!HasNextFrame()) {
      return NULL;
    }
    UnpoisonStack(frames_.fp_);
#if !defined(TARGET_ARCH_DBC)
    if (frames_.pc_ == 0) {
      // Iteration starts from an exit frame given by its fp.
      current_frame_ = NextExitFrame();
    } else if (*(reinterpret_cast<uword*>(
                   frames_.fp_ +
                   ((frames_.is_interpreted() ? kKBCSavedCallerFpSlotFromFp
                                              : kSavedCallerFpSlotFromFp) *
                    kWordSize))) == 0) {
      // Iteration starts from an entry frame given by its fp, sp, and pc.
      current_frame_ = NextEntryFrame();
    } else {
      // Iteration starts from a Dart or stub frame given by its fp, sp, and pc.
      current_frame_ = frames_.NextFrame(validate_);
    }
#else
    // Iteration starts from an exit frame given by its fp. This is the only
    // mode supported on DBC.
    ASSERT(frames_.pc_ == 0);
    current_frame_ = NextExitFrame();
#endif  // !defined(TARGET_ARCH_DBC)
    return current_frame_;
  }
  ASSERT(!validate_ || current_frame_->IsValid());
  if (current_frame_->IsEntryFrame()) {
    if (HasNextFrame()) {  // We have another chained block.
      current_frame_ = NextExitFrame();
      return current_frame_;
    }
    current_frame_ = NULL;  // No more frames.
    return current_frame_;
  }
  ASSERT(!validate_ || current_frame_->IsExitFrame() ||
         current_frame_->IsDartFrame(validate_) ||
         current_frame_->IsStubFrame());

  // Consume dart/stub frames using StackFrameIterator::FrameSetIterator
  // until we are out of dart/stub frames at which point we return the
  // corresponding entry frame for that set of dart/stub frames.
  current_frame_ =
      (frames_.HasNext()) ? frames_.NextFrame(validate_) : NextEntryFrame();
  return current_frame_;
}

void StackFrameIterator::FrameSetIterator::CheckIfInterpreted(
    uword exit_marker) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  // TODO(regis): We should rely on a new thread vm_tag to identify an
  // interpreter frame and not need the HasFrame() method.
  ASSERT(FLAG_enable_interpreter);
  Interpreter* interpreter = thread_->interpreter();
  is_interpreted_ = (interpreter != NULL) && interpreter->HasFrame(exit_marker);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

StackFrame* StackFrameIterator::FrameSetIterator::NextFrame(bool validate) {
  StackFrame* frame;
  ASSERT(HasNext());
  frame = &stack_frame_;
  frame->sp_ = sp_;
  frame->fp_ = fp_;
  frame->pc_ = pc_;
  frame->is_interpreted_ = is_interpreted_;
  sp_ = frame->GetCallerSp();
  fp_ = frame->GetCallerFp();
  pc_ = frame->GetCallerPc();
  ASSERT(is_interpreted_ == frame->is_interpreted_);
  ASSERT(!validate || frame->IsValid());
  return frame;
}

ExitFrame* StackFrameIterator::NextExitFrame() {
  exit_.sp_ = frames_.sp_;
  exit_.fp_ = frames_.fp_;
  exit_.pc_ = frames_.pc_;
  exit_.is_interpreted_ = frames_.is_interpreted_;
  frames_.sp_ = exit_.GetCallerSp();
  frames_.fp_ = exit_.GetCallerFp();
  frames_.pc_ = exit_.GetCallerPc();
  ASSERT(frames_.is_interpreted_ == exit_.is_interpreted_);
  ASSERT(!validate_ || exit_.IsValid());
  return &exit_;
}

EntryFrame* StackFrameIterator::NextEntryFrame() {
  ASSERT(!frames_.HasNext());
  entry_.sp_ = frames_.sp_;
  entry_.fp_ = frames_.fp_;
  entry_.pc_ = frames_.pc_;
  entry_.is_interpreted_ = frames_.is_interpreted_;
  SetupNextExitFrameData();  // Setup data for next exit frame in chain.
  ASSERT(!validate_ || entry_.IsValid());
  return &entry_;
}

InlinedFunctionsIterator::InlinedFunctionsIterator(const Code& code, uword pc)
    : index_(0),
      num_materializations_(0),
      dest_frame_size_(0),
      code_(Code::Handle(code.raw())),
      deopt_info_(TypedData::Handle()),
      function_(Function::Handle()),
      pc_(pc),
      deopt_instructions_(),
      object_table_(ObjectPool::Handle()) {
  ASSERT(code_.is_optimized());
  ASSERT(pc_ != 0);
  ASSERT(code.ContainsInstructionAt(pc));
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(deopt_info_.IsNull());
  function_ = code_.function();
#else
  ICData::DeoptReasonId deopt_reason = ICData::kDeoptUnknown;
  uint32_t deopt_flags = 0;
  deopt_info_ = code_.GetDeoptInfoAtPc(pc, &deopt_reason, &deopt_flags);
  if (deopt_info_.IsNull()) {
    // This is the case when a call without deopt info in optimized code
    // throws an exception. (e.g. in the parameter copying prologue).
    // In that case there won't be any inlined frames.
    function_ = code_.function();
  } else {
    // Unpack deopt info into instructions (translate away suffixes).
    const Array& deopt_table = Array::Handle(code_.deopt_info_array());
    ASSERT(!deopt_table.IsNull());
    DeoptInfo::Unpack(deopt_table, deopt_info_, &deopt_instructions_);
    num_materializations_ = DeoptInfo::NumMaterializations(deopt_instructions_);
    dest_frame_size_ = DeoptInfo::FrameSize(deopt_info_);
    object_table_ = code_.GetObjectPool();
    Advance();
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void InlinedFunctionsIterator::Advance() {
  // Iterate over the deopt instructions and determine the inlined
  // functions if any and iterate over them.
  ASSERT(!Done());

#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(deopt_info_.IsNull());
  SetDone();
  return;
#else
  if (deopt_info_.IsNull()) {
    SetDone();
    return;
  }

  ASSERT(deopt_instructions_.length() != 0);
  while (index_ < deopt_instructions_.length()) {
    DeoptInstr* deopt_instr = deopt_instructions_[index_++];
    if (deopt_instr->kind() == DeoptInstr::kRetAddress) {
      pc_ = DeoptInstr::GetRetAddress(deopt_instr, object_table_, &code_);
      function_ = code_.function();
      return;
    }
  }
  SetDone();
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

// Finds the potential offset for the current function's FP if the
// current frame were to be deoptimized.
intptr_t InlinedFunctionsIterator::GetDeoptFpOffset() const {
  ASSERT(deopt_instructions_.length() != 0);
  for (intptr_t index = index_; index < deopt_instructions_.length(); index++) {
    DeoptInstr* deopt_instr = deopt_instructions_[index];
    if (deopt_instr->kind() == DeoptInstr::kCallerFp) {
      intptr_t fp_offset = (index - num_materializations_);
#if defined(TARGET_ARCH_DBC)
      // Stack on DBC is growing upwards but we record deopt commands
      // in the same order we record them on other architectures as if
      // the stack was growing downwards.
      fp_offset = dest_frame_size_ - fp_offset;
#endif
      return fp_offset;
    }
  }
  UNREACHABLE();
  return 0;
}

#if defined(DEBUG)
void ValidateFrames() {
  StackFrameIterator frames(ValidationPolicy::kValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != NULL) {
    frame = frames.NextFrame();
  }
}
#endif

}  // namespace dart
