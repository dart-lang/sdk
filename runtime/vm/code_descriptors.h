// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODE_DESCRIPTORS_H_
#define RUNTIME_VM_CODE_DESCRIPTORS_H_

#include "vm/ast.h"
#include "vm/code_generator.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/log.h"

namespace dart {

class DescriptorList : public ZoneAllocated {
 public:
  explicit DescriptorList(intptr_t initial_capacity)
      : encoded_data_(initial_capacity),
        prev_pc_offset(0),
        prev_deopt_id(0),
        prev_token_pos(0) {}

  ~DescriptorList() {}

  void AddDescriptor(RawPcDescriptors::Kind kind,
                     intptr_t pc_offset,
                     intptr_t deopt_id,
                     TokenPosition token_pos,
                     intptr_t try_index);

  RawPcDescriptors* FinalizePcDescriptors(uword entry_point);

 private:
  GrowableArray<uint8_t> encoded_data_;

  intptr_t prev_pc_offset;
  intptr_t prev_deopt_id;
  intptr_t prev_token_pos;

  DISALLOW_COPY_AND_ASSIGN(DescriptorList);
};


class StackMapTableBuilder : public ZoneAllocated {
 public:
  StackMapTableBuilder()
      : stack_map_(StackMap::ZoneHandle()),
        list_(GrowableObjectArray::ZoneHandle(
            GrowableObjectArray::New(Heap::kOld))) {}
  ~StackMapTableBuilder() {}

  void AddEntry(intptr_t pc_offset,
                BitmapBuilder* bitmap,
                intptr_t register_bit_count);

  bool Verify();

  RawArray* FinalizeStackMaps(const Code& code);

 private:
  intptr_t Length() const { return list_.Length(); }
  RawStackMap* MapAt(intptr_t index) const;

  StackMap& stack_map_;
  GrowableObjectArray& list_;
  DISALLOW_COPY_AND_ASSIGN(StackMapTableBuilder);
};


class ExceptionHandlerList : public ZoneAllocated {
 public:
  struct HandlerDesc {
    intptr_t outer_try_index;    // Try block in which this try block is nested.
    intptr_t pc_offset;          // Handler PC offset value.
    const Array* handler_types;  // Catch clause guards.
    bool needs_stacktrace;
  };

  ExceptionHandlerList() : list_() {}

  intptr_t Length() const { return list_.length(); }

  void AddPlaceHolder() {
    struct HandlerDesc data;
    data.outer_try_index = -1;
    data.pc_offset = ExceptionHandlers::kInvalidPcOffset;
    data.handler_types = NULL;
    data.needs_stacktrace = false;
    list_.Add(data);
  }

  void AddHandler(intptr_t try_index,
                  intptr_t outer_try_index,
                  intptr_t pc_offset,
                  const Array& handler_types,
                  bool needs_stacktrace) {
    ASSERT(try_index >= 0);
    while (Length() <= try_index) {
      AddPlaceHolder();
    }
    list_[try_index].outer_try_index = outer_try_index;
    ASSERT(list_[try_index].pc_offset == ExceptionHandlers::kInvalidPcOffset);
    list_[try_index].pc_offset = pc_offset;
    ASSERT(handler_types.IsZoneHandle());
    list_[try_index].handler_types = &handler_types;
    list_[try_index].needs_stacktrace |= needs_stacktrace;
  }


  // Called by rethrows, to mark their enclosing handlers.
  void SetNeedsStackTrace(intptr_t try_index) {
    // Rethrows can be generated outside a try by the compiler.
    if (try_index == CatchClauseNode::kInvalidTryIndex) {
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

  RawExceptionHandlers* FinalizeExceptionHandlers(uword entry_point) const;

 private:
  GrowableArray<struct HandlerDesc> list_;
  DISALLOW_COPY_AND_ASSIGN(ExceptionHandlerList);
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

  void StartInliningInterval(int32_t pc_offset, intptr_t inline_id);
  void BeginCodeSourceRange(int32_t pc_offset);
  void EndCodeSourceRange(int32_t pc_offset, TokenPosition pos);
  void NoteDescriptor(RawPcDescriptors::Kind kind,
                      int32_t pc_offset,
                      TokenPosition pos);

  RawArray* InliningIdToFunction();
  RawCodeSourceMap* Finalize();

 private:
  void BufferChangePosition(TokenPosition pos) {
    buffered_token_pos_stack_.Last() = pos;
  }
  void WriteChangePosition(TokenPosition pos) {
    stream_.Write<uint8_t>(kChangePosition);
    stream_.Write<int32_t>(static_cast<int32_t>(pos.value()));
    written_token_pos_stack_.Last() = pos;
  }
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
    stream_.Write<int32_t>(inline_id);
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

 private:
  const CodeSourceMap& map_;
  const Array& functions_;
  const Function& root_;

  DISALLOW_COPY_AND_ASSIGN(CodeSourceMapReader);
};

}  // namespace dart

#endif  // RUNTIME_VM_CODE_DESCRIPTORS_H_
