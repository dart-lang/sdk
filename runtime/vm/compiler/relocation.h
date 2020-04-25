// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RELOCATION_H_
#define RUNTIME_VM_COMPILER_RELOCATION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/image_snapshot.h"
#include "vm/intrusive_dlist.h"
#include "vm/object.h"
#include "vm/type_testing_stubs.h"
#include "vm/visitor.h"

namespace dart {

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

// Represents a pc-relative call which has not been patched up with the final
// destination.
class UnresolvedCall : public IntrusiveDListEntry<UnresolvedCall>,
                       public IntrusiveDListEntry<UnresolvedCall, 2> {
 public:
  UnresolvedCall(CodePtr caller,
                 intptr_t call_offset,
                 intptr_t text_offset,
                 CodePtr callee,
                 intptr_t offset_into_target,
                 bool is_tail_call)
      : caller(caller),
        call_offset(call_offset),
        text_offset(text_offset),
        callee(callee),
        offset_into_target(offset_into_target),
        is_tail_call(is_tail_call) {}

  UnresolvedCall(const UnresolvedCall& other)
      : IntrusiveDListEntry<UnresolvedCall>(),
        IntrusiveDListEntry<UnresolvedCall, 2>(),
        caller(other.caller),
        call_offset(other.call_offset),
        text_offset(other.text_offset),
        callee(other.callee),
        offset_into_target(other.offset_into_target),
        is_tail_call(other.is_tail_call) {}

  // The caller which has an unresolved call (will be null'ed out when
  // resolved).
  CodePtr caller;
  // The offset from the payload of the calling code which performs the call.
  const intptr_t call_offset;
  // The offset in the .text segment where the call happens.
  const intptr_t text_offset;
  // The target of the forward call (will be null'ed out when resolved).
  CodePtr callee;
  // The extra offset into the target.
  const intptr_t offset_into_target;
  // Whether this is a tail call.
  const bool is_tail_call;
};

// A list of all unresolved calls.
using AllUnresolvedCallsList = IntrusiveDList<UnresolvedCall>;

// A list of all unresolved calls which call the same destination.
using SameDestinationUnresolvedCallsList = IntrusiveDList<UnresolvedCall, 2>;

// Represents a trampoline which has not been patched up with the final
// destination.
//
// The [CodeRelocator] will insert trampolines into the ".text" segment which
// increase the range of PC-relative calls.  If a pc-relative call in normal
// code is too far away from it's destination, it will call a trampoline
// instead (which will tail-call the destination).
class UnresolvedTrampoline : public IntrusiveDListEntry<UnresolvedTrampoline> {
 public:
  UnresolvedTrampoline(CodePtr callee,
                       intptr_t offset_into_target,
                       uint8_t* trampoline_bytes,
                       intptr_t text_offset)
      : callee(callee),
        offset_into_target(offset_into_target),
        trampoline_bytes(trampoline_bytes),
        text_offset(text_offset) {}

  // The target of the forward call.
  CodePtr callee;
  // The extra offset into the target.
  intptr_t offset_into_target;

  // The trampoline buffer.
  uint8_t* trampoline_bytes;
  // The offset in the .text segment where the trampoline starts.
  intptr_t text_offset;
};

using UnresolvedTrampolineList = IntrusiveDList<UnresolvedTrampoline>;

template <typename ValueType, ValueType kNoValue>
class InstructionsMapTraits {
 public:
  struct Pair {
    InstructionsPtr instructions;
    ValueType value;

    Pair() : instructions(nullptr), value(kNoValue) {}
    Pair(InstructionsPtr i, const ValueType& value)
        : instructions(i), value(value) {}
  };

  typedef const InstructionsPtr Key;
  typedef const ValueType Value;

  static Key KeyOf(Pair kv) { return kv.instructions; }
  static ValueType ValueOf(Pair kv) { return kv.value; }
  static inline intptr_t Hashcode(Key key) {
    return static_cast<intptr_t>(key);
  }
  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.instructions == key;
  }
};

using InstructionsPosition =
    DirectChainedHashMap<InstructionsMapTraits<intptr_t, -1>>;

using TrampolinesMap = DirectChainedHashMap<
    InstructionsMapTraits<UnresolvedTrampolineList*, nullptr>>;

using InstructionsUnresolvedCalls = DirectChainedHashMap<
    InstructionsMapTraits<SameDestinationUnresolvedCallsList*, nullptr>>;

// Relocates the given code objects by patching the instructions with the
// correct pc offsets.
//
// Produces a set of [ImageWriterCommand]s which tell the image writer in which
// order (and at which offset) to emit instructions.
class CodeRelocator : public StackResource {
 public:
  // Relocates instructions of the code objects provided by patching any
  // pc-relative calls/jumps.
  //
  // Populates the image writer command array which must be used later to write
  // the ".text" segment.
  static void Relocate(Thread* thread,
                       GrowableArray<CodePtr>* code_objects,
                       GrowableArray<ImageWriterCommand>* commands,
                       bool is_vm_isolate) {
    CodeRelocator relocator(thread, code_objects, commands);
    relocator.Relocate(is_vm_isolate);
  }

 private:
  CodeRelocator(Thread* thread,
                GrowableArray<CodePtr>* code_objects,
                GrowableArray<ImageWriterCommand>* commands);

  void Relocate(bool is_vm_isolate);

  void FindInstructionAndCallLimits();

  bool AddInstructionsToText(CodePtr code);
  void ScanCallTargets(const Code& code,
                       const Array& call_targets,
                       intptr_t code_text_offset);

  UnresolvedTrampoline* FindTrampolineFor(UnresolvedCall* unresolved_call);
  void AddTrampolineToText(InstructionsPtr destination,
                           uint8_t* trampoline_bytes,
                           intptr_t trampoline_length);

  void EnqueueUnresolvedCall(UnresolvedCall* unresolved_call);
  void EnqueueUnresolvedTrampoline(UnresolvedTrampoline* unresolved_trampoline);

  bool TryResolveBackwardsCall(UnresolvedCall* unresolved_call);
  void ResolveUnresolvedCallsTargeting(const InstructionsPtr instructions);
  void ResolveCall(UnresolvedCall* unresolved_call);
  void ResolveCallToDestination(UnresolvedCall* unresolved_call,
                                intptr_t destination_text);
  void ResolveTrampoline(UnresolvedTrampoline* unresolved_trampoline);

  void BuildTrampolinesForAlmostOutOfRangeCalls();

  intptr_t FindDestinationInText(const InstructionsPtr destination,
                                 intptr_t offset_into_target);

  static intptr_t AdjustPayloadOffset(intptr_t payload_offset);

  bool IsTargetInRangeFor(UnresolvedCall* unresolved_call,
                          intptr_t target_text_offset);

  CodePtr GetTarget(const StaticCallsTableEntry& entry);

  // The code relocation happens during AOT snapshot writing and operates on raw
  // objects. No allocations can be done.
  NoSafepointScope no_savepoint_scope_;
  Thread* thread_;

  const GrowableArray<CodePtr>* code_objects_;
  GrowableArray<ImageWriterCommand>* commands_;

  // The size of largest instructions object in bytes.
  intptr_t max_instructions_size_ = 0;
  // The maximum number of pc-relative calls in an instructions object.
  intptr_t max_calls_ = 0;
  intptr_t max_offset_into_target_ = 0;

  // Data structures used for relocation.
  intptr_t next_text_offset_ = 0;
  InstructionsPosition text_offsets_;
  TrampolinesMap trampolines_by_destination_;
  InstructionsUnresolvedCalls unresolved_calls_by_destination_;
  AllUnresolvedCallsList all_unresolved_calls_;

  // Reusable handles for [ScanCallTargets].
  Smi& kind_type_and_offset_;
  Object& target_;
  Code& destination_;
};

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RELOCATION_H_
