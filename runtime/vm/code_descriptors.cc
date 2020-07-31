// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/code_descriptors.h"

#include "vm/compiler/api/deopt_id.h"
#include "vm/log.h"
#include "vm/object_store.h"
#include "vm/zone_text_buffer.h"

namespace dart {

void DescriptorList::AddDescriptor(PcDescriptorsLayout::Kind kind,
                                   intptr_t pc_offset,
                                   intptr_t deopt_id,
                                   TokenPosition token_pos,
                                   intptr_t try_index,
                                   intptr_t yield_index) {
  // yield index 0 is reserved for normal entry.
  RELEASE_ASSERT(yield_index != 0);

  ASSERT((kind == PcDescriptorsLayout::kRuntimeCall) ||
         (kind == PcDescriptorsLayout::kBSSRelocation) ||
         (kind == PcDescriptorsLayout::kOther) ||
         (yield_index != PcDescriptorsLayout::kInvalidYieldIndex) ||
         (deopt_id != DeoptId::kNone));

  // When precompiling, we only use pc descriptors for exceptions,
  // relocations and yield indices.
  if (!FLAG_precompiled_mode || try_index != -1 ||
      yield_index != PcDescriptorsLayout::kInvalidYieldIndex ||
      kind == PcDescriptorsLayout::kBSSRelocation) {
    const int32_t kind_and_metadata =
        PcDescriptorsLayout::KindAndMetadata::Encode(kind, try_index,
                                                     yield_index);

    PcDescriptors::EncodeInteger(&encoded_data_, kind_and_metadata);
    PcDescriptors::EncodeInteger(&encoded_data_, pc_offset - prev_pc_offset);
    prev_pc_offset = pc_offset;

    if (!FLAG_precompiled_mode) {
      PcDescriptors::EncodeInteger(&encoded_data_, deopt_id - prev_deopt_id);
      PcDescriptors::EncodeInteger(&encoded_data_,
                                   token_pos.value() - prev_token_pos);
      prev_deopt_id = deopt_id;
      prev_token_pos = token_pos.value();
    }
  }
}

PcDescriptorsPtr DescriptorList::FinalizePcDescriptors(uword entry_point) {
  if (encoded_data_.length() == 0) {
    return Object::empty_descriptors().raw();
  }
  return PcDescriptors::New(&encoded_data_);
}

// Encode unsigned integer |value| in LEB128 format and store into |data|.
void CompressedStackMapsBuilder::EncodeLEB128(GrowableArray<uint8_t>* data,
                                              uintptr_t value) {
  while (true) {
    uint8_t part = value & 0x7f;
    value >>= 7;
    if (value != 0) part |= 0x80;
    data->Add(part);
    if (value == 0) break;
  }
}

void CompressedStackMapsBuilder::AddEntry(intptr_t pc_offset,
                                          BitmapBuilder* bitmap,
                                          intptr_t spill_slot_bit_count) {
  ASSERT(bitmap != nullptr);
  ASSERT(pc_offset > last_pc_offset_);
  ASSERT(spill_slot_bit_count >= 0 && spill_slot_bit_count <= bitmap->Length());
  auto const pc_delta = pc_offset - last_pc_offset_;
  auto const non_spill_slot_bit_count = bitmap->Length() - spill_slot_bit_count;
  EncodeLEB128(&encoded_bytes_, pc_delta);
  EncodeLEB128(&encoded_bytes_, spill_slot_bit_count);
  EncodeLEB128(&encoded_bytes_, non_spill_slot_bit_count);
  bitmap->AppendAsBytesTo(&encoded_bytes_);
  last_pc_offset_ = pc_offset;
}

CompressedStackMapsPtr CompressedStackMapsBuilder::Finalize() const {
  if (encoded_bytes_.length() == 0) return CompressedStackMaps::null();
  return CompressedStackMaps::NewInlined(encoded_bytes_);
}

CompressedStackMapsIterator::CompressedStackMapsIterator(
    const CompressedStackMaps& maps,
    const CompressedStackMaps& global_table)
    : maps_(maps),
      bits_container_(maps_.UsesGlobalTable() ? global_table : maps_) {
  ASSERT(!maps_.IsGlobalTable());
  ASSERT(!maps_.UsesGlobalTable() || bits_container_.IsGlobalTable());
}

CompressedStackMapsIterator::CompressedStackMapsIterator(
    const CompressedStackMaps& maps)
    : CompressedStackMapsIterator(
          maps,
          // Only look up the global table if the map will end up using it.
          maps.UsesGlobalTable() ? CompressedStackMaps::Handle(
                                       Thread::Current()
                                           ->isolate()
                                           ->object_store()
                                           ->canonicalized_stack_map_entries())
                                 : Object::null_compressed_stack_maps()) {}

CompressedStackMapsIterator::CompressedStackMapsIterator(
    const CompressedStackMapsIterator& it)
    : maps_(it.maps_),
      bits_container_(it.bits_container_),
      next_offset_(it.next_offset_),
      current_pc_offset_(it.current_pc_offset_),
      current_global_table_offset_(it.current_global_table_offset_),
      current_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
      current_non_spill_slot_bit_count_(it.current_spill_slot_bit_count_),
      current_bits_offset_(it.current_bits_offset_) {}

// Decode unsigned integer in LEB128 format from the payload of |maps| and
// update |byte_index|.
uintptr_t CompressedStackMapsIterator::DecodeLEB128(
    const CompressedStackMaps& maps,
    uintptr_t* byte_index) {
  uword shift = 0;
  uintptr_t value = 0;
  uint8_t part = 0;
  do {
    ASSERT(*byte_index < maps.payload_size());
    part = maps.PayloadByte((*byte_index)++);
    value |= static_cast<uintptr_t>(part & 0x7f) << shift;
    shift += 7;
  } while ((part & 0x80) != 0);

  return value;
}

bool CompressedStackMapsIterator::MoveNext() {
  // Empty CompressedStackMaps are represented as null values.
  if (maps_.IsNull() || next_offset_ >= maps_.payload_size()) return false;
  uintptr_t offset = next_offset_;

  auto const pc_delta = DecodeLEB128(maps_, &offset);
  ASSERT(pc_delta <= (kMaxUint32 - current_pc_offset_));
  current_pc_offset_ += pc_delta;

  // Table-using CSMs have a table offset after the PC offset delta, whereas
  // the post-delta part of inlined entries has the same information as
  // global table entries.
  if (maps_.UsesGlobalTable()) {
    current_global_table_offset_ = DecodeLEB128(maps_, &offset);
    ASSERT(current_global_table_offset_ < bits_container_.payload_size());

    // Since generally we only use entries in the GC and the GC only needs
    // the rest of the entry information if the PC offset matches, we lazily
    // load and cache the information stored in the global object when it is
    // actually requested.
    current_spill_slot_bit_count_ = -1;
    current_non_spill_slot_bit_count_ = -1;
    current_bits_offset_ = -1;
  } else {
    current_spill_slot_bit_count_ = DecodeLEB128(maps_, &offset);
    ASSERT(current_spill_slot_bit_count_ >= 0);

    current_non_spill_slot_bit_count_ = DecodeLEB128(maps_, &offset);
    ASSERT(current_non_spill_slot_bit_count_ >= 0);

    const auto stackmap_bits =
        current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
    const uintptr_t stackmap_size =
        Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
    ASSERT(stackmap_size <= (maps_.payload_size() - offset));

    current_bits_offset_ = offset;
    offset += stackmap_size;
  }

  next_offset_ = offset;
  return true;
}

intptr_t CompressedStackMapsIterator::Length() {
  EnsureFullyLoadedEntry();
  return current_spill_slot_bit_count_ + current_non_spill_slot_bit_count_;
}
intptr_t CompressedStackMapsIterator::SpillSlotBitCount() {
  EnsureFullyLoadedEntry();
  return current_spill_slot_bit_count_;
}

bool CompressedStackMapsIterator::IsObject(intptr_t bit_index) {
  EnsureFullyLoadedEntry();
  ASSERT(!bits_container_.IsNull());
  ASSERT(bit_index >= 0 && bit_index < Length());
  const intptr_t byte_index = bit_index >> kBitsPerByteLog2;
  const intptr_t bit_remainder = bit_index & (kBitsPerByte - 1);
  uint8_t byte_mask = 1U << bit_remainder;
  const intptr_t byte_offset = current_bits_offset_ + byte_index;
  return (bits_container_.PayloadByte(byte_offset) & byte_mask) != 0;
}

void CompressedStackMapsIterator::LazyLoadGlobalTableEntry() {
  ASSERT(maps_.UsesGlobalTable() && bits_container_.IsGlobalTable());
  ASSERT(HasLoadedEntry());
  ASSERT(current_global_table_offset_ < bits_container_.payload_size());

  uintptr_t offset = current_global_table_offset_;
  current_spill_slot_bit_count_ = DecodeLEB128(bits_container_, &offset);
  ASSERT(current_spill_slot_bit_count_ >= 0);

  current_non_spill_slot_bit_count_ = DecodeLEB128(bits_container_, &offset);
  ASSERT(current_non_spill_slot_bit_count_ >= 0);

  const auto stackmap_bits = Length();
  const uintptr_t stackmap_size =
      Utils::RoundUp(stackmap_bits, kBitsPerByte) >> kBitsPerByteLog2;
  ASSERT(stackmap_size <= (bits_container_.payload_size() - offset));

  current_bits_offset_ = offset;
}

const char* CompressedStackMapsIterator::ToCString(Zone* zone) const {
  ZoneTextBuffer b(zone, 100);
  CompressedStackMapsIterator it(*this);
  // If we haven't loaded an entry yet, do so (but don't skip the current
  // one if we have!)
  if (!it.HasLoadedEntry()) {
    if (!it.MoveNext()) return b.buffer();
  }
  bool first_entry = true;
  do {
    if (first_entry) {
      first_entry = false;
    } else {
      b.AddString("\n");
    }
    b.Printf("0x%08x: ", it.pc_offset());
    for (intptr_t i = 0, n = it.Length(); i < n; i++) {
      b.AddString(it.IsObject(i) ? "1" : "0");
    }
  } while (it.MoveNext());
  return b.buffer();
}

const char* CompressedStackMapsIterator::ToCString() const {
  return ToCString(Thread::Current()->zone());
}

ExceptionHandlersPtr ExceptionHandlerList::FinalizeExceptionHandlers(
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
                              list_[i].is_generated);
      handlers.SetHandledTypes(i, Array::empty_array());
    } else {
      const bool has_catch_all = ContainsDynamic(*list_[i].handler_types);
      handlers.SetHandlerInfo(i, list_[i].outer_try_index, list_[i].pc_offset,
                              list_[i].needs_stacktrace, has_catch_all,
                              list_[i].is_generated);
      handlers.SetHandledTypes(i, *list_[i].handler_types);
    }
  }
  return handlers.raw();
}

static uint8_t* ZoneAllocator(uint8_t* ptr,
                              intptr_t old_size,
                              intptr_t new_size) {
  Zone* zone = Thread::Current()->zone();
  return zone->Realloc<uint8_t>(ptr, old_size, new_size);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
class CatchEntryMovesMapBuilder::TrieNode : public ZoneAllocated {
 public:
  TrieNode() : move_(), entry_state_offset_(-1) {}
  TrieNode(CatchEntryMove move, intptr_t index)
      : move_(move), entry_state_offset_(index) {}

  intptr_t Offset() { return entry_state_offset_; }

  TrieNode* Insert(TrieNode* node) {
    children_.Add(node);
    return node;
  }

  TrieNode* Follow(CatchEntryMove next) {
    for (intptr_t i = 0; i < children_.length(); i++) {
      if (children_[i]->move_ == next) return children_[i];
    }
    return NULL;
  }

 private:
  CatchEntryMove move_;
  const intptr_t entry_state_offset_;
  GrowableArray<TrieNode*> children_;
};

CatchEntryMovesMapBuilder::CatchEntryMovesMapBuilder()
    : zone_(Thread::Current()->zone()),
      root_(new TrieNode()),
      current_pc_offset_(0),
      buffer_(NULL),
      stream_(&buffer_, ZoneAllocator, 64) {}

void CatchEntryMovesMapBuilder::Append(const CatchEntryMove& move) {
  moves_.Add(move);
}

void CatchEntryMovesMapBuilder::NewMapping(intptr_t pc_offset) {
  moves_.Clear();
  current_pc_offset_ = pc_offset;
}

void CatchEntryMovesMapBuilder::EndMapping() {
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
    moves_[i].WriteTo(&stream_);

    TrieNode* child = new (zone_) TrieNode(moves_[i], current_offset);
    node->Insert(child);
    node = child;
  }
}

TypedDataPtr CatchEntryMovesMapBuilder::FinalizeCatchEntryMovesMap() {
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

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
      stream_(&buffer_, ZoneAllocator, 64),
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

void CodeSourceMapBuilder::NoteDescriptor(PcDescriptorsLayout::Kind kind,
                                          int32_t pc_offset,
                                          TokenPosition pos) {
  const uint8_t kCanThrow =
      PcDescriptorsLayout::kIcCall | PcDescriptorsLayout::kUnoptStaticCall |
      PcDescriptorsLayout::kRuntimeCall | PcDescriptorsLayout::kOther;
  if ((kind & kCanThrow) != 0) {
    BufferChangePosition(pos);
    BufferAdvancePC(pc_offset - buffered_pc_offset_);
    FlushBuffer();
  }
}

void CodeSourceMapBuilder::NoteNullCheck(int32_t pc_offset,
                                         TokenPosition pos,
                                         intptr_t name_index) {
  BufferChangePosition(pos);
  BufferAdvancePC(pc_offset - buffered_pc_offset_);
  FlushBuffer();
  WriteNullCheck(name_index);
}

intptr_t CodeSourceMapBuilder::GetFunctionId(intptr_t inline_id) {
  const Function& function = *inline_id_to_function_[inline_id];
  for (intptr_t i = 0; i < inlined_functions_.Length(); i++) {
    if (inlined_functions_.At(i) == function.raw()) {
      return i;
    }
  }
  RELEASE_ASSERT(!function.IsNull());
  inlined_functions_.Add(function, Heap::kOld);
  return inlined_functions_.Length() - 1;
}

ArrayPtr CodeSourceMapBuilder::InliningIdToFunction() {
  if (inlined_functions_.Length() == 0) {
    return Object::empty_array().raw();
  }
  return Array::MakeFixedLength(inlined_functions_);
}

CodeSourceMapPtr CodeSourceMapBuilder::Finalize() {
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
  intptr_t position_or_line = pos.value();
#if defined(DART_PRECOMPILER)
  intptr_t column = TokenPosition::kNoSourcePos;
  if (FLAG_precompiled_mode) {
    // Don't use the raw position value directly in precompiled mode. Instead,
    // use the value of kNoSource as a fallback when no line or column
    // information is found.
    position_or_line = TokenPosition::kNoSourcePos;
    intptr_t inline_id = buffered_inline_id_stack_.Last();
    if (inline_id < inline_id_to_function_.length()) {
      const Function* function = inline_id_to_function_[inline_id];
      Script& script = Script::Handle(function->script());
      script.GetTokenLocationUsingLineStarts(pos.SourcePosition(),
                                             &position_or_line, &column);
    }
  }
#endif
  stream_.Write<int32_t>(position_or_line);
#if defined(DART_PRECOMPILER)
  // For non-symbolic stack traces, the CodeSourceMaps are not serialized,
  // so we need not worry about increasing snapshot size by including more
  // information here.
  if (FLAG_dwarf_stack_traces_mode) {
    stream_.Write<int32_t>(column);
  }
#endif
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
        (*token_positions)[token_positions->length() - 1] =
            ReadPosition(&stream);
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
      case CodeSourceMapBuilder::kNullCheck: {
        stream.Read<int32_t>();
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
        ReadPosition(&stream);
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
      case CodeSourceMapBuilder::kNullCheck: {
        stream.Read<int32_t>();
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

  THR_Print("Inline intervals for function '%s' {\n",
            root_.ToFullyQualifiedCString());
  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        ReadPosition(&stream);
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
      case CodeSourceMapBuilder::kNullCheck: {
        stream.Read<int32_t>();
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

  THR_Print("Source positions for function '%s' {\n",
            root_.ToFullyQualifiedCString());
  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        token_positions[token_positions.length() - 1] = ReadPosition(&stream);
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
      case CodeSourceMapBuilder::kNullCheck: {
        const intptr_t name_index = stream.Read<int32_t>();
        THR_Print("%" Px "-%" Px ": null check PP#%" Pd "\n",
                  start + current_pc_offset, start + current_pc_offset,
                  name_index);
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  THR_Print("}\n");
}

intptr_t CodeSourceMapReader::GetNullCheckNameIndexAt(int32_t pc_offset) {
  NoSafepointScope no_safepoint;
  ReadStream stream(map_.Data(), map_.Length());

  int32_t current_pc_offset = 0;

  while (stream.PendingBytes() > 0) {
    uint8_t opcode = stream.Read<uint8_t>();
    switch (opcode) {
      case CodeSourceMapBuilder::kChangePosition: {
        ReadPosition(&stream);
        break;
      }
      case CodeSourceMapBuilder::kAdvancePC: {
        int32_t delta = stream.Read<int32_t>();
        current_pc_offset += delta;
        RELEASE_ASSERT(current_pc_offset <= pc_offset);
        break;
      }
      case CodeSourceMapBuilder::kPushFunction: {
        stream.Read<int32_t>();
        break;
      }
      case CodeSourceMapBuilder::kPopFunction: {
        break;
      }
      case CodeSourceMapBuilder::kNullCheck: {
        const int32_t name_index = stream.Read<int32_t>();
        if (current_pc_offset == pc_offset) {
          return name_index;
        }
        break;
      }
      default:
        UNREACHABLE();
    }
  }

  UNREACHABLE();
  return -1;
}

TokenPosition CodeSourceMapReader::ReadPosition(ReadStream* stream) {
  const intptr_t line = stream->Read<int32_t>();
#if defined(DART_PRECOMPILER)
  // The special handling for non-symbolic stack trace mode only needs to
  // happen in the precompiler, because those CSMs are not serialized in
  // precompiled snapshots.
  if (FLAG_dwarf_stack_traces_mode) {
    stream->Read<int32_t>();  // Discard the column information.
  }
#endif
  return TokenPosition(line);
}

}  // namespace dart
