// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_DESCRIPTORS_H_
#define RUNTIME_VM_CODE_DESCRIPTORS_H_

#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/runtime_entry.h"

namespace dart {

static const intptr_t kInvalidTryIndex = -1;

class DescriptorList : public ZoneAllocated {
 public:
  explicit DescriptorList(intptr_t initial_capacity)
      : encoded_data_(initial_capacity),
        prev_pc_offset(0),
        prev_deopt_id(0),
        prev_token_pos(0) {}

  ~DescriptorList() {}

  void AddDescriptor(PcDescriptorsLayout::Kind kind,
                     intptr_t pc_offset,
                     intptr_t deopt_id,
                     TokenPosition token_pos,
                     intptr_t try_index,
                     intptr_t yield_index);

  PcDescriptorsPtr FinalizePcDescriptors(uword entry_point);

 private:
  GrowableArray<uint8_t> encoded_data_;

  intptr_t prev_pc_offset;
  intptr_t prev_deopt_id;
  intptr_t prev_token_pos;

  DISALLOW_COPY_AND_ASSIGN(DescriptorList);
};

class CompressedStackMapsBuilder : public ZoneAllocated {
 public:
  CompressedStackMapsBuilder() : encoded_bytes_() {}

  static void EncodeLEB128(GrowableArray<uint8_t>* data, uintptr_t value);

  void AddEntry(intptr_t pc_offset,
                BitmapBuilder* bitmap,
                intptr_t spill_slot_bit_count);

  CompressedStackMapsPtr Finalize() const;

 private:
  intptr_t last_pc_offset_ = 0;
  GrowableArray<uint8_t> encoded_bytes_;
  DISALLOW_COPY_AND_ASSIGN(CompressedStackMapsBuilder);
};

class CompressedStackMapsIterator : public ValueObject {
 public:
  // We use the null value to represent CompressedStackMaps with no
  // entries, so any CompressedStackMaps arguments to constructors can be null.
  CompressedStackMapsIterator(const CompressedStackMaps& maps,
                              const CompressedStackMaps& global_table);
  explicit CompressedStackMapsIterator(const CompressedStackMaps& maps);

  explicit CompressedStackMapsIterator(const CompressedStackMapsIterator& it);

  // Loads the next entry from [maps_], if any. If [maps_] is the null
  // value, this always returns false.
  bool MoveNext();

  // Finds the entry with the given PC offset starting at the current
  // position of the iterator. If [maps_] is the null value, this always
  // returns false.
  bool Find(uint32_t pc_offset) {
    // We should never have an entry with a PC offset of 0 inside an
    // non-empty CSM, so fail.
    if (pc_offset == 0) return false;
    do {
      if (current_pc_offset_ >= pc_offset) break;
    } while (MoveNext());
    return current_pc_offset_ == pc_offset;
  }

  // Methods for accessing parts of an entry should not be called until
  // a successful MoveNext() or Find() call has been made.

  uint32_t pc_offset() const {
    ASSERT(HasLoadedEntry());
    return current_pc_offset_;
  }
  // We lazily load and cache information from the global table if the
  // CSM uses it, so these methods cannot be const.
  intptr_t Length();
  intptr_t SpillSlotBitCount();
  bool IsObject(intptr_t bit_offset);

  void EnsureFullyLoadedEntry() {
    ASSERT(HasLoadedEntry());
    if (current_spill_slot_bit_count_ < 0) {
      LazyLoadGlobalTableEntry();
    }
    ASSERT(current_spill_slot_bit_count_ >= 0);
  }

  const char* ToCString(Zone* zone) const;
  const char* ToCString() const;

 private:
  static uintptr_t DecodeLEB128(const CompressedStackMaps& data,
                                uintptr_t* byte_index);
  bool HasLoadedEntry() const { return next_offset_ > 0; }
  void LazyLoadGlobalTableEntry();

  const CompressedStackMaps& maps_;
  const CompressedStackMaps& bits_container_;

  uintptr_t next_offset_ = 0;
  uint32_t current_pc_offset_ = 0;
  // Only used when looking up non-PC information in the global table.
  uintptr_t current_global_table_offset_ = 0;
  intptr_t current_spill_slot_bit_count_ = -1;
  intptr_t current_non_spill_slot_bit_count_ = -1;
  intptr_t current_bits_offset_ = -1;

  friend class StackMapEntry;
};

class ExceptionHandlerList : public ZoneAllocated {
 public:
  struct HandlerDesc {
    intptr_t outer_try_index;    // Try block in which this try block is nested.
    intptr_t pc_offset;          // Handler PC offset value.
    bool is_generated;           // False if this is directly from Dart code.
    const Array* handler_types;  // Catch clause guards.
    bool needs_stacktrace;
  };

  ExceptionHandlerList() : list_() {}

  intptr_t Length() const { return list_.length(); }

  void AddPlaceHolder() {
    struct HandlerDesc data;
    data.outer_try_index = -1;
    data.pc_offset = ExceptionHandlers::kInvalidPcOffset;
    data.is_generated = true;
    data.handler_types = NULL;
    data.needs_stacktrace = false;
    list_.Add(data);
  }

  void AddHandler(intptr_t try_index,
                  intptr_t outer_try_index,
                  intptr_t pc_offset,
                  bool is_generated,
                  const Array& handler_types,
                  bool needs_stacktrace) {
    ASSERT(try_index >= 0);
    while (Length() <= try_index) {
      AddPlaceHolder();
    }
    list_[try_index].outer_try_index = outer_try_index;
    ASSERT(list_[try_index].pc_offset == ExceptionHandlers::kInvalidPcOffset);
    list_[try_index].pc_offset = pc_offset;
    list_[try_index].is_generated = is_generated;
    ASSERT(handler_types.IsZoneHandle());
    list_[try_index].handler_types = &handler_types;
    list_[try_index].needs_stacktrace |= needs_stacktrace;
  }

  // Called by rethrows, to mark their enclosing handlers.
  void SetNeedsStackTrace(intptr_t try_index) {
    // Rethrows can be generated outside a try by the compiler.
    if (try_index == kInvalidTryIndex) {
      return;
    }
    ASSERT(try_index >= 0);
    while (Length() <= try_index) {
      AddPlaceHolder();
    }
    list_[try_index].needs_stacktrace = true;
  }

  static bool ContainsDynamic(const Array& array) {
    for (intptr_t i = 0; i < array.Length(); i++) {
      if (array.At(i) == Type::DynamicType()) {
        return true;
      }
    }
    return false;
  }

  ExceptionHandlersPtr FinalizeExceptionHandlers(uword entry_point) const;

 private:
  GrowableArray<struct HandlerDesc> list_;
  DISALLOW_COPY_AND_ASSIGN(ExceptionHandlerList);
};

#if !defined(DART_PRECOMPILED_RUNTIME)
// Used to construct CatchEntryMoves for the AOT mode of compilation.
class CatchEntryMovesMapBuilder : public ZoneAllocated {
 public:
  CatchEntryMovesMapBuilder();

  void NewMapping(intptr_t pc_offset);
  void Append(const CatchEntryMove& move);
  void EndMapping();
  TypedDataPtr FinalizeCatchEntryMovesMap();

 private:
  class TrieNode;

  Zone* zone_;
  TrieNode* root_;
  intptr_t current_pc_offset_;
  GrowableArray<CatchEntryMove> moves_;
  uint8_t* buffer_;
  WriteStream stream_;

  DISALLOW_COPY_AND_ASSIGN(CatchEntryMovesMapBuilder);
};
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// A CodeSourceMap maps from pc offsets to a stack of inlined functions and
// their positions. This is encoded as a little bytecode that pushes and pops
// functions and changes the top function's position as the PC advances.
// Decoding happens by running this bytecode until we reach the desired PC.
//
// The implementation keeps track of two sets of state: one written to the byte
// stream and one that is buffered. On the JIT, this buffering effectively gives
// us a peephole optimization that merges adjacent advance PC bytecodes. On AOT,
// this allows to skip encoding our position until we reach a PC where we might
// throw.
class CodeSourceMapBuilder : public ZoneAllocated {
 public:
  CodeSourceMapBuilder(
      bool stack_traces_only,
      const GrowableArray<intptr_t>& caller_inline_id,
      const GrowableArray<TokenPosition>& inline_id_to_token_pos,
      const GrowableArray<const Function*>& inline_id_to_function);

  // The position at which a function implicitly starts, for both the root and
  // after a push bytecode. We use the classifying position kDartCodePrologue
  // since it is the most common.
  static const TokenPosition kInitialPosition;

  static const uint8_t kChangePosition = 0;
  static const uint8_t kAdvancePC = 1;
  static const uint8_t kPushFunction = 2;
  static const uint8_t kPopFunction = 3;
  static const uint8_t kNullCheck = 4;

  void StartInliningInterval(int32_t pc_offset, intptr_t inline_id);
  void BeginCodeSourceRange(int32_t pc_offset);
  void EndCodeSourceRange(int32_t pc_offset, TokenPosition pos);
  void NoteDescriptor(PcDescriptorsLayout::Kind kind,
                      int32_t pc_offset,
                      TokenPosition pos);
  void NoteNullCheck(int32_t pc_offset, TokenPosition pos, intptr_t name_index);

  ArrayPtr InliningIdToFunction();
  CodeSourceMapPtr Finalize();

 private:
  intptr_t GetFunctionId(intptr_t inline_id);

  void BufferChangePosition(TokenPosition pos) {
    buffered_token_pos_stack_.Last() = pos;
  }
  void WriteChangePosition(TokenPosition pos);
  void BufferAdvancePC(int32_t distance) { buffered_pc_offset_ += distance; }
  void WriteAdvancePC(int32_t distance) {
    stream_.Write<uint8_t>(kAdvancePC);
    stream_.Write<int32_t>(distance);
    written_pc_offset_ += distance;
  }
  void BufferPush(intptr_t inline_id) {
    buffered_inline_id_stack_.Add(inline_id);
    buffered_token_pos_stack_.Add(kInitialPosition);
  }
  void WritePush(intptr_t inline_id) {
    stream_.Write<uint8_t>(kPushFunction);
    stream_.Write<int32_t>(GetFunctionId(inline_id));
    written_inline_id_stack_.Add(inline_id);
    written_token_pos_stack_.Add(kInitialPosition);
  }
  void BufferPop() {
    buffered_inline_id_stack_.RemoveLast();
    buffered_token_pos_stack_.RemoveLast();
  }
  void WritePop() {
    stream_.Write<uint8_t>(kPopFunction);
    written_inline_id_stack_.RemoveLast();
    written_token_pos_stack_.RemoveLast();
  }
  void WriteNullCheck(int32_t name_index) {
    stream_.Write<uint8_t>(kNullCheck);
    stream_.Write<int32_t>(name_index);
  }

  void FlushBuffer();
  void FlushBufferStack();
  void FlushBufferPosition();
  void FlushBufferPC();

  bool IsOnBufferedStack(intptr_t inline_id) {
    for (intptr_t i = 0; i < buffered_inline_id_stack_.length(); i++) {
      if (buffered_inline_id_stack_[i] == inline_id) return true;
    }
    return false;
  }

  intptr_t buffered_pc_offset_;
  GrowableArray<intptr_t> buffered_inline_id_stack_;
  GrowableArray<TokenPosition> buffered_token_pos_stack_;

  intptr_t written_pc_offset_;
  GrowableArray<intptr_t> written_inline_id_stack_;
  GrowableArray<TokenPosition> written_token_pos_stack_;

  const GrowableArray<intptr_t>& caller_inline_id_;
  const GrowableArray<TokenPosition>& inline_id_to_token_pos_;
  const GrowableArray<const Function*>& inline_id_to_function_;

  const GrowableObjectArray& inlined_functions_;

  uint8_t* buffer_;
  WriteStream stream_;

  const bool stack_traces_only_;

  DISALLOW_COPY_AND_ASSIGN(CodeSourceMapBuilder);
};

class CodeSourceMapReader : public ValueObject {
 public:
  CodeSourceMapReader(const CodeSourceMap& map,
                      const Array& functions,
                      const Function& root)
      : map_(map), functions_(functions), root_(root) {}

  void GetInlinedFunctionsAt(int32_t pc_offset,
                             GrowableArray<const Function*>* function_stack,
                             GrowableArray<TokenPosition>* token_positions);
  NOT_IN_PRODUCT(void PrintJSONInlineIntervals(JSONObject* jsobj));
  void DumpInlineIntervals(uword start);
  void DumpSourcePositions(uword start);

  intptr_t GetNullCheckNameIndexAt(int32_t pc_offset);

 private:
  // Reads a TokenPosition value from a CSM, handling the different encoding for
  // when non-symbolic stack traces are enabled.
  static TokenPosition ReadPosition(ReadStream* stream);

  const CodeSourceMap& map_;
  const Array& functions_;
  const Function& root_;

  DISALLOW_COPY_AND_ASSIGN(CodeSourceMapReader);
};

}  // namespace dart

#endif  // RUNTIME_VM_CODE_DESCRIPTORS_H_
