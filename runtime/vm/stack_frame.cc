// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stack_frame.h"

#include "platform/memory_sanitizer.h"
#include "vm/code_descriptors.h"
#include "vm/compiler/runtime_api.h"
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

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/deopt_instructions.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

const FrameLayout invalid_frame_layout = {
    /*.first_object_from_fp = */ -1,
    /*.last_fixed_object_from_fp = */ -1,
    /*.param_end_from_fp = */ -1,
    /*.last_param_from_entry_sp = */ -1,
    /*.first_local_from_fp = */ -1,
    /*.dart_fixed_frame_size = */ -1,
    /*.saved_caller_pp_from_fp = */ -1,
    /*.saved_caller_fp_from_fp = */ -1,
    /*.saved_caller_pc_from_fp = */ -1,
    /*.code_from_fp = */ -1,
    /*.exit_link_slot_from_entry_fp = */ -1,
};

const FrameLayout default_frame_layout = {
    /*.first_object_from_fp = */ kFirstObjectSlotFromFp,
    /*.last_fixed_object_from_fp = */ kLastFixedObjectSlotFromFp,
    /*.param_end_from_fp = */ kParamEndSlotFromFp,
    /*.last_param_from_entry_sp = */ kLastParamSlotFromEntrySp,
    /*.first_local_from_fp = */ kFirstLocalSlotFromFp,
    /*.dart_fixed_frame_size = */ kDartFrameFixedSize,
    /*.saved_caller_pp_from_fp = */ kSavedCallerPpSlotFromFp,
    /*.saved_caller_fp_from_fp = */ kSavedCallerFpSlotFromFp,
    /*.saved_caller_pc_from_fp = */ kSavedCallerPcSlotFromFp,
    /*.code_from_fp = */ kPcMarkerSlotFromFp,
    /*.exit_link_slot_from_entry_fp = */ kExitLinkSlotFromEntryFp,
};
const FrameLayout bare_instructions_frame_layout = {
    /*.first_object_from_pc =*/kFirstObjectSlotFromFp,  // No saved PP slot.
    /*.last_fixed_object_from_fp = */ kLastFixedObjectSlotFromFp +
        2,  // No saved CODE, PP slots
    /*.param_end_from_fp = */ kParamEndSlotFromFp,
    /*.last_param_from_entry_sp = */ kLastParamSlotFromEntrySp,
    /*.first_local_from_fp =*/kFirstLocalSlotFromFp +
        2,  // No saved CODE, PP slots.
    /*.dart_fixed_frame_size =*/kDartFrameFixedSize -
        2,                              // No saved CODE, PP slots.
    /*.saved_caller_pp_from_fp = */ 0,  // No saved PP slot.
    /*.saved_caller_fp_from_fp = */ kSavedCallerFpSlotFromFp,
    /*.saved_caller_pc_from_fp = */ kSavedCallerPcSlotFromFp,
    /*.code_from_fp = */ 0,  // No saved CODE
    /*.exit_link_slot_from_entry_fp = */ kExitLinkSlotFromEntryFp,
};

namespace compiler {

namespace target {
FrameLayout frame_layout = invalid_frame_layout;
}

}  // namespace compiler

FrameLayout runtime_frame_layout = invalid_frame_layout;

intptr_t FrameLayout::FrameSlotForVariable(
    const LocalVariable* variable) const {
  ASSERT(!variable->is_captured());
  return this->FrameSlotForVariableIndex(variable->index().value());
}

intptr_t FrameLayout::FrameSlotForVariableIndex(intptr_t variable_index) const {
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

  if (FLAG_precompiled_mode) {
    compiler::target::frame_layout = bare_instructions_frame_layout;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_precompiled_mode) {
    compiler::target::frame_layout = invalid_frame_layout;
    runtime_frame_layout = bare_instructions_frame_layout;
  }
#endif
}

bool StackFrame::IsBareInstructionsDartFrame() const {
  if (!FLAG_precompiled_mode) {
    return false;
  }
  NoSafepointScope no_safepoint;

  Code code;
  code = ReversePc::Lookup(this->isolate_group(), pc(),
                           /*is_return_address=*/true);
  if (!code.IsNull()) {
    auto const cid = code.OwnerClassId();
    ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
    return cid == kFunctionCid;
  }

  return false;
}

bool StackFrame::IsBareInstructionsStubFrame() const {
  if (!FLAG_precompiled_mode) {
    return false;
  }
  NoSafepointScope no_safepoint;

  Code code;
  code = ReversePc::Lookup(this->isolate_group(), pc(),
                           /*is_return_address=*/true);
  if (!code.IsNull()) {
    auto const cid = code.OwnerClassId();
    ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
    return cid == kNullCid || cid == kClassCid;
  }

  return false;
}

bool StackFrame::IsStubFrame() const {
  if (is_interpreted()) {
    return false;
  }

  if (FLAG_precompiled_mode) {
    return IsBareInstructionsStubFrame();
  }

  ASSERT(!(IsEntryFrame() || IsExitFrame()));
#if !defined(DART_HOST_OS_WINDOWS) && !defined(DART_HOST_OS_FUCHSIA)
  // On Windows and Fuchsia, the profiler calls this from a separate thread
  // where Thread::Current() is nullptr, so we cannot create a NoSafepointScope.
  NoSafepointScope no_safepoint;
#endif

  CodePtr code = GetCodeObject();
  ASSERT(code != Object::null());
  auto const cid = Code::OwnerClassIdOf(code);
  ASSERT(cid == kNullCid || cid == kClassCid || cid == kFunctionCid);
  return cid == kNullCid || cid == kClassCid;
}

const char* StackFrame::ToCString() const {
  ASSERT(thread_ == Thread::Current());
  Zone* zone = Thread::Current()->zone();
#if defined(DART_DYNAMIC_MODULES)
  if (is_interpreted()) {
    const char* name;
    if (IsEntryFrame()) {
      name = "[Interpreter] Entry frame";
    } else if (IsExitFrame()) {
      name = "[Interpreter] Exit frame";
    } else {
      const Bytecode& bytecode = Bytecode::Handle(zone, LookupDartBytecode());
      name = bytecode.IsNull() ? "Cannot find bytecode object"
                               : bytecode.FullyQualifiedName();
    }
    return zone->PrintToString("  pc 0x%" Pp " fp 0x%" Pp " sp 0x%" Pp " %s",
                               pc(), fp(), sp(), name);
  }
#endif  // defined(DART_DYNAMIC_MODULES)
  const Code& code = Code::Handle(zone, GetCodeObject());
  const char* name =
      code.IsNull()
          ? "Cannot find code object"
          : code.QualifiedName(NameFormattingParams(Object::kInternalName));
  uword offset = code.IsNull() ? 0 : pc() - code.PayloadStart();
  return zone->PrintToString("  pc 0x%" Pp " fp 0x%" Pp " sp 0x%" Pp
                             " %s+0x%" Px,
                             pc(), fp(), sp(), name, offset);
}

void ExitFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != nullptr);
  // Visit pc marker and saved pool pointer, or, for interpreted frame, code
  // object and function object.
  ObjectPtr* last_fixed =
      reinterpret_cast<ObjectPtr*>(fp()) +
      (is_interpreted() ? kKBCLastFixedObjectSlotFromFp
                        : runtime_frame_layout.first_object_from_fp);
  ObjectPtr* first_fixed =
      reinterpret_cast<ObjectPtr*>(fp()) +
      (is_interpreted() ? kKBCFirstObjectSlotFromFp
                        : runtime_frame_layout.last_fixed_object_from_fp);
  if (first_fixed <= last_fixed) {
    visitor->VisitPointers(first_fixed, last_fixed);
  } else {
    ASSERT(runtime_frame_layout.first_object_from_fp ==
           runtime_frame_layout.first_local_from_fp);
  }
}

void EntryFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != nullptr);
  // Visit objects between SP and (FP - callee_save_area).
  ObjectPtr* first = is_interpreted() ? reinterpret_cast<ObjectPtr*>(fp()) +
                                            kKBCSavedArgDescSlotFromEntryFp
                                      : reinterpret_cast<ObjectPtr*>(sp());
  ObjectPtr* last = is_interpreted() ? reinterpret_cast<ObjectPtr*>(sp())
                                     : reinterpret_cast<ObjectPtr*>(fp()) +
                                           kExitLinkSlotFromEntryFp - 1;
  // There may not be any pointer to visit; in this case, first > last.
  visitor->VisitPointers(first, last);
}

void StackFrame::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != nullptr);
  // NOTE: This code runs while GC is in progress and runs within
  // a NoHandleScope block. Hence it is not ok to use regular Zone or
  // Scope handles. We use direct stack handles, the raw pointers in
  // these handles are not traversed. The use of handles is mainly to
  // be able to reuse the handle based code and avoid having to add
  // helper functions to the raw object interface.
  NoSafepointScope no_safepoint;
  Code code;

  CompressedStackMaps::RawPayloadHandle maps;
  CompressedStackMaps::RawPayloadHandle global_table;

  uword code_start;

  if (FLAG_precompiled_mode) {
    const UntaggedCompressedStackMaps::Payload* global_table_payload;
    maps = ReversePc::FindStackMap(isolate_group(), pc(),
                                   /*is_return_address=*/true, &code_start,
                                   &global_table_payload);
    global_table = global_table_payload;
  } else {
    ObjectPtr pc_marker = *(reinterpret_cast<ObjectPtr*>(
        fp() + ((is_interpreted() ? kKBCPcMarkerSlotFromFp
                                  : runtime_frame_layout.code_from_fp) *
                kWordSize)));
    // May forward raw code. Note we don't just visit the pc marker slot first
    // because the visitor's forwarding might not be idempotent.
    visitor->VisitPointer(&pc_marker);
    if (pc_marker->GetClassId() == kCodeCid) {
      code ^= pc_marker;
      code_start = code.PayloadStart();
      ASSERT(code.compressed_stackmaps() != CompressedStackMaps::null());
      maps = code.compressed_stackmaps();
      if (maps.UsesGlobalTable()) {
        global_table =
            isolate_group()->object_store()->canonicalized_stack_map_entries();
      }
    } else {
      ASSERT(pc_marker == Object::null() ||
             (is_interpreted() && (!pc_marker->IsHeapObject() ||
                                   (pc_marker->GetClassId() == kBytecodeCid))));
    }
  }

  if (!maps.IsNull()) {
    // Optimized frames have a stack map. We need to visit the frame based
    // on the stack map.
    CompressedStackMaps::Iterator<CompressedStackMaps::RawPayloadHandle> it(
        maps, global_table);
    const uint32_t pc_offset = pc() - code_start;
    if (it.Find(pc_offset)) {
      if (is_interpreted()) {
        UNIMPLEMENTED();
      }
      ObjectPtr* first = reinterpret_cast<ObjectPtr*>(sp());
      ObjectPtr* last = reinterpret_cast<ObjectPtr*>(
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

      // Spill slots are at the 'bottom' of the frame.
      intptr_t spill_slot_count = it.SpillSlotBitCount();
      for (intptr_t bit = 0; bit < spill_slot_count; ++bit) {
        if (it.IsObject(bit)) {
          visitor->VisitPointer(last);
        }
        --last;
      }

      // The live registers at the 'top' of the frame comprise the rest of the
      // stack map.
      for (intptr_t bit = it.Length() - 1; bit >= spill_slot_count; --bit) {
        if (it.IsObject(bit)) {
          visitor->VisitPointer(first);
        }
        ++first;
      }

      // The last slot can be one slot (but not more) past the last slot
      // in the case that all slots were covered by the stack map.
      ASSERT((last + 1) >= first);
      visitor->VisitPointers(first, last);

      // Now visit other slots which might be part of the calling convention.
      first = reinterpret_cast<ObjectPtr*>(
          fp() + ((runtime_frame_layout.first_local_from_fp + 1) * kWordSize));
      last = reinterpret_cast<ObjectPtr*>(
          fp() + (runtime_frame_layout.first_object_from_fp * kWordSize));
      visitor->VisitPointers(first, last);
      return;
    }

    // If we are missing a stack map for a given PC offset, this must either be
    // unoptimized code, code with no stack map information at all, or the entry
    // to an osr function. In each of these cases, all stack slots contain
    // tagged pointers, so fall through.
#if defined(DEBUG)
    if (FLAG_precompiled_mode) {
      ASSERT(IsStubFrame());
    } else {
      ASSERT(!code.is_optimized() ||
             (pc_offset == code.EntryPoint() - code.PayloadStart()));
    }
#endif  // defined(DEBUG)
  }

  // For normal unoptimized Dart frames and Stub frames each slot
  // between the first and last included are tagged objects.
  if (is_interpreted()) {
    // Do not visit caller's pc or caller's fp.
    ObjectPtr* first =
        reinterpret_cast<ObjectPtr*>(fp()) + kKBCFirstObjectSlotFromFp;
    ObjectPtr* last =
        reinterpret_cast<ObjectPtr*>(fp()) + kKBCLastFixedObjectSlotFromFp;

    visitor->VisitPointers(first, last);
  }
  ObjectPtr* first =
      reinterpret_cast<ObjectPtr*>(is_interpreted() ? fp() : sp());
  ObjectPtr* last = reinterpret_cast<ObjectPtr*>(
      is_interpreted()
          ? sp()
          : fp() + (runtime_frame_layout.first_object_from_fp * kWordSize));

  visitor->VisitPointers(first, last);
}

FunctionPtr StackFrame::LookupDartFunction() const {
  if (is_interpreted()) {
    ObjectPtr result = *(reinterpret_cast<FunctionPtr*>(
        fp() + kKBCFunctionSlotFromFp * kWordSize));
    ASSERT((result == Object::null()) ||
           (result->GetClassId() == kFunctionCid));
    return static_cast<FunctionPtr>(result);
  }
  const Code& code = Code::Handle(LookupDartCode());
  if (!code.IsNull()) {
    const Object& owner = Object::Handle(code.owner());
    if (owner.IsFunction()) {
      return Function::Cast(owner).ptr();
    }
  }
  return Function::null();
}

CodePtr StackFrame::LookupDartCode() const {
// We add a no gc scope to ensure that the code below does not trigger
// a GC as we are handling raw object references here. It is possible
// that the code is called while a GC is in progress, that is ok.
#if !defined(DART_HOST_OS_WINDOWS) && !defined(DART_HOST_OS_FUCHSIA)
  // On Windows and Fuchsia, the profiler calls this from a separate thread
  // where Thread::Current() is nullptr, so we cannot create a NoSafepointScope.
  NoSafepointScope no_safepoint;
#endif
  CodePtr code = GetCodeObject();
  if ((code != Code::null()) && Code::OwnerClassIdOf(code) == kFunctionCid) {
    return code;
  }
  return Code::null();
}

CodePtr StackFrame::GetCodeObject() const {
  ASSERT(!is_interpreted());

#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_precompiled_mode) {
    if (pc() == 0) {
      return Code::null();
    }
    NoSafepointScope no_safepoint;
    CodePtr code = ReversePc::Lookup(isolate_group(), pc(),
                                     /*is_return_address=*/true);
    ASSERT(code != Code::null());
    return code;
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  ObjectPtr pc_marker = *(reinterpret_cast<ObjectPtr*>(
      fp() + runtime_frame_layout.code_from_fp * kWordSize));
  ASSERT((pc_marker == Object::null()) ||
         (pc_marker->GetClassId() == kCodeCid));
  return static_cast<CodePtr>(pc_marker);
}

BytecodePtr StackFrame::LookupDartBytecode() const {
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

BytecodePtr StackFrame::GetBytecodeObject() const {
  ASSERT(is_interpreted());
  ASSERT(!IsEntryFrame() && !IsExitFrame());
  ObjectPtr pc_marker = *(
      reinterpret_cast<ObjectPtr*>(fp() + kKBCPcMarkerSlotFromFp * kWordSize));
  ASSERT((pc_marker == Object::null()) ||
         (pc_marker->GetClassId() == kBytecodeCid));
  return static_cast<BytecodePtr>(pc_marker);
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
  {
    SafepointMutexLocker ml(thread->isolate_group()->cache_mutex());
    HandlerInfoCache* cache = thread->isolate_group()->handler_info_cache();
    ExceptionHandlerInfo* info = cache->Lookup(pc());
    if (info != nullptr) {
      *handler_pc = start + info->handler_pc_offset;
      *needs_stacktrace = (info->needs_stacktrace != 0);
      *has_catch_all = (info->has_catch_all != 0);
      return true;
    }

    intptr_t try_index = -1;
    if (handlers.num_entries() != 0) {
      if (is_interpreted()) {
        try_index = bytecode.GetTryIndexAtPc(pc());
      } else {
        uword pc_offset = pc() - code.PayloadStart();
        PcDescriptors::Iterator iter(descriptors,
                                     UntaggedPcDescriptors::kAnyKind);
        while (iter.MoveNext()) {
          const intptr_t current_try_index = iter.TryIndex();
          if ((iter.PcOffset() == pc_offset) && (current_try_index != -1)) {
            try_index = current_try_index;
            break;
          }
        }
      }
    }
    if (try_index == -1) {
      if (handlers.has_async_handler()) {
        *handler_pc = StubCode::AsyncExceptionHandler().EntryPoint();
        *needs_stacktrace = true;
        *has_catch_all = true;
        return true;
      }
      return false;
    }
    ExceptionHandlerInfo handler_info;
    handlers.GetHandlerInfo(try_index, &handler_info);
    *handler_pc = start + handler_info.handler_pc_offset;
    *needs_stacktrace = (handler_info.needs_stacktrace != 0);
    *has_catch_all = (handler_info.has_catch_all != 0);
    cache->Insert(pc(), handler_info);
  }
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
  PcDescriptors::Iterator iter(descriptors, UntaggedPcDescriptors::kAnyKind);
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

void StackFrame::DumpCurrentTrace() {
  StackFrameIterator frames(ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

void StackFrame::DumpCurrentTrace(uword sp, uword fp, uword pc) {
  StackFrameIterator frames(fp, sp, pc, ValidationPolicy::kDontValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    OS::PrintErr("%s\n", frame->ToCString());
    frame = frames.NextFrame();
  }
}

void StackFrameIterator::SetupLastExitFrameData() {
  ASSERT(thread_ != nullptr);
  uword exit_marker = thread_->top_exit_frame_info();
  frames_.fp_ = exit_marker;
  frames_.sp_ = 0;
  frames_.pc_ = 0;
#if defined(DART_DYNAMIC_MODULES)
  frames_.CheckIfInterpreted(exit_marker);
#endif
  frames_.Unpoison();
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
#if defined(DART_DYNAMIC_MODULES)
  frames_.CheckIfInterpreted(exit_marker);
#endif
  frames_.Unpoison();
}

StackFrameIterator::StackFrameIterator(ValidationPolicy validation_policy,
                                       Thread* thread,
                                       CrossThreadPolicy cross_thread_policy)
    : validate_(validation_policy == ValidationPolicy::kValidateFrames),
      entry_(thread),
      exit_(thread),
      frames_(thread),
      current_frame_(nullptr),
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
      current_frame_(nullptr),
      thread_(thread) {
  ASSERT(cross_thread_policy == kAllowCrossThreadIteration ||
         thread_ == Thread::Current());
  frames_.fp_ = last_fp;
  frames_.sp_ = 0;
  frames_.pc_ = 0;
#if defined(DART_DYNAMIC_MODULES)
  frames_.CheckIfInterpreted(last_fp);
#endif
  frames_.Unpoison();
}

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
      current_frame_(nullptr),
      thread_(thread) {
  ASSERT(cross_thread_policy == kAllowCrossThreadIteration ||
         thread_ == Thread::Current());
  frames_.fp_ = fp;
  frames_.sp_ = sp;
  frames_.pc_ = pc;
#if defined(DART_DYNAMIC_MODULES)
  frames_.CheckIfInterpreted(fp);
#endif
  frames_.Unpoison();
}

StackFrameIterator::StackFrameIterator(const StackFrameIterator& orig)
    : validate_(orig.validate_),
      entry_(orig.thread_),
      exit_(orig.thread_),
      frames_(orig.thread_),
      current_frame_(nullptr),
      thread_(orig.thread_) {
  frames_.fp_ = orig.frames_.fp_;
  frames_.sp_ = orig.frames_.sp_;
  frames_.pc_ = orig.frames_.pc_;
  frames_.Unpoison();
}

StackFrame* StackFrameIterator::NextFrame() {
  // When we are at the start of iteration after having created an
  // iterator object, current_frame_ will be nullptr as we haven't seen
  // any frames yet (unless we start iterating in the simulator from a given
  // triplet of fp, sp, and pc). At this point, if NextFrame is called, it tries
  // to set up the next exit frame by reading the top_exit_frame_info
  // from the isolate. If we do not have any dart invocations yet,
  // top_exit_frame_info will be 0 and so we would return nullptr.

  // current_frame_ will also be nullptr, when we are at the end of having
  // iterated through all the frames. If NextFrame is called at this
  // point, we will try and set up the next exit frame, but since we are
  // at the end of the iteration, fp_ will be 0 and we would return nullptr.
  if (current_frame_ == nullptr) {
    if (!HasNextFrame()) {
      return nullptr;
    }
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
    return current_frame_;
  }
  ASSERT(!validate_ || current_frame_->IsValid());
  if (current_frame_->IsEntryFrame()) {
    if (HasNextFrame()) {  // We have another chained block.
      current_frame_ = NextExitFrame();
      return current_frame_;
    }
    current_frame_ = nullptr;  // No more frames.
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

#if defined(DART_DYNAMIC_MODULES)
void StackFrameIterator::FrameSetIterator::CheckIfInterpreted(
    uword exit_marker) {
  Interpreter* interpreter = thread_->interpreter();
  is_interpreted_ =
      (interpreter != nullptr) && interpreter->HasFrame(exit_marker);
}
#endif  // defined(DART_DYNAMIC_MODULES)

// Tell MemorySanitizer that generated code initializes part of the stack.
void StackFrameIterator::FrameSetIterator::Unpoison() {
  // When using a simulator, all writes to the stack happened from MSAN
  // instrumented C++, so there is nothing to unpoison. Additionally,
  // fp_ will be somewhere in the simulator's stack instead of the OSThread's
  // stack.
#if !defined(DART_INCLUDE_SIMULATOR)
  if (fp_ == 0) return;
  // Note that Thread::os_thread_ is cleared when the thread is descheduled.
  ASSERT(is_interpreted() || (thread_->os_thread() == nullptr) ||
         ((thread_->os_thread()->stack_limit() < fp_) &&
          (thread_->os_thread()->stack_base() > fp_)));
  uword lower;
  if (sp_ == 0) {
    // Exit frame: guess sp.
    lower = fp_ - kDartFrameFixedSize * kWordSize;
  } else {
    lower = sp_;
  }
  uword upper = fp_ + kSavedCallerPcSlotFromFp * kWordSize;
  // Both lower and upper are inclusive, so we add one word when computing size.
  MSAN_UNPOISON(reinterpret_cast<void*>(lower), upper - lower + kWordSize);
#endif  // !defined(DART_INCLUDE_SIMULATOR)
}

StackFrame* StackFrameIterator::FrameSetIterator::NextFrame(bool validate) {
  StackFrame* frame;
  ASSERT(HasNext());
  frame = &stack_frame_;
  frame->sp_ = sp_;
  frame->fp_ = fp_;
  frame->pc_ = pc_;
#if defined(DART_DYNAMIC_MODULES)
  frame->is_interpreted_ = is_interpreted();
#endif
  sp_ = frame->GetCallerSp();
  fp_ = frame->GetCallerFp();
  pc_ = frame->GetCallerPc();
  Unpoison();
  ASSERT(is_interpreted() == frame->is_interpreted());
  ASSERT(!validate || frame->IsValid());
  return frame;
}

ExitFrame* StackFrameIterator::NextExitFrame() {
  exit_.sp_ = frames_.sp_;
  exit_.fp_ = frames_.fp_;
  exit_.pc_ = frames_.pc_;
#if defined(DART_DYNAMIC_MODULES)
  exit_.is_interpreted_ = frames_.is_interpreted();
#endif
  frames_.sp_ = exit_.GetCallerSp();
  frames_.fp_ = exit_.GetCallerFp();
  frames_.pc_ = exit_.GetCallerPc();
  frames_.Unpoison();
  ASSERT(frames_.is_interpreted() == exit_.is_interpreted());
  ASSERT(!validate_ || exit_.IsValid());
  return &exit_;
}

EntryFrame* StackFrameIterator::NextEntryFrame() {
  ASSERT(!frames_.HasNext());
  entry_.sp_ = frames_.sp_;
  entry_.fp_ = frames_.fp_;
  entry_.pc_ = frames_.pc_;
#if defined(DART_DYNAMIC_MODULES)
  entry_.is_interpreted_ = frames_.is_interpreted();
#endif
  SetupNextExitFrameData();  // Setup data for next exit frame in chain.
  ASSERT(!validate_ || entry_.IsValid());
  return &entry_;
}

InlinedFunctionsIterator::InlinedFunctionsIterator(const Code& code, uword pc)
    : index_(0),
      num_materializations_(0),
      dest_frame_size_(0),
      code_(Code::Handle(code.ptr())),
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

#if !defined(DART_PRECOMPILED_RUNTIME)
// Finds the potential offset for the current function's FP if the
// current frame were to be deoptimized.
intptr_t InlinedFunctionsIterator::GetDeoptFpOffset() const {
  ASSERT(deopt_instructions_.length() != 0);
  for (intptr_t index = index_; index < deopt_instructions_.length(); index++) {
    DeoptInstr* deopt_instr = deopt_instructions_[index];
    if (deopt_instr->kind() == DeoptInstr::kCallerFp) {
      return index - num_materializations_ - kSavedCallerFpSlotFromFp;
    }
  }
  UNREACHABLE();
  return 0;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DEBUG)
void ValidateFrames() {
  StackFrameIterator frames(ValidationPolicy::kValidateFrames,
                            Thread::Current(),
                            StackFrameIterator::kNoCrossThreadIteration);
  StackFrame* frame = frames.NextFrame();
  while (frame != nullptr) {
    frame = frames.NextFrame();
  }
}
#endif

}  // namespace dart
