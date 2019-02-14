// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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

class InstructionsMapTraits {
 public:
  struct Pair {
    RawInstructions* instructions;
    intptr_t inst_nr;

    Pair() : instructions(nullptr), inst_nr(-1) {}
    Pair(RawInstructions* i, intptr_t nr) : instructions(i), inst_nr(nr) {}
  };

  typedef const RawInstructions* Key;
  typedef const intptr_t Value;

  static Key KeyOf(Pair kv) { return kv.instructions; }
  static Value ValueOf(Pair kv) { return kv.inst_nr; }
  static inline intptr_t Hashcode(Key key) {
    return reinterpret_cast<intptr_t>(key);
  }
  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.instructions == key;
  }
};

typedef DirectChainedHashMap<InstructionsMapTraits> InstructionsMap;

void CodeRelocator::Relocate(bool is_vm_isolate) {
  auto zone = Thread::Current()->zone();
  intptr_t next_text_offsets = 0;

  // Keeps track of mapping from Code to the index in [commands_] at which the
  // code object's instructions are located. This allows us to calculate the
  // distance to the destination using commands_[index].expected_offset.
  InstructionsMap instructions_map;

  // The callers which has an unresolved call.
  GrowableArray<RawCode*> callers;
  // The offset from the instruction at which the call happens.
  GrowableArray<intptr_t> call_offsets;
  // Type entry-point type we call in the destination.
  GrowableArray<Code::CallEntryPoint> call_entry_points;
  // The offset in the .text segment where the call happens.
  GrowableArray<intptr_t> text_offsets;
  // The target of the forward call.
  GrowableArray<RawCode*> callees;

  auto& targets = Array::Handle(zone);
  auto& kind_type_and_offset = Smi::Handle(zone);
  auto& target = Object::Handle(zone);
  auto& destination = Code::Handle(zone);
  auto& instructions = Instructions::Handle(zone);
  auto& caller = Code::Handle(zone);
  for (intptr_t i = 0; i < code_objects_->length(); ++i) {
    caller = (*code_objects_)[i];
    instructions = caller.instructions();

    // If two [Code] objects point to the same [Instructions] object, we'll just
    // use the first one (they are equivalent for all practical purposes).
    if (instructions_map.HasKey(instructions.raw())) {
      continue;
    }
    instructions_map.Insert({instructions.raw(), commands_->length()});

    // First we'll add the instructions of [caller] itself.
    const intptr_t active_code_text_offsets = next_text_offsets;
    commands_->Add(ImageWriterCommand(
        next_text_offsets, ImageWriterCommand::InsertInstructionOfCode,
        caller.raw()));

    next_text_offsets += instructions.raw()->Size();

    targets = caller.static_calls_target_table();
    if (!targets.IsNull()) {
      StaticCallsTable calls(targets);
      for (auto call : calls) {
        kind_type_and_offset = call.Get<Code::kSCallTableKindAndOffset>();
        auto kind = Code::KindField::decode(kind_type_and_offset.Value());
        auto offset = Code::OffsetField::decode(kind_type_and_offset.Value());
        auto entry_point =
            Code::EntryPointField::decode(kind_type_and_offset.Value());

        if (kind == Code::kCallViaCode) {
          continue;
        }

        target = call.Get<Code::kSCallTableFunctionTarget>();
        if (target.IsFunction()) {
          auto& fun = Function::Cast(target);
          ASSERT(fun.HasCode());
          destination = fun.CurrentCode();
          ASSERT(!destination.IsStubCode());
        } else {
          target = call.Get<Code::kSCallTableCodeTarget>();
          ASSERT(target.IsCode());
          destination = Code::Cast(target).raw();
        }

        const intptr_t start_of_call =
            active_code_text_offsets + instructions.HeaderSize() + offset;

        callers.Add(caller.raw());
        callees.Add(destination.raw());
        text_offsets.Add(start_of_call);
        call_offsets.Add(offset);
        call_entry_points.Add(entry_point);
      }
    }
  }

  auto& callee = Code::Handle(zone);
  auto& caller_instruction = Instructions::Handle(zone);
  auto& destination_instruction = Instructions::Handle(zone);
  for (intptr_t i = 0; i < callees.length(); ++i) {
    caller = callers[i];
    callee = callees[i];
    const intptr_t text_offset = text_offsets[i];
    const intptr_t call_offset = call_offsets[i];
    const bool use_unchecked_entry =
        call_entry_points[i] == Code::kUncheckedEntry;
    caller_instruction = caller.instructions();
    destination_instruction = callee.instructions();

    const uword entry_point = use_unchecked_entry ? callee.UncheckedEntryPoint()
                                                  : callee.EntryPoint();
    const intptr_t unchecked_offset =
        destination_instruction.HeaderSize() +
        (entry_point - destination_instruction.PayloadStart());

    auto map_entry = instructions_map.Lookup(destination_instruction.raw());
    auto& dst = (*commands_)[map_entry->inst_nr];
    ASSERT(dst.op == ImageWriterCommand::InsertInstructionOfCode);

    const int32_t distance =
        (dst.expected_offset + unchecked_offset) - text_offset;
    {
      NoSafepointScope no_safepoint_scope;

      PcRelativeCallPattern call(caller_instruction.PayloadStart() +
                                 call_offset);
      ASSERT(call.IsValid());
      call.set_distance(static_cast<int32_t>(distance));
      ASSERT(call.distance() == distance);
    }
  }

  // We're done now, so we clear out the targets tables.
  if (!is_vm_isolate) {
    for (intptr_t i = 0; i < code_objects_->length(); ++i) {
      caller = (*code_objects_)[i];
      caller.set_static_calls_target_table(Array::empty_array());
    }
  }
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_DBC) &&           \
        // !defined(TARGET_ARCH_IA32)

}  // namespace dart
