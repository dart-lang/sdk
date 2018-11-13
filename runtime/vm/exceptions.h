// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_EXCEPTIONS_H_
#define RUNTIME_VM_EXCEPTIONS_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/token_position.h"

namespace dart {

// Forward declarations.
class AbstractType;
class Array;
class DartFrameIterator;
class Error;
class LanguageError;
class Instance;
class Integer;
class RawInstance;
class RawObject;
class RawScript;
class RawStackTrace;
class ReadStream;
class WriteStream;
class String;
class Thread;

class Exceptions : AllStatic {
 public:
  static void Throw(Thread* thread, const Instance& exception);
  static void ReThrow(Thread* thread,
                      const Instance& exception,
                      const Instance& stacktrace);
  static void PropagateError(const Error& error);

  // Propagate an error to the entry frame, skipping over Dart frames.
  static void PropagateToEntry(const Error& error);

  // Helpers to create and throw errors.
  static RawStackTrace* CurrentStackTrace();
  static RawScript* GetCallerScript(DartFrameIterator* iterator);
  static RawInstance* NewInstance(const char* class_name);
  static void CreateAndThrowTypeError(TokenPosition location,
                                      const AbstractType& src_type,
                                      const AbstractType& dst_type,
                                      const String& dst_name,
                                      const String& bound_error_msg);

  enum ExceptionType {
    kNone,
    kRange,
    kRangeMsg,
    kArgument,
    kArgumentValue,
    kIntegerDivisionByZeroException,
    kNoSuchMethod,
    kFormat,
    kUnsupported,
    kStackOverflow,
    kOutOfMemory,
    kNullThrown,
    kIsolateSpawn,
    kAssertion,
    kCast,
    kType,
    kFallThrough,
    kAbstractClassInstantiation,
    kCyclicInitializationError,
    kCompileTimeError,
  };

  static void ThrowByType(ExceptionType type, const Array& arguments);
  // Uses the preallocated out of memory exception to avoid calling
  // into Dart code or allocating any code.
  static void ThrowOOM();
  static void ThrowStackOverflow();
  static void ThrowArgumentError(const Instance& arg);
  static void ThrowRangeError(const char* argument_name,
                              const Integer& argument_value,
                              intptr_t expected_from,
                              intptr_t expected_to);
  static void ThrowRangeErrorMsg(const char* msg);
  static void ThrowCompileTimeError(const LanguageError& error);

  // Returns a RawInstance if the exception is successfully created,
  // otherwise returns a RawError.
  static RawObject* Create(ExceptionType type, const Array& arguments);

  static void JumpToFrame(Thread* thread,
                          uword program_counter,
                          uword stack_pointer,
                          uword frame_pointer,
                          bool clear_deopt_at_target);

 private:
  DISALLOW_COPY_AND_ASSIGN(Exceptions);
};

// The index into the ExceptionHandlers table corresponds to
// the try_index of the handler.
struct ExceptionHandlerInfo {
  uint32_t handler_pc_offset;  // PC offset value of handler.
  int16_t outer_try_index;     // Try block index of enclosing try block.
  int8_t needs_stacktrace;     // True if a stacktrace is needed.
  int8_t has_catch_all;        // Catches all exceptions.
  int8_t is_generated;         // True if this is a generated handler.
};

//
// Support for try/catch in the optimized code.
//
// Optimizing compiler does not model exceptional control flow explicitly,
// instead we rely on the runtime system to create correct state at the
// entry into the catch block by reshuffling values in the frame into
// positions where they are expected to be at the beginning of the catch block.
//
// See runtime/docs/compiler/exceptions.md for more details.
//

// A single move from a stack slot or an object pool into another stack slot.
// Destination slot is expecting only tagged values, however source
// slot can contain an unboxed value (e.g. an unboxed double) - in this case
// we will box the value before executing the move.
class CatchEntryMove {
 public:
  CatchEntryMove()
      : src_(0),
        dest_and_kind_(static_cast<intptr_t>(SourceKind::kTaggedSlot)) {
    ASSERT(IsRedundant());
  }

  enum class SourceKind {
    kConstant,
    kTaggedSlot,
    kDoubleSlot,
    kFloat32x4Slot,
    kFloat64x2Slot,
    kInt32x4Slot,
    kInt64PairSlot,
    kInt64Slot,
    kInt32Slot,
    kUint32Slot,
  };

  SourceKind source_kind() const {
    return SourceKindField::decode(dest_and_kind_);
  }

  intptr_t src_slot() const {
    ASSERT(source_kind() != SourceKind::kInt64PairSlot);
    return src_;
  }

  intptr_t src_lo_slot() const {
    ASSERT(source_kind() == SourceKind::kInt64PairSlot);
    return LoSourceSlot::decode(src_);
  }

  intptr_t src_hi_slot() const {
    ASSERT(source_kind() == SourceKind::kInt64PairSlot);
    return HiSourceSlot::decode(src_);
  }

  intptr_t dest_slot() const {
    return dest_and_kind_ >> SourceKindField::bitsize();
  }

  static CatchEntryMove FromConstant(intptr_t pool_id, intptr_t dest_slot) {
    return FromSlot(SourceKind::kConstant, pool_id, dest_slot);
  }

  static CatchEntryMove FromSlot(SourceKind kind,
                                 intptr_t src_slot,
                                 intptr_t dest_slot) {
    return CatchEntryMove(src_slot,
                          SourceKindField::encode(kind) |
                              (dest_slot << SourceKindField::bitsize()));
  }

  static intptr_t EncodePairSource(intptr_t src_lo_slot, intptr_t src_hi_slot) {
    return LoSourceSlot::encode(src_lo_slot) |
           HiSourceSlot::encode(src_hi_slot);
  }

  bool IsRedundant() const {
    return (source_kind() == SourceKind::kTaggedSlot) &&
           (dest_slot() == src_slot());
  }

  bool operator==(const CatchEntryMove& rhs) {
    return src_ == rhs.src_ && dest_and_kind_ == rhs.dest_and_kind_;
  }

  static CatchEntryMove ReadFrom(ReadStream* stream);

#if !defined(DART_PRECOMPILED_RUNTIME)
  void WriteTo(WriteStream* stream);
#endif

 private:
  CatchEntryMove(intptr_t src, intptr_t dest_and_kind)
      : src_(src), dest_and_kind_(dest_and_kind) {}

  // Note: BitField helper does not work with signed values of size that does
  // not match the destination size - thus we don't use BitField for declaring
  // DestinationField and instead encode and decode it manually.
  using SourceKindField = BitField<intptr_t, SourceKind, 0, 4>;

  static constexpr intptr_t kHalfSourceBits = kBitsPerWord / 2;
  using LoSourceSlot = BitField<intptr_t, intptr_t, 0, kHalfSourceBits>;
  using HiSourceSlot =
      BitField<intptr_t, intptr_t, kHalfSourceBits, kHalfSourceBits>;

  intptr_t src_;
  intptr_t dest_and_kind_;
};

// A sequence of moves that needs to be executed to create a state expected
// at the catch entry.
// Note: this is a deserialized representation that is used by the runtime
// system as a temporary representation and for caching. That is why this
// object is allocated in the malloced heap and not in the Dart heap.
class CatchEntryMoves {
 public:
  static CatchEntryMoves* Allocate(intptr_t num_moves) {
    auto result = reinterpret_cast<CatchEntryMoves*>(
        malloc(sizeof(CatchEntryMoves) + sizeof(CatchEntryMove) * num_moves));
    result->count_ = num_moves;
    return result;
  }

  static void Free(const CatchEntryMoves* moves) {
    free(const_cast<CatchEntryMoves*>(moves));
  }

  intptr_t count() const { return count_; }
  CatchEntryMove& At(intptr_t i) { return Moves()[i]; }
  const CatchEntryMove& At(intptr_t i) const { return Moves()[i]; }

 private:
  CatchEntryMove* Moves() {
    return reinterpret_cast<CatchEntryMove*>(this + 1);
  }

  const CatchEntryMove* Moves() const {
    return reinterpret_cast<const CatchEntryMove*>(this + 1);
  }

  intptr_t count_;
  // Followed by CatchEntryMove[count_]
};

// A simple reference counting wrapper for CatchEntryMoves.
//
// TODO(vegorov) switch this to intrusive reference counting.
class CatchEntryMovesRefPtr {
 public:
  CatchEntryMovesRefPtr() : moves_(nullptr), ref_count_(nullptr) {}
  explicit CatchEntryMovesRefPtr(const CatchEntryMoves* moves)
      : moves_(moves), ref_count_(new intptr_t(1)) {}

  CatchEntryMovesRefPtr(const CatchEntryMovesRefPtr& state) { Copy(state); }

  ~CatchEntryMovesRefPtr() { Destroy(); }

  CatchEntryMovesRefPtr& operator=(const CatchEntryMovesRefPtr& state) {
    Destroy();
    Copy(state);
    return *this;
  }

  bool IsEmpty() { return ref_count_ == nullptr; }

  const CatchEntryMoves& moves() { return *moves_; }

 private:
  void Destroy() {
    if (ref_count_ != nullptr) {
      (*ref_count_)--;
      if (*ref_count_ == 0) {
        delete ref_count_;
        CatchEntryMoves::Free(moves_);
      }
    }
  }

  void Copy(const CatchEntryMovesRefPtr& state) {
    moves_ = state.moves_;
    ref_count_ = state.ref_count_;
    if (ref_count_ != nullptr) {
      (*ref_count_)++;
    }
  }

  const CatchEntryMoves* moves_;
  intptr_t* ref_count_;
};

}  // namespace dart

#endif  // RUNTIME_VM_EXCEPTIONS_H_
