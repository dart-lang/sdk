// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/relocation.h"

#include "vm/code_patcher.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"

namespace dart {

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_DBC) &&                  \
    !defined(TARGET_ARCH_IA32)

// Only for testing.
DEFINE_FLAG(bool,
            always_generate_trampolines_for_testing,
            false,
            "Generate always trampolines (for testing purposes).");

const intptr_t kTrampolineSize = OS::kMaxPreferredCodeAlignment;

CodeRelocator::CodeRelocator(Thread* thread,
                             GrowableArray<RawCode*>* code_objects,
                             GrowableArray<ImageWriterCommand>* commands)
    : StackResource(thread),
      code_objects_(code_objects),
      commands_(commands),
      kind_type_and_offset_(Smi::Handle(thread->zone())),
      target_(Object::Handle(thread->zone())),
      destination_(Code::Handle(thread->zone())) {}

void CodeRelocator::Relocate(bool is_vm_isolate) {
  Zone* zone = Thread::Current()->zone();
  auto& current_caller = Code::Handle(zone);
  auto& call_targets = Array::Handle(zone);

  // Find out the size of the largest [RawInstructions] object.
  for (intptr_t i = 0; i < code_objects_->length(); ++i) {
    current_caller = (*code_objects_)[i];
    const intptr_t size = current_caller.instructions()->Size();
    if (size > max_instructions_size_) {
      max_instructions_size_ = size;
    }

    call_targets = current_caller.static_calls_target_table();
    if (!call_targets.IsNull()) {
      StaticCallsTable calls(call_targets);
      const intptr_t num_calls = calls.Length();
      if (num_calls > max_calls_) {
        max_calls_ = num_calls;
      }
    }
  }

  // Emit all instructions and do relocations on the way.
  for (intptr_t i = 0; i < code_objects_->length(); ++i) {
    current_caller = (*code_objects_)[i];

    const intptr_t code_text_offset = next_text_offset_;
    if (!AddInstructionsToText(current_caller.raw())) {
      continue;
    }

    call_targets = current_caller.static_calls_target_table();
    ScanCallTargets(current_caller, call_targets, code_text_offset);

    // Any unresolved calls to this instruction can be fixed now.
    ResolveUnresolvedCallsTargeting(current_caller.instructions());

    // If we have forward/backwards calls which are almost out-of-range, we'll
    // create trampolines now.
    BuildTrampolinesForAlmostOutOfRangeCalls();
  }

  // We're guaranteed to have all calls resolved, since
  //   * backwards calls are resolved eagerly
  //   * forward calls are resolved once the target is written
  ASSERT(all_unresolved_calls_.IsEmpty());
  ASSERT(unresolved_calls_by_destination_.IsEmpty());

  // Any trampolines we created must be patched with the right offsets.
  for (auto unresolved_trampoline : unresolved_trampolines_) {
    ResolveTrampoline(unresolved_trampoline);
    delete unresolved_trampoline;
  }

  // We're done now, so we clear out the targets tables.
  auto& caller = Code::Handle(zone);
  if (!is_vm_isolate) {
    for (intptr_t i = 0; i < code_objects_->length(); ++i) {
      caller = (*code_objects_)[i];
      caller.set_static_calls_target_table(Array::empty_array());
    }
  }
}

bool CodeRelocator::AddInstructionsToText(RawCode* code) {
  RawInstructions* instructions = Code::InstructionsOf(code);

  // If two [Code] objects point to the same [Instructions] object, we'll just
  // use the first one (they are equivalent for all practical purposes).
  if (text_offsets_.HasKey(instructions)) {
    return false;
  }
  text_offsets_.Insert({instructions, next_text_offset_});
  commands_->Add(ImageWriterCommand(next_text_offset_, code));
  next_text_offset_ += instructions->Size();

  return true;
}

void CodeRelocator::AddTrampolineToText(RawInstructions* destination,
                                        uint8_t* trampoline_bytes,
                                        intptr_t trampoline_length) {
  commands_->Add(ImageWriterCommand(next_text_offset_, trampoline_bytes,
                                    trampoline_length));
  trampoline_text_offsets_.Insert({destination, next_text_offset_});
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
    auto kind = Code::KindField::decode(kind_type_and_offset_.Value());
    auto offset = Code::OffsetField::decode(kind_type_and_offset_.Value());
    auto entry_point =
        Code::EntryPointField::decode(kind_type_and_offset_.Value());

    if (kind == Code::kCallViaCode) {
      continue;
    }

    target_ = call.Get<Code::kSCallTableFunctionTarget>();
    if (target_.IsFunction()) {
      auto& fun = Function::Cast(target_);
      ASSERT(fun.HasCode());
      destination_ = fun.CurrentCode();
      ASSERT(!destination_.IsStubCode());
    } else {
      target_ = call.Get<Code::kSCallTableCodeTarget>();
      ASSERT(target_.IsCode());
      destination_ = Code::Cast(target_).raw();
    }

    const intptr_t text_offset =
        code_text_offset + Instructions::HeaderSize() + offset;
    UnresolvedCall unresolved_call(code.raw(), offset, entry_point, text_offset,
                                   destination_.raw());
    if (!TryResolveBackwardsCall(&unresolved_call)) {
      EnqueueUnresolvedCall(new UnresolvedCall(unresolved_call));
    }
  }
}

void CodeRelocator::EnqueueUnresolvedCall(UnresolvedCall* unresolved_call) {
  // Add it to the min-heap by .text offset.
  all_unresolved_calls_.Append(unresolved_call);

  // Add it to callers of destination.
  RawInstructions* destination = Code::InstructionsOf(unresolved_call->callee);
  if (!unresolved_calls_by_destination_.HasKey(destination)) {
    unresolved_calls_by_destination_.Insert(
        {destination, new SameDestinationUnresolvedCallsList()});
  }
  unresolved_calls_by_destination_.LookupValue(destination)
      ->Append(unresolved_call);
}

void CodeRelocator::EnqueueUnresolvedTrampoline(
    UnresolvedTrampoline* unresolved_trampoline) {
  unresolved_trampolines_.Add(unresolved_trampoline);
}

bool CodeRelocator::TryResolveBackwardsCall(UnresolvedCall* unresolved_call) {
  auto callee = Code::InstructionsOf(unresolved_call->callee);
  auto map_entry = text_offsets_.Lookup(callee);
  if (map_entry == nullptr) return false;

  ResolveCall(unresolved_call);
  return true;
}

void CodeRelocator::ResolveUnresolvedCallsTargeting(
    const RawInstructions* instructions) {
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
  const auto destination_text =
      FindDestinationInText(Code::InstructionsOf(unresolved_call->callee),
                            unresolved_call->call_entry_point);

  ResolveCallToDestination(unresolved_call, destination_text);
}

void CodeRelocator::ResolveCallToDestination(UnresolvedCall* unresolved_call,
                                             intptr_t destination_text) {
  const intptr_t call_text_offset = unresolved_call->text_offset;
  const intptr_t call_offset = unresolved_call->call_offset;

  auto caller = Code::InstructionsOf(unresolved_call->caller);
  const int32_t distance = destination_text - call_text_offset;
  {
    NoSafepointScope no_safepoint_scope;

    PcRelativeCallPattern call(Instructions::PayloadStart(caller) +
                               call_offset);
    ASSERT(call.IsValid());
    call.set_distance(static_cast<int32_t>(distance));
    ASSERT(call.distance() == distance);
  }

  unresolved_call->caller = nullptr;
  unresolved_call->callee = nullptr;
}

void CodeRelocator::ResolveTrampoline(
    UnresolvedTrampoline* unresolved_trampoline) {
  const intptr_t trampoline_text_offset = unresolved_trampoline->text_offset;
  const uword trampoline_start =
      reinterpret_cast<uword>(unresolved_trampoline->trampoline_bytes);
  auto call_entry_point = unresolved_trampoline->call_entry_point;

  auto callee = Code::InstructionsOf(unresolved_trampoline->callee);
  auto destination_text = FindDestinationInText(callee, call_entry_point);
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
  return PcRelativeCallPattern::kLowerCallingRange < forward_distance &&
         forward_distance < PcRelativeCallPattern::kUpperCallingRange;
}

void CodeRelocator::BuildTrampolinesForAlmostOutOfRangeCalls() {
  while (!all_unresolved_calls_.IsEmpty()) {
    UnresolvedCall* first_unresolved_call = all_unresolved_calls_.First();

    // If we can emit another instructions object without causing the unresolved
    // forward calls to become out-of-range, we'll not resolve it yet (maybe the
    // target function will come very soon and we don't need a trampoline at
    // all).
    const intptr_t future_boundary =
        next_text_offset_ + max_instructions_size_ +
        kTrampolineSize *
            (unresolved_calls_by_destination_.Length() + max_calls_);
    if (IsTargetInRangeFor(first_unresolved_call, future_boundary) &&
        !FLAG_always_generate_trampolines_for_testing) {
      break;
    }

    // We have a "critical" [first_unresolved_call] we have to resolve.  If an
    // existing trampoline is in range, we use that otherwise we create a new
    // trampoline.

    // In the worst case we'll make a new trampoline here, in which case the
    // current text offset must be in range for the "critical"
    // [first_unresolved_call].
    ASSERT(IsTargetInRangeFor(first_unresolved_call, next_text_offset_));

    // See if there is already a trampoline we could use.
    intptr_t trampoline_text_offset = -1;
    auto callee = Code::InstructionsOf(first_unresolved_call->callee);
    auto old_trampoline_entry = trampoline_text_offsets_.Lookup(callee);
    if (old_trampoline_entry != nullptr &&
        !FLAG_always_generate_trampolines_for_testing) {
      const intptr_t offset = old_trampoline_entry->value;
      if (IsTargetInRangeFor(first_unresolved_call, offset)) {
        trampoline_text_offset = offset;
      }
    }

    // If there is no trampoline yet, we'll create a new one.
    if (trampoline_text_offset == -1) {
      // The ownership of the trampoline bytes will be transferred to the
      // [ImageWriter], which will eventually write out the bytes and delete the
      // buffer.
      auto trampoline_bytes = new uint8_t[kTrampolineSize];
      memset(trampoline_bytes, 0x00, kTrampolineSize);
      auto unresolved_trampoline = new UnresolvedTrampoline{
          first_unresolved_call->call_entry_point,
          first_unresolved_call->callee,
          trampoline_bytes,
          next_text_offset_,
      };
      AddTrampolineToText(callee, trampoline_bytes, kTrampolineSize);
      EnqueueUnresolvedTrampoline(unresolved_trampoline);
      trampoline_text_offset = unresolved_trampoline->text_offset;
    }

    // Let the unresolved call to [destination] jump to the trampoline
    // instead.
    auto destination = Code::InstructionsOf(first_unresolved_call->callee);
    ResolveCallToDestination(first_unresolved_call, trampoline_text_offset);

    // Remove this unresolved call from the global list and the per-destination
    // list.
    auto calls = unresolved_calls_by_destination_.LookupValue(destination);
    calls->Remove(first_unresolved_call);
    all_unresolved_calls_.Remove(first_unresolved_call);
    delete first_unresolved_call;

    // If this destination has no longer any unresolved calls, remove it.
    if (calls->IsEmpty()) {
      unresolved_calls_by_destination_.Remove(destination);
      delete calls;
    }
  }
}

intptr_t CodeRelocator::FindDestinationInText(
    const RawInstructions* destination,
    Code::CallEntryPoint call_entry_point) {
  const uword entry_point = call_entry_point == Code::kUncheckedEntry
                                ? Instructions::UncheckedEntryPoint(destination)
                                : Instructions::EntryPoint(destination);
  const uword payload_offset =
      entry_point - Instructions::PayloadStart(destination);
  const intptr_t unchecked_offset = Instructions::HeaderSize() + payload_offset;
  auto destination_offset = text_offsets_.LookupValue(destination);
  return destination_offset + unchecked_offset;
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_DBC) &&           \
        // !defined(TARGET_ARCH_IA32)

}  // namespace dart
