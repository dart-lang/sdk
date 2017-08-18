// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_descriptors.h"

#include "vm/log.h"

namespace dart {

void DescriptorList::AddDescriptor(RawPcDescriptors::Kind kind,
                                   intptr_t pc_offset,
                                   intptr_t deopt_id,
                                   TokenPosition token_pos,
                                   intptr_t try_index) {
  ASSERT((kind == RawPcDescriptors::kRuntimeCall) ||
         (kind == RawPcDescriptors::kOther) ||
         (deopt_id != Thread::kNoDeoptId));

  // When precompiling, we only use pc descriptors for exceptions.
  if (!FLAG_precompiled_mode || try_index != -1) {
    intptr_t merged_kind_try =
        RawPcDescriptors::MergedKindTry::Encode(kind, try_index);

    PcDescriptors::EncodeInteger(&encoded_data_, merged_kind_try);
    PcDescriptors::EncodeInteger(&encoded_data_, pc_offset - prev_pc_offset);
    PcDescriptors::EncodeInteger(&encoded_data_, deopt_id - prev_deopt_id);
    PcDescriptors::EncodeInteger(&encoded_data_,
                                 token_pos.value() - prev_token_pos);

    prev_pc_offset = pc_offset;
    prev_deopt_id = deopt_id;
    prev_token_pos = token_pos.value();
  }
}

RawPcDescriptors* DescriptorList::FinalizePcDescriptors(uword entry_point) {
  if (encoded_data_.length() == 0) {
    return Object::empty_descriptors().raw();
  }
  return PcDescriptors::New(&encoded_data_);
}

void StackMapTableBuilder::AddEntry(intptr_t pc_offset,
                                    BitmapBuilder* bitmap,
                                    intptr_t register_bit_count) {
  stack_map_ = StackMap::New(pc_offset, bitmap, register_bit_count);
  list_.Add(stack_map_, Heap::kOld);
}

bool StackMapTableBuilder::Verify() {
  intptr_t num_entries = Length();
  StackMap& map1 = StackMap::Handle();
  StackMap& map2 = StackMap::Handle();
  for (intptr_t i = 1; i < num_entries; i++) {
    map1 = MapAt(i - 1);
    map2 = MapAt(i);
    // Ensure there are no duplicates and the entries are sorted.
    if (map1.PcOffset() >= map2.PcOffset()) {
      return false;
    }
  }
  return true;
}

RawArray* StackMapTableBuilder::FinalizeStackMaps(const Code& code) {
  ASSERT(Verify());
  intptr_t num_entries = Length();
  if (num_entries == 0) {
    return Object::empty_array().raw();
  }
  return Array::MakeFixedLength(list_);
}

RawStackMap* StackMapTableBuilder::MapAt(intptr_t index) const {
  StackMap& map = StackMap::Handle();
  map ^= list_.At(index);
  return map.raw();
}

RawExceptionHandlers* ExceptionHandlerList::FinalizeExceptionHandlers(
    uword entry_point) const {
  intptr_t num_handlers = Length();
  if (num_handlers == 0) {
    return Object::empty_exception_handlers().raw();
  }
  const ExceptionHandlers& handlers =
      ExceptionHandlers::Handle(ExceptionHandlers::New(num_handlers));
  for (intptr_t i = 0; i < num_handlers; i++) {
    // Assert that every element in the array has been initialized.
    if (list_[i].handler_types == NULL) {
      // Unreachable handler, entry not computed.
      // Initialize it to some meaningful value.
      const bool has_catch_all = false;
      // Check it is uninitialized.
      ASSERT((list_[i].outer_try_index == -1) &&
             (list_[i].pc_offset == ExceptionHandlers::kInvalidPcOffset));
      handlers.SetHandlerInfo(i, list_[i].outer_try_index, list_[i].pc_offset,
                              list_[i].needs_stacktrace, has_catch_all,
                              list_[i].token_pos, list_[i].is_generated);
      handlers.SetHandledTypes(i, Array::empty_array());
    } else {
      const bool has_catch_all = ContainsDynamic(*list_[i].handler_types);
      handlers.SetHandlerInfo(i, list_[i].outer_try_index, list_[i].pc_offset,
                              list_[i].needs_stacktrace, has_catch_all,
                              list_[i].token_pos, list_[i].is_generated);
      handlers.SetHandledTypes(i, *list_[i].handler_types);
    }
  }
  return handlers.raw();
}

static uint8_t* zone_allocator(uint8_t* ptr,
                               intptr_t old_size,
                               intptr_t new_size) {
  Zone* zone = Thread::Current()->zone();
  return zone->Realloc<uint8_t>(ptr, old_size, new_size);
}

class CatchEntryStateMapBuilder::TrieNode : public ZoneAllocated {
 public:
  TrieNode() : pair_(), entry_state_offset_(-1) {}
  TrieNode(CatchEntryStatePair pair, intptr_t index)
      : pair_(pair), entry_state_offset_(index) {}

  intptr_t Offset() { return entry_state_offset_; }

  TrieNode* Insert(TrieNode* node) {
    children_.Add(node);
    return node;
  }

  TrieNode* Follow(CatchEntryStatePair next) {
    for (intptr_t i = 0; i < children_.length(); i++) {
      if (children_[i]->pair_ == next) return children_[i];
    }
    return NULL;
  }

 private:
  CatchEntryStatePair pair_;
  const intptr_t entry_state_offset_;
  GrowableArray<TrieNode*> children_;
};

CatchEntryStateMapBuilder::CatchEntryStateMapBuilder()
    : zone_(Thread::Current()->zone()),
      root_(new TrieNode()),
      current_pc_offset_(0),
      buffer_(NULL),
      stream_(&buffer_, zone_allocator, 64) {}

void CatchEntryStateMapBuilder::AppendMove(intptr_t src_slot,
                                           intptr_t dest_slot) {
  moves_.Add(CatchEntryStatePair::FromMove(src_slot, dest_slot));
}

void CatchEntryStateMapBuilder::AppendConstant(intptr_t pool_id,
                                               intptr_t dest_slot) {
  moves_.Add(CatchEntryStatePair::FromConstant(pool_id, dest_slot));
}

void CatchEntryStateMapBuilder::NewMapping(intptr_t pc_offset) {
  moves_.Clear();
  current_pc_offset_ = pc_offset;
}

void CatchEntryStateMapBuilder::EndMapping() {
  intptr_t suffix_length = 0;
  TrieNode* suffix = root_;
  // Find the largest common suffix, get the last node of the path.
  for (intptr_t i = moves_.length() - 1; i >= 0; i--) {
    TrieNode* n = suffix->Follow(moves_[i]);
    if (n == NULL) break;
    suffix_length++;
    suffix = n;
  }
  intptr_t length = moves_.length() - suffix_length;
  intptr_t current_offset = stream_.bytes_written();

  typedef WriteStream::Raw<sizeof(intptr_t), intptr_t> Writer;
  Writer::Write(&stream_, current_pc_offset_);
  Writer::Write(&stream_, length);
  Writer::Write(&stream_, suffix_length);
  Writer::Write(&stream_, suffix->Offset());

  // Write the unshared part, adding it to the trie.
  TrieNode* node = suffix;
  for (intptr_t i = length - 1; i >= 0; i--) {
    Writer::Write(&stream_, moves_[i].src);
    Writer::Write(&stream_, moves_[i].dest);

    TrieNode* child = new (zone_) TrieNode(moves_[i], current_offset);
    node->Insert(child);
    node = child;
  }
}

RawTypedData* CatchEntryStateMapBuilder::FinalizeCatchEntryStateMap() {
  TypedData& td = TypedData::Handle(TypedData::New(
      kTypedDataInt8ArrayCid, stream_.bytes_written(), Heap::kOld));
  NoSafepointScope no_safepoint;
  uint8_t* dest = reinterpret_cast<uint8_t*>(td.DataAddr(0));
  uint8_t* src = stream_.buffer();
  for (intptr_t i = 0; i < stream_.bytes_written(); i++) {
    dest[i] = src[i];
  }
  return td.raw();
}

const TokenPosition CodeSourceMapBuilder::kInitialPosition =
    TokenPosition(TokenPosition::kDartCodeProloguePos);

CodeSourceMapBuilder::CodeSourceMapBuilder(
    bool stack_traces_only,
    const GrowableArray<intptr_t>& caller_inline_id,
    const GrowableArray<TokenPosition>& inline_id_to_token_pos,
    const GrowableArray<const Function*>& inline_id_to_function)
    : buffered_pc_offset_(0),
      buffered_inline_id_stack_(),
      buffered_token_pos_stack_(),
      written_pc_offset_(0),
      written_inline_id_stack_(),
      written_token_pos_stack_(),
      caller_inline_id_(caller_inline_id),
      inline_id_to_token_pos_(inline_id_to_token_pos),
      inline_id_to_function_(inline_id_to_function),
      inlined_functions_(
          GrowableObjectArray::Handle(GrowableObjectArray::New(Heap::kOld))),
      buffer_(NULL),
      stream_(&buffer_, zone_allocator, 64),
      stack_traces_only_(stack_traces_only) {
  buffered_inline_id_stack_.Add(0);
  buffered_token_pos_stack_.Add(kInitialPosition);
  written_inline_id_stack_.Add(0);
  written_token_pos_stack_.Add(kInitialPosition);
}

void CodeSourceMapBuilder::FlushBuffer() {
  FlushBufferStack();
  FlushBufferPosition();
  FlushBufferPC();
}

void CodeSourceMapBuilder::FlushBufferStack() {
  for (intptr_t i = buffered_inline_id_stack_.length() - 1; i >= 0; i--) {
    intptr_t buffered_id = buffered_inline_id_stack_[i];
    if (i < written_inline_id_stack_.length()) {
      intptr_t written_id = written_inline_id_stack_[i];
      if (buffered_id == written_id) {
        // i is the top-most position where the buffered and written stack
        // match.
        while (written_inline_id_stack_.length() > i + 1) {
          WritePop();
        }
        for (intptr_t j = i + 1; j < buffered_inline_id_stack_.length(); j++) {
          TokenPosition buffered_pos = buffered_token_pos_stack_[j - 1];
          TokenPosition written_pos = written_token_pos_stack_[j - 1];
          if (buffered_pos != written_pos) {
            WriteChangePosition(buffered_pos);
          }
          WritePush(buffered_inline_id_stack_[j]);
        }
        return;
      }
    }
  }
  UNREACHABLE();
}

void CodeSourceMapBuilder::FlushBufferPosition() {
  ASSERT(buffered_token_pos_stack_.length() ==
         written_token_pos_stack_.length());

  intptr_t top = buffered_token_pos_stack_.length() - 1;
  TokenPosition buffered_pos = buffered_token_pos_stack_[top];
  TokenPosition written_pos = written_token_pos_stack_[top];
  if (buffered_pos != written_pos) {
    WriteChangePosition(buffered_pos);
  }
}

void CodeSourceMapBuilder::FlushBufferPC() {
  if (buffered_pc_offset_ != written_pc_offset_) {
    WriteAdvancePC(buffered_pc_offset_ - written_pc_offset_);
  }
}

void CodeSourceMapBuilder::StartInliningInterval(int32_t pc_offset,
                                                 intptr_t inline_id) {
  if (buffered_inline_id_stack_.Last() == inline_id) {
    // No change in function stack.
    return;
  }
  if (inline_id == -1) {
    // Basic blocking missing an inline_id.
    return;
  }

  if (!stack_traces_only_) {
    FlushBuffer();
  }

  // Find a minimal set of pops and pushes to bring us to the new function
  // stack.

  // Pop to a common ancestor.
  intptr_t common_parent = inline_id;
  while (!IsOnBufferedStack(common_parent)) {
    common_parent = caller_inline_id_[common_parent];
  }
  while (buffered_inline_id_stack_.Last() != common_parent) {
    BufferPop();
  }

  // Push to the new top-of-stack function.
  GrowableArray<intptr_t> to_push;
  intptr_t id = inline_id;
  while (id != common_parent) {
    to_push.Add(id);
    id = caller_inline_id_[id];
  }
  for (intptr_t i = to_push.length() - 1; i >= 0; i--) {
    intptr_t callee_id = to_push[i];
    TokenPosition call_token;
    if (callee_id != 0) {
      // TODO(rmacnak): Should make this array line up with the others.
      call_token = inline_id_to_token_pos_[callee_id - 1];
    } else {
      UNREACHABLE();
    }

    // Report caller as at the position of the call.
    BufferChangePosition(call_token);

    BufferPush(callee_id);
  }
}

void CodeSourceMapBuilder::BeginCodeSourceRange(int32_t pc_offset) {}

void CodeSourceMapBuilder::EndCodeSourceRange(int32_t pc_offset,
                                              TokenPosition pos) {
  if (pc_offset == buffered_pc_offset_) {
    return;  // Empty intermediate instruction.
  }
  if (pos != buffered_token_pos_stack_.Last()) {
    if (!stack_traces_only_) {
      FlushBuffer();
    }
    BufferChangePosition(pos);
  }
  BufferAdvancePC(pc_offset - buffered_pc_offset_);
}

void CodeSourceMapBuilder::NoteDescriptor(RawPcDescriptors::Kind kind,
                                          int32_t pc_offset,
                                          TokenPosition pos) {
  const uint8_t kCanThrow =
      RawPcDescriptors::kIcCall | RawPcDescriptors::kUnoptStaticCall |
      RawPcDescriptors::kRuntimeCall | RawPcDescriptors::kOther;
  if (stack_traces_only_ && ((kind & kCanThrow) != 0)) {
    BufferChangePosition(pos);
    BufferAdvancePC(pc_offset - buffered_pc_offset_);
    FlushBuffer();
  }
}

intptr_t CodeSourceMapBuilder::GetFunctionId(intptr_t inline_id) {
  const Function& function = *inline_id_to_function_[inline_id];
  for (intptr_t i = 0; i < inlined_functions_.Length(); i++) {
    if (inlined_functions_.At(i) == function.raw()) {
      return i;
    }
  }
  inlined_functions_.Add(function, Heap::kOld);
  return inlined_functions_.Length() - 1;
}

RawArray* CodeSourceMapBuilder::InliningIdToFunction() {
  if (inlined_functions_.Length() == 0) {
    return Object::empty_array().raw();
  }
  return Array::MakeFixedLength(inlined_functions_);
}

RawCodeSourceMap* CodeSourceMapBuilder::Finalize() {
  if (!stack_traces_only_) {
    FlushBuffer();
  }
  intptr_t length = stream_.bytes_written();
  const CodeSourceMap& map = CodeSourceMap::Handle(CodeSourceMap::New(length));
  NoSafepointScope no_safepoint;
  memmove(map.Data(), buffer_, length);
  return map.raw();
}

void CodeSourceMapBuilder::WriteChangePosition(TokenPosition pos) {
  stream_.Write<uint8_t>(kChangePosition);
  if (FLAG_precompiled_mode) {
    intptr_t line = -1;
    intptr_t inline_id = buffered_inline_id_stack_.Last();
    if (inline_id < inline_id_to_function_.length()) {
      const Function* function = inline_id_to_function_[inline_id];
      Script& script = Script::Handle(function->script());
      line = script.GetTokenLineUsingLineStarts(pos.SourcePosition());
    }
    stream_.Write<int32_t>(static_cast<int32_t>(line));
  } else {
    stream_.Write<int32_t>(static_cast<int32_t>(pos.value()));
  }
  written_token_pos_stack_.Last() = pos;
}

void CodeSourceMapReader::GetInlinedFunctionsAt(
    int32_t pc_offset,
    GrowableArray<const Function*>* function_stack,
    GrowableArray<TokenPosition>* token_positions) {
  function_stack->Clear();
  token_positions->Clear();

  NoSafepointScope no_safepoint;
  ReadStream stream(map_.Data(), map_.Length());

  int32_t current_pc_offset = 0;
  function_stack->Add(&root_);
  token_positions->Add(CodeSourceMapBuilder::kInitialPosition);

  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        int32_t position = stream.Read<int32_t>();
        (*token_positions)[token_positions->length() - 1] =
            TokenPosition(position);
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        current_pc_offset += delta;
        if (current_pc_offset > pc_offset) {
          return;
        }
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        int32_t func = stream.Read<int32_t>();
        function_stack->Add(
            &Function::Handle(Function::RawCast(functions_.At(func))));
        token_positions->Add(CodeSourceMapBuilder::kInitialPosition);
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        // We never pop the root function.
        ASSERT(function_stack->length() > 1);
        ASSERT(token_positions->length() > 1);
        function_stack->RemoveLast();
        token_positions->RemoveLast();
        break;
      }
      default:
        UNREACHABLE();
    }
  }
}

#ifndef PRODUCT
void CodeSourceMapReader::PrintJSONInlineIntervals(JSONObject* jsobj) {
  {
    JSONArray inlined_functions(jsobj, "_inlinedFunctions");
    Function& function = Function::Handle();
    for (intptr_t i = 0; i < functions_.Length(); i++) {
      function ^= functions_.At(i);
      ASSERT(!function.IsNull());
      inlined_functions.AddValue(function);
    }
  }

  GrowableArray<intptr_t> function_stack;
  JSONArray inline_intervals(jsobj, "_inlinedIntervals");
  NoSafepointScope no_safepoint;
  ReadStream stream(map_.Data(), map_.Length());

  int32_t current_pc_offset = 0;
  function_stack.Add(0);

  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        stream.Read<int32_t>();
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        // Format: [start, end, inline functions...]
        JSONArray inline_interval(&inline_intervals);
        inline_interval.AddValue(static_cast<intptr_t>(current_pc_offset));
        inline_interval.AddValue(
            static_cast<intptr_t>(current_pc_offset + delta - 1));
        for (intptr_t i = 0; i < function_stack.length(); i++) {
          inline_interval.AddValue(function_stack[i]);
        }
        current_pc_offset += delta;
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        int32_t func = stream.Read<int32_t>();
        function_stack.Add(func);
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        // We never pop the root function.
        ASSERT(function_stack.length() > 1);
        function_stack.RemoveLast();
        break;
      }
      default:
        UNREACHABLE();
    }
  }
}
#endif  // !PRODUCT

void CodeSourceMapReader::DumpInlineIntervals(uword start) {
  GrowableArray<const Function*> function_stack;
  LogBlock lb;
  NoSafepointScope no_safepoint;
  ReadStream stream(map_.Data(), map_.Length());

  int32_t current_pc_offset = 0;
  function_stack.Add(&root_);

  THR_Print("Inline intervals {\n");
  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        stream.Read<int32_t>();
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        THR_Print("%" Px "-%" Px ": ", start + current_pc_offset,
                  start + current_pc_offset + delta - 1);
        for (intptr_t i = 0; i < function_stack.length(); i++) {
          THR_Print("%s ", function_stack[i]->ToCString());
        }
        THR_Print("\n");
        current_pc_offset += delta;
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        int32_t func = stream.Read<int32_t>();
        function_stack.Add(
            &Function::Handle(Function::RawCast(functions_.At(func))));
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        // We never pop the root function.
        ASSERT(function_stack.length() > 1);
        function_stack.RemoveLast();
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  THR_Print("}\n");
}

void CodeSourceMapReader::DumpSourcePositions(uword start) {
  GrowableArray<const Function*> function_stack;
  GrowableArray<TokenPosition> token_positions;
  LogBlock lb;
  NoSafepointScope no_safepoint;
  ReadStream stream(map_.Data(), map_.Length());

  int32_t current_pc_offset = 0;
  function_stack.Add(&root_);
  token_positions.Add(CodeSourceMapBuilder::kInitialPosition);

  THR_Print("Source positions {\n");
  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        int32_t position = stream.Read<int32_t>();
        token_positions[token_positions.length() - 1] = TokenPosition(position);
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        THR_Print("%" Px "-%" Px ": ", start + current_pc_offset,
                  start + current_pc_offset + delta - 1);
        for (intptr_t i = 0; i < function_stack.length(); i++) {
          THR_Print("%s@%" Pd " ", function_stack[i]->ToCString(),
                    token_positions[i].value());
        }
        THR_Print("\n");
        current_pc_offset += delta;
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        int32_t func = stream.Read<int32_t>();
        function_stack.Add(
            &Function::Handle(Function::RawCast(functions_.At(func))));
        token_positions.Add(CodeSourceMapBuilder::kInitialPosition);
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        // We never pop the root function.
        ASSERT(function_stack.length() > 1);
        ASSERT(token_positions.length() > 1);
        function_stack.RemoveLast();
        token_positions.RemoveLast();
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  THR_Print("}\n");
}

}  // namespace dart
