// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/image_snapshot.h"

#include "platform/assert.h"
#include "vm/dwarf.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/stub_code.h"
#include "vm/timeline.h"

namespace dart {

int32_t ImageWriter::GetTextOffsetFor(RawInstructions* instructions,
                                      RawCode* code) {
  intptr_t heap_size = instructions->Size();
  intptr_t offset = next_offset_;
  next_offset_ += heap_size;
  instructions_.Add(InstructionsData(instructions, code, offset));
  return offset;
}

int32_t ImageWriter::GetDataOffsetFor(RawObject* raw_object) {
  intptr_t heap_size = raw_object->Size();
  intptr_t offset = next_object_offset_;
  next_object_offset_ += heap_size;
  objects_.Add(ObjectData(raw_object));
  return offset;
}

void ImageWriter::Write(WriteStream* clustered_stream, bool vm) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Heap* heap = thread->isolate()->heap();
  NOT_IN_PRODUCT(TimelineDurationScope tds(thread, Timeline::GetIsolateStream(),
                                           "WriteInstructions"));

  // Handlify collected raw pointers as building the names below
  // will allocate on the Dart heap.
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    InstructionsData& data = instructions_[i];
    data.insns_ = &Instructions::Handle(zone, data.raw_insns_);
    ASSERT(data.raw_code_ != NULL);
    data.code_ = &Code::Handle(zone, data.raw_code_);

    // Update object id table with offsets that will refer to the VM snapshot,
    // causing a subsequently written isolate snapshot to share instructions
    // with the VM snapshot.
    heap->SetObjectId(data.insns_->raw(), -data.offset_);
  }
  for (intptr_t i = 0; i < objects_.length(); i++) {
    ObjectData& data = objects_[i];
    data.obj_ = &Object::Handle(zone, data.raw_obj_);
  }

  // Append the direct-mapped RO data objects after the clustered snapshot.
  WriteROData(clustered_stream);

  WriteText(clustered_stream, vm);
}

void ImageWriter::WriteROData(WriteStream* stream) {
  stream->Align(OS::kMaxPreferredCodeAlignment);

  // Heap page starts here.

  stream->WriteWord(next_object_offset_);  // Data length.
  COMPILE_ASSERT(OS::kMaxPreferredCodeAlignment >= kObjectAlignment);
  stream->Align(OS::kMaxPreferredCodeAlignment);

  // Heap page objects start here.

  for (intptr_t i = 0; i < objects_.length(); i++) {
    const Object& obj = *objects_[i].obj_;

    NoSafepointScope no_safepoint;
    uword start = reinterpret_cast<uword>(obj.raw()) - kHeapObjectTag;
    uword end = start + obj.raw()->Size();

    // Write object header with the mark and VM heap bits set.
    uword marked_tags = obj.raw()->ptr()->tags_;
    marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
    marked_tags = RawObject::MarkBit::update(true, marked_tags);
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

AssemblyImageWriter::AssemblyImageWriter(uint8_t** assembly_buffer,
                                         ReAlloc alloc,
                                         intptr_t initial_size)
    : ImageWriter(),
      assembly_stream_(assembly_buffer, alloc, initial_size),
      text_size_(0),
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

static void EnsureIdentifier(char* label) {
  for (char c = *label; c != '\0'; c = *++label) {
    if (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) ||
        ((c >= '0') && (c <= '9'))) {
      continue;
    }
    *label = '_';
  }
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
  intptr_t instructions_length = next_offset_;
  WriteWordLiteralText(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    WriteWordLiteralText(0);
  }

  FrameUnwindPrologue();

  Object& owner = Object::Handle(zone);
  String& str = String::Handle(zone);

  for (intptr_t i = 0; i < instructions_.length(); i++) {
    const Instructions& insns = *instructions_[i].insns_;
    const Code& code = *instructions_[i].code_;

    ASSERT(insns.raw()->Size() % sizeof(uint64_t) == 0);

    // 1. Write from the header to the entry point.
    {
      NoSafepointScope no_safepoint;

      uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
      uword entry = beginning + Instructions::HeaderSize();

      // Write Instructions with the mark and VM heap bits set.
      uword marked_tags = insns.raw_ptr()->tags_;
      marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
      marked_tags = RawObject::MarkBit::update(true, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
      // Can't use GetObjectTagsAndHash because the update methods discard the
      // high bits.
      marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

      WriteWordLiteralText(marked_tags);
      beginning += sizeof(uword);

      WriteByteSequence(beginning, entry);
    }

    // 2. Write a label at the entry point.
    // Linux's perf uses these labels.
    owner = code.owner();
    if (owner.IsNull()) {
      const char* name = StubCode::NameOfStub(insns.UncheckedEntryPoint());
      assembly_stream_.Print("Precompiled_Stub_%s:\n", name);
    } else if (owner.IsClass()) {
      str = Class::Cast(owner).Name();
      const char* name = str.ToCString();
      EnsureIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_AllocationStub_%s_%" Pd ":\n", name,
                             i);
    } else if (owner.IsFunction()) {
      const char* name = Function::Cast(owner).ToQualifiedCString();
      EnsureIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_%s_%" Pd ":\n", name, i);
    } else {
      UNREACHABLE();
    }

#ifdef DART_PRECOMPILER
    // Create a label for use by DWARF.
    intptr_t dwarf_index = dwarf_->AddCode(code);
    assembly_stream_.Print(".Lcode%" Pd ":\n", dwarf_index);
#endif

    {
      // 3. Write from the entry point to the end.
      NoSafepointScope no_safepoint;
      uword beginning = reinterpret_cast<uword>(insns.raw()) - kHeapObjectTag;
      uword entry = beginning + Instructions::HeaderSize();
      uword payload_size = insns.Size();
      payload_size = Utils::RoundUp(payload_size, OS::PreferredCodeAlignment());
      uword end = entry + payload_size;

      ASSERT(Utils::IsAligned(beginning, sizeof(uword)));
      ASSERT(Utils::IsAligned(entry, sizeof(uword)));
      ASSERT(Utils::IsAligned(end, sizeof(uword)));

      WriteByteSequence(entry, end);
    }
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

void AssemblyImageWriter::WriteByteSequence(uword start, uword end) {
  for (uword* cursor = reinterpret_cast<uword*>(start);
       cursor < reinterpret_cast<uword*>(end); cursor++) {
    WriteWordLiteralText(*cursor);
  }
}

void BlobImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  // This header provides the gap to make the instructions snapshot look like a
  // HeapPage.
  intptr_t instructions_length = next_offset_;
  instructions_blob_stream_.WriteWord(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    instructions_blob_stream_.WriteWord(0);
  }

  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    const Instructions& insns = *instructions_[i].insns_;

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
    marked_tags = RawObject::MarkBit::update(true, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    // Can't use GetObjectTagsAndHash because the update methods discard the
    // high bits.
    marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

    instructions_blob_stream_.WriteWord(marked_tags);
    beginning += sizeof(uword);

    for (uword* cursor = reinterpret_cast<uword*>(beginning);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      instructions_blob_stream_.WriteWord(*cursor);
    }
  }
}

ImageReader::ImageReader(const uint8_t* instructions_buffer,
                         const uint8_t* data_buffer)
    : instructions_buffer_(instructions_buffer), data_buffer_(data_buffer) {
  ASSERT(instructions_buffer != NULL);
  ASSERT(data_buffer != NULL);
  ASSERT(Utils::IsAligned(reinterpret_cast<uword>(instructions_buffer),
                          OS::PreferredCodeAlignment()));
  vm_instructions_buffer_ = Dart::vm_snapshot_instructions();
}

RawInstructions* ImageReader::GetInstructionsAt(int32_t offset) const {
  ASSERT(Utils::IsAligned(offset, OS::PreferredCodeAlignment()));

  RawInstructions* result;
  if (offset < 0) {
    result = reinterpret_cast<RawInstructions*>(
        reinterpret_cast<uword>(vm_instructions_buffer_) - offset +
        kHeapObjectTag);
  } else {
    result = reinterpret_cast<RawInstructions*>(
        reinterpret_cast<uword>(instructions_buffer_) + offset +
        kHeapObjectTag);
  }
  ASSERT(result->IsInstructions());
  ASSERT(result->IsMarked());

  return result;
}

RawObject* ImageReader::GetObjectAt(int32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kWordSize));

  RawObject* result = reinterpret_cast<RawObject*>(
      reinterpret_cast<uword>(data_buffer_) + offset + kHeapObjectTag);
  ASSERT(result->IsMarked());

  return result;
}

}  // namespace dart
