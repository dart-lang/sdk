// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <functional>

#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/compiler_pass.h"
#include "vm/compiler/write_barrier_elimination.h"

namespace dart {

#if defined(DEBUG)
DEFINE_FLAG(bool,
            trace_write_barrier_elimination,
            false,
            "Trace WriteBarrierElimination pass.");
#endif

class DefinitionIndexPairTrait {
 public:
  typedef Definition* Key;
  typedef intptr_t Value;
  struct Pair {
    Definition* definition = nullptr;
    intptr_t index = -1;
    Pair() {}
    Pair(Definition* definition, intptr_t index)
        : definition(definition), index(index) {}
  };

  static Key KeyOf(Pair kv) { return kv.definition; }
  static Value ValueOf(Pair kv) { return kv.index; }
  static inline intptr_t Hashcode(Key key) { return std::hash<Key>()(key); }
  static inline bool IsKeyEqual(Pair kv, Key key) {
    return kv.definition == key;
  }
};

typedef DirectChainedHashMap<DefinitionIndexPairTrait> DefinitionIndexMap;

// Inter-block write-barrier elimination.
//
// This optimization removes write barriers from some store instructions under
// certain assumptions which the runtime is responsible to sustain.
//
// We can skip a write barrier on a StoreInstanceField to a container object X
// if we know that either:
//   - X is in new-space, or
//   - X is in old-space, and:
//     - X is in the store buffer, and
//     - X is in the deferred marking stack (if concurrent marking is enabled)
//
// The result of an Allocation instruction (Instruction::IsAllocation()) will
// satisfy one of these requirements immediately after the instruction
// if WillAllocateNewOrRemembered() is true.
//
// Without runtime support, we would have to assume that any instruction which
// can trigger a new-space scavenge (Instruction::CanTriggerGC()) might promote
// a new-space temporary into old-space, and we could not skip a store barrier
// on a write into it afterward.
//
// However, many instructions can trigger GC in unlikely cases, like
// CheckStackOverflow and Box. To avoid interrupting write barrier elimination
// across these instructions, the runtime ensures that any live temporaries
// (except arrays) promoted during a scavenge caused by a non-Dart-call
// instruction (see Instruction::CanCallDart()) will be added to the store
// buffer. Additionally, if concurrent marking was initiated, the runtime
// ensures that all live temporaries are also in the deferred marking stack.
//
// See also Thread::RememberLiveTemporaries() and
// Thread::DeferredMarkLiveTemporaries().
class WriteBarrierElimination : public ValueObject {
 public:
  WriteBarrierElimination(Zone* zone, FlowGraph* flow_graph);

  void Analyze();
  void SaveResults();

 private:
  void IndexDefinitions(Zone* zone);

  bool AnalyzeBlock(BlockEntryInstr* entry);
  void MergePredecessors(BlockEntryInstr* entry);

  void UpdateVectorForBlock(BlockEntryInstr* entry, bool finalize);

  static intptr_t Index(BlockEntryInstr* entry) {
    return entry->postorder_number();
  }

  intptr_t Index(Definition* def) {
    ASSERT(IsUsable(def));
    return definition_indices_.LookupValue(def);
  }

  bool IsUsable(Definition* def) {
    return def->IsPhi() || (def->IsAllocation() &&
                            def->AsAllocation()->WillAllocateNewOrRemembered());
  }

#if defined(DEBUG)
  static bool SlotEligibleForWBE(const Slot& slot);
#endif

  FlowGraph* const flow_graph_;
  const GrowableArray<BlockEntryInstr*>* const block_order_;

  // Number of usable definitions in the graph.
  intptr_t definition_count_ = 0;

  // Maps each usable definition to its index in the bitvectors.
  DefinitionIndexMap definition_indices_;

  // Bitvector with all non-Array-allocation instructions set. Used to
  // un-mark Array allocations as usable.
  BitVector* array_allocations_mask_;

  // Bitvectors for each block of which allocations are new or remembered
  // at the start (after Phis).
  GrowableArray<BitVector*> usable_allocs_in_;

  // Bitvectors for each block of which allocations are new or remembered
  // at the end of the block.
  GrowableArray<BitVector*> usable_allocs_out_;

  // Remaining blocks to process.
  GrowableArray<BlockEntryInstr*> worklist_;

  // Temporary used in many functions to avoid repeated zone allocation.
  BitVector* vector_;

  // Bitvector of blocks which have been processed, to ensure each block
  // is processed at least once.
  BitVector* processed_blocks_;

#if defined(DEBUG)
  bool tracing_ = false;
#else
  static constexpr bool tracing_ = false;
#endif
};

WriteBarrierElimination::WriteBarrierElimination(Zone* zone,
                                                 FlowGraph* flow_graph)
    : flow_graph_(flow_graph), block_order_(&flow_graph->postorder()) {
#if defined(DEBUG)
  if (flow_graph->should_print() && FLAG_trace_write_barrier_elimination) {
    tracing_ = true;
  }
#endif

  IndexDefinitions(zone);

  for (intptr_t i = 0; i < block_order_->length(); ++i) {
    usable_allocs_in_.Add(new (zone) BitVector(zone, definition_count_));
    usable_allocs_in_[i]->CopyFrom(vector_);

    usable_allocs_out_.Add(new (zone) BitVector(zone, definition_count_));
    usable_allocs_out_[i]->CopyFrom(vector_);
  }

  processed_blocks_ = new (zone) BitVector(zone, block_order_->length());
}

void WriteBarrierElimination::Analyze() {
  for (intptr_t i = 0; i < block_order_->length(); ++i) {
    worklist_.Add(block_order_->At(i));
  }

  while (!worklist_.is_empty()) {
    auto* const entry = worklist_.RemoveLast();
    if (AnalyzeBlock(entry)) {
      for (intptr_t i = 0; i < entry->last_instruction()->SuccessorCount();
           ++i) {
        if (tracing_) {
          THR_Print("Enqueueing block %" Pd "\n", entry->block_id());
        }
        worklist_.Add(entry->last_instruction()->SuccessorAt(i));
      }
    }
  }
}

void WriteBarrierElimination::SaveResults() {
  for (intptr_t i = 0; i < block_order_->length(); ++i) {
    vector_->CopyFrom(usable_allocs_in_[i]);
    UpdateVectorForBlock(block_order_->At(i), /*finalize=*/true);
  }
}

void WriteBarrierElimination::IndexDefinitions(Zone* zone) {
  BitmapBuilder array_allocations;

  GrowableArray<Definition*> create_array_worklist;

  for (intptr_t i = 0; i < block_order_->length(); ++i) {
    BlockEntryInstr* const block = block_order_->At(i);
    if (auto join_block = block->AsJoinEntry()) {
      for (PhiIterator it(join_block); !it.Done(); it.Advance()) {
        array_allocations.Set(definition_count_, false);
        definition_indices_.Insert({it.Current(), definition_count_++});
#if defined(DEBUG)
        if (tracing_) {
          THR_Print("Definition (%" Pd ") has index %" Pd ".\n",
                    it.Current()->ssa_temp_index(), definition_count_ - 1);
        }
#endif
      }
    }
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      if (Definition* current = it.Current()->AsDefinition()) {
        if (IsUsable(current)) {
          const bool is_create_array = current->IsCreateArray();
          array_allocations.Set(definition_count_, is_create_array);
          definition_indices_.Insert({current, definition_count_++});
          if (is_create_array) {
            create_array_worklist.Add(current);
          }
#if defined(DEBUG)
          if (tracing_) {
            THR_Print("Definition (%" Pd ") has index %" Pd ".\n",
                      current->ssa_temp_index(), definition_count_ - 1);
          }
#endif
        }
      }
    }
  }

  while (!create_array_worklist.is_empty()) {
    auto instr = create_array_worklist.RemoveLast();
    for (Value::Iterator it(instr->input_use_list()); !it.Done();
         it.Advance()) {
      if (auto phi_use = it.Current()->instruction()->AsPhi()) {
        const intptr_t index = Index(phi_use);
        if (!array_allocations.Get(index)) {
          array_allocations.Set(index, /*can_be_create_array=*/true);
          create_array_worklist.Add(phi_use);
        }
      }
    }
  }

  vector_ = new (zone) BitVector(zone, definition_count_);
  vector_->SetAll();
  array_allocations_mask_ = new (zone) BitVector(zone, definition_count_);
  for (intptr_t i = 0; i < definition_count_; ++i) {
    if (!array_allocations.Get(i)) array_allocations_mask_->Add(i);
  }
}

void WriteBarrierElimination::MergePredecessors(BlockEntryInstr* entry) {
  vector_->Clear();
  for (intptr_t i = 0; i < entry->PredecessorCount(); ++i) {
    BitVector* predecessor_set =
        usable_allocs_out_[Index(entry->PredecessorAt(i))];
    if (i == 0) {
      vector_->AddAll(predecessor_set);
    } else {
      vector_->Intersect(predecessor_set);
    }
  }

  if (JoinEntryInstr* join = entry->AsJoinEntry()) {
    // A Phi is usable if and only if all its inputs are usable.
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      ASSERT(phi->InputCount() == entry->PredecessorCount());
      bool is_usable = true;
      for (intptr_t i = 0; i < phi->InputCount(); ++i) {
        BitVector* const predecessor_set =
            usable_allocs_out_[Index(entry->PredecessorAt(i))];
        Definition* const origin = phi->InputAt(i)->definition();
        if (!IsUsable(origin) || !predecessor_set->Contains(Index(origin))) {
          is_usable = false;
          break;
        }
      }
      vector_->Set(Index(phi), is_usable);
    }

#if defined(DEBUG)
    if (tracing_) {
      THR_Print("Merge predecessors for %" Pd ".\n", entry->block_id());
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        THR_Print("%" Pd ": %s\n", phi->ssa_temp_index(),
                  vector_->Contains(Index(phi)) ? "true" : "false");
      }
    }
#endif
  }
}

bool WriteBarrierElimination::AnalyzeBlock(BlockEntryInstr* entry) {
  // Recompute the usable allocs in-set.
  MergePredecessors(entry);

  // If the in-set has not changed, there's no work to do.
  BitVector* const in_set = usable_allocs_in_[Index(entry)];
  ASSERT(vector_->SubsetOf(*in_set));  // convergence
  if (vector_->Equals(*in_set) && processed_blocks_->Contains(Index(entry))) {
    if (tracing_) {
      THR_Print("Bailout of block %" Pd ": inputs didn't change.\n",
                entry->block_id());
    }
    return false;
  } else if (tracing_) {
    THR_Print("Inputs of block %" Pd " changed: ", entry->block_id());
    in_set->Print();
    THR_Print(" -> ");
    vector_->Print();
    THR_Print("\n");
  }

  usable_allocs_in_[Index(entry)]->CopyFrom(vector_);
  UpdateVectorForBlock(entry, /*finalize=*/false);

  processed_blocks_->Add(Index(entry));

  // Successors only need to be updated if the out-set changes.
  if (vector_->Equals(*usable_allocs_out_[Index(entry)])) {
    if (tracing_) {
      THR_Print("Bailout of block %" Pd ": out-set didn't change.\n",
                entry->block_id());
    }
    return false;
  }

  BitVector* const out_set = usable_allocs_out_[Index(entry)];
  ASSERT(vector_->SubsetOf(*out_set));  // convergence
  out_set->CopyFrom(vector_);
  if (tracing_) {
    THR_Print("Block %" Pd " changed.\n", entry->block_id());
  }
  return true;
}

#if defined(DEBUG)
bool WriteBarrierElimination::SlotEligibleForWBE(const Slot& slot) {
  // We assume that Dart code only stores into Instances, Contexts, and
  // UnhandledExceptions. This assumption is used in
  // RestoreWriteBarrierInvariantVisitor::VisitPointers.

  switch (slot.kind()) {
    case Slot::Kind::kCapturedVariable:  // Context
      return true;
    case Slot::Kind::kDartField:  // Instance
      return true;

#define FOR_EACH_NATIVE_SLOT(class, underlying_type, field, __, ___)           \
  case Slot::Kind::k##class##_##field:                                         \
    return std::is_base_of<InstanceLayout, underlying_type>::value ||          \
           std::is_base_of<ContextLayout, underlying_type>::value ||           \
           std::is_base_of<UnhandledExceptionLayout, underlying_type>::value;

      NATIVE_SLOTS_LIST(FOR_EACH_NATIVE_SLOT)
#undef FOR_EACH_NATIVE_SLOT

    default:
      return false;
  }
}
#endif

void WriteBarrierElimination::UpdateVectorForBlock(BlockEntryInstr* entry,
                                                   bool finalize) {
  for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
    Instruction* const current = it.Current();

    if (finalize) {
      if (StoreInstanceFieldInstr* instr = current->AsStoreInstanceField()) {
        Definition* const container = instr->instance()->definition();
        if (IsUsable(container) && vector_->Contains(Index(container))) {
          DEBUG_ASSERT(SlotEligibleForWBE(instr->slot()));
          instr->set_emit_store_barrier(kNoStoreBarrier);
        }
      } else if (StoreIndexedInstr* instr = current->AsStoreIndexed()) {
        Definition* const array = instr->array()->definition();
        if (IsUsable(array) && vector_->Contains(Index(array))) {
          instr->set_emit_store_barrier(StoreBarrierType::kNoStoreBarrier);
        }
      }
    }

    if (current->CanCallDart()) {
      vector_->Clear();
    } else if (current->CanTriggerGC()) {
      // Clear array allocations. These are not added to the remembered set
      // by Thread::RememberLiveTemporaries() after a scavenge.
      vector_->Intersect(array_allocations_mask_);
    }

    if (AllocationInstr* const alloc = current->AsAllocation()) {
      if (alloc->WillAllocateNewOrRemembered()) {
        vector_->Add(Index(alloc));
      }
    }
  }
}

void EliminateWriteBarriers(FlowGraph* flow_graph) {
  WriteBarrierElimination elimination(Thread::Current()->zone(), flow_graph);
  elimination.Analyze();
  elimination.SaveResults();
}

}  // namespace dart
