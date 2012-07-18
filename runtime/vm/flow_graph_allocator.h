// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_ALLOCATOR_H_
#define VM_FLOW_GRAPH_ALLOCATOR_H_

#include "vm/growable_array.h"
#include "vm/intermediate_language.h"

namespace dart {

class FlowGraphBuilder;
class LiveRange;
class UseInterval;

class FlowGraphAllocator : public ValueObject {
 public:
  FlowGraphAllocator(const GrowableArray<BlockEntryInstr*>& block_order,
                     FlowGraphBuilder* builder);

  void AllocateRegisters();

  // Build live-in and live-out sets for each block.
  void AnalyzeLiveness();

 private:
  // Compute initial values for live-out, kill and live-in sets.
  void ComputeInitialSets();

  // Update live-out set for the given block: live-out should contain
  // all values that are live-in for block's successors.
  // Returns true if live-out set was changed.
  bool UpdateLiveOut(BlockEntryInstr* instr);

  // Update live-in set for the given block: live-in should contain
  // all values that are live-out from the block and are not defined
  // by this block.
  // Returns true if live-in set was changed.
  bool UpdateLiveIn(BlockEntryInstr* instr);

  // Perform fix-point iteration updating live-out and live-in sets
  // for blocks until they stop changing.
  void ComputeLiveInAndLiveOutSets();

  // Print results of liveness analysis.
  void DumpLiveness();

  // Visit blocks in the code generation order (reverse post order) and
  // linearly assign consequent lifetime positions to every instruction.
  // Each instruction gets two positions:
  //
  //    2 * n     - even one corresponding to instruction's start
  //
  //    2 * n + 1 - odd one corresponding to instruction's end
  //
  // Having two positions allows us to capture non-trivial register
  // constraints in use intervals: for example we can declare that
  // an input value is only used at the start of the instruction and
  // this might allow register allocator to allocate both this input
  // and output (or temp) to the same register if this is the last
  // use of the value.
  // Additionally creates parallel moves at the joins' predecessors
  // that will be used for phi resolution.
  void NumberInstructions();

  LiveRange* GetLiveRange(intptr_t vreg);
  void BuildLiveRanges();
  void PrintLiveRanges();

  // Register use of the given virtual register at lifetime position use_pos.
  // If definition position is unknown then start of the block contaning
  // use_pos will be passed.
  void UseValue(Instruction* instr,
                intptr_t def_pos,  // Lifetime position for the definition.
                intptr_t use_pos,  // Lifetime position for the use.
                intptr_t vreg,
                Location* loc,
                bool use_at_end);

  // Register definition of the given virtual register at lifetime position
  // def_pos.  Existing use interval will be shortened to start at def_pos.
  void Define(Instruction* instr,
              intptr_t def_pos,
              intptr_t vreg,
              Location* loc);

  void AddToUnallocated(UseInterval* chain);
  void BlockLocation(Location loc, intptr_t pos);

  bool AllocateFreeRegister(UseInterval* unallocated);
  void AssignFreeRegister(UseInterval* unallocated, Register reg);

  void FinalizeInterval(UseInterval* interval, Location loc);
  void AdvanceActiveIntervals(const intptr_t start);

  bool UnallocatedIsSorted();
  void AllocateCPURegisters();

  // TODO(vegorov): this field is used only to call Bailout. Remove when
  // all bailouts are gone.
  FlowGraphBuilder* builder_;

  const GrowableArray<BlockEntryInstr*>& block_order_;
  const GrowableArray<BlockEntryInstr*>& postorder_;

  // Live-out sets for each block.  They contain indices of SSA values
  // that are live out from this block: that is values that were either
  // defined in this block or live into it and that are used in some
  // successor block.
  GrowableArray<BitVector*> live_out_;

  // Kill sets for each block.  They contain indices of SSA values that
  // are defined by this block.
  GrowableArray<BitVector*> kill_;

  // Live-in sets for each block.  They contain indices of SSA values
  // that are used by this block or its successors.
  GrowableArray<BitVector*> live_in_;

  // Number of virtual registers.  Currently equal to the number of
  // SSA values.
  const intptr_t vreg_count_;

  // LiveRanges corresponding to SSA values.
  GrowableArray<LiveRange*> live_ranges_;

  // Worklist for register allocator. Always maintained sorted according
  // to ShouldBeAllocatedBefore predicate.
  GrowableArray<UseInterval*> unallocated_;

  // Per register lists of allocated UseIntervals, linked through
  // next_allocated field.  Contains only those intervals that
  // can be affected by future allocation decisions.  Those intervals
  // that end before the start of the current UseInterval are removed
  // from this list and will not be affected.
  UseInterval* cpu_regs_[kNumberOfCpuRegisters];

  DISALLOW_COPY_AND_ASSIGN(FlowGraphAllocator);
};


// UsePosition represents a single use of an SSA value by some instruction.
// It points to a location slot which either tells register allocator
// where instruction expects the value (if slot contains a fixed location) or
// asks register allocator to allocate storage (register or spill slot) for
// this use with certain properties (if slot contain an unallocated location).
class UsePosition : public ZoneAllocated {
 public:
  enum UseFlag {
    kNoFlag = 0,
    kFixedUse = 1,
    kSameAsFirstUse = 2,
    kOther = 3
  };

  static const intptr_t kUseFlagMask = 0x3;
  static const intptr_t kPositionShift = 2;

  static UseFlag FlagForUse(const Location& loc) {
    if (loc.IsRegister()) return kFixedUse;
    if (loc.IsUnallocated() && (loc.policy() == Location::kSameAsFirstInput)) {
      return kSameAsFirstUse;
    }
    return kOther;
  }

  // TODO(vegorov): we encode either position or instruction pointer
  // into the pos_ field to generate moves when needed to resolve
  // fixed or same-as-first constraints, but this looks ugly.
  UsePosition(Instruction* instr,
              intptr_t pos,
              UsePosition* next,
              Location* location_slot)
      : pos_(pos << kPositionShift),
        location_slot_(location_slot),
        next_(next) {
    // Non-NULL instr is considered unlikely so we preinitialize pos_ field
    // with an encoded position even if instr is not NULL.
    if (instr != NULL) {
      ASSERT(location_slot_ != NULL);
      pos_ = reinterpret_cast<intptr_t>(instr) | FlagForUse(*location_slot_);
    }
    ASSERT(this->pos() == pos);
  }

  // Tell the use that it should load the value from the given location.
  // If location slot for the use is flexible (unallocated) it will be updated
  // with the given location. Otherwise a move will be scheduled from the given
  // location to the location already stored in the slot.
  void AssignLocation(Location loc);

  Location* location_slot() const { return location_slot_; }
  void set_location_slot(Location* location_slot) {
    location_slot_ = location_slot;
  }

  void set_next(UsePosition* next) { next_ = next; }
  UsePosition* next() const { return next_; }

  intptr_t pos() const {
    if ((pos_ & kUseFlagMask) != kNoFlag) {
      return instr()->lifetime_position();
    }
    return pos_ >> kPositionShift;
  }

  Instruction* instr() const {
    ASSERT((pos_ & kUseFlagMask) != kNoFlag);
    return reinterpret_cast<Instruction*>(pos_ & ~kUseFlagMask);
  }

  bool HasHint() const {
    return (pos_ & kUseFlagMask) == kFixedUse;
  }

  Location hint() const {
    ASSERT(HasHint());
    ASSERT(location_slot()->IsRegister());
    return *location_slot_;
  }

 private:
  intptr_t pos_;
  Location* location_slot_;
  UsePosition* next_;
};


// UseInterval represents a holeless half open interval of liveness for a given
// SSA value: [start, end) in terms of lifetime positions that
// NumberInstructions assigns to instructions.  Register allocator has to keep
// a value live in the register or in a spill slot from start position and until
// the end position.  The interval can cover zero or more uses.
// During the register allocation UseIntervals from different live ranges
// allocated to the same register will be chained together through
// next_allocated_ field.
// Note: currently all uses of the same SSA value are linked together into a
// single list (and not split between UseIntervals).
class UseInterval : public ZoneAllocated {
 public:
  UseInterval(intptr_t vreg, intptr_t start, intptr_t end, UseInterval* next)
      : vreg_(vreg),
        start_(start),
        end_(end),
        uses_((next == NULL) ? NULL : next->uses_),
        next_(next),
        next_allocated_(next) { }


  void AddUse(Instruction* instr, intptr_t pos, Location* loc);
  void Print();

  intptr_t vreg() const { return vreg_; }
  intptr_t start() const { return start_; }
  intptr_t end() const { return end_; }
  UsePosition* first_use() const { return uses_; }
  UseInterval* next() const { return next_; }

  bool Contains(intptr_t pos) const {
    return (start() <= pos) && (pos < end());
  }

  // Return the smallest position that is covered by both UseIntervals or
  // kIllegalPosition if intervals do not intersect.
  intptr_t Intersect(UseInterval* other);

  UseInterval* Split(intptr_t pos);

  void set_next_allocated(UseInterval* next_allocated) {
    next_allocated_ = next_allocated;
  }
  UseInterval* next_allocated() const { return next_allocated_; }

 private:
  friend class LiveRange;
  const intptr_t vreg_;

  intptr_t start_;
  intptr_t end_;

  UsePosition* uses_;

  UseInterval* next_;
  UseInterval* next_allocated_;
};


// LiveRange represents a sequence of UseIntervals for a given SSA value.
// TODO(vegorov): this class is actually redundant currently.
class LiveRange : public ZoneAllocated {
 public:
  explicit LiveRange(intptr_t vreg) : vreg_(vreg), head_(NULL) { }

  void DefineAt(Instruction* instr, intptr_t pos, Location* loc);

  void UseAt(Instruction* instr,
             intptr_t def_pos,
             intptr_t use_pos,
             bool use_at_end,
             Location* loc);

  void AddUseInterval(intptr_t start, intptr_t end);

  void Print();

  UseInterval* head() const { return head_; }

 private:
  const intptr_t vreg_;
  UseInterval* head_;
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_ALLOCATOR_H_
