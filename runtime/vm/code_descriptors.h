// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_DESCRIPTORS_H_
#define RUNTIME_VM_CODE_DESCRIPTORS_H_

#include "vm/datastream.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/log.h"
#include "vm/runtime_entry.h"
#include "vm/token_position.h"

namespace dart {

static const intptr_t kInvalidTryIndex = -1;

class DescriptorList : public ZoneAllocated {
 public:
  explicit DescriptorList(
      Zone* zone,
      const GrowableArray<const Function*>* inline_id_to_function = nullptr);

  ~DescriptorList() {}

  void AddDescriptor(PcDescriptorsLayout::Kind kind,
                     intptr_t pc_offset,
                     intptr_t deopt_id,
                     TokenPosition token_pos,
                     intptr_t try_index,
                     intptr_t yield_index);

  PcDescriptorsPtr FinalizePcDescriptors(uword entry_point);

 private:
  static constexpr intptr_t kInitialStreamSize = 64;

  const Function& function_;
  const Script& script_;
  ZoneWriteStream encoded_data_;

  intptr_t prev_pc_offset;
  intptr_t prev_deopt_id;
  int32_t prev_token_pos;

  DISALLOW_COPY_AND_ASSIGN(DescriptorList);
};

class CompressedStackMapsBuilder : public ZoneAllocated {
 public:
  explicit CompressedStackMapsBuilder(Zone* zone)
      : encoded_bytes_(zone, kInitialStreamSize) {}

  void AddEntry(intptr_t pc_offset,
                BitmapBuilder* bitmap,
                intptr_t spill_slot_bit_count);

  CompressedStackMapsPtr Finalize() const;

 private:
  static constexpr intptr_t kInitialStreamSize = 16;

  ZoneWriteStream encoded_bytes_;
  intptr_t last_pc_offset_ = 0;
  DISALLOW_COPY_AND_ASSIGN(CompressedStackMapsBuilder);
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

  static bool ContainsCatchAllType(const Array& array) {
    auto& type = AbstractType::Handle();
    for (intptr_t i = 0; i < array.Length(); i++) {
      type ^= array.At(i);
      if (type.IsCatchAllType()) {
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
  ZoneWriteStream stream_;

  DISALLOW_COPY_AND_ASSIGN(CatchEntryMovesMapBuilder);
};
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Instructions have two pieces of information needed to get accurate source
// locations: the token position and the inlining id. The inlining id tells us
// which function, and thus which script, to use for this instruction and the
// token position, when real, tells us the position in the source for the
// script for the instruction.
//
// Thus, we bundle the two pieces of information in InstructionSource structs
// when copying or retrieving to lower the likelihood that the token position
// is used without the appropriate inlining id.
struct InstructionSource {
  // Treat an instruction source without inlining id information as unset.
  InstructionSource() : InstructionSource(TokenPosition::kNoSource) {}
  explicit InstructionSource(TokenPosition pos) : InstructionSource(pos, -1) {}
  InstructionSource(TokenPosition pos, intptr_t id)
      : token_pos(pos), inlining_id(id) {}

  const TokenPosition token_pos;
  const intptr_t inlining_id;

  DISALLOW_ALLOCATION();
};

struct CodeSourceMapOps : AllStatic {
  static const uint8_t kChangePosition = 0;
  static const uint8_t kAdvancePC = 1;
  static const uint8_t kPushFunction = 2;
  static const uint8_t kPopFunction = 3;
  static const uint8_t kNullCheck = 4;

  static uint8_t Read(ReadStream* stream,
                      int32_t* arg1,
                      int32_t* arg2 = nullptr);

  static void Write(BaseWriteStream* stream,
                    uint8_t op,
                    int32_t arg1 = 0,
                    int32_t arg2 = 0);

 private:
  static constexpr intptr_t kOpBits = 3;

  using OpField = BitField<int32_t, uint8_t, 0, kOpBits>;
  using ArgField = BitField<int32_t, int32_t, OpField::kNextBit>;

  static constexpr int32_t kMaxArgValue =
      Utils::NBitMaskUnsafe(ArgField::bitsize() - 1);
  static constexpr int32_t kMinArgValue = ~kMaxArgValue;
  static constexpr int32_t kSignBits = static_cast<uint32_t>(kMinArgValue) << 1;
};

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
      Zone* zone,
      bool stack_traces_only,
      const GrowableArray<intptr_t>& caller_inline_id,
      const GrowableArray<TokenPosition>& inline_id_to_token_pos,
      const GrowableArray<const Function*>& inline_id_to_function);

  // The position at which a function implicitly starts, for both the root and
  // after a push bytecode. We use the classifying position kDartCodePrologue
  // since it is the most common.
  static const TokenPosition& kInitialPosition;

  void BeginCodeSourceRange(int32_t pc_offset, const InstructionSource& source);
  void EndCodeSourceRange(int32_t pc_offset, const InstructionSource& source);
  void NoteDescriptor(PcDescriptorsLayout::Kind kind,
                      int32_t pc_offset,
                      const InstructionSource& source);
  void NoteNullCheck(int32_t pc_offset,
                     const InstructionSource& source,
                     intptr_t name_index);

  // If source is from an inlined call, returns the token position of the
  // original call in the root function, otherwise the source's token position.
  TokenPosition RootPosition(const InstructionSource& source);
  ArrayPtr InliningIdToFunction();
  CodeSourceMapPtr Finalize();

  const GrowableArray<const Function*>& inline_id_to_function() const {
    return inline_id_to_function_;
  }

 private:
  intptr_t GetFunctionId(intptr_t inline_id);
  void StartInliningInterval(int32_t pc_offset,
                             const InstructionSource& source);

  void BufferChangePosition(TokenPosition pos);
  void WriteChangePosition(TokenPosition pos);
  void BufferAdvancePC(int32_t distance) { buffered_pc_offset_ += distance; }
  void WriteAdvancePC(int32_t distance) {
    CodeSourceMapOps::Write(&stream_, CodeSourceMapOps::kAdvancePC, distance);
    written_pc_offset_ += distance;
  }
  void BufferPush(intptr_t inline_id) {
    buffered_inline_id_stack_.Add(inline_id);
    buffered_token_pos_stack_.Add(kInitialPosition);
  }
  void WritePush(intptr_t inline_id) {
    CodeSourceMapOps::Write(&stream_, CodeSourceMapOps::kPushFunction,
                            GetFunctionId(inline_id));
    written_inline_id_stack_.Add(inline_id);
    written_token_pos_stack_.Add(kInitialPosition);
  }
  void BufferPop() {
    buffered_inline_id_stack_.RemoveLast();
    buffered_token_pos_stack_.RemoveLast();
  }
  void WritePop() {
    CodeSourceMapOps::Write(&stream_, CodeSourceMapOps::kPopFunction);
    written_inline_id_stack_.RemoveLast();
    written_token_pos_stack_.RemoveLast();
  }
  void WriteNullCheck(int32_t name_index) {
    CodeSourceMapOps::Write(&stream_, CodeSourceMapOps::kNullCheck, name_index);
  }

  void FlushBuffer();

  bool IsOnBufferedStack(intptr_t inline_id) {
    for (intptr_t i = 0; i < buffered_inline_id_stack_.length(); i++) {
      if (buffered_inline_id_stack_[i] == inline_id) return true;
    }
    return false;
  }

  Zone* const zone_;
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

  Script& script_;
  ZoneWriteStream stream_;

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
  static const TokenPosition& InitialPosition() {
    if (FLAG_precompiled_mode) {
      // In precompiled mode, the CodeSourceMap stores lines instead of
      // real token positions and uses kNoSourcePos for no line information.
      return TokenPosition::kNoSource;
    } else {
      return CodeSourceMapBuilder::kInitialPosition;
    }
  }

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
