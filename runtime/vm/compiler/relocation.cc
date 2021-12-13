// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/relocation.h"

#include "vm/code_patcher.h"
#include "vm/heap/pages.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

namespace dart {

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

// Only for testing.
DEFINE_FLAG(bool,
            always_generate_trampolines_for_testing,
            false,
            "Generate always trampolines (for testing purposes).");

DEFINE_FLAG(int,
            lower_tail_pc_relative_call_distance,
            -1,
            "Lower tail call distance.");
DEFINE_FLAG(int,
            upper_tail_pc_relative_call_distance,
            -1,
            "Upper tail call distance.");
DEFINE_FLAG(int, lower_pc_relative_call_distance, -1, "Lower call distance.");
DEFINE_FLAG(int, upper_pc_relative_call_distance, -1, "Upper call distance.");

struct TailCallDistanceLimits {
  static intptr_t Lower() {
    if (FLAG_lower_tail_pc_relative_call_distance != -1) {
      return FLAG_lower_tail_pc_relative_call_distance;
    }
    return PcRelativeTailCallPattern::kLowerCallingRange;
  }
  static intptr_t Upper() {
    if (FLAG_upper_tail_pc_relative_call_distance != -1) {
      return FLAG_upper_tail_pc_relative_call_distance;
    }
    return PcRelativeTailCallPattern::kUpperCallingRange;
  }
};

struct CallDistanceLimits {
  static intptr_t Lower() {
    if (FLAG_lower_pc_relative_call_distance != -1) {
      return FLAG_lower_pc_relative_call_distance;
    }
    return PcRelativeCallPattern::kLowerCallingRange;
  }
  static intptr_t Upper() {
    if (FLAG_upper_pc_relative_call_distance != -1) {
      return FLAG_upper_pc_relative_call_distance;
    }
    return PcRelativeCallPattern::kUpperCallingRange;
  }
};

const intptr_t kTrampolineSize =
    Utils::RoundUp(PcRelativeTrampolineJumpPattern::kLengthInBytes,
                   compiler::target::Instructions::kBarePayloadAlignment);

CodeRelocator::CodeRelocator(Thread* thread,
                             GrowableArray<CodePtr>* code_objects,
                             GrowableArray<ImageWriterCommand>* commands)
    : StackResource(thread),
      thread_(thread),
      code_objects_(code_objects),
      commands_(commands),
      kind_type_and_offset_(Smi::Handle(thread->zone())),
      target_(Object::Handle(thread->zone())),
      destination_(Code::Handle(thread->zone())) {}

void CodeRelocator::Relocate(bool is_vm_isolate) {
  Zone* zone = Thread::Current()->zone();
  auto& current_caller = Code::Handle(zone);
  auto& call_targets = Array::Handle(zone);

  auto& next_caller = Code::Handle(zone);
  auto& next_caller_targets = Array::Handle(zone);

  // Emit all instructions and do relocations on the way.
  for (intptr_t i = 0; i < code_objects_->length(); ++i) {
    current_caller = (*code_objects_)[i];

    const intptr_t code_text_offset = next_text_offset_;
    if (!AddInstructionsToText(current_caller.ptr())) {
      continue;
    }

    call_targets = current_caller.static_calls_target_table();
    ScanCallTargets(current_caller, call_targets, code_text_offset);

    // Any unresolved calls to this instruction can be fixed now.
    ResolveUnresolvedCallsTargeting(current_caller.instructions());

    // If we have forward/backwards calls which are almost out-of-range, we'll
    // create trampolines now.
    if (i < (code_objects_->length() - 1)) {
      next_caller = (*code_objects_)[i + 1];
      next_caller_targets = next_caller.static_calls_target_table();
    } else {
      next_caller = Code::null();
      next_caller_targets = Array::null();
    }
    BuildTrampolinesForAlmostOutOfRangeCalls(next_caller, next_caller_targets);
  }

  // We're guaranteed to have all calls resolved, since
  //   * backwards calls are resolved eagerly
  //   * forward calls are resolved once the target is written
  if (!all_unresolved_calls_.IsEmpty()) {
    for (auto call : all_unresolved_calls_) {
      OS::PrintErr("Unresolved call to %s from %s\n",
                   Object::Handle(call->callee).ToCString(),
                   Object::Handle(call->caller).ToCString());
    }
  }
  RELEASE_ASSERT(all_unresolved_calls_.IsEmpty());
  RELEASE_ASSERT(unresolved_calls_by_destination_.IsEmpty());

  // Any trampolines we created must be patched with the right offsets.
  auto it = trampolines_by_destination_.GetIterator();
  while (true) {
    auto entry = it.Next();
    if (entry == nullptr) break;

    UnresolvedTrampolineList* trampoline_list = entry->value;
    while (!trampoline_list->IsEmpty()) {
      auto unresolved_trampoline = trampoline_list->RemoveFirst();
      ResolveTrampoline(unresolved_trampoline);
      delete unresolved_trampoline;
    }
    delete trampoline_list;
  }
  trampolines_by_destination_.Clear();

  // Don't drop static call targets table yet. Snapshotter will skip it anyway
  // however we might need it to write information into V8 snapshot profile.
}

bool CodeRelocator::AddInstructionsToText(CodePtr code) {
  InstructionsPtr instructions = Code::InstructionsOf(code);

  // If two [Code] objects point to the same [Instructions] object, we'll just
  // use the first one (they are equivalent for all practical purposes).
  if (text_offsets_.HasKey(instructions)) {
    return false;
  }
  text_offsets_.Insert({instructions, next_text_offset_});
  commands_->Add(ImageWriterCommand(next_text_offset_, code));
  next_text_offset_ += ImageWriter::SizeInSnapshot(instructions);

  return true;
}

UnresolvedTrampoline* CodeRelocator::FindTrampolineFor(
    UnresolvedCall* unresolved_call) {
  auto destination = Code::InstructionsOf(unresolved_call->callee);
  auto entry = trampolines_by_destination_.Lookup(destination);
  if (entry != nullptr) {
    UnresolvedTrampolineList* trampolines = entry->value;
    ASSERT(!trampolines->IsEmpty());

    // For the destination of [unresolved_call] we might have multiple
    // trampolines.  The trampolines are sorted according to insertion order,
    // which guarantees increasing text_offset's.  So we go from the back of the
    // list as long as we have trampolines that are in-range and then check
    // whether the target offset matches.
    auto it = trampolines->End();
    --it;
    do {
      UnresolvedTrampoline* trampoline = *it;
      if (!IsTargetInRangeFor(unresolved_call, trampoline->text_offset)) {
        break;
      }
      if (trampoline->offset_into_target ==
          unresolved_call->offset_into_target) {
        return trampoline;
      }
      --it;
    } while (it != trampolines->Begin());
  }
  return nullptr;
}

void CodeRelocator::AddTrampolineToText(InstructionsPtr destination,
                                        uint8_t* trampoline_bytes,
                                        intptr_t trampoline_length) {
  commands_->Add(ImageWriterCommand(next_text_offset_, trampoline_bytes,
                                    trampoline_length));
  next_text_offset_ += trampoline_length;
}

void CodeRelocator::ScanCallTargets(const Code& code,
                                    const Array& call_targets,
                                    intptr_t code_text_offset) {
  if (call_targets.IsNull()) {
    return;
  }
  StaticCallsTable calls(call_targets);
  for (auto call : calls) {
    kind_type_and_offset_ = call.Get<Code::kSCallTableKindAndOffset>();
    const auto kind = Code::KindField::decode(kind_type_and_offset_.Value());
    const auto return_pc_offset =
        Code::OffsetField::decode(kind_type_and_offset_.Value());
    const auto call_entry_point =
        Code::EntryPointField::decode(kind_type_and_offset_.Value());

    if (kind == Code::kCallViaCode) {
      continue;
    }

    destination_ = GetTarget(call);

    // A call site can decide to jump not to the beginning of a function but
    // rather jump into it at a certain offset.
    int32_t offset_into_target = 0;
    bool is_tail_call;
    intptr_t call_instruction_offset;
    if (kind == Code::kPcRelativeCall || kind == Code::kPcRelativeTTSCall) {
      call_instruction_offset =
          return_pc_offset - PcRelativeCallPattern::kLengthInBytes;
      PcRelativeCallPattern call(code.PayloadStart() + call_instruction_offset);
      ASSERT(call.IsValid());
      offset_into_target = call.distance();
      is_tail_call = false;
    } else {
      ASSERT(kind == Code::kPcRelativeTailCall);
      call_instruction_offset =
          return_pc_offset - PcRelativeTailCallPattern::kLengthInBytes;
      PcRelativeTailCallPattern call(code.PayloadStart() +
                                     call_instruction_offset);
      ASSERT(call.IsValid());
      offset_into_target = call.distance();
      is_tail_call = true;
    }

    const uword destination_payload = destination_.PayloadStart();
    const uword entry_point = call_entry_point == Code::kUncheckedEntry
                                  ? destination_.UncheckedEntryPoint()
                                  : destination_.EntryPoint();

    offset_into_target += (entry_point - destination_payload);

    const intptr_t text_offset =
        code_text_offset + AdjustPayloadOffset(call_instruction_offset);

    UnresolvedCall unresolved_call(code.ptr(), call_instruction_offset,
                                   text_offset, destination_.ptr(),
                                   offset_into_target, is_tail_call);
    if (!TryResolveBackwardsCall(&unresolved_call)) {
      EnqueueUnresolvedCall(new UnresolvedCall(unresolved_call));
    }
  }
}

void CodeRelocator::EnqueueUnresolvedCall(UnresolvedCall* unresolved_call) {
  // Add it to the min-heap by .text offset.
  all_unresolved_calls_.Append(unresolved_call);

  // Add it to callers of destination.
  InstructionsPtr destination = Code::InstructionsOf(unresolved_call->callee);
  if (!unresolved_calls_by_destination_.HasKey(destination)) {
    unresolved_calls_by_destination_.Insert(
        {destination, new SameDestinationUnresolvedCallsList()});
  }
  unresolved_calls_by_destination_.LookupValue(destination)
      ->Append(unresolved_call);
}

void CodeRelocator::EnqueueUnresolvedTrampoline(
    UnresolvedTrampoline* unresolved_trampoline) {
  auto destination = Code::InstructionsOf(unresolved_trampoline->callee);
  auto entry = trampolines_by_destination_.Lookup(destination);

  UnresolvedTrampolineList* trampolines = nullptr;
  if (entry == nullptr) {
    trampolines = new UnresolvedTrampolineList();
    trampolines_by_destination_.Insert({destination, trampolines});
  } else {
    trampolines = entry->value;
  }
  trampolines->Append(unresolved_trampoline);
}

bool CodeRelocator::TryResolveBackwardsCall(UnresolvedCall* unresolved_call) {
  auto callee = Code::InstructionsOf(unresolved_call->callee);
  auto map_entry = text_offsets_.Lookup(callee);
  if (map_entry == nullptr) return false;

  if (IsTargetInRangeFor(unresolved_call, map_entry->value)) {
    ResolveCall(unresolved_call);
    return true;
  }
  return false;
}

void CodeRelocator::ResolveUnresolvedCallsTargeting(
    const InstructionsPtr instructions) {
  if (unresolved_calls_by_destination_.HasKey(instructions)) {
    SameDestinationUnresolvedCallsList* calls =
        unresolved_calls_by_destination_.LookupValue(instructions);
    auto it = calls->Begin();
    while (it != calls->End()) {
      UnresolvedCall* unresolved_call = *it;
      ++it;
      ASSERT(Code::InstructionsOf(unresolved_call->callee) == instructions);
      ResolveCall(unresolved_call);

      // Remove the call from both lists.
      calls->Remove(unresolved_call);
      all_unresolved_calls_.Remove(unresolved_call);

      delete unresolved_call;
    }
    ASSERT(calls->IsEmpty());
    delete calls;
    bool ok = unresolved_calls_by_destination_.Remove(instructions);
    ASSERT(ok);
  }
}

void CodeRelocator::ResolveCall(UnresolvedCall* unresolved_call) {
  const intptr_t destination_text =
      FindDestinationInText(Code::InstructionsOf(unresolved_call->callee),
                            unresolved_call->offset_into_target);

  ResolveCallToDestination(unresolved_call, destination_text);
}

void CodeRelocator::ResolveCallToDestination(UnresolvedCall* unresolved_call,
                                             intptr_t destination_text) {
  const intptr_t call_text_offset = unresolved_call->text_offset;
  const intptr_t call_offset = unresolved_call->call_offset;

  const int32_t distance = destination_text - call_text_offset;
  {
    auto const caller = unresolved_call->caller;
    uword addr = Code::PayloadStartOf(caller) + call_offset;
    if (FLAG_write_protect_code) {
      addr -= OldPage::Of(Code::InstructionsOf(caller))->AliasOffset();
    }
    if (unresolved_call->is_tail_call) {
      PcRelativeTailCallPattern call(addr);
      ASSERT(call.IsValid());
      call.set_distance(static_cast<int32_t>(distance));
      ASSERT(call.distance() == distance);
    } else {
      PcRelativeCallPattern call(addr);
      ASSERT(call.IsValid());
      call.set_distance(static_cast<int32_t>(distance));
      ASSERT(call.distance() == distance);
    }
  }

  unresolved_call->caller = nullptr;
  unresolved_call->callee = nullptr;
}

void CodeRelocator::ResolveTrampoline(
    UnresolvedTrampoline* unresolved_trampoline) {
  const intptr_t trampoline_text_offset = unresolved_trampoline->text_offset;
  const uword trampoline_start =
      reinterpret_cast<uword>(unresolved_trampoline->trampoline_bytes);

  auto callee = Code::InstructionsOf(unresolved_trampoline->callee);
  auto destination_text =
      FindDestinationInText(callee, unresolved_trampoline->offset_into_target);
  const int32_t distance = destination_text - trampoline_text_offset;

  PcRelativeTrampolineJumpPattern pattern(trampoline_start);
  pattern.Initialize();
  pattern.set_distance(distance);
  ASSERT(pattern.distance() == distance);
}

bool CodeRelocator::IsTargetInRangeFor(UnresolvedCall* unresolved_call,
                                       intptr_t target_text_offset) {
  const auto forward_distance =
      target_text_offset - unresolved_call->text_offset;
  if (unresolved_call->is_tail_call) {
    return TailCallDistanceLimits::Lower() <= forward_distance &&
           forward_distance <= TailCallDistanceLimits::Upper();
  } else {
    return CallDistanceLimits::Lower() <= forward_distance &&
           forward_distance <= CallDistanceLimits::Upper();
  }
}

CodePtr CodeRelocator::GetTarget(const StaticCallsTableEntry& call) {
  // The precompiler should have already replaced all function entries
  // with code entries.
  ASSERT(call.Get<Code::kSCallTableFunctionTarget>() == Function::null());

  target_ = call.Get<Code::kSCallTableCodeOrTypeTarget>();
  if (target_.IsAbstractType()) {
    target_ = AbstractType::Cast(target_).type_test_stub();
    destination_ = Code::Cast(target_).ptr();

    // The AssertAssignableInstr will emit pc-relative calls to the TTS iff
    // dst_type is instantiated. If we happened to not install an optimized
    // TTS but rather a default one, it will live in the vm-isolate (to
    // which we cannot make pc-relative calls).
    // Though we have "equivalent" isolate-specific stubs we can use as
    // targets instead.
    //
    // (We could make the AOT compiler install isolate-specific stubs
    // into the types directly, but that does not work for types which
    // live in the "vm-isolate" - such as `Type::dynamic_type()`).
    if (destination_.InVMIsolateHeap()) {
      auto object_store = thread_->isolate_group()->object_store();

      if (destination_.ptr() == StubCode::DefaultTypeTest().ptr()) {
        destination_ = object_store->default_tts_stub();
      } else if (destination_.ptr() ==
                 StubCode::DefaultNullableTypeTest().ptr()) {
        destination_ = object_store->default_nullable_tts_stub();
      } else if (destination_.ptr() == StubCode::TopTypeTypeTest().ptr()) {
        destination_ = object_store->top_type_tts_stub();
      } else if (destination_.ptr() == StubCode::UnreachableTypeTest().ptr()) {
        destination_ = object_store->unreachable_tts_stub();
      } else if (destination_.ptr() == StubCode::SlowTypeTest().ptr()) {
        destination_ = object_store->slow_tts_stub();
      } else if (destination_.ptr() ==
                 StubCode::NullableTypeParameterTypeTest().ptr()) {
        destination_ = object_store->nullable_type_parameter_tts_stub();
      } else if (destination_.ptr() ==
                 StubCode::TypeParameterTypeTest().ptr()) {
        destination_ = object_store->type_parameter_tts_stub();
      } else {
        UNREACHABLE();
      }
    }
  } else {
    ASSERT(target_.IsCode());
    destination_ = Code::Cast(target_).ptr();
  }
  ASSERT(!destination_.InVMIsolateHeap());
  return destination_.ptr();
}

void CodeRelocator::BuildTrampolinesForAlmostOutOfRangeCalls(
    const Code& next_caller,
    const Array& next_caller_targets) {
  const bool all_functions_emitted = next_caller.IsNull();

  uword next_size = 0;
  uword next_call_count = 0;
  if (!all_functions_emitted) {
    next_size = ImageWriter::SizeInSnapshot(next_caller.instructions());
    if (!next_caller_targets.IsNull()) {
      StaticCallsTable calls(next_caller_targets);
      next_call_count = calls.Length();
    }
  }

  while (!all_unresolved_calls_.IsEmpty()) {
    UnresolvedCall* unresolved_call = all_unresolved_calls_.First();

    if (!all_functions_emitted) {
      // If we can emit another instructions object without causing the
      // unresolved forward calls to become out-of-range, we'll not resolve it
      // yet (maybe the target function will come very soon and we don't need
      // a trampoline at all).
      const intptr_t future_boundary =
          next_text_offset_ + next_size +
          kTrampolineSize *
              (unresolved_calls_by_destination_.Length() + next_call_count - 1);
      if (IsTargetInRangeFor(unresolved_call, future_boundary) &&
          !FLAG_always_generate_trampolines_for_testing) {
        break;
      }
    }

    // We have a "critical" [unresolved_call] we have to resolve.  If an
    // existing trampoline is in range, we use that otherwise we create a new
    // trampoline.

    // In the worst case we'll make a new trampoline here, in which case the
    // current text offset must be in range for the "critical"
    // [unresolved_call].
    ASSERT(IsTargetInRangeFor(unresolved_call, next_text_offset_));

    // See if there is already a trampoline we could use.
    intptr_t trampoline_text_offset = -1;
    auto callee = Code::InstructionsOf(unresolved_call->callee);

    if (!FLAG_always_generate_trampolines_for_testing) {
      auto old_trampoline_entry = FindTrampolineFor(unresolved_call);
      if (old_trampoline_entry != nullptr) {
        trampoline_text_offset = old_trampoline_entry->text_offset;
      }
    }

    // If there is no trampoline yet, we'll create a new one.
    if (trampoline_text_offset == -1) {
      // The ownership of the trampoline bytes will be transferred to the
      // [ImageWriter], which will eventually write out the bytes and delete the
      // buffer.
      auto trampoline_bytes = new uint8_t[kTrampolineSize];
      ASSERT((kTrampolineSize % compiler::target::kWordSize) == 0);
      for (uint8_t* cur = trampoline_bytes;
           cur < trampoline_bytes + kTrampolineSize;
           cur += compiler::target::kWordSize) {
        *reinterpret_cast<compiler::target::uword*>(cur) =
            kBreakInstructionFiller;
      }
      auto unresolved_trampoline = new UnresolvedTrampoline{
          unresolved_call->callee,
          unresolved_call->offset_into_target,
          trampoline_bytes,
          next_text_offset_,
      };
      AddTrampolineToText(callee, trampoline_bytes, kTrampolineSize);
      EnqueueUnresolvedTrampoline(unresolved_trampoline);
      trampoline_text_offset = unresolved_trampoline->text_offset;
    }

    // Let the unresolved call to [destination] jump to the trampoline
    // instead.
    auto destination = Code::InstructionsOf(unresolved_call->callee);
    ResolveCallToDestination(unresolved_call, trampoline_text_offset);

    // Remove this unresolved call from the global list and the per-destination
    // list.
    auto calls = unresolved_calls_by_destination_.LookupValue(destination);
    calls->Remove(unresolved_call);
    all_unresolved_calls_.Remove(unresolved_call);
    delete unresolved_call;

    // If this destination has no longer any unresolved calls, remove it.
    if (calls->IsEmpty()) {
      unresolved_calls_by_destination_.Remove(destination);
      delete calls;
    }
  }
}

intptr_t CodeRelocator::FindDestinationInText(const InstructionsPtr destination,
                                              intptr_t offset_into_target) {
  auto const destination_offset = text_offsets_.LookupValue(destination);
  return destination_offset + AdjustPayloadOffset(offset_into_target);
}

intptr_t CodeRelocator::AdjustPayloadOffset(intptr_t payload_offset) {
  if (FLAG_precompiled_mode) {
    return payload_offset;
  }
  return compiler::target::Instructions::HeaderSize() + payload_offset;
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

}  // namespace dart
