// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/image_snapshot.h"

#include "platform/assert.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/dwarf.h"
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

DEFINE_FLAG(bool,
            trace_reused_instructions,
            false,
            "Print code that lacks reusable instructions");

intptr_t ObjectOffsetTrait::Hashcode(Key key) {
  RawObject* obj = key;
  ASSERT(!obj->IsSmi());

  uword body = RawObject::ToAddr(obj) + sizeof(RawObject);
  uword end = RawObject::ToAddr(obj) + obj->Size();

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

  intptr_t heap_size = a->Size();
  if (b->Size() != heap_size) {
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

ImageWriter::ImageWriter(Heap* heap,
                         const void* shared_objects,
                         const void* shared_instructions,
                         const void* reused_instructions)
    : heap_(heap),
      next_data_offset_(0),
      next_text_offset_(0),
      objects_(),
      instructions_() {
  ResetOffsets();
  SetupShared(&shared_objects_, shared_objects);
  SetupShared(&shared_instructions_, shared_instructions);
  SetupShared(&reuse_instructions_, reused_instructions);
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
          next_text_offset_ += instructions->Size();
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

void ImageWriter::SetupShared(ObjectOffsetMap* map, const void* shared_image) {
  if (shared_image == NULL) {
    return;
  }
  Image image(shared_image);
  uword obj_addr = reinterpret_cast<uword>(image.object_start());
  uword end_addr = obj_addr + image.object_size();
  while (obj_addr < end_addr) {
    int32_t offset = obj_addr - reinterpret_cast<uword>(shared_image);
    RawObject* raw_obj = RawObject::FromAddr(obj_addr);
    ObjectOffsetPair pair;
    pair.object = raw_obj;
    pair.offset = offset;
    map->Insert(pair);
    obj_addr += raw_obj->Size();
  }
  ASSERT(obj_addr == end_addr);
}

int32_t ImageWriter::GetTextOffsetFor(RawInstructions* instructions,
                                      RawCode* code) {
  intptr_t offset = heap_->GetObjectId(instructions);
  if (offset != 0) {
    return offset;
  }

  if (!reuse_instructions_.IsEmpty()) {
    ObjectOffsetPair* pair = reuse_instructions_.Lookup(instructions);
    if (pair == NULL) {
      // Code should have been removed by DropCodeWithoutReusableInstructions.
      FATAL("Expected instructions to reuse\n");
    }
    return pair->offset;
  }

  ObjectOffsetPair* pair = shared_instructions_.Lookup(instructions);
  if (pair != NULL) {
    // Negative offsets tell the reader the offset is w/r/t the shared
    // instructions image instead of the app-specific instructions image.
    // Compare ImageReader::GetInstructionsAt.
    return -pair->offset;
  }

  offset = next_text_offset_;
  heap_->SetObjectId(instructions, offset);
  next_text_offset_ += instructions->Size();
  instructions_.Add(InstructionsData(instructions, code, offset));

  return offset;
}

bool ImageWriter::GetSharedDataOffsetFor(RawObject* raw_object,
                                         uint32_t* offset) {
  ObjectOffsetPair* pair = shared_objects_.Lookup(raw_object);
  if (pair == NULL) {
    return false;
  }
  *offset = pair->offset;
  return true;
}

uint32_t ImageWriter::GetDataOffsetFor(RawObject* raw_object) {
  intptr_t heap_size = raw_object->Size();
  intptr_t offset = next_data_offset_;
  next_data_offset_ += heap_size;
  objects_.Add(ObjectData(raw_object));
  return offset;
}

#if defined(DART_PRECOMPILER)
void ImageWriter::DumpInstructionStats() {
  CombinedCodeStatistics instruction_stats;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    CodeStatistics* stats = data.insns_->stats();
    if (stats != nullptr) {
      stats->AppendTo(&instruction_stats);
    }
  }
  instruction_stats.DumpStatistics();
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
    if (data.code_->IsNull()) {
      // TODO(34650): Type testing stubs are added to the serializer without
      // their Code.
      continue;
    }
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
    js.PrintProperty("s", data.insns_->Size());
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
  stream->Align(OS::kMaxPreferredCodeAlignment);

  // Heap page starts here.

  intptr_t section_start = stream->Position();

  stream->WriteWord(next_data_offset_);  // Data length.
  COMPILE_ASSERT(OS::kMaxPreferredCodeAlignment >= kObjectAlignment);
  stream->Align(OS::kMaxPreferredCodeAlignment);

  ASSERT(stream->Position() - section_start == Image::kHeaderSize);

  // Heap page objects start here.

  for (intptr_t i = 0; i < objects_.length(); i++) {
    const Object& obj = *objects_[i].obj_;
    AutoTraceImage(obj, section_start, stream);

    NoSafepointScope no_safepoint;
    uword start = reinterpret_cast<uword>(obj.raw()) - kHeapObjectTag;
    uword end = start + obj.raw()->Size();

    // Write object header with the mark and VM heap bits set.
    uword marked_tags = obj.raw()->ptr()->tags_;
    marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
    marked_tags = RawObject::OldBit::update(true, marked_tags);
    marked_tags = RawObject::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags = RawObject::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = RawObject::NewBit::update(false, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    marked_tags |= static_cast<uword>(obj.raw()->ptr()->hash_) << 32;
#endif
    stream->WriteWord(marked_tags);
    start += sizeof(uword);
    for (uword* cursor = reinterpret_cast<uword*>(start);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      stream->WriteWord(*cursor);
    }
  }
}

AssemblyImageWriter::AssemblyImageWriter(Thread* thread,
                                         Dart_StreamingWriteCallback callback,
                                         void* callback_data,
                                         const void* shared_objects,
                                         const void* shared_instructions)
    : ImageWriter(thread->heap(), shared_objects, shared_instructions, nullptr),
      assembly_stream_(512 * KB, callback, callback_data),
      dwarf_(NULL) {
#if defined(DART_PRECOMPILER)
  Zone* zone = Thread::Current()->zone();
  dwarf_ = new (zone) Dwarf(zone, &assembly_stream_);
#endif
}

void AssemblyImageWriter::Finalize() {
#ifdef DART_PRECOMPILER
  dwarf_->Write();
#endif
}

static void EnsureAssemblerIdentifier(char* label) {
  for (char c = *label; c != '\0'; c = *++label) {
    if (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) ||
        ((c >= '0') && (c <= '9'))) {
      continue;
    }
    *label = '_';
  }
}

const char* NameOfStubIsolateSpecificStub(ObjectStore* object_store,
                                          const Code& code) {
  if (code.raw() == object_store->build_method_extractor_code()) {
    return "_iso_stub_BuildMethodExtractorStub";
  } else if (code.raw() == object_store->null_error_stub_with_fpu_regs_stub()) {
    return "_iso_stub_NullErrorSharedWithFPURegsStub";
  } else if (code.raw() ==
             object_store->null_error_stub_without_fpu_regs_stub()) {
    return "_iso_stub_NullErrorSharedWithoutFPURegsStub";
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

void AssemblyImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  Zone* zone = Thread::Current()->zone();

  const char* instructions_symbol =
      vm ? "_kDartVmSnapshotInstructions" : "_kDartIsolateSnapshotInstructions";
  assembly_stream_.Print(".text\n");
  assembly_stream_.Print(".globl %s\n", instructions_symbol);

  // Start snapshot at page boundary.
  ASSERT(VirtualMemory::PageSize() >= OS::kMaxPreferredCodeAlignment);
  assembly_stream_.Print(".balign %" Pd ", 0\n", VirtualMemory::PageSize());
  assembly_stream_.Print("%s:\n", instructions_symbol);

  // This head also provides the gap to make the instructions snapshot
  // look like a HeapPage.
  intptr_t instructions_length = next_text_offset_;
  WriteWordLiteralText(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    WriteWordLiteralText(0);
  }

  FrameUnwindPrologue();

  Object& owner = Object::Handle(zone);
  String& str = String::Handle(zone);

  ObjectStore* object_store = Isolate::Current()->object_store();

  TypeTestingStubNamer tts;
  intptr_t text_offset = 0;

  ASSERT(offset_space_ != V8SnapshotProfileWriter::kSnapshot);
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT((data.text_offset_ - instructions_[0].text_offset_) == text_offset);

    if (is_trampoline) {
      if (profile_writer_ != nullptr) {
        const intptr_t offset = Image::kHeaderSize + text_offset;
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

    if (profile_writer_ != nullptr) {
      const intptr_t offset = Image::kHeaderSize + text_offset;
      profile_writer_->SetObjectTypeAndName({offset_space_, offset},
                                            "Instructions",
                                            /*name=*/nullptr);
      profile_writer_->AttributeBytesTo({offset_space_, offset},
                                        insns.raw()->Size());
    }

    ASSERT(insns.raw()->Size() % sizeof(uint64_t) == 0);

    // 1. Write from the header to the entry point.
    {
      NoSafepointScope no_safepoint;

      uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
      uword entry = beginning + Instructions::HeaderSize();

      // Write Instructions with the mark and VM heap bits set.
      uword marked_tags = insns.raw_ptr()->tags_;
      marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
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

      WriteWordLiteralText(marked_tags);
      beginning += sizeof(uword);
      text_offset += sizeof(uword);
      text_offset += WriteByteSequence(beginning, entry);

      ASSERT((text_offset - instr_start) == insns.HeaderSize());
    }

    // 2. Write a label at the entry point.
    // Linux's perf uses these labels.
    ASSERT(!code.IsNull());
    owner = code.owner();
    if (owner.IsNull()) {
      const char* name = StubCode::NameOfStub(insns.EntryPoint());
      if (name != nullptr) {
        assembly_stream_.Print("Precompiled_Stub_%s:\n", name);
      } else {
        if (name == nullptr) {
          name = NameOfStubIsolateSpecificStub(object_store, code);
        }
        ASSERT(name != nullptr);
        assembly_stream_.Print("Precompiled__%s:\n", name);
      }
    } else if (owner.IsClass()) {
      str = Class::Cast(owner).Name();
      const char* name = str.ToCString();
      EnsureAssemblerIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_AllocationStub_%s_%" Pd ":\n", name,
                             i);
    } else if (owner.IsAbstractType()) {
      const char* name = tts.StubNameForType(AbstractType::Cast(owner));
      assembly_stream_.Print("Precompiled_%s:\n", name);
    } else if (owner.IsFunction()) {
      const char* name = Function::Cast(owner).ToQualifiedCString();
      EnsureAssemblerIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_%s_%" Pd ":\n", name, i);
    } else {
      UNREACHABLE();
    }

#ifdef DART_PRECOMPILER
    // Create a label for use by DWARF.
    if (!code.IsNull()) {
      const intptr_t dwarf_index = dwarf_->AddCode(code);
      assembly_stream_.Print(".Lcode%" Pd ":\n", dwarf_index);
    }
#endif

    {
      // 3. Write from the entry point to the end.
      NoSafepointScope no_safepoint;
      uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
      uword entry = beginning + Instructions::HeaderSize();
      uword payload_size = insns.raw()->Size() - insns.HeaderSize();
      uword end = entry + payload_size;

      ASSERT(Utils::IsAligned(beginning, sizeof(uword)));
      ASSERT(Utils::IsAligned(entry, sizeof(uword)));
      ASSERT(Utils::IsAligned(end, sizeof(uword)));

      text_offset += WriteByteSequence(entry, end);
    }

    ASSERT((text_offset - instr_start) == insns.raw()->Size());
  }

  FrameUnwindEpilogue();

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
  assembly_stream_.Print(".balign %" Pd ", 0\n",
                         OS::kMaxPreferredCodeAlignment);
  assembly_stream_.Print("%s:\n", data_symbol);
  uword buffer = reinterpret_cast<uword>(clustered_stream->buffer());
  intptr_t length = clustered_stream->bytes_written();
  WriteByteSequence(buffer, buffer + length);
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
  for (uword* cursor = reinterpret_cast<uword*>(start);
       cursor < reinterpret_cast<uword*>(end); cursor++) {
    WriteWordLiteralText(*cursor);
  }
  return end - start;
}

BlobImageWriter::BlobImageWriter(Thread* thread,
                                 uint8_t** instructions_blob_buffer,
                                 ReAlloc alloc,
                                 intptr_t initial_size,
                                 const void* shared_objects,
                                 const void* shared_instructions,
                                 const void* reused_instructions)
    : ImageWriter(thread->heap(),
                  shared_objects,
                  shared_instructions,
                  reused_instructions),
      instructions_blob_stream_(instructions_blob_buffer, alloc, initial_size) {
}

intptr_t BlobImageWriter::WriteByteSequence(uword start, uword end) {
  for (uword* cursor = reinterpret_cast<uword*>(start);
       cursor < reinterpret_cast<uword*>(end); cursor++) {
    instructions_blob_stream_.WriteWord(*cursor);
  }
  return end - start;
}

void BlobImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  // This header provides the gap to make the instructions snapshot look like a
  // HeapPage.
  intptr_t instructions_length = next_text_offset_;
  instructions_blob_stream_.WriteWord(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    instructions_blob_stream_.WriteWord(0);
  }

  intptr_t text_offset = 0;

  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT((data.text_offset_ - instructions_[0].text_offset_) == text_offset);

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

    uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
    uword entry = beginning + Instructions::HeaderSize();
    uword payload_size = insns.Size();
    payload_size = Utils::RoundUp(payload_size, OS::PreferredCodeAlignment());
    uword end = entry + payload_size;

    ASSERT(Utils::IsAligned(beginning, sizeof(uword)));
    ASSERT(Utils::IsAligned(entry, sizeof(uword)));

    // Write Instructions with the mark and VM heap bits set.
    uword marked_tags = insns.raw_ptr()->tags_;
    marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
    marked_tags = RawObject::OldBit::update(true, marked_tags);
    marked_tags = RawObject::OldAndNotMarkedBit::update(false, marked_tags);
    marked_tags = RawObject::OldAndNotRememberedBit::update(true, marked_tags);
    marked_tags = RawObject::NewBit::update(false, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    // Can't use GetObjectTagsAndHash because the update methods discard the
    // high bits.
    marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

    instructions_blob_stream_.WriteWord(marked_tags);
    text_offset += sizeof(uword);
    beginning += sizeof(uword);
    text_offset += WriteByteSequence(beginning, end);

    ASSERT((text_offset - instr_start) == insns.raw()->Size());
  }
}

ImageReader::ImageReader(const uint8_t* data_image,
                         const uint8_t* instructions_image,
                         const uint8_t* shared_data_image,
                         const uint8_t* shared_instructions_image)
    : data_image_(data_image),
      instructions_image_(instructions_image),
      shared_data_image_(shared_data_image),
      shared_instructions_image_(shared_instructions_image) {
  ASSERT(data_image != NULL);
  ASSERT(instructions_image != NULL);
}

RawApiError* ImageReader::VerifyAlignment() const {
  if (!Utils::IsAligned(data_image_, kObjectAlignment) ||
      !Utils::IsAligned(shared_data_image_, kObjectAlignment) ||
      !Utils::IsAligned(instructions_image_, OS::PreferredCodeAlignment()) ||
      !Utils::IsAligned(shared_instructions_image_,
                        OS::PreferredCodeAlignment())) {
    return ApiError::New(
        String::Handle(String::New("Snapshot is misaligned", Heap::kOld)),
        Heap::kOld);
  }
  return ApiError::null();
}

RawInstructions* ImageReader::GetInstructionsAt(int32_t offset) const {
  ASSERT(Utils::IsAligned(offset, OS::PreferredCodeAlignment()));

  RawObject* result;
  if (offset < 0) {
    result = RawObject::FromAddr(
        reinterpret_cast<uword>(shared_instructions_image_) - offset);
  } else {
    result = RawObject::FromAddr(reinterpret_cast<uword>(instructions_image_) +
                                 offset);
  }
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

RawObject* ImageReader::GetSharedObjectAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  RawObject* result =
      RawObject::FromAddr(reinterpret_cast<uword>(shared_data_image_) + offset);
  ASSERT(result->IsMarked());

  return result;
}

void DropCodeWithoutReusableInstructions(const void* reused_instructions) {
  class DropCodeVisitor : public FunctionVisitor, public ClassVisitor {
   public:
    explicit DropCodeVisitor(const void* reused_instructions)
        : code_(Code::Handle()), instructions_(Instructions::Handle()) {
      ImageWriter::SetupShared(&reused_instructions_, reused_instructions);
      if (FLAG_trace_reused_instructions) {
        OS::PrintErr("%" Pd " reusable instructions\n",
                     reused_instructions_.Size());
      }
    }

    void Visit(const Class& cls) {
      code_ = cls.allocation_stub();
      if (!code_.IsNull() && !IsAvailable(code_)) {
        if (FLAG_trace_reused_instructions) {
          OS::PrintErr("No reusable instructions for %s\n", cls.ToCString());
        }
        cls.DisableAllocationStub();
      }
    }

    void Visit(const Function& func) {
      if (func.HasCode()) {
        code_ = func.CurrentCode();
        if (!IsAvailable(code_)) {
          if (FLAG_trace_reused_instructions) {
            OS::PrintErr("No reusable instructions for %s\n", func.ToCString());
          }
          func.ClearCode();
          func.ClearICDataArray();
          return;
        }
      }
      code_ = func.unoptimized_code();
      if (!code_.IsNull() && !IsAvailable(code_)) {
        if (FLAG_trace_reused_instructions) {
          OS::PrintErr("No reusable instructions for %s\n", func.ToCString());
        }
        func.ClearCode();
        func.ClearICDataArray();
        return;
      }
    }

   private:
    bool IsAvailable(const Code& code) {
      ObjectOffsetPair* pair = reused_instructions_.Lookup(code.instructions());
      return pair != NULL;
    }

    ObjectOffsetMap reused_instructions_;
    Code& code_;
    Instructions& instructions_;

    DISALLOW_COPY_AND_ASSIGN(DropCodeVisitor);
  };

  DropCodeVisitor visitor(reused_instructions);
  ProgramVisitor::VisitClasses(&visitor);
  ProgramVisitor::VisitFunctions(&visitor);
}

}  // namespace dart
