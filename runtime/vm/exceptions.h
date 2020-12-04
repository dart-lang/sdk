// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_EXCEPTIONS_H_
#define RUNTIME_VM_EXCEPTIONS_H_

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/tagged_pointer.h"
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
class ReadStream;
class BaseWriteStream;
class String;
class Thread;
class TypedData;

class Exceptions : AllStatic {
 public:
  DART_NORETURN static void Throw(Thread* thread, const Instance& exception);
  DART_NORETURN static void ReThrow(Thread* thread,
                                    const Instance& exception,
                                    const Instance& stacktrace);
  DART_NORETURN static void PropagateError(const Error& error);

  // Propagate an error to the entry frame, skipping over Dart frames.
  DART_NORETURN static void PropagateToEntry(const Error& error);

  // Helpers to create and throw errors.
  static StackTracePtr CurrentStackTrace();
  static ScriptPtr GetCallerScript(DartFrameIterator* iterator);
  static InstancePtr NewInstance(const char* class_name);
  static void CreateAndThrowTypeError(TokenPosition location,
                                      const AbstractType& src_type,
                                      const AbstractType& dst_type,
                                      const String& dst_name);

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
    kLateFieldAssignedDuringInitialization,
    kLateFieldNotInitialized,
  };

  DART_NORETURN static void ThrowByType(ExceptionType type,
                                        const Array& arguments);
  // Uses the preallocated out of memory exception to avoid calling
  // into Dart code or allocating any code.
  DART_NORETURN static void ThrowOOM();
  DART_NORETURN static void ThrowStackOverflow();
  DART_NORETURN static void ThrowArgumentError(const Instance& arg);
  DART_NORETURN static void ThrowRangeError(const char* argument_name,
                                            const Integer& argument_value,
                                            intptr_t expected_from,
                                            intptr_t expected_to);
  DART_NORETURN static void ThrowUnsupportedError(const char* msg);
  DART_NORETURN static void ThrowCompileTimeError(const LanguageError& error);
  DART_NORETURN static void ThrowLateFieldAssignedDuringInitialization(
      const String& name);
  DART_NORETURN static void ThrowLateFieldNotInitialized(const String& name);

  // Returns a RawInstance if the exception is successfully created,
  // otherwise returns a RawError.
  static ObjectPtr Create(ExceptionType type, const Array& arguments);

  // Returns RawUnhandledException that wraps exception of type [type] with
  // [msg] as a single argument.
  static UnhandledExceptionPtr CreateUnhandledException(Zone* zone,
                                                        ExceptionType type,
                                                        const char* msg);

  DART_NORETURN static void JumpToFrame(Thread* thread,
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
    return index_to_pair_slot(LoSourceSlot::decode(src_));
  }

  intptr_t src_hi_slot() const {
    ASSERT(source_kind() == SourceKind::kInt64PairSlot);
    return index_to_pair_slot(HiSourceSlot::decode(src_));
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
    return CatchEntryMove(src_slot, SourceKindField::encode(kind) |
                                        (static_cast<uintptr_t>(dest_slot)
                                         << SourceKindField::bitsize()));
  }

  static intptr_t EncodePairSource(intptr_t src_lo_slot, intptr_t src_hi_slot) {
    return LoSourceSlot::encode(pair_slot_to_index(src_lo_slot)) |
           HiSourceSlot::encode(pair_slot_to_index(src_hi_slot));
  }

  bool IsRedundant() const {
    return (source_kind() == SourceKind::kTaggedSlot) &&
           (dest_slot() == src_slot());
  }

  bool operator==(const CatchEntryMove& rhs) const {
    return src_ == rhs.src_ && dest_and_kind_ == rhs.dest_and_kind_;
  }

  static CatchEntryMove ReadFrom(ReadStream* stream);

#if !defined(DART_PRECOMPILED_RUNTIME)
  void WriteTo(BaseWriteStream* stream);
#endif

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
  const char* ToCString() const;
#endif

 private:
  static intptr_t pair_slot_to_index(intptr_t slot) {
    return (slot < 0) ? -2 * slot : 2 * slot + 1;
  }

  static intptr_t index_to_pair_slot(intptr_t index) {
    ASSERT(index >= 0);
    return ((index & 1) != 0) ? (index >> 1) : -(index >> 1);
  }

  CatchEntryMove(int32_t src, int32_t dest_and_kind)
      : src_(src), dest_and_kind_(dest_and_kind) {}

  // Note: BitField helper does not work with signed values of size that does
  // not match the destination size - thus we don't use BitField for declaring
  // DestinationField and instead encode and decode it manually.
  using SourceKindField = BitField<int32_t, SourceKind, 0, 4>;

  static constexpr intptr_t kHalfSourceBits = 16;
  using LoSourceSlot = BitField<int32_t, int32_t, 0, kHalfSourceBits>;
  using HiSourceSlot =
      BitField<int32_t, int32_t, kHalfSourceBits, kHalfSourceBits>;

  int32_t src_;
  int32_t dest_and_kind_;
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

// Used for reading the [CatchEntryMoves] from the compressed form.
class CatchEntryMovesMapReader : public ValueObject {
 public:
  explicit CatchEntryMovesMapReader(const TypedData& bytes) : bytes_(bytes) {}

  // The returned [CatchEntryMoves] must be freed by the caller via [free].
  CatchEntryMoves* ReadMovesForPcOffset(intptr_t pc_offset);

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
  void PrintEntries();
#endif

 private:
  // Given the [pc_offset] this function will find the [position] at which to
  // read the catch entries and the [length] of the catch entry moves array.
  void FindEntryForPc(ReadStream* stream,
                      intptr_t pc_offset,
                      intptr_t* position,
                      intptr_t* length);

  // Reads the [length] catch entry moves from [offset] in the [stream].
  CatchEntryMoves* ReadCompressedCatchEntryMovesSuffix(ReadStream* stream,
                                                       intptr_t offset,
                                                       intptr_t length);

  const TypedData& bytes_;
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
