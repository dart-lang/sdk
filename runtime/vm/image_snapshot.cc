// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/image_snapshot.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/class_id.h"
#include "vm/compiler/runtime_api.h"
#include "vm/dwarf.h"
#include "vm/elf.h"
#include "vm/hash.h"
#include "vm/hash_map.h"
#include "vm/heap/heap.h"
#include "vm/instructions.h"
#include "vm/json_writer.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/program_visitor.h"
#include "vm/stub_code.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/code_statistics.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#if defined(DART_PRECOMPILER)
DEFINE_FLAG(bool,
            print_instruction_stats,
            false,
            "Print instruction statistics");

DEFINE_FLAG(charp,
            print_instructions_sizes_to,
            NULL,
            "Print sizes of all instruction objects to the given file");
#endif

intptr_t ObjectOffsetTrait::Hashcode(Key key) {
  ObjectPtr obj = key;
  ASSERT(!obj->IsSmi());

  uword body = ObjectLayout::ToAddr(obj) + sizeof(ObjectLayout);
  uword end = ObjectLayout::ToAddr(obj) + obj->ptr()->HeapSize();

  uint32_t hash = obj->GetClassId();
  // Don't include the header. Objects in the image are pre-marked, but objects
  // in the current isolate are not.
  for (uword cursor = body; cursor < end; cursor += sizeof(uint32_t)) {
    hash = CombineHashes(hash, *reinterpret_cast<uint32_t*>(cursor));
  }

  return FinalizeHash(hash, 30);
}

bool ObjectOffsetTrait::IsKeyEqual(Pair pair, Key key) {
  ObjectPtr a = pair.object;
  ObjectPtr b = key;
  ASSERT(!a->IsSmi());
  ASSERT(!b->IsSmi());

  if (a->GetClassId() != b->GetClassId()) {
    return false;
  }

  intptr_t heap_size = a->ptr()->HeapSize();
  if (b->ptr()->HeapSize() != heap_size) {
    return false;
  }

  // Don't include the header. Objects in the image are pre-marked, but objects
  // in the current isolate are not.
  uword body_a = ObjectLayout::ToAddr(a) + sizeof(ObjectLayout);
  uword body_b = ObjectLayout::ToAddr(b) + sizeof(ObjectLayout);
  uword body_size = heap_size - sizeof(ObjectLayout);
  return 0 == memcmp(reinterpret_cast<const void*>(body_a),
                     reinterpret_cast<const void*>(body_b), body_size);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
ImageWriter::ImageWriter(Thread* t)
    : heap_(t->heap()),
      next_data_offset_(0),
      next_text_offset_(0),
      objects_(),
      instructions_(),
      instructions_section_type_(
          TagObjectTypeAsReadOnly(t->zone(), "InstructionsSection")),
      instructions_type_(TagObjectTypeAsReadOnly(t->zone(), "Instructions")),
      trampoline_type_(TagObjectTypeAsReadOnly(t->zone(), "Trampoline")) {
  ResetOffsets();
}

void ImageWriter::PrepareForSerialization(
    GrowableArray<ImageWriterCommand>* commands) {
  if (commands != nullptr) {
    const intptr_t initial_offset = next_text_offset_;
    for (auto& inst : *commands) {
      ASSERT((initial_offset + inst.expected_offset) == next_text_offset_);
      switch (inst.op) {
        case ImageWriterCommand::InsertInstructionOfCode: {
          CodePtr code = inst.insert_instruction_of_code.code;
          InstructionsPtr instructions = Code::InstructionsOf(code);
          const intptr_t offset = next_text_offset_;
          instructions_.Add(InstructionsData(instructions, code, offset));
          next_text_offset_ += SizeInSnapshot(instructions);
          ASSERT(heap_->GetObjectId(instructions) == 0);
          heap_->SetObjectId(instructions, offset);
          break;
        }
        case ImageWriterCommand::InsertBytesOfTrampoline: {
          auto trampoline_bytes = inst.insert_trampoline_bytes.buffer;
          auto trampoline_length = inst.insert_trampoline_bytes.buffer_length;
          const intptr_t offset = next_text_offset_;
          instructions_.Add(
              InstructionsData(trampoline_bytes, trampoline_length, offset));
          next_text_offset_ += trampoline_length;
          break;
        }
        default:
          UNREACHABLE();
      }
    }
  }
}

int32_t ImageWriter::GetTextOffsetFor(InstructionsPtr instructions,
                                      CodePtr code) {
  intptr_t offset = heap_->GetObjectId(instructions);
  if (offset != 0) {
    return offset;
  }

  offset = next_text_offset_;
  heap_->SetObjectId(instructions, offset);
  next_text_offset_ += SizeInSnapshot(instructions);
  instructions_.Add(InstructionsData(instructions, code, offset));

  ASSERT(offset != 0);
  return offset;
}

static intptr_t InstructionsSizeInSnapshot(InstructionsPtr raw) {
  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    // Currently, we align bare instruction payloads on 4 byte boundaries.
    //
    // If we later decide to align on larger boundaries to put entries at the
    // start of cache lines, make sure to account for entry points that are
    // _not_ at the start of the payload.
    return Utils::RoundUp(Instructions::Size(raw),
                          ImageWriter::kBareInstructionsAlignment);
  }
#if defined(IS_SIMARM_X64)
  return Utils::RoundUp(
      compiler::target::Instructions::HeaderSize() + Instructions::Size(raw),
      compiler::target::ObjectAlignment::kObjectAlignment);
#else
  return raw->ptr()->HeapSize();
#endif
}

#if defined(IS_SIMARM_X64)
static intptr_t CompressedStackMapsSizeInSnapshot(intptr_t payload_size) {
  const intptr_t unrounded_size_in_bytes =
      compiler::target::CompressedStackMaps::HeaderSize() + payload_size;
  return Utils::RoundUp(unrounded_size_in_bytes,
                        compiler::target::ObjectAlignment::kObjectAlignment);
}

static intptr_t StringPayloadSize(intptr_t len, bool isOneByteString) {
  return len * (isOneByteString ? OneByteString::kBytesPerElement
                                : TwoByteString::kBytesPerElement);
}

static intptr_t StringSizeInSnapshot(intptr_t len, bool isOneByteString) {
  const intptr_t unrounded_size_in_bytes =
      (String::kSizeofRawString / 2) + StringPayloadSize(len, isOneByteString);
  return Utils::RoundUp(unrounded_size_in_bytes,
                        compiler::target::ObjectAlignment::kObjectAlignment);
}

static intptr_t CodeSourceMapSizeInSnapshot(intptr_t len) {
  const intptr_t unrounded_size_in_bytes =
      2 * compiler::target::kWordSize + len;
  return Utils::RoundUp(unrounded_size_in_bytes,
                        compiler::target::ObjectAlignment::kObjectAlignment);
}

static intptr_t PcDescriptorsSizeInSnapshot(intptr_t len) {
  const intptr_t unrounded_size_in_bytes =
      2 * compiler::target::kWordSize + len;
  return Utils::RoundUp(unrounded_size_in_bytes,
                        compiler::target::ObjectAlignment::kObjectAlignment);
}

intptr_t ImageWriter::SizeInSnapshot(ObjectPtr raw_object) {
  const classid_t cid = raw_object->GetClassId();

  switch (cid) {
    case kCompressedStackMapsCid: {
      CompressedStackMapsPtr raw_maps =
          static_cast<CompressedStackMapsPtr>(raw_object);
      auto const payload_size = CompressedStackMaps::PayloadSizeOf(raw_maps);
      return CompressedStackMapsSizeInSnapshot(payload_size);
    }
    case kOneByteStringCid:
    case kTwoByteStringCid: {
      StringPtr raw_str = static_cast<StringPtr>(raw_object);
      return StringSizeInSnapshot(Smi::Value(raw_str->ptr()->length_),
                                  cid == kOneByteStringCid);
    }
    case kCodeSourceMapCid: {
      CodeSourceMapPtr raw_map = static_cast<CodeSourceMapPtr>(raw_object);
      return CodeSourceMapSizeInSnapshot(raw_map->ptr()->length_);
    }
    case kPcDescriptorsCid: {
      PcDescriptorsPtr raw_desc = static_cast<PcDescriptorsPtr>(raw_object);
      return PcDescriptorsSizeInSnapshot(raw_desc->ptr()->length_);
    }
    case kInstructionsCid: {
      InstructionsPtr raw_insns = static_cast<InstructionsPtr>(raw_object);
      return InstructionsSizeInSnapshot(raw_insns);
    }
    default: {
      const Class& clazz = Class::Handle(Object::Handle(raw_object).clazz());
      FATAL1("Unsupported class %s in rodata section.\n", clazz.ToCString());
      return 0;
    }
  }
}
#else   // defined(IS_SIMARM_X64)
intptr_t ImageWriter::SizeInSnapshot(ObjectPtr raw) {
  switch (raw->GetClassId()) {
    case kInstructionsCid:
      return InstructionsSizeInSnapshot(static_cast<InstructionsPtr>(raw));
    default:
      return raw->ptr()->HeapSize();
  }
}
#endif  // defined(IS_SIMARM_X64)

uint32_t ImageWriter::GetDataOffsetFor(ObjectPtr raw_object) {
  intptr_t snap_size = SizeInSnapshot(raw_object);
  intptr_t offset = next_data_offset_;
  next_data_offset_ += snap_size;
  objects_.Add(ObjectData(raw_object));
  return offset;
}

intptr_t ImageWriter::GetTextObjectCount() const {
  return instructions_.length();
}

void ImageWriter::GetTrampolineInfo(intptr_t* count, intptr_t* size) const {
  ASSERT(count != nullptr && size != nullptr);
  *count = 0;
  *size = 0;
  for (auto const data : instructions_) {
    if (data.trampoline_length != 0) {
      *count += 1;
      *size += data.trampoline_length;
    }
  }
}

// Returns nullptr if there is no profile writer.
const char* ImageWriter::ObjectTypeForProfile(const Object& object) const {
  if (profile_writer_ == nullptr) return nullptr;
  ASSERT(IsROSpace());
  Thread* thread = Thread::Current();
  REUSABLE_CLASS_HANDLESCOPE(thread);
  REUSABLE_STRING_HANDLESCOPE(thread);
  Class& klass = thread->ClassHandle();
  String& name = thread->StringHandle();
  klass = object.clazz();
  name = klass.UserVisibleName();
  auto const name_str = name.ToCString();
  return TagObjectTypeAsReadOnly(thread->zone(), name_str);
}

const char* ImageWriter::TagObjectTypeAsReadOnly(Zone* zone, const char* type) {
  ASSERT(zone != nullptr && type != nullptr);
  return OS::SCreate(zone, "(RO) %s", type);
}

#if defined(DART_PRECOMPILER)
void ImageWriter::DumpInstructionStats() {
  std::unique_ptr<CombinedCodeStatistics> instruction_stats(
      new CombinedCodeStatistics());
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    CodeStatistics* stats = data.insns_->stats();
    if (stats != nullptr) {
      stats->AppendTo(instruction_stats.get());
    }
  }
  instruction_stats->DumpStatistics();
}

void ImageWriter::DumpInstructionsSizes() {
  auto thread = Thread::Current();
  auto zone = thread->zone();

  auto& cls = Class::Handle(zone);
  auto& lib = Library::Handle(zone);
  auto& owner = Object::Handle(zone);
  auto& url = String::Handle(zone);
  auto& name = String::Handle(zone);
  intptr_t trampolines_total_size = 0;

  JSONWriter js;
  js.OpenArray();
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.code_ == nullptr;
    if (is_trampoline) {
      trampolines_total_size += data.trampoline_length;
      continue;
    }
    owner = WeakSerializationReference::Unwrap(data.code_->owner());
    js.OpenObject();
    if (owner.IsFunction()) {
      cls = Function::Cast(owner).Owner();
      name = cls.ScrubbedName();
      lib = cls.library();
      url = lib.url();
      js.PrintPropertyStr("l", url);
      js.PrintPropertyStr("c", name);
    } else if (owner.IsClass()) {
      cls ^= owner.raw();
      name = cls.ScrubbedName();
      lib = cls.library();
      js.PrintPropertyStr("l", url);
      js.PrintPropertyStr("c", name);
    }
    js.PrintProperty("n",
                     data.code_->QualifiedName(
                         NameFormattingParams::DisambiguatedWithoutClassName(
                             Object::kInternalName)));
    js.PrintProperty("s", SizeInSnapshot(data.insns_->raw()));
    js.CloseObject();
  }
  if (trampolines_total_size != 0) {
    js.OpenObject();
    js.PrintProperty("n", "[Stub] Trampoline");
    js.PrintProperty("s", trampolines_total_size);
    js.CloseObject();
  }
  js.CloseArray();

  auto file_open = Dart::file_open_callback();
  auto file_write = Dart::file_write_callback();
  auto file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    return;
  }

  auto file = file_open(FLAG_print_instructions_sizes_to, /*write=*/true);
  if (file == nullptr) {
    OS::PrintErr("Failed to open file %s\n", FLAG_print_instructions_sizes_to);
    return;
  }

  char* output = nullptr;
  intptr_t output_length = 0;
  js.Steal(&output, &output_length);
  file_write(output, output_length, file);
  free(output);
  file_close(file);
}

void ImageWriter::DumpStatistics() {
  if (FLAG_print_instruction_stats) {
    DumpInstructionStats();
  }

  if (FLAG_print_instructions_sizes_to != nullptr) {
    DumpInstructionsSizes();
  }
}
#endif

void ImageWriter::Write(WriteStream* clustered_stream, bool vm) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Heap* heap = thread->isolate()->heap();
  TIMELINE_DURATION(thread, Isolate, "WriteInstructions");

  // Handlify collected raw pointers as building the names below
  // will allocate on the Dart heap.
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    InstructionsData& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    if (is_trampoline) continue;

    data.insns_ = &Instructions::Handle(zone, data.raw_insns_);
    ASSERT(data.raw_code_ != nullptr);
    data.code_ = &Code::Handle(zone, data.raw_code_);

    // Reset object id as an isolate snapshot after a VM snapshot will not use
    // the VM snapshot's text image.
    heap->SetObjectId(data.insns_->raw(), 0);
  }
  for (intptr_t i = 0; i < objects_.length(); i++) {
    ObjectData& data = objects_[i];
    data.obj_ = &Object::Handle(zone, data.raw_obj_);
  }

  // Append the direct-mapped RO data objects after the clustered snapshot.
  // We need to do this before WriteText because WriteText currently adds the
  // finalized contents of the clustered_stream as data sections.
  offset_space_ = vm ? V8SnapshotProfileWriter::kVmData
                     : V8SnapshotProfileWriter::kIsolateData;
  WriteROData(clustered_stream);

  offset_space_ = vm ? V8SnapshotProfileWriter::kVmText
                     : V8SnapshotProfileWriter::kIsolateText;
  // Needs to happen after WriteROData, because all image writers currently
  // add the clustered data information to their output in WriteText().
  WriteText(clustered_stream, vm);
}

void ImageWriter::WriteROData(WriteStream* stream) {
#if defined(DART_PRECOMPILER)
  const intptr_t start_position = stream->Position();
#endif
  stream->Align(kMaxObjectAlignment);

  // Heap page starts here.

  intptr_t section_start = stream->Position();

  stream->WriteWord(next_data_offset_);  // Data length.
  // Zero values for other image header fields.
  stream->Align(kMaxObjectAlignment);
  ASSERT(stream->Position() - section_start == Image::kHeaderSize);
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    const intptr_t end_position = stream->Position();
    profile_writer_->AttributeBytesTo(
        V8SnapshotProfileWriter::ArtificialRootId(),
        end_position - start_position);
  }
#endif

  // Heap page objects start here.

  for (intptr_t i = 0; i < objects_.length(); i++) {
    const Object& obj = *objects_[i].obj_;
    AutoTraceImage(obj, section_start, stream);

    NoSafepointScope no_safepoint;
    uword start = static_cast<uword>(obj.raw()) - kHeapObjectTag;

    // Write object header with the mark and read-only bits set.
    uword marked_tags = obj.raw()->ptr()->tags_;
    marked_tags = ObjectLayout::OldBit::update(true, marked_tags);
    marked_tags = ObjectLayout::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags =
        ObjectLayout::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = ObjectLayout::NewBit::update(false, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    marked_tags |= static_cast<uword>(obj.raw()->ptr()->hash_) << 32;
#endif

#if defined(IS_SIMARM_X64)
    if (obj.IsCompressedStackMaps()) {
      const CompressedStackMaps& map = CompressedStackMaps::Cast(obj);
      auto const object_start = stream->Position();

      const intptr_t payload_size = map.payload_size();
      const intptr_t size_in_bytes =
          CompressedStackMapsSizeInSnapshot(payload_size);
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);

      stream->WriteTargetWord(marked_tags);
      stream->WriteFixed<uint32_t>(map.raw()->ptr()->flags_and_size_);
      ASSERT_EQUAL(stream->Position() - object_start,
                   compiler::target::CompressedStackMaps::HeaderSize());
      stream->WriteBytes(map.raw()->ptr()->data(), payload_size);
      stream->Align(compiler::target::ObjectAlignment::kObjectAlignment);
    } else if (obj.IsString()) {
      const String& str = String::Cast(obj);
      RELEASE_ASSERT(String::GetCachedHash(str.raw()) != 0);
      RELEASE_ASSERT(str.IsOneByteString() || str.IsTwoByteString());
      const intptr_t size_in_bytes =
          StringSizeInSnapshot(str.Length(), str.IsOneByteString());
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);

      stream->WriteTargetWord(marked_tags);
      stream->WriteTargetWord(static_cast<uword>(str.raw()->ptr()->length_));
      stream->WriteTargetWord(static_cast<uword>(str.raw()->ptr()->hash_));
      stream->WriteBytes(
          reinterpret_cast<const void*>(start + String::kSizeofRawString),
          StringPayloadSize(str.Length(), str.IsOneByteString()));
      stream->Align(compiler::target::ObjectAlignment::kObjectAlignment);
    } else if (obj.IsCodeSourceMap()) {
      const CodeSourceMap& map = CodeSourceMap::Cast(obj);
      const intptr_t size_in_bytes = CodeSourceMapSizeInSnapshot(map.Length());
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);

      stream->WriteTargetWord(marked_tags);
      stream->WriteTargetWord(map.Length());
      stream->WriteBytes(map.Data(), map.Length());
      stream->Align(compiler::target::ObjectAlignment::kObjectAlignment);
    } else if (obj.IsPcDescriptors()) {
      const PcDescriptors& desc = PcDescriptors::Cast(obj);

      const intptr_t size_in_bytes = PcDescriptorsSizeInSnapshot(desc.Length());
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);

      stream->WriteTargetWord(marked_tags);
      stream->WriteTargetWord(desc.Length());
      stream->WriteBytes(desc.raw()->ptr()->data(), desc.Length());
      stream->Align(compiler::target::ObjectAlignment::kObjectAlignment);
    } else {
      const Class& clazz = Class::Handle(obj.clazz());
      FATAL1("Unsupported class %s in rodata section.\n", clazz.ToCString());
    }
#else   // defined(IS_SIMARM_X64)
    const uword end = start + obj.raw()->ptr()->HeapSize();

    stream->WriteWord(marked_tags);
    start += sizeof(uword);
    for (uword* cursor = reinterpret_cast<uword*>(start);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      stream->WriteWord(*cursor);
    }
#endif  // defined(IS_SIMARM_X64)
  }
}

#if defined(DART_PRECOMPILER)
class DwarfAssemblyStream : public DwarfWriteStream {
 public:
  explicit DwarfAssemblyStream(StreamingWriteStream* stream)
      : stream_(ASSERT_NOTNULL(stream)) {}

  void sleb128(intptr_t value) { Print(".sleb128 %" Pd "\n", value); }
  void uleb128(uintptr_t value) { Print(".uleb128 %" Pd "\n", value); }
  void u1(uint8_t value) { Print(".byte %u\n", value); }
  void u2(uint16_t value) { Print(".2byte %u\n", value); }
  void u4(uint32_t value) { Print(".4byte %" Pu32 "\n", value); }
  void u8(uint64_t value) { Print(".8byte %" Pu64 "\n", value); }
  void string(const char* cstr) {     // NOLINT
    Print(".string \"%s\"\n", cstr);  // NOLINT
  }
  // Uses labels, so doesn't output to start or return a useful fixup position.
  intptr_t ReserveSize(const char* prefix, intptr_t* start) {
    // Assignment to temp works around buggy Mac assembler.
    Print("L%s_size = .L%s_end - .L%s_start\n", prefix, prefix, prefix);
    Print(".4byte L%s_size\n", prefix);
    Print(".L%s_start:\n", prefix);
    return -1;
  }
  // Just need to label the end so the assembler can calculate the size, so
  // start and the fixup position is unused.
  void SetSize(intptr_t fixup, const char* prefix, intptr_t start) {
    Print(".L%s_end:\n", prefix);
  }
  void OffsetFromSymbol(const char* symbol, intptr_t offset) {
    if (offset == 0) {
      PrintNamedAddress(symbol);
    } else {
      PrintNamedAddressWithOffset(symbol, offset);
    }
  }
  void DistanceBetweenSymbolOffsets(const char* symbol1,
                                    intptr_t offset1,
                                    const char* symbol2,
                                    intptr_t offset2) {
    Print(".uleb128 %s - %s + %" Pd "\n", symbol1, symbol2, offset1 - offset2);
  }

  // No-op, we'll be using labels.
  void InitializeAbstractOrigins(intptr_t size) {}
  void RegisterAbstractOrigin(intptr_t index) {
    // Label for DW_AT_abstract_origin references
    Print(".Lfunc%" Pd ":\n", index);
  }
  void AbstractOrigin(intptr_t index) {
    // Assignment to temp works around buggy Mac assembler.
    Print("Ltemp%" Pd " = .Lfunc%" Pd " - %s\n", temp_, index, kDebugInfoLabel);
    Print(".4byte Ltemp%" Pd "\n", temp_);
    temp_++;
  }

  // Methods for writing the assembly prologues for various DWARF sections.
  void AbbreviationsPrologue() {
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
    Print(".section __DWARF,__debug_abbrev,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
    Print(".section .debug_abbrev,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
  }
  void DebugInfoPrologue() {
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
    Print(".section __DWARF,__debug_info,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
    Print(".section .debug_info,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
    // Used to calculate abstract origin values.
    Print("%s:\n", kDebugInfoLabel);
  }
  void LineNumberProgramPrologue() {
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
    Print(".section __DWARF,__debug_line,regular,debug\n");
#elif defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                \
    defined(TARGET_OS_FUCHSIA)
    Print(".section .debug_line,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
  }

 private:
  static constexpr const char* kDebugInfoLabel = ".Ldebug_info";

  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3) {
    va_list args;
    va_start(args, format);
    stream_->VPrint(format, args);
    va_end(args);
  }

#if defined(TARGET_ARCH_IS_32_BIT)
#define FORM_ADDR ".4byte"
#elif defined(TARGET_ARCH_IS_64_BIT)
#define FORM_ADDR ".8byte"
#endif

  void PrintNamedAddress(const char* name) { Print(FORM_ADDR " %s\n", name); }
  void PrintNamedAddressWithOffset(const char* name, intptr_t offset) {
    Print(FORM_ADDR " %s + %" Pd "\n", name, offset);
  }

#undef FORM_ADDR

  StreamingWriteStream* const stream_;
  intptr_t temp_ = 0;

  DISALLOW_COPY_AND_ASSIGN(DwarfAssemblyStream);
};
#endif

static inline Dwarf* AddDwarfIfUnstripped(Zone* zone, bool strip, Elf* elf) {
#if defined(DART_PRECOMPILER)
  if (!strip) {
    if (elf != nullptr) {
      // Reuse the existing DWARF object.
      ASSERT(elf->dwarf() != nullptr);
      return elf->dwarf();
    }
    return new (zone) Dwarf(zone);
  }
#endif
  return nullptr;
}

AssemblyImageWriter::AssemblyImageWriter(Thread* thread,
                                         Dart_StreamingWriteCallback callback,
                                         void* callback_data,
                                         bool strip,
                                         Elf* debug_elf)
    : ImageWriter(thread),
      assembly_stream_(512 * KB, callback, callback_data),
      assembly_dwarf_(AddDwarfIfUnstripped(thread->zone(), strip, debug_elf)),
      debug_elf_(debug_elf) {}

void AssemblyImageWriter::Finalize() {
#if defined(DART_PRECOMPILER)
  if (assembly_dwarf_ != nullptr) {
    DwarfAssemblyStream dwarf_stream(&assembly_stream_);
    dwarf_stream.AbbreviationsPrologue();
    assembly_dwarf_->WriteAbbreviations(&dwarf_stream);
    dwarf_stream.DebugInfoPrologue();
    assembly_dwarf_->WriteDebugInfo(&dwarf_stream);
    dwarf_stream.LineNumberProgramPrologue();
    assembly_dwarf_->WriteLineNumberProgram(&dwarf_stream);
  }
  if (debug_elf_ != nullptr) {
    debug_elf_->Finalize();
  }
#endif
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static void EnsureAssemblerIdentifier(char* label) {
  for (char c = *label; c != '\0'; c = *++label) {
    if (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) ||
        ((c >= '0') && (c <= '9'))) {
      continue;
    }
    *label = '_';
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

const char* SnapshotTextObjectNamer::SnapshotNameFor(intptr_t code_index,
                                                     const Code& code) {
  ASSERT(!code.IsNull());
  const char* prefix = FLAG_precompiled_mode ? "Precompiled_" : "";
  owner_ = code.owner();
  if (owner_.IsNull()) {
    insns_ = code.instructions();
    const char* name = StubCode::NameOfStub(insns_.EntryPoint());
    ASSERT(name != nullptr);
    return OS::SCreate(zone_, "%sStub_%s", prefix, name);
  }
  // The weak reference to the Code's owner should never have been removed via
  // an intermediate serialization, since WSRs are only introduced during
  // precompilation.
  owner_ = WeakSerializationReference::Unwrap(owner_);
  ASSERT(!owner_.IsNull());
  if (owner_.IsClass()) {
    string_ = Class::Cast(owner_).Name();
    const char* name = string_.ToCString();
    EnsureAssemblerIdentifier(const_cast<char*>(name));
    return OS::SCreate(zone_, "%sAllocationStub_%s_%" Pd, prefix, name,
                       code_index);
  } else if (owner_.IsAbstractType()) {
    const char* name = namer_.StubNameForType(AbstractType::Cast(owner_));
    return OS::SCreate(zone_, "%s%s_%" Pd, prefix, name, code_index);
  } else if (owner_.IsFunction()) {
    const char* name = Function::Cast(owner_).ToQualifiedCString();
    EnsureAssemblerIdentifier(const_cast<char*>(name));
    return OS::SCreate(zone_, "%s%s_%" Pd, prefix, name, code_index);
  } else {
    UNREACHABLE();
  }
}

const char* SnapshotTextObjectNamer::SnapshotNameFor(
    intptr_t index,
    const ImageWriter::InstructionsData& data) {
  if (data.trampoline_bytes != nullptr) {
    return OS::SCreate(zone_, "Trampoline_%" Pd "", index);
  }
  return SnapshotNameFor(index, *data.code_);
}

void AssemblyImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
#else
  Zone* zone = Thread::Current()->zone();

  const bool bare_instruction_payloads =
      FLAG_precompiled_mode && FLAG_use_bare_instructions;

#if defined(DART_PRECOMPILER)
  const char* bss_symbol =
      vm ? "_kDartVmSnapshotBss" : "_kDartIsolateSnapshotBss";
  intptr_t debug_segment_base = 0;
  if (debug_elf_ != nullptr) {
    debug_segment_base = debug_elf_->NextMemoryOffset();
  }
#endif

  const char* instructions_symbol = vm ? kVmSnapshotInstructionsAsmSymbol
                                       : kIsolateSnapshotInstructionsAsmSymbol;
  assembly_stream_.Print(".text\n");
  assembly_stream_.Print(".globl %s\n", instructions_symbol);

  // Start snapshot at page boundary.
  ASSERT(VirtualMemory::PageSize() >= kMaxObjectAlignment);
  ASSERT(VirtualMemory::PageSize() >= Image::kBssAlignment);
  Align(VirtualMemory::PageSize());
  assembly_stream_.Print("%s:\n", instructions_symbol);

  intptr_t text_offset = 0;
#if defined(DART_PRECOMPILER)
  // Parent used for later profile objects. Starts off as the Image. When
  // writing bare instructions payloads, this is later updated with the
  // InstructionsSection object which contains all the bare payloads.
  V8SnapshotProfileWriter::ObjectId parent_id(offset_space_, text_offset);
#endif

  // This head also provides the gap to make the instructions snapshot
  // look like a OldPage.
  const intptr_t image_size = Utils::RoundUp(
      next_text_offset_, compiler::target::ObjectAlignment::kObjectAlignment);
  text_offset += WriteWordLiteralText(image_size);

#if defined(DART_PRECOMPILER)
  assembly_stream_.Print("%s %s - %s\n", kLiteralPrefix, bss_symbol,
                         instructions_symbol);
  text_offset += compiler::target::kWordSize;
#else
  text_offset += WriteWordLiteralText(0);  // No relocations.
#endif

  text_offset += Align(kMaxObjectAlignment, text_offset);
  ASSERT_EQUAL(text_offset, Image::kHeaderSize);
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    profile_writer_->SetObjectTypeAndName(parent_id, "Image",
                                          instructions_symbol);
    // Assign post-instruction padding to the Image, unless we're writing bare
    // instruction payloads, in which case we'll assign it to the
    // InstructionsSection object.
    const intptr_t padding =
        bare_instruction_payloads ? 0 : image_size - next_text_offset_;
    profile_writer_->AttributeBytesTo(parent_id, Image::kHeaderSize + padding);
    profile_writer_->AddRoot(parent_id);
  }
#endif

  if (bare_instruction_payloads) {
#if defined(DART_PRECOMPILER)
    if (profile_writer_ != nullptr) {
      const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
      profile_writer_->SetObjectTypeAndName(id, instructions_section_type_,
                                            instructions_symbol);
      const intptr_t padding = image_size - next_text_offset_;
      profile_writer_->AttributeBytesTo(
          id, compiler::target::InstructionsSection::HeaderSize() + padding);
      const intptr_t element_offset = id.second - parent_id.second;
      profile_writer_->AttributeReferenceTo(
          parent_id,
          {id, V8SnapshotProfileWriter::Reference::kElement, element_offset});
      // Later objects will have the InstructionsSection as a parent.
      parent_id = id;
    }
#endif
    const intptr_t section_size = image_size - text_offset;
    // Add the RawInstructionsSection header.
    const compiler::target::uword marked_tags =
        ObjectLayout::OldBit::encode(true) |
        ObjectLayout::OldAndNotMarkedBit::encode(false) |
        ObjectLayout::OldAndNotRememberedBit::encode(true) |
        ObjectLayout::NewBit::encode(false) |
        ObjectLayout::SizeTag::encode(AdjustObjectSizeForTarget(section_size)) |
        ObjectLayout::ClassIdTag::encode(kInstructionsSectionCid);
    text_offset += WriteWordLiteralText(marked_tags);
    // Calculated using next_text_offset_, which doesn't include post-payload
    // padding to object alignment.
    const intptr_t instructions_length =
        next_text_offset_ - (text_offset + compiler::target::kWordSize);
    text_offset += WriteWordLiteralText(instructions_length);
  }

  FrameUnwindPrologue();

  PcDescriptors& descriptors = PcDescriptors::Handle(zone);
  SnapshotTextObjectNamer namer(zone);

  ASSERT(offset_space_ != V8SnapshotProfileWriter::kSnapshot);
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT_EQUAL(data.text_offset_, text_offset);

    intptr_t dwarf_index = i;
#if defined(DART_PRECOMPILER)
    if (!is_trampoline && assembly_dwarf_ != nullptr) {
      dwarf_index =
          assembly_dwarf_->AddCode(*data.code_, SegmentRelativeOffset(vm));
    }
#endif

    const auto object_name = namer.SnapshotNameFor(dwarf_index, data);

#if defined(DART_PRECOMPILER)
    if (profile_writer_ != nullptr) {
      const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
      auto const type = is_trampoline ? trampoline_type_ : instructions_type_;
      const intptr_t size = is_trampoline ? data.trampoline_length
                                          : SizeInSnapshot(data.insns_->raw());
      profile_writer_->SetObjectTypeAndName(id, type, object_name);
      profile_writer_->AttributeBytesTo(id, size);
      const intptr_t element_offset = id.second - parent_id.second;
      profile_writer_->AttributeReferenceTo(
          parent_id,
          {id, V8SnapshotProfileWriter::Reference::kElement, element_offset});
    }
#endif

    if (is_trampoline) {
      const auto start = reinterpret_cast<uword>(data.trampoline_bytes);
      const auto end = start + data.trampoline_length;
      text_offset += WriteByteSequence(start, end);
      delete[] data.trampoline_bytes;
      data.trampoline_bytes = nullptr;
      continue;
    }

    const intptr_t instr_start = text_offset;

    const auto& code = *data.code_;
    const auto& insns = *data.insns_;
    descriptors = code.pc_descriptors();

    const uword payload_start = insns.PayloadStart();

    // 1. Write from the object start to the payload start. This includes the
    // object header and the fixed fields.  Not written for AOT snapshots using
    // bare instructions.
    if (!bare_instruction_payloads) {
      NoSafepointScope no_safepoint;

      // Write Instructions with the mark and read-only bits set.
      uword marked_tags = insns.raw_ptr()->tags_;
      marked_tags = ObjectLayout::OldBit::update(true, marked_tags);
      marked_tags =
          ObjectLayout::OldAndNotMarkedBit::update(false, marked_tags);
      marked_tags =
          ObjectLayout::OldAndNotRememberedBit::update(true, marked_tags);
      marked_tags = ObjectLayout::NewBit::update(false, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
      // Can't use GetObjectTagsAndHash because the update methods discard the
      // high bits.
      marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

#if defined(IS_SIMARM_X64)
      const intptr_t size_in_bytes = InstructionsSizeInSnapshot(insns.raw());
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);
      WriteWordLiteralText(marked_tags);
      text_offset += sizeof(compiler::target::uword);
      WriteWordLiteralText(insns.raw_ptr()->size_and_flags_);
      text_offset += sizeof(compiler::target::uword);
#else   // defined(IS_SIMARM_X64)
      uword object_start = reinterpret_cast<uword>(insns.raw_ptr());
      WriteWordLiteralText(marked_tags);
      object_start += sizeof(uword);
      text_offset += sizeof(uword);
      text_offset += WriteByteSequence(object_start, payload_start);
#endif  // defined(IS_SIMARM_X64)

      ASSERT((text_offset - instr_start) ==
             compiler::target::Instructions::HeaderSize());
    }

#if defined(DART_PRECOMPILER)
    if (debug_elf_ != nullptr) {
      debug_elf_->dwarf()->AddCode(code, {vm, text_offset});
    }
#endif
    // 2. Write a label at the entry point.
    // Linux's perf uses these labels.
    assembly_stream_.Print("%s:\n", object_name);

    {
      // 3. Write from the payload start to payload end. For AOT snapshots
      // with bare instructions, this is the only part serialized.
      NoSafepointScope no_safepoint;
      assert(kBareInstructionsAlignment <=
             compiler::target::ObjectAlignment::kObjectAlignment);
      const auto payload_align = bare_instruction_payloads
                                     ? kBareInstructionsAlignment
                                     : sizeof(compiler::target::uword);
      const uword payload_size = Utils::RoundUp(insns.Size(), payload_align);
      const uword payload_end = payload_start + payload_size;

      ASSERT(Utils::IsAligned(text_offset, payload_align));

#if defined(DART_PRECOMPILER)
      PcDescriptors::Iterator iterator(descriptors,
                                       PcDescriptorsLayout::kBSSRelocation);
      uword next_reloc_offset = iterator.MoveNext() ? iterator.PcOffset() : -1;

      // We only generate BSS relocations that are word-sized and at
      // word-aligned offsets in the payload.
      auto const possible_relocations_end =
          Utils::RoundDown(payload_end, sizeof(compiler::target::uword));
      for (uword cursor = payload_start; cursor < possible_relocations_end;
           cursor += sizeof(compiler::target::uword)) {
        compiler::target::uword data =
            *reinterpret_cast<compiler::target::uword*>(cursor);
        if ((cursor - payload_start) == next_reloc_offset) {
          assembly_stream_.Print("%s %s - (.) + %" Pd "\n", kLiteralPrefix,
                                 bss_symbol, /*addend=*/data);
          text_offset += compiler::target::kWordSize;
          next_reloc_offset = iterator.MoveNext() ? iterator.PcOffset() : -1;
        } else {
          text_offset += WriteWordLiteralText(data);
        }
      }
      assert(next_reloc_offset != (possible_relocations_end - payload_start));
      text_offset += WriteByteSequence(possible_relocations_end, payload_end);
#else
      text_offset += WriteByteSequence(payload_start, payload_end);
#endif

      // 4. Write from the payload end to object end. Note we can't simply copy
      // from the object because the host object may have less alignment filler
      // than the target object in the cross-word case. Not written for AOT
      // snapshots using bare instructions.
      if (!bare_instruction_payloads) {
        uword unaligned_size =
            compiler::target::Instructions::HeaderSize() + payload_size;
        uword alignment_size =
            Utils::RoundUp(
                unaligned_size,
                compiler::target::ObjectAlignment::kObjectAlignment) -
            unaligned_size;
        while (alignment_size > 0) {
          text_offset += WriteWordLiteralText(kBreakInstructionFiller);
          alignment_size -= sizeof(compiler::target::uword);
        }

        ASSERT(kWordSize != compiler::target::kWordSize ||
               (text_offset - instr_start) == insns.raw()->ptr()->HeapSize());
      }
    }

    ASSERT((text_offset - instr_start) == SizeInSnapshot(insns.raw()));
  }

  // Should be a no-op unless writing bare instruction payloads, in which case
  // we need to add post-payload padding to the object alignment. The alignment
  // needs to match the one we used for image_size above.
  text_offset +=
      Align(compiler::target::ObjectAlignment::kObjectAlignment, text_offset);

  ASSERT_EQUAL(text_offset, image_size);

  FrameUnwindEpilogue();

#if defined(DART_PRECOMPILER)
  if (debug_elf_ != nullptr) {
    // We need to generate a text segment of the appropriate size in the ELF
    // for two reasons:
    //
    // * We need unique virtual addresses for each text section in the DWARF
    //   file and that the virtual addresses for payloads within those sections
    //   do not overlap.
    //
    // * Our tools for converting DWARF stack traces back to "normal" Dart
    //   stack traces calculate an offset into the appropriate instructions
    //   section, and then add that offset to the virtual address of the
    //   corresponding segment to get the virtual address for the frame.
    //
    // Since we don't want to add the actual contents of the segment in the
    // separate debugging information, we pass nullptr for the bytes, which
    // creates an appropriate NOBITS section instead of PROGBITS.
    auto const debug_segment_base2 = debug_elf_->AddText(
        instructions_symbol, /*bytes=*/nullptr, text_offset);
    // Double-check that no other ELF sections were added in the middle of
    // writing the text section.
    ASSERT(debug_segment_base2 == debug_segment_base);
  }

  assembly_stream_.Print(".bss\n");
  // Align the BSS contents as expected by the Image class.
  Align(Image::kBssAlignment);
  assembly_stream_.Print("%s:\n", bss_symbol);

  auto const entry_count = vm ? BSS::kVmEntryCount : BSS::kIsolateEntryCount;
  for (intptr_t i = 0; i < entry_count; i++) {
    WriteWordLiteralText(0);
  }
#endif

#if defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                  \
    defined(TARGET_OS_FUCHSIA)
  assembly_stream_.Print(".section .rodata\n");
#elif defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  assembly_stream_.Print(".const\n");
#else
  UNIMPLEMENTED();
#endif

  const char* data_symbol =
      vm ? kVmSnapshotDataAsmSymbol : kIsolateSnapshotDataAsmSymbol;
  assembly_stream_.Print(".globl %s\n", data_symbol);
  Align(kMaxObjectAlignment);
  assembly_stream_.Print("%s:\n", data_symbol);
  const uword buffer = reinterpret_cast<uword>(clustered_stream->buffer());
  const intptr_t length = clustered_stream->bytes_written();
  WriteByteSequence(buffer, buffer + length);
#if defined(DART_PRECOMPILER)
  if (debug_elf_ != nullptr) {
    // Add a NoBits section for the ROData as well.
    debug_elf_->AddROData(data_symbol, clustered_stream->buffer(), length);
  }
#endif  // defined(DART_PRECOMPILER)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

void AssemblyImageWriter::FrameUnwindPrologue() {
  // Creates DWARF's .debug_frame
  // CFI = Call frame information
  // CFA = Canonical frame address
  assembly_stream_.Print(".cfi_startproc\n");

#if defined(TARGET_ARCH_X64)
  assembly_stream_.Print(".cfi_def_cfa rbp, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset rbp, 0\n");   // saved fp is *(CFA+0)
  assembly_stream_.Print(".cfi_offset rip, 8\n");   // saved pc is *(CFA+8)
  // saved sp is CFA+16
  // Should be ".cfi_value_offset rsp, 16", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (rsp)        7   (DWARF register number)
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend               16
  assembly_stream_.Print(".cfi_escape 0x10, 31, 2, 0x23, 16\n");

#elif defined(TARGET_ARCH_ARM64)
  COMPILE_ASSERT(FP == R29);
  COMPILE_ASSERT(LR == R30);
  assembly_stream_.Print(".cfi_def_cfa x29, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset x29, 0\n");   // saved fp is *(CFA+0)
  assembly_stream_.Print(".cfi_offset x30, 8\n");   // saved pc is *(CFA+8)
  // saved sp is CFA+16
  // Should be ".cfi_value_offset sp, 16", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (x31)       31
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend               16
  assembly_stream_.Print(".cfi_escape 0x10, 31, 2, 0x23, 16\n");

#elif defined(TARGET_ARCH_ARM)
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R7);
  assembly_stream_.Print(".cfi_def_cfa r7, 0\n");  // CFA is fp+j0
  assembly_stream_.Print(".cfi_offset r7, 0\n");   // saved fp is *(CFA+0)
#else
  COMPILE_ASSERT(FP == R11);
  assembly_stream_.Print(".cfi_def_cfa r11, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset r11, 0\n");   // saved fp is *(CFA+0)
#endif
  assembly_stream_.Print(".cfi_offset lr, 4\n");   // saved pc is *(CFA+4)
  // saved sp is CFA+8
  // Should be ".cfi_value_offset sp, 8", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (sp)        13
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend                8
  assembly_stream_.Print(".cfi_escape 0x10, 13, 2, 0x23, 8\n");

// libunwind on ARM may use .ARM.exidx instead of .debug_frame
#if !defined(TARGET_OS_MACOS) && !defined(TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R11);
  assembly_stream_.Print(".fnstart\n");
  assembly_stream_.Print(".save {r11, lr}\n");
  assembly_stream_.Print(".setfp r11, sp, #0\n");
#endif

#endif
}

void AssemblyImageWriter::FrameUnwindEpilogue() {
#if defined(TARGET_ARCH_ARM)
#if !defined(TARGET_OS_MACOS) && !defined(TARGET_OS_MACOS_IOS)
  assembly_stream_.Print(".fnend\n");
#endif
#endif
  assembly_stream_.Print(".cfi_endproc\n");
}

intptr_t AssemblyImageWriter::WriteByteSequence(uword start, uword end) {
  assert(end >= start);
  auto const end_of_words =
      Utils::RoundDown(end, sizeof(compiler::target::uword));
  for (auto cursor = reinterpret_cast<compiler::target::uword*>(start);
       cursor < reinterpret_cast<compiler::target::uword*>(end_of_words);
       cursor++) {
    WriteWordLiteralText(*cursor);
  }
  if (end != end_of_words) {
    auto start_of_rest = reinterpret_cast<const uint8_t*>(end_of_words);
    assembly_stream_.Print(".byte ");
    for (auto cursor = start_of_rest;
         cursor < reinterpret_cast<const uint8_t*>(end); cursor++) {
      if (cursor != start_of_rest) assembly_stream_.Print(", ");
      assembly_stream_.Print("0x%0.2" Px "", *cursor);
    }
    assembly_stream_.Print("\n");
  }
  return end - start;
}

intptr_t AssemblyImageWriter::Align(intptr_t alignment, uword position) {
  const uword next_position = Utils::RoundUp(position, alignment);
  assembly_stream_.Print(".balign %" Pd ", 0\n", alignment);
  return next_position - position;
}

BlobImageWriter::BlobImageWriter(Thread* thread,
                                 uint8_t** instructions_blob_buffer,
                                 ReAlloc alloc,
                                 intptr_t initial_size,
                                 Elf* debug_elf,
                                 Elf* elf)
    : ImageWriter(thread),
      instructions_blob_stream_(instructions_blob_buffer, alloc, initial_size),
      elf_(elf),
      debug_elf_(debug_elf) {
#if defined(DART_PRECOMPILER)
  ASSERT(debug_elf_ == nullptr || debug_elf_->dwarf() != nullptr);
#else
  RELEASE_ASSERT(elf_ == nullptr);
#endif
}

intptr_t BlobImageWriter::WriteByteSequence(uword start, uword end) {
  const uword size = end - start;
  instructions_blob_stream_.WriteBytes(reinterpret_cast<const void*>(start),
                                       size);
  return size;
}

void BlobImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  const bool bare_instruction_payloads =
      FLAG_precompiled_mode && FLAG_use_bare_instructions;
  auto const zone = Thread::Current()->zone();

#if defined(DART_PRECOMPILER)
  auto const instructions_symbol = vm ? kVmSnapshotInstructionsAsmSymbol
                                      : kIsolateSnapshotInstructionsAsmSymbol;
  intptr_t segment_base = 0;
  if (elf_ != nullptr) {
    segment_base = elf_->NextMemoryOffset();
  }
  intptr_t debug_segment_base = 0;
  if (debug_elf_ != nullptr) {
    debug_segment_base = debug_elf_->NextMemoryOffset();
    // If we're also generating an ELF snapshot, we want the virtual addresses
    // in it and the separately saved DWARF information to match.
    ASSERT(elf_ == nullptr || segment_base == debug_segment_base);
  }
#endif

  intptr_t text_offset = 0;
#if defined(DART_PRECOMPILER)
  // Parent used for later profile objects. Starts off as the Image. When
  // writing bare instructions payloads, this is later updated with the
  // InstructionsSection object which contains all the bare payloads.
  V8SnapshotProfileWriter::ObjectId parent_id(offset_space_, text_offset);
#endif

  // This header provides the gap to make the instructions snapshot look like a
  // OldPage.
  const intptr_t image_size = Utils::RoundUp(
      next_text_offset_, compiler::target::ObjectAlignment::kObjectAlignment);
  instructions_blob_stream_.WriteTargetWord(image_size);
#if defined(DART_PRECOMPILER)
  // Store the offset of the BSS section from the instructions section here.
  // If not compiling to ELF (and thus no BSS segment), write 0.
  const word bss_offset =
      elf_ != nullptr ? elf_->BssStart(vm) - segment_base : 0;
  ASSERT_EQUAL(Utils::RoundDown(bss_offset, Image::kBssAlignment), bss_offset);
  // Set the lowest bit if we are compiling to ELF.
  const word compiled_to_elf = elf_ != nullptr ? 0x1 : 0x0;
  instructions_blob_stream_.WriteTargetWord(bss_offset | compiled_to_elf);
#else
  instructions_blob_stream_.WriteTargetWord(0);  // No relocations.
#endif
  instructions_blob_stream_.Align(kMaxObjectAlignment);
  ASSERT_EQUAL(instructions_blob_stream_.Position(), Image::kHeaderSize);
  text_offset += Image::kHeaderSize;
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    profile_writer_->SetObjectTypeAndName(parent_id, "Image",
                                          instructions_symbol);
    // Assign post-instruction padding to the Image, unless we're writing bare
    // instruction payloads, in which case we'll assign it to the
    // InstructionsSection object.
    const intptr_t padding =
        bare_instruction_payloads ? 0 : image_size - next_text_offset_;
    profile_writer_->AttributeBytesTo(parent_id, Image::kHeaderSize + padding);
    profile_writer_->AddRoot(parent_id);
  }
#endif

  if (bare_instruction_payloads) {
#if defined(DART_PRECOMPILER)
    if (profile_writer_ != nullptr) {
      const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
      profile_writer_->SetObjectTypeAndName(id, instructions_section_type_,
                                            instructions_symbol);
      const intptr_t padding = image_size - next_text_offset_;
      profile_writer_->AttributeBytesTo(
          id, compiler::target::InstructionsSection::HeaderSize() + padding);
      const intptr_t element_offset = id.second - parent_id.second;
      profile_writer_->AttributeReferenceTo(
          parent_id,
          {id, V8SnapshotProfileWriter::Reference::kElement, element_offset});
      // Later objects will have the InstructionsSection as a parent.
      parent_id = id;
    }
#endif
    const intptr_t section_size = image_size - Image::kHeaderSize;
    // Add the RawInstructionsSection header.
    const compiler::target::uword marked_tags =
        ObjectLayout::OldBit::encode(true) |
        ObjectLayout::OldAndNotMarkedBit::encode(false) |
        ObjectLayout::OldAndNotRememberedBit::encode(true) |
        ObjectLayout::NewBit::encode(false) |
        ObjectLayout::SizeTag::encode(AdjustObjectSizeForTarget(section_size)) |
        ObjectLayout::ClassIdTag::encode(kInstructionsSectionCid);
    instructions_blob_stream_.WriteTargetWord(marked_tags);
    // Uses next_text_offset_ to avoid any post-payload padding.
    const intptr_t instructions_length =
        next_text_offset_ - Image::kHeaderSize -
        compiler::target::InstructionsSection::HeaderSize();
    instructions_blob_stream_.WriteTargetWord(instructions_length);
    ASSERT_EQUAL(instructions_blob_stream_.Position() - text_offset,
                 compiler::target::InstructionsSection::HeaderSize());
    text_offset += compiler::target::InstructionsSection::HeaderSize();
  }

  ASSERT_EQUAL(text_offset, instructions_blob_stream_.Position());

#if defined(DART_PRECOMPILER)
  auto& descriptors = PcDescriptors::Handle(zone);
#endif
  SnapshotTextObjectNamer namer(zone);

  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT(data.text_offset_ == text_offset);

#if defined(DART_PRECOMPILER)
    const auto object_name = namer.SnapshotNameFor(i, data);
    if (profile_writer_ != nullptr) {
      const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
      auto const type = is_trampoline ? trampoline_type_ : instructions_type_;
      const intptr_t size = is_trampoline ? data.trampoline_length
                                          : SizeInSnapshot(data.insns_->raw());
      profile_writer_->SetObjectTypeAndName(id, type, object_name);
      profile_writer_->AttributeBytesTo(id, size);
      // If the object is wrapped in an InstructionSection, then add an
      // element reference.
      const intptr_t element_offset = id.second - parent_id.second;
      profile_writer_->AttributeReferenceTo(
          parent_id,
          {id, V8SnapshotProfileWriter::Reference::kElement, element_offset});
    }
#endif

    if (is_trampoline) {
      const auto start = reinterpret_cast<uword>(data.trampoline_bytes);
      const auto end = start + data.trampoline_length;
      text_offset += WriteByteSequence(start, end);
      delete[] data.trampoline_bytes;
      data.trampoline_bytes = nullptr;
      continue;
    }

    const intptr_t instr_start = text_offset;

    const auto& insns = *data.insns_;
    const uword payload_start = insns.PayloadStart();

    ASSERT(Utils::IsAligned(payload_start, sizeof(compiler::target::uword)));

    // Write Instructions with the mark and read-only bits set.
    uword marked_tags = insns.raw_ptr()->tags_;
    marked_tags = ObjectLayout::OldBit::update(true, marked_tags);
    marked_tags = ObjectLayout::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags =
        ObjectLayout::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = ObjectLayout::NewBit::update(false, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    // Can't use GetObjectTagsAndHash because the update methods discard the
    // high bits.
    marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

#if defined(IS_SIMARM_X64)
    const intptr_t start_offset = instructions_blob_stream_.bytes_written();

    if (!bare_instruction_payloads) {
      const intptr_t size_in_bytes = InstructionsSizeInSnapshot(insns.raw());
      marked_tags = UpdateObjectSizeForTarget(size_in_bytes, marked_tags);
      instructions_blob_stream_.WriteTargetWord(marked_tags);
      instructions_blob_stream_.WriteFixed<uint32_t>(
          insns.raw_ptr()->size_and_flags_);
    } else {
      ASSERT(Utils::IsAligned(instructions_blob_stream_.Position(),
                              kBareInstructionsAlignment));
    }
    const intptr_t payload_offset = instructions_blob_stream_.Position();
    instructions_blob_stream_.WriteBytes(
        reinterpret_cast<const void*>(insns.PayloadStart()), insns.Size());
    const intptr_t alignment =
        bare_instruction_payloads
            ? kBareInstructionsAlignment
            : compiler::target::ObjectAlignment::kObjectAlignment;
    instructions_blob_stream_.Align(alignment);
    const intptr_t end_offset = instructions_blob_stream_.bytes_written();
    text_offset += (end_offset - start_offset);
#else   // defined(IS_SIMARM_X64)
    // Only payload is output in AOT snapshots.
    const uword header_size =
        bare_instruction_payloads
            ? 0
            : compiler::target::Instructions::HeaderSize();
    const uword payload_size = SizeInSnapshot(insns.raw()) - header_size;
    const uword object_end = payload_start + payload_size;
    if (!bare_instruction_payloads) {
      uword object_start = reinterpret_cast<uword>(insns.raw_ptr());
      instructions_blob_stream_.WriteWord(marked_tags);
      text_offset += sizeof(uword);
      object_start += sizeof(uword);
      text_offset += WriteByteSequence(object_start, payload_start);
    } else {
      ASSERT(Utils::IsAligned(instructions_blob_stream_.Position(),
                              kBareInstructionsAlignment));
    }
    const intptr_t payload_offset = instructions_blob_stream_.Position();
    text_offset += WriteByteSequence(payload_start, object_end);
#endif

#if defined(DART_PRECOMPILER)
    const auto& code = *data.code_;
    if (elf_ != nullptr && elf_->dwarf() != nullptr) {
      elf_->dwarf()->AddCode(code, {vm, payload_offset});
    }
    if (debug_elf_ != nullptr) {
      debug_elf_->dwarf()->AddCode(code, {vm, payload_offset});
    }

    // Don't patch the relocation if we're not generating ELF. The regular blobs
    // format does not yet support these relocations. Use
    // Code::VerifyBSSRelocations to check whether the relocations are patched
    // or not after loading.
    if (elf_ != nullptr) {
      const intptr_t current_stream_position =
          instructions_blob_stream_.Position();

      descriptors = code.pc_descriptors();

      PcDescriptors::Iterator iterator(
          descriptors, /*kind_mask=*/PcDescriptorsLayout::kBSSRelocation);

      while (iterator.MoveNext()) {
        const intptr_t reloc_offset = iterator.PcOffset();

        // The instruction stream at the relocation position holds an offset
        // into BSS corresponding to the symbol being resolved. This addend is
        // factored into the relocation.
        const auto addend = *reinterpret_cast<compiler::target::word*>(
            insns.PayloadStart() + reloc_offset);

        // Overwrite the relocation position in the instruction stream with the
        // offset of the BSS segment from the relocation position plus the
        // addend in the relocation.
        auto const reloc_pos = payload_offset + reloc_offset;
        instructions_blob_stream_.SetPosition(reloc_pos);

        const compiler::target::word offset = bss_offset - reloc_pos + addend;
        instructions_blob_stream_.WriteTargetWord(offset);
      }

      // Restore stream position after the relocation was patched.
      instructions_blob_stream_.SetPosition(current_stream_position);
    }
#else
    USE(payload_offset);
#endif

    ASSERT((text_offset - instr_start) ==
           ImageWriter::SizeInSnapshot(insns.raw()));
  }

  // Should be a no-op unless writing bare instruction payloads, in which case
  // we need to add post-payload padding to the object alignment. The alignment
  // should match the alignment used in image_size above.
  instructions_blob_stream_.Align(
      compiler::target::ObjectAlignment::kObjectAlignment);
  text_offset = Utils::RoundUp(
      text_offset, compiler::target::ObjectAlignment::kObjectAlignment);

  ASSERT_EQUAL(text_offset, instructions_blob_stream_.bytes_written());
  ASSERT_EQUAL(text_offset, image_size);

#ifdef DART_PRECOMPILER
  auto const data_symbol =
      vm ? kVmSnapshotDataAsmSymbol : kIsolateSnapshotDataAsmSymbol;
  if (elf_ != nullptr) {
    auto const segment_base2 =
        elf_->AddText(instructions_symbol, instructions_blob_stream_.buffer(),
                      instructions_blob_stream_.bytes_written());
    ASSERT_EQUAL(segment_base2, segment_base);
    // Write the .rodata section here like the AssemblyImageWriter.
    elf_->AddROData(data_symbol, clustered_stream->buffer(),
                    clustered_stream->bytes_written());
  }
  if (debug_elf_ != nullptr) {
    // To keep memory addresses consistent, we create elf::SHT_NOBITS sections
    // in the debugging information. We still pass along the buffers because
    // we'll need the buffer bytes at generation time to calculate the build ID
    // so it'll match the one in the snapshot.
    auto const debug_segment_base2 = debug_elf_->AddText(
        instructions_symbol, instructions_blob_stream_.buffer(),
        instructions_blob_stream_.bytes_written());
    ASSERT_EQUAL(debug_segment_base2, debug_segment_base);
    debug_elf_->AddROData(data_symbol, clustered_stream->buffer(),
                          clustered_stream->bytes_written());
  }
#endif
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

ImageReader::ImageReader(const uint8_t* data_image,
                         const uint8_t* instructions_image)
    : data_image_(data_image), instructions_image_(instructions_image) {
  ASSERT(data_image != NULL);
  ASSERT(instructions_image != NULL);
}

ApiErrorPtr ImageReader::VerifyAlignment() const {
  if (!Utils::IsAligned(data_image_, kObjectAlignment) ||
      !Utils::IsAligned(instructions_image_, kMaxObjectAlignment)) {
    return ApiError::New(
        String::Handle(String::New("Snapshot is misaligned", Heap::kOld)),
        Heap::kOld);
  }
  return ApiError::null();
}

#if defined(DART_PRECOMPILED_RUNTIME)
uword ImageReader::GetBareInstructionsAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, ImageWriter::kBareInstructionsAlignment));
  return reinterpret_cast<uword>(instructions_image_) + offset;
}

uword ImageReader::GetBareInstructionsEnd() const {
  Image image(instructions_image_);
  return reinterpret_cast<uword>(image.object_start()) + image.object_size();
}
#endif

InstructionsPtr ImageReader::GetInstructionsAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  ObjectPtr result = ObjectLayout::FromAddr(
      reinterpret_cast<uword>(instructions_image_) + offset);
  ASSERT(result->IsInstructions());
  ASSERT(result->ptr()->IsMarked());

  return Instructions::RawCast(result);
}

ObjectPtr ImageReader::GetObjectAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  ObjectPtr result =
      ObjectLayout::FromAddr(reinterpret_cast<uword>(data_image_) + offset);
  ASSERT(result->ptr()->IsMarked());

  return result;
}

}  // namespace dart
