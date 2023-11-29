// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/parallel_move_resolver.h"

namespace dart {

// Simple dynamically allocated array of fixed length.
template <typename Subclass, typename Element>
class FixedArray {
 public:
  static Subclass& Allocate(intptr_t length) {
    static_assert(Utils::IsAligned(alignof(Subclass), alignof(Element)));
    auto result =
        reinterpret_cast<void*>(Thread::Current()->zone()->AllocUnsafe(
            sizeof(Subclass) + length * sizeof(Element)));
    return *new (result) Subclass(length);
  }

  intptr_t length() const { return length_; }

  Element& operator[](intptr_t i) {
    ASSERT(0 <= i && i < length_);
    return data()[i];
  }

  const Element& operator[](intptr_t i) const {
    ASSERT(0 <= i && i < length_);
    return data()[i];
  }

  Element* data() { OPEN_ARRAY_START(Element, Element); }
  const Element* data() const { OPEN_ARRAY_START(Element, Element); }

  Element* begin() { return data(); }
  const Element* begin() const { return data(); }

  Element* end() { return data() + length_; }
  const Element* end() const { return data() + length_; }

 protected:
  explicit FixedArray(intptr_t length) : length_(length) {}

 private:
  intptr_t length_;

  DISALLOW_COPY_AND_ASSIGN(FixedArray);
};

class MoveSchedule : public FixedArray<MoveSchedule, ParallelMoveResolver::Op> {
 public:
  // Converts the given list of |ParallelMoveResolver::Op| operations
  // into a |MoveSchedule| and filters out all |kNop| operations.
  static const MoveSchedule& From(
      const GrowableArray<ParallelMoveResolver::Op>& ops) {
    intptr_t count = 0;
    for (const auto& op : ops) {
      if (op.kind != ParallelMoveResolver::OpKind::kNop) count++;
    }

    auto& result = FixedArray::Allocate(count);
    intptr_t i = 0;
    for (const auto& op : ops) {
      if (op.kind != ParallelMoveResolver::OpKind::kNop) {
        result[i++] = op;
      }
    }
    return result;
  }

 private:
  friend class FixedArray<MoveSchedule, ParallelMoveResolver::Op>;

  explicit MoveSchedule(intptr_t length) : FixedArray(length) {}

  DISALLOW_COPY_AND_ASSIGN(MoveSchedule);
};

static uword RegMaskBit(Register reg) {
  return ((reg) != kNoRegister) ? (1 << (reg)) : 0;
}

ParallelMoveResolver::ParallelMoveResolver() : moves_(32) {}

void ParallelMoveResolver::Resolve(ParallelMoveInstr* parallel_move) {
  ASSERT(moves_.is_empty());

  // Build up a worklist of moves.
  BuildInitialMoveList(parallel_move);

  const InstructionSource& move_source = InstructionSource(
      TokenPosition::kParallelMove, parallel_move->inlining_id());
  for (intptr_t i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = moves_[i];
    // Skip constants to perform them last.  They don't block other moves
    // and skipping such moves with register destinations keeps those
    // registers free for the whole algorithm.
    if (!move.IsEliminated() && !move.src().IsConstant()) {
      PerformMove(move_source, i);
    }
  }

  // Perform the moves with constant sources.
  for (const auto& move : moves_) {
    if (!move.IsEliminated()) {
      ASSERT(move.src().IsConstant());
      scheduled_ops_.Add({OpKind::kMove, move});
    }
  }
  moves_.Clear();

  // Schedule is ready. Update parallel move itself.
  parallel_move->set_move_schedule(MoveSchedule::From(scheduled_ops_));
  scheduled_ops_.Clear();
}

void ParallelMoveResolver::BuildInitialMoveList(
    ParallelMoveInstr* parallel_move) {
  // Perform a linear sweep of the moves to add them to the initial list of
  // moves to perform, ignoring any move that is redundant (the source is
  // the same as the destination, the destination is ignored and
  // unallocated, or the move was already eliminated).
  for (int i = 0; i < parallel_move->NumMoves(); i++) {
    MoveOperands* move = parallel_move->MoveOperandsAt(i);
    if (!move->IsRedundant()) moves_.Add(*move);
  }
}

void ParallelMoveResolver::PerformMove(const InstructionSource& source,
                                       int index) {
  // Each call to this function performs a move and deletes it from the move
  // graph.  We first recursively perform any move blocking this one.  We
  // mark a move as "pending" on entry to PerformMove in order to detect
  // cycles in the move graph.  We use operand swaps to resolve cycles,
  // which means that a call to PerformMove could change any source operand
  // in the move graph.

  ASSERT(!moves_[index].IsPending());
  ASSERT(!moves_[index].IsRedundant());

  // Clear this move's destination to indicate a pending move.  The actual
  // destination is saved in a stack-allocated local.  Recursion may allow
  // multiple moves to be pending.
  ASSERT(!moves_[index].src().IsInvalid());
  Location destination = moves_[index].MarkPending();

  // Perform a depth-first traversal of the move graph to resolve
  // dependencies.  Any unperformed, unpending move with a source the same
  // as this one's destination blocks this one so recursively perform all
  // such moves.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = moves_[i];
    if (other_move.Blocks(destination) && !other_move.IsPending()) {
      // Though PerformMove can change any source operand in the move graph,
      // this call cannot create a blocking move via a swap (this loop does
      // not miss any).  Assume there is a non-blocking move with source A
      // and this move is blocked on source B and there is a swap of A and
      // B.  Then A and B must be involved in the same cycle (or they would
      // not be swapped).  Since this move's destination is B and there is
      // only a single incoming edge to an operand, this move must also be
      // involved in the same cycle.  In that case, the blocking move will
      // be created but will be "pending" when we return from PerformMove.
      PerformMove(source, i);
    }
  }

  // We are about to resolve this move and don't need it marked as
  // pending, so restore its destination.
  moves_[index].ClearPending(destination);

  // This move's source may have changed due to swaps to resolve cycles and
  // so it may now be the last move in the cycle.  If so remove it.
  if (moves_[index].src().Equals(destination)) {
    moves_[index].Eliminate();
    return;
  }

  // The move may be blocked on a (at most one) pending move, in which case
  // we have a cycle.  Search for such a blocking move and perform a swap to
  // resolve it.
  for (auto& other_move : moves_) {
    if (other_move.Blocks(destination)) {
      ASSERT(other_move.IsPending());
      AddSwapToSchedule(index);
      return;
    }
  }

  // This move is not blocked.
  AddMoveToSchedule(index);
}

void ParallelMoveResolver::AddMoveToSchedule(int index) {
  auto& move = moves_[index];
  scheduled_ops_.Add({OpKind::kMove, move});
  move.Eliminate();
}

void ParallelMoveResolver::AddSwapToSchedule(int index) {
  auto& move = moves_[index];
  const auto source = move.src();
  const auto destination = move.dest();

  scheduled_ops_.Add({OpKind::kSwap, move});

  // The swap of source and destination has executed a move from source to
  // destination.
  move.Eliminate();

  // Any unperformed (including pending) move with a source of either
  // this move's source or destination needs to have their source
  // changed to reflect the state of affairs after the swap.
  for (auto& other_move : moves_) {
    if (other_move.Blocks(source)) {
      other_move.set_src(destination);
    } else if (other_move.Blocks(destination)) {
      other_move.set_src(source);
    }
  }
}

void ParallelMoveEmitter::EmitNativeCode() {
  const auto& move_schedule = parallel_move_->move_schedule();
  for (intptr_t i = 0; i < move_schedule.length(); i++) {
    current_move_ = i;
    const auto& op = move_schedule[i];
    switch (op.kind) {
      case ParallelMoveResolver::OpKind::kNop:
        // |MoveSchedule::From| is expected to filter nops.
        UNREACHABLE();
        break;
      case ParallelMoveResolver::OpKind::kMove:
        EmitMove(op.operands);
        break;
      case ParallelMoveResolver::OpKind::kSwap:
        EmitSwap(op.operands);
        break;
    }
  }
}

void ParallelMoveEmitter::EmitMove(const MoveOperands& move) {
  Location src = move.src();
  Location dst = move.dest();
#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
  dst = compiler_->RebaseIfImprovesAddressing(dst);
  src = compiler_->RebaseIfImprovesAddressing(src);
#endif
  ParallelMoveEmitter::TemporaryAllocator temp(this, /*blocked=*/kNoRegister);
  compiler_->EmitMove(dst, src, &temp);
#if defined(DEBUG)
  // Allocating a scratch register here may cause stack spilling. Neither the
  // source nor destination register should be SP-relative in that case.
  for (const Location& loc : {dst, src}) {
    ASSERT(!temp.DidAllocateTemporary() || !loc.HasStackIndex() ||
           loc.base_reg() != SPREG);
  }
#endif
}

bool ParallelMoveEmitter::IsScratchLocation(Location loc) {
  const auto& move_schedule = parallel_move_->move_schedule();
  for (intptr_t i = current_move_; i < move_schedule.length(); i++) {
    const auto& op = move_schedule[i];
    if (op.operands.src().Equals(loc) ||
        (op.kind == ParallelMoveResolver::OpKind::kSwap &&
         op.operands.dest().Equals(loc))) {
      return false;
    }
  }

  for (intptr_t i = current_move_ + 1; i < move_schedule.length(); i++) {
    const auto& op = move_schedule[i];
    if (op.kind == ParallelMoveResolver::OpKind::kMove &&
        op.operands.dest().Equals(loc)) {
      return true;
    }
  }

  return false;
}

intptr_t ParallelMoveEmitter::AllocateScratchRegister(
    Location::Kind kind,
    uword blocked_mask,
    intptr_t first_free_register,
    intptr_t last_free_register,
    bool* spilled) {
  COMPILE_ASSERT(static_cast<intptr_t>(sizeof(blocked_mask)) * kBitsPerByte >=
                 kNumberOfFpuRegisters);
  COMPILE_ASSERT(static_cast<intptr_t>(sizeof(blocked_mask)) * kBitsPerByte >=
                 kNumberOfCpuRegisters);
  intptr_t scratch = -1;
  for (intptr_t reg = first_free_register; reg <= last_free_register; reg++) {
    if ((((1 << reg) & blocked_mask) == 0) &&
        IsScratchLocation(Location::MachineRegisterLocation(kind, reg))) {
      scratch = reg;
      break;
    }
  }

  if (scratch == -1) {
    *spilled = true;
    for (intptr_t reg = first_free_register; reg <= last_free_register; reg++) {
      if (((1 << reg) & blocked_mask) == 0) {
        scratch = reg;
        break;
      }
    }
  } else {
    *spilled = false;
  }

  return scratch;
}

ParallelMoveEmitter::ScratchFpuRegisterScope::ScratchFpuRegisterScope(
    ParallelMoveEmitter* emitter,
    FpuRegister blocked)
    : emitter_(emitter), reg_(kNoFpuRegister), spilled_(false) {
  COMPILE_ASSERT(FpuTMP != kNoFpuRegister);
  uword blocked_mask =
      ((blocked != kNoFpuRegister) ? 1 << blocked : 0) | 1 << FpuTMP;
  reg_ = static_cast<FpuRegister>(
      emitter_->AllocateScratchRegister(Location::kFpuRegister, blocked_mask, 0,
                                        kNumberOfFpuRegisters - 1, &spilled_));

  if (spilled_) {
    emitter->SpillFpuScratch(reg_);
  }
}

ParallelMoveEmitter::ScratchFpuRegisterScope::~ScratchFpuRegisterScope() {
  if (spilled_) {
    emitter_->RestoreFpuScratch(reg_);
  }
}

ParallelMoveEmitter::TemporaryAllocator::TemporaryAllocator(
    ParallelMoveEmitter* emitter,
    Register blocked)
    : emitter_(emitter),
      blocked_(blocked),
      reg_(kNoRegister),
      spilled_(false) {}

Register ParallelMoveEmitter::TemporaryAllocator::AllocateTemporary() {
  ASSERT(reg_ == kNoRegister);

  uword blocked_mask = RegMaskBit(blocked_) | kReservedCpuRegisters;
  if (emitter_->compiler_->intrinsic_mode()) {
    // Block additional registers that must be preserved for intrinsics.
    blocked_mask |= RegMaskBit(ARGS_DESC_REG);
#if !defined(TARGET_ARCH_IA32)
    // Need to preserve CODE_REG to be able to store the PC marker
    // and load the pool pointer.
    blocked_mask |= RegMaskBit(CODE_REG);
#endif
  }
  reg_ = static_cast<Register>(
      emitter_->AllocateScratchRegister(Location::kRegister, blocked_mask, 0,
                                        kNumberOfCpuRegisters - 1, &spilled_));

  if (spilled_) {
    emitter_->SpillScratch(reg_);
  }

  DEBUG_ONLY(allocated_ = true;)
  return reg_;
}

void ParallelMoveEmitter::TemporaryAllocator::ReleaseTemporary() {
  if (spilled_) {
    emitter_->RestoreScratch(reg_);
  }
  reg_ = kNoRegister;
}

ParallelMoveEmitter::ScratchRegisterScope::ScratchRegisterScope(
    ParallelMoveEmitter* emitter,
    Register blocked)
    : allocator_(emitter, blocked) {
  reg_ = allocator_.AllocateTemporary();
}

ParallelMoveEmitter::ScratchRegisterScope::~ScratchRegisterScope() {
  allocator_.ReleaseTemporary();
}

template <>
void FlowGraphSerializer::WriteTrait<const MoveSchedule*>::Write(
    FlowGraphSerializer* s,
    const MoveSchedule* schedule) {
  ASSERT(schedule != nullptr);
  const intptr_t len = schedule->length();
  s->Write<intptr_t>(len);
  for (intptr_t i = 0; i < len; ++i) {
    const auto& op = (*schedule)[i];
    s->Write<uint8_t>(static_cast<uint8_t>(op.kind));
    op.operands.Write(s);
  }
}

template <>
const MoveSchedule* FlowGraphDeserializer::ReadTrait<const MoveSchedule*>::Read(
    FlowGraphDeserializer* d) {
  const intptr_t len = d->Read<intptr_t>();
  MoveSchedule& schedule = MoveSchedule::Allocate(len);
  for (intptr_t i = 0; i < len; ++i) {
    schedule[i].kind =
        static_cast<ParallelMoveResolver::OpKind>(d->Read<uint8_t>());
    schedule[i].operands = MoveOperands(d);
  }
  return &schedule;
}

}  // namespace dart
