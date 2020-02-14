// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/image_snapshot.h"

#include "platform/assert.h"
#include "vm/class_id.h"
#include "vm/compiler/backend/code_statistics.h"
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
  RawObject* obj = key;
  ASSERT(!obj->IsSmi());

  uword body = RawObject::ToAddr(obj) + sizeof(RawObject);
  uword end = RawObject::ToAddr(obj) + obj->HeapSize();

  uint32_t hash = obj->GetClassId();
  // Don't include the header. Objects in the image are pre-marked, but objects
  // in the current isolate are not.
  for (uword cursor = body; cursor < end; cursor += sizeof(uint32_t)) {
    hash = CombineHashes(hash, *reinterpret_cast<uint32_t*>(cursor));
  }

  return FinalizeHash(hash, 30);
}

bool ObjectOffsetTrait::IsKeyEqual(Pair pair, Key key) {
  RawObject* a = pair.object;
  RawObject* b = key;
  ASSERT(!a->IsSmi());
  ASSERT(!b->IsSmi());

  if (a->GetClassId() != b->GetClassId()) {
    return false;
  }

  intptr_t heap_size = a->HeapSize();
  if (b->HeapSize() != heap_size) {
    return false;
  }

  // Don't include the header. Objects in the image are pre-marked, but objects
  // in the current isolate are not.
  uword body_a = RawObject::ToAddr(a) + sizeof(RawObject);
  uword body_b = RawObject::ToAddr(b) + sizeof(RawObject);
  uword body_size = heap_size - sizeof(RawObject);
  return 0 == memcmp(reinterpret_cast<const void*>(body_a),
                     reinterpret_cast<const void*>(body_b), body_size);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
ImageWriter::ImageWriter(Heap* heap)
    : heap_(heap),
      next_data_offset_(0),
      next_text_offset_(0),
      objects_(),
      instructions_() {
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
          RawCode* code = inst.insert_instruction_of_code.code;
          RawInstructions* instructions = Code::InstructionsOf(code);
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

int32_t ImageWriter::GetTextOffsetFor(RawInstructions* instructions,
                                      RawCode* code) {
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

static intptr_t InstructionsSizeInSnapshot(RawInstructions* raw) {
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
  return raw->HeapSize();
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

intptr_t ImageWriter::SizeInSnapshot(RawObject* raw_object) {
  const classid_t cid = raw_object->GetClassId();

  switch (cid) {
    case kCompressedStackMapsCid: {
      RawCompressedStackMaps* raw_maps =
          static_cast<RawCompressedStackMaps*>(raw_object);
      auto const payload_size = CompressedStackMaps::PayloadSizeOf(raw_maps);
      return CompressedStackMapsSizeInSnapshot(payload_size);
    }
    case kOneByteStringCid:
    case kTwoByteStringCid: {
      RawString* raw_str = static_cast<RawString*>(raw_object);
      return StringSizeInSnapshot(Smi::Value(raw_str->ptr()->length_),
                                  cid == kOneByteStringCid);
    }
    case kCodeSourceMapCid: {
      RawCodeSourceMap* raw_map = static_cast<RawCodeSourceMap*>(raw_object);
      return CodeSourceMapSizeInSnapshot(raw_map->ptr()->length_);
    }
    case kPcDescriptorsCid: {
      RawPcDescriptors* raw_desc = static_cast<RawPcDescriptors*>(raw_object);
      return PcDescriptorsSizeInSnapshot(raw_desc->ptr()->length_);
    }
    case kInstructionsCid: {
      RawInstructions* raw_insns = static_cast<RawInstructions*>(raw_object);
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
intptr_t ImageWriter::SizeInSnapshot(RawObject* raw) {
  switch (raw->GetClassId()) {
    case kInstructionsCid:
      return InstructionsSizeInSnapshot(static_cast<RawInstructions*>(raw));
    default:
      return raw->HeapSize();
  }
}
#endif  // defined(IS_SIMARM_X64)

uint32_t ImageWriter::GetDataOffsetFor(RawObject* raw_object) {
  intptr_t snap_size = SizeInSnapshot(raw_object);
  intptr_t offset = next_data_offset_;
  next_data_offset_ += snap_size;
  objects_.Add(ObjectData(raw_object));
  return offset;
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

  JSONWriter js;
  js.OpenArray();
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    owner = data.code_->owner();
    js.OpenObject();
    if (owner.IsFunction()) {
      cls = Function::Cast(owner).Owner();
      name = cls.ScrubbedName();
      lib = cls.library();
      url = lib.url();
      js.PrintPropertyStr("l", url);
      js.PrintPropertyStr("c", name);
    }
    js.PrintProperty("n", data.code_->QualifiedName());
    js.PrintProperty("s", SizeInSnapshot(data.insns_->raw()));
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
    ASSERT(data.raw_code_ != NULL);
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
  offset_space_ = vm ? V8SnapshotProfileWriter::kVmData
                     : V8SnapshotProfileWriter::kIsolateData;
  WriteROData(clustered_stream);

  offset_space_ = vm ? V8SnapshotProfileWriter::kVmText
                     : V8SnapshotProfileWriter::kIsolateText;
  WriteText(clustered_stream, vm);
}

void ImageWriter::WriteROData(WriteStream* stream) {
  stream->Align(kMaxObjectAlignment);

  // Heap page starts here.

  intptr_t section_start = stream->Position();

  stream->WriteWord(next_data_offset_);  // Data length.
  COMPILE_ASSERT(kMaxObjectAlignment >= kObjectAlignment);
  stream->Align(kMaxObjectAlignment);

  ASSERT(stream->Position() - section_start == Image::kHeaderSize);

  // Heap page objects start here.

  for (intptr_t i = 0; i < objects_.length(); i++) {
    const Object& obj = *objects_[i].obj_;
    AutoTraceImage(obj, section_start, stream);

    NoSafepointScope no_safepoint;
    uword start = reinterpret_cast<uword>(obj.raw()) - kHeapObjectTag;

    // Write object header with the mark and read-only bits set.
    uword marked_tags = obj.raw()->ptr()->tags_;
    marked_tags = RawObject::OldBit::update(true, marked_tags);
    marked_tags = RawObject::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags = RawObject::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = RawObject::NewBit::update(false, marked_tags);
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
      stream->WriteTargetWord(
          reinterpret_cast<uword>(str.raw()->ptr()->length_));
      stream->WriteTargetWord(reinterpret_cast<uword>(str.raw()->ptr()->hash_));
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
    const uword end = start + obj.raw()->HeapSize();

    stream->WriteWord(marked_tags);
    start += sizeof(uword);
    for (uword* cursor = reinterpret_cast<uword*>(start);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      stream->WriteWord(*cursor);
    }
#endif  // defined(IS_SIMARM_X64)
  }
}

AssemblyImageWriter::AssemblyImageWriter(Thread* thread,
                                         Dart_StreamingWriteCallback callback,
                                         void* callback_data,
                                         bool strip,
                                         Elf* debug_elf)
    : ImageWriter(thread->heap()),
      assembly_stream_(512 * KB, callback, callback_data),
      assembly_dwarf_(nullptr),
      debug_dwarf_(nullptr) {
#if defined(DART_PRECOMPILER)
  Zone* zone = Thread::Current()->zone();
  if (!strip) {
    assembly_dwarf_ =
        new (zone) Dwarf(zone, &assembly_stream_, /*elf=*/nullptr);
  }
  if (debug_elf != nullptr) {
    debug_dwarf_ =
        new (zone) Dwarf(zone, /*assembly_stream=*/nullptr, debug_elf);
  }
#endif
}

void AssemblyImageWriter::Finalize() {
#ifdef DART_PRECOMPILER
  if (assembly_dwarf_ != nullptr) {
    assembly_dwarf_->Write();
  }
  if (debug_dwarf_ != nullptr) {
    debug_dwarf_->Write();
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

static const char* NameOfStubIsolateSpecificStub(ObjectStore* object_store,
                                                 const Code& code) {
  if (code.raw() == object_store->build_method_extractor_code()) {
    return "_iso_stub_BuildMethodExtractorStub";
  } else if (code.raw() == object_store->dispatch_table_null_error_stub()) {
    return "_iso_stub_DispatchTableNullErrorStub";
  } else if (code.raw() == object_store->null_error_stub_with_fpu_regs_stub()) {
    return "_iso_stub_NullErrorSharedWithFPURegsStub";
  } else if (code.raw() ==
             object_store->null_error_stub_without_fpu_regs_stub()) {
    return "_iso_stub_NullErrorSharedWithoutFPURegsStub";
  } else if (code.raw() ==
             object_store->null_arg_error_stub_with_fpu_regs_stub()) {
    return "_iso_stub_NullArgErrorSharedWithFPURegsStub";
  } else if (code.raw() ==
             object_store->null_arg_error_stub_without_fpu_regs_stub()) {
    return "_iso_stub_NullArgErrorSharedWithoutFPURegsStub";
  } else if (code.raw() == object_store->allocate_mint_with_fpu_regs_stub()) {
    return "_iso_stub_AllocateMintWithFPURegsStub";
  } else if (code.raw() ==
             object_store->allocate_mint_without_fpu_regs_stub()) {
    return "_iso_stub_AllocateMintWithoutFPURegsStub";
  } else if (code.raw() ==
             object_store->stack_overflow_stub_with_fpu_regs_stub()) {
    return "_iso_stub_StackOverflowStubWithFPURegsStub";
  } else if (code.raw() ==
             object_store->stack_overflow_stub_without_fpu_regs_stub()) {
    return "_iso_stub_StackOverflowStubWithoutFPURegsStub";
  } else if (code.raw() == object_store->write_barrier_wrappers_stub()) {
    return "_iso_stub_WriteBarrierWrappersStub";
  } else if (code.raw() == object_store->array_write_barrier_stub()) {
    return "_iso_stub_ArrayWriteBarrierStub";
  }
  return nullptr;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

const char* AssemblyCodeNamer::AssemblyNameFor(intptr_t code_index,
                                               const Code& code) {
  ASSERT(!code.IsNull());
  owner_ = code.owner();
  if (owner_.IsNull()) {
    insns_ = code.instructions();
    const char* name = StubCode::NameOfStub(insns_.EntryPoint());
    if (name != nullptr) {
      return OS::SCreate(zone_, "Precompiled_Stub_%s", name);
    }
    name = NameOfStubIsolateSpecificStub(store_, code);
    ASSERT(name != nullptr);
    return OS::SCreate(zone_, "Precompiled__%s", name);
  } else if (owner_.IsClass()) {
    string_ = Class::Cast(owner_).Name();
    const char* name = string_.ToCString();
    EnsureAssemblerIdentifier(const_cast<char*>(name));
    return OS::SCreate(zone_, "Precompiled_AllocationStub_%s_%" Pd, name,
                       code_index);
  } else if (owner_.IsAbstractType()) {
    const char* name = namer_.StubNameForType(AbstractType::Cast(owner_));
    return OS::SCreate(zone_, "Precompiled_%s", name);
  } else if (owner_.IsFunction()) {
    const char* name = Function::Cast(owner_).ToQualifiedCString();
    EnsureAssemblerIdentifier(const_cast<char*>(name));
    return OS::SCreate(zone_, "Precompiled_%s_%" Pd, name, code_index);
  } else {
    UNREACHABLE();
  }
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
  if (debug_dwarf_ != nullptr) {
    debug_segment_base = debug_dwarf_->elf()->NextMemoryOffset();
  }
#endif

  const char* instructions_symbol =
      vm ? "_kDartVmSnapshotInstructions" : "_kDartIsolateSnapshotInstructions";
  assembly_stream_.Print(".text\n");
  assembly_stream_.Print(".globl %s\n", instructions_symbol);

  // Start snapshot at page boundary.
  ASSERT(VirtualMemory::PageSize() >= kMaxObjectAlignment);
  Align(VirtualMemory::PageSize());
  assembly_stream_.Print("%s:\n", instructions_symbol);

  // This head also provides the gap to make the instructions snapshot
  // look like a HeapPage.
  const intptr_t image_size = Utils::RoundUp(
      next_text_offset_, compiler::target::ObjectAlignment::kObjectAlignment);
  WriteWordLiteralText(image_size);

#if defined(DART_PRECOMPILER)
  assembly_stream_.Print("%s %s - %s\n", kLiteralPrefix, bss_symbol,
                         instructions_symbol);
#else
  WriteWordLiteralText(0);  // No relocations.
#endif

  intptr_t header_words = Image::kHeaderSize / sizeof(compiler::target::uword);
  for (intptr_t i = Image::kHeaderFields; i < header_words; i++) {
    WriteWordLiteralText(0);
  }

  if (bare_instruction_payloads) {
    const intptr_t section_size = image_size - Image::kHeaderSize;
    // Add the RawInstructionsSection header.
    const compiler::target::uword marked_tags =
        RawObject::OldBit::encode(true) |
        RawObject::OldAndNotMarkedBit::encode(false) |
        RawObject::OldAndNotRememberedBit::encode(true) |
        RawObject::NewBit::encode(false) |
        RawObject::SizeTag::encode(AdjustObjectSizeForTarget(section_size)) |
        RawObject::ClassIdTag::encode(kInstructionsSectionCid);
    WriteWordLiteralText(marked_tags);
    // Calculated using next_text_offset_, which doesn't include post-payload
    // padding to object alignment.
    const intptr_t instructions_length =
        next_text_offset_ - Image::kHeaderSize -
        compiler::target::InstructionsSection::HeaderSize();
    WriteWordLiteralText(instructions_length);

    if (profile_writer_ != nullptr) {
      const intptr_t offset = Image::kHeaderSize;
      const intptr_t non_instruction_bytes =
          compiler::target::InstructionsSection::HeaderSize();
      profile_writer_->SetObjectTypeAndName({offset_space_, offset},
                                            "InstructionsSection",
                                            /*name=*/nullptr);
      profile_writer_->AttributeBytesTo({offset_space_, offset},
                                        non_instruction_bytes);
      profile_writer_->AddRoot({offset_space_, offset});
    }
  }

  const intptr_t section_headers_size =
      Image::kHeaderSize +
      (bare_instruction_payloads
           ? compiler::target::InstructionsSection::HeaderSize()
           : 0);

  FrameUnwindPrologue();

  PcDescriptors& descriptors = PcDescriptors::Handle(zone);
  AssemblyCodeNamer namer(zone);
  intptr_t text_offset = 0;

  ASSERT(offset_space_ != V8SnapshotProfileWriter::kSnapshot);
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT((data.text_offset_ - instructions_[0].text_offset_) == text_offset);

    if (bare_instruction_payloads && profile_writer_ != nullptr) {
      const intptr_t instructions_sections_offset = Image::kHeaderSize;
      const intptr_t offset = section_headers_size + text_offset;
      profile_writer_->AttributeReferenceTo(
          {offset_space_, instructions_sections_offset},
          {{offset_space_, offset},
           V8SnapshotProfileWriter::Reference::kElement,
           text_offset});
    }

    if (is_trampoline) {
      if (profile_writer_ != nullptr) {
        const intptr_t offset = section_headers_size + text_offset;
        profile_writer_->SetObjectTypeAndName({offset_space_, offset},
                                              "Trampolines",
                                              /*name=*/nullptr);
        profile_writer_->AttributeBytesTo({offset_space_, offset},
                                          data.trampline_length);
      }

      const auto start = reinterpret_cast<uword>(data.trampoline_bytes);
      const auto end = start + data.trampline_length;
      text_offset += WriteByteSequence(start, end);
      delete[] data.trampoline_bytes;
      data.trampoline_bytes = nullptr;
      continue;
    }

    const intptr_t instr_start = text_offset;

    const Instructions& insns = *data.insns_;
    const Code& code = *data.code_;
    descriptors = data.code_->pc_descriptors();

    if (profile_writer_ != nullptr) {
      const intptr_t offset = section_headers_size + text_offset;
      profile_writer_->SetObjectTypeAndName({offset_space_, offset},
                                            "Instructions",
                                            /*name=*/nullptr);
      profile_writer_->AttributeBytesTo({offset_space_, offset},
                                        SizeInSnapshot(insns.raw()));
    }

    const uword payload_start = insns.PayloadStart();

    // 1. Write from the object start to the payload start. This includes the
    // object header and the fixed fields.  Not written for AOT snapshots using
    // bare instructions.
    if (!bare_instruction_payloads) {
      NoSafepointScope no_safepoint;

      // Write Instructions with the mark and read-only bits set.
      uword marked_tags = insns.raw_ptr()->tags_;
      marked_tags = RawObject::OldBit::update(true, marked_tags);
      marked_tags = RawObject::OldAndNotMarkedBit::update(false, marked_tags);
      marked_tags =
          RawObject::OldAndNotRememberedBit::update(true, marked_tags);
      marked_tags = RawObject::NewBit::update(false, marked_tags);
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

    intptr_t dwarf_index = i;
#ifdef DART_PRECOMPILER
    // Create a label for use by DWARF.
    if (assembly_dwarf_ != nullptr) {
      dwarf_index = assembly_dwarf_->AddCode(code);
    }
    if (debug_dwarf_ != nullptr) {
      auto const virtual_address =
          debug_segment_base + section_headers_size + text_offset;
      debug_dwarf_->AddCode(code, virtual_address);
    }
#endif
    // 2. Write a label at the entry point.
    // Linux's perf uses these labels.
    assembly_stream_.Print("%s:\n", namer.AssemblyNameFor(dwarf_index, code));

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
                                       RawPcDescriptors::kBSSRelocation);
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
          next_reloc_offset = iterator.MoveNext() ? iterator.PcOffset() : -1;
        } else {
          WriteWordLiteralText(data);
        }
      }
      assert(next_reloc_offset != (possible_relocations_end - payload_start));
      WriteByteSequence(possible_relocations_end, payload_end);
      text_offset += payload_size;
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
          WriteWordLiteralText(
              compiler::Assembler::GetBreakInstructionFiller());
          alignment_size -= sizeof(compiler::target::uword);
          text_offset += sizeof(compiler::target::uword);
        }

        ASSERT(kWordSize != compiler::target::kWordSize ||
               (text_offset - instr_start) == insns.raw()->HeapSize());
      }
    }

    ASSERT((text_offset - instr_start) == SizeInSnapshot(insns.raw()));
  }

  // Should be a no-op unless writing bare instruction payloads, in which case
  // we need to add post-payload padding to the object alignment. The alignment
  // needs to match the one we used for image_size above.
  text_offset +=
      Align(compiler::target::ObjectAlignment::kObjectAlignment, text_offset);

  ASSERT_EQUAL(section_headers_size + text_offset, image_size);

  FrameUnwindEpilogue();

#if defined(DART_PRECOMPILER)
  if (debug_dwarf_ != nullptr) {
    // We need to generate a text segment of the appropriate size in the ELF
    // for two reasons:
    //
    // * We use Elf::NextMemoryOffset() as the current segment base when
    //   calling Dwarf::AddCode above, so we get unique virtual addresses in
    //   the DWARF line number program.
    //
    // * Our tools for converting DWARF stack traces back to "normal" Dart
    //   stack traces calculate an offset into the appropriate instructions
    //   section, and then add that offset to the virtual address of the
    //   corresponding segment to get the virtual address for the frame.
    //
    // Since we won't actually be adding the instructions to the ELF output,
    // we can pass nullptr for the bytes of the section/segment.
    auto const debug_segment_base2 =
        debug_dwarf_->elf()->AddText(instructions_symbol, /*bytes=*/nullptr,
                                     section_headers_size + text_offset);
    ASSERT(debug_segment_base2 == debug_segment_base);
  }

  assembly_stream_.Print(".bss\n");
  assembly_stream_.Print("%s:\n", bss_symbol);

  // Currently we only put one symbol in the data section, the address of
  // DLRT_GetThreadForNativeCallback, which is populated when the snapshot is
  // loaded.
  WriteWordLiteralText(0);
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
      vm ? "_kDartVmSnapshotData" : "_kDartIsolateSnapshotData";
  assembly_stream_.Print(".globl %s\n", data_symbol);
  Align(kMaxObjectAlignment);
  assembly_stream_.Print("%s:\n", data_symbol);
  uword buffer = reinterpret_cast<uword>(clustered_stream->buffer());
  intptr_t length = clustered_stream->bytes_written();
  WriteByteSequence(buffer, buffer + length);
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
                                 Dwarf* debug_dwarf,
                                 intptr_t bss_base,
                                 Elf* elf,
                                 Dwarf* elf_dwarf)
    : ImageWriter(thread->heap()),
      instructions_blob_stream_(instructions_blob_buffer, alloc, initial_size),
      elf_(elf),
      elf_dwarf_(elf_dwarf),
      bss_base_(bss_base),
      debug_dwarf_(debug_dwarf) {
#if defined(DART_PRECOMPILER)
  RELEASE_ASSERT(elf_ == nullptr || elf_dwarf_ == nullptr ||
                 elf_dwarf_->elf() == elf_);
#else
  RELEASE_ASSERT(elf_ == nullptr);
  RELEASE_ASSERT(elf_dwarf_ == nullptr);
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

#ifdef DART_PRECOMPILER
  intptr_t segment_base = 0;
  if (elf_ != nullptr) {
    segment_base = elf_->NextMemoryOffset();
  }
  intptr_t debug_segment_base = 0;
  if (debug_dwarf_ != nullptr) {
    debug_segment_base = debug_dwarf_->elf()->NextMemoryOffset();
  }
#endif

  // This header provides the gap to make the instructions snapshot look like a
  // HeapPage.
  const intptr_t image_size = Utils::RoundUp(
      next_text_offset_, compiler::target::ObjectAlignment::kObjectAlignment);
  instructions_blob_stream_.WriteTargetWord(image_size);
#if defined(DART_PRECOMPILER)
  instructions_blob_stream_.WriteTargetWord(
      elf_ != nullptr ? bss_base_ - segment_base : 0);
#else
  instructions_blob_stream_.WriteTargetWord(0);  // No relocations.
#endif
  const intptr_t header_words =
      Image::kHeaderSize / sizeof(compiler::target::uword);
  for (intptr_t i = Image::kHeaderFields; i < header_words; i++) {
    instructions_blob_stream_.WriteTargetWord(0);
  }

  if (bare_instruction_payloads) {
    const intptr_t section_size = image_size - Image::kHeaderSize;
    // Add the RawInstructionsSection header.
    const compiler::target::uword marked_tags =
        RawObject::OldBit::encode(true) |
        RawObject::OldAndNotMarkedBit::encode(false) |
        RawObject::OldAndNotRememberedBit::encode(true) |
        RawObject::NewBit::encode(false) |
        RawObject::SizeTag::encode(AdjustObjectSizeForTarget(section_size)) |
        RawObject::ClassIdTag::encode(kInstructionsSectionCid);
    instructions_blob_stream_.WriteTargetWord(marked_tags);
    // Uses next_text_offset_ to avoid any post-payload padding.
    const intptr_t instructions_length =
        next_text_offset_ - Image::kHeaderSize -
        compiler::target::InstructionsSection::HeaderSize();
    instructions_blob_stream_.WriteTargetWord(instructions_length);

    if (profile_writer_ != nullptr) {
      const intptr_t offset = Image::kHeaderSize;
      const intptr_t non_instruction_bytes =
          compiler::target::InstructionsSection::HeaderSize();
      profile_writer_->SetObjectTypeAndName({offset_space_, offset},
                                            "InstructionsSection",
                                            /*name=*/nullptr);
      profile_writer_->AttributeBytesTo({offset_space_, offset},
                                        non_instruction_bytes);
      profile_writer_->AddRoot({offset_space_, offset});
    }
  }

  intptr_t text_offset = 0;

#if defined(DART_PRECOMPILER)
  PcDescriptors& descriptors = PcDescriptors::Handle();
  AssemblyCodeNamer namer(Thread::Current()->zone());
#endif

  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT((data.text_offset_ - instructions_[0].text_offset_) == text_offset);

    if (bare_instruction_payloads && profile_writer_ != nullptr) {
      const intptr_t instructions_sections_offset = Image::kHeaderSize;
      profile_writer_->AttributeReferenceTo(
          {offset_space_, instructions_sections_offset},
          {{offset_space_, instructions_blob_stream_.Position()},
           V8SnapshotProfileWriter::Reference::kElement,
           text_offset});
    }

    if (is_trampoline) {
      const auto start = reinterpret_cast<uword>(data.trampoline_bytes);
      const auto end = start + data.trampline_length;
      text_offset += WriteByteSequence(start, end);
      delete[] data.trampoline_bytes;
      data.trampoline_bytes = nullptr;
      continue;
    }

    const intptr_t instr_start = text_offset;

    const Instructions& insns = *instructions_[i].insns_;
    AutoTraceImage(insns, 0, &this->instructions_blob_stream_);
    const uword payload_start = insns.PayloadStart();

    ASSERT(Utils::IsAligned(payload_start, sizeof(compiler::target::uword)));

    // Write Instructions with the mark and read-only bits set.
    uword marked_tags = insns.raw_ptr()->tags_;
    marked_tags = RawObject::OldBit::update(true, marked_tags);
    marked_tags = RawObject::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags = RawObject::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = RawObject::NewBit::update(false, marked_tags);
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
    const intptr_t payload_stream_start = instructions_blob_stream_.Position();
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
    const intptr_t payload_stream_start = instructions_blob_stream_.Position();
    text_offset += WriteByteSequence(payload_start, object_end);
#endif

#if defined(DART_PRECOMPILER)
    if (elf_ != nullptr && elf_dwarf_ != nullptr) {
      const auto& code = *instructions_[i].code_;
      auto const virtual_address = segment_base + payload_stream_start;
      elf_dwarf_->AddCode(code, virtual_address);
      elf_->AddStaticSymbol(elf_->NextSectionIndex(),
                            namer.AssemblyNameFor(i, code), virtual_address);
    }
    if (debug_dwarf_ != nullptr) {
      const auto& code = *instructions_[i].code_;
      auto const virtual_address = debug_segment_base + payload_stream_start;
      debug_dwarf_->AddCode(code, virtual_address);
    }

    // Don't patch the relocation if we're not generating ELF. The regular blobs
    // format does not yet support these relocations. Use
    // Code::VerifyBSSRelocations to check whether the relocations are patched
    // or not after loading.
    if (elf_ != nullptr) {
      const intptr_t current_stream_position =
          instructions_blob_stream_.Position();

      descriptors = data.code_->pc_descriptors();

      PcDescriptors::Iterator iterator(
          descriptors, /*kind_mask=*/RawPcDescriptors::kBSSRelocation);

      while (iterator.MoveNext()) {
        const intptr_t reloc_offset = iterator.PcOffset();

        // The instruction stream at the relocation position holds an offset
        // into BSS corresponding to the symbol being resolved. This addend is
        // factored into the relocation.
        const auto addend = *reinterpret_cast<compiler::target::word*>(
            insns.PayloadStart() + reloc_offset);

        // Overwrite the relocation position in the instruction stream with the
        // (positive) offset of the start of the payload from the start of the
        // BSS segment plus the addend in the relocation.
        instructions_blob_stream_.SetPosition(payload_stream_start +
                                              reloc_offset);

        const compiler::target::word offset =
            bss_base_ - (segment_base + payload_stream_start + reloc_offset) +
            addend;
        instructions_blob_stream_.WriteTargetWord(offset);
      }

      // Restore stream position after the relocation was patched.
      instructions_blob_stream_.SetPosition(current_stream_position);
    }
#else
    USE(payload_stream_start);
#endif

    ASSERT((text_offset - instr_start) ==
           ImageWriter::SizeInSnapshot(insns.raw()));
  }

  // Should be a no-op unless writing bare instruction payloads, in which case
  // we need to add post-payload padding to the object alignment. The alignment
  // should match the alignment used in image_size above.
  instructions_blob_stream_.Align(
      compiler::target::ObjectAlignment::kObjectAlignment);

  ASSERT_EQUAL(instructions_blob_stream_.bytes_written(), image_size);

#ifdef DART_PRECOMPILER
  const char* instructions_symbol =
      vm ? "_kDartVmSnapshotInstructions" : "_kDartIsolateSnapshotInstructions";
  if (elf_ != nullptr) {
    auto const segment_base2 =
        elf_->AddText(instructions_symbol, instructions_blob_stream_.buffer(),
                      instructions_blob_stream_.bytes_written());
    ASSERT(segment_base == segment_base2);
  }
  if (debug_dwarf_ != nullptr) {
    auto const debug_segment_base2 = debug_dwarf_->elf()->AddText(
        instructions_symbol, instructions_blob_stream_.buffer(),
        instructions_blob_stream_.bytes_written());
    ASSERT(debug_segment_base == debug_segment_base2);
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

RawApiError* ImageReader::VerifyAlignment() const {
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

RawInstructions* ImageReader::GetInstructionsAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  RawObject* result = RawObject::FromAddr(
      reinterpret_cast<uword>(instructions_image_) + offset);
  ASSERT(result->IsInstructions());
  ASSERT(result->IsMarked());

  return Instructions::RawCast(result);
}

RawObject* ImageReader::GetObjectAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  RawObject* result =
      RawObject::FromAddr(reinterpret_cast<uword>(data_image_) + offset);
  ASSERT(result->IsMarked());

  return result;
}

}  // namespace dart
