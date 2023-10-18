// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/image_snapshot.h"

#include "include/dart_api.h"
#include "platform/assert.h"
#include "platform/elf.h"
#include "vm/bss_relocs.h"
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
#include "vm/zone_text_buffer.h"

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
            nullptr,
            "Print sizes of all instruction objects to the given file");
#endif

const UntaggedInstructionsSection* Image::ExtraInfo(const uword raw_memory,
                                                    const uword size) {
#if defined(DART_PRECOMPILED_RUNTIME)
  auto const raw_value =
      FieldValue(raw_memory, HeaderField::InstructionsSectionOffset);
  if (raw_value != kNoInstructionsSection) {
    ASSERT(raw_value >= kHeaderSize);
    ASSERT(raw_value <= size - InstructionsSection::HeaderSize());
    auto const layout = reinterpret_cast<const UntaggedInstructionsSection*>(
        raw_memory + raw_value);
    // The instructions section is likely non-empty in bare instructions mode
    // (unless splitting into multiple outputs and there are no Code objects
    // in this particular output), but is guaranteed empty otherwise (the
    // instructions follow the InstructionsSection object instead).
    ASSERT(raw_value <=
           size - InstructionsSection::InstanceSize(layout->payload_length_));
    return layout;
  }
#endif
  return nullptr;
}

uword* Image::bss() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(extra_info_ != nullptr);
  // There should always be a non-zero BSS offset.
  ASSERT(extra_info_->bss_offset_ != 0);
  // Returning a non-const uword* is safe because we're translating from
  // the start of the instructions (read-only) to the start of the BSS
  // (read-write).
  return reinterpret_cast<uword*>(raw_memory_ + extra_info_->bss_offset_);
#else
  return nullptr;
#endif
}

uword Image::instructions_relocated_address() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(extra_info_ != nullptr);
  // For assembly snapshots, we need to retrieve this from the initialized BSS.
  const uword address =
      compiled_to_elf() ? extra_info_->instructions_relocated_address_
                        : bss()[BSS::RelocationIndex(
                              BSS::Relocation::InstructionsRelocatedAddress)];
  ASSERT(address != kNoRelocatedAddress);
  return address;
#else
  return kNoRelocatedAddress;
#endif
}

const uint8_t* Image::build_id() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(extra_info_ != nullptr);
  if (extra_info_->build_id_offset_ != kNoBuildId) {
    auto const note = reinterpret_cast<elf::Note*>(
        raw_memory_ + extra_info_->build_id_offset_);
    return note->data + note->name_size;
  }
#endif
  return nullptr;
}

intptr_t Image::build_id_length() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(extra_info_ != nullptr);
  if (extra_info_->build_id_offset_ != kNoBuildId) {
    auto const note = reinterpret_cast<elf::Note*>(
        raw_memory_ + extra_info_->build_id_offset_);
    return note->description_size;
  }
#endif
  return 0;
}

bool Image::compiled_to_elf() const {
#if defined(DART_PRECOMPILED_RUNTIME)
  ASSERT(extra_info_ != nullptr);
  // Since assembly snapshots can't set up this field correctly (instead,
  // it's initialized in BSS at snapshot load time), we use it to detect
  // direct-to-ELF snapshots.
  return extra_info_->instructions_relocated_address_ != kNoRelocatedAddress;
#else
  return false;
#endif
}

uword ObjectOffsetTrait::Hash(Key key) {
  ObjectPtr obj = key;
  ASSERT(!obj->IsSmi());

  uword body = UntaggedObject::ToAddr(obj) + sizeof(UntaggedObject);
  uword end = UntaggedObject::ToAddr(obj) + obj->untag()->HeapSize();

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

  intptr_t heap_size = a->untag()->HeapSize();
  if (b->untag()->HeapSize() != heap_size) {
    return false;
  }

  // Don't include the header. Objects in the image are pre-marked, but objects
  // in the current isolate are not.
  uword body_a = UntaggedObject::ToAddr(a) + sizeof(UntaggedObject);
  uword body_b = UntaggedObject::ToAddr(b) + sizeof(UntaggedObject);
  uword body_size = heap_size - sizeof(UntaggedObject);
  return 0 == memcmp(reinterpret_cast<const void*>(body_a),
                     reinterpret_cast<const void*>(body_b), body_size);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DART_PRECOMPILER)
ImageWriter::ImageWriter(Thread* t,
                         bool generates_assembly,
                         const Trie<const char>* deobfuscation_trie)
#else
ImageWriter::ImageWriter(Thread* t, bool generates_assembly)
#endif
    : thread_(ASSERT_NOTNULL(t)),
      zone_(t->zone()),
      next_data_offset_(0),
      next_text_offset_(0),
      objects_(),
      instructions_(),
#if defined(DART_PRECOMPILER)
      namer_(t->zone(),
             deobfuscation_trie,
             /*for_assembly=*/generates_assembly),
#endif
      image_type_(TagObjectTypeAsReadOnly(zone_, "Image")),
      instructions_section_type_(
          TagObjectTypeAsReadOnly(zone_, "InstructionsSection")),
      instructions_type_(TagObjectTypeAsReadOnly(zone_, "Instructions")),
      trampoline_type_(TagObjectTypeAsReadOnly(zone_, "Trampoline")) {
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
          Heap* const heap = thread_->heap();
          CodePtr code = inst.insert_instruction_of_code.code;
          InstructionsPtr instructions = Code::InstructionsOf(code);
          const intptr_t offset = next_text_offset_;
          instructions_.Add(InstructionsData(instructions, code, offset));
          next_text_offset_ += SizeInSnapshot(instructions);
          ASSERT(heap->GetObjectId(instructions) == 0);
          heap->SetObjectId(instructions, offset);
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
  Heap* const heap = thread_->heap();
  intptr_t offset = heap->GetObjectId(instructions);
  if (offset != 0) {
    return offset;
  }

  offset = next_text_offset_;
  heap->SetObjectId(instructions, offset);
  next_text_offset_ += SizeInSnapshot(instructions);
  instructions_.Add(InstructionsData(instructions, code, offset));

  ASSERT(offset != 0);
  return offset;
}

intptr_t ImageWriter::SizeInSnapshotForBytes(intptr_t length) {
  // We are just going to write it out as a string.
  return compiler::target::String::InstanceSize(
      length * OneByteString::kBytesPerElement);
}

intptr_t ImageWriter::SizeInSnapshot(ObjectPtr raw_object) {
  const classid_t cid = raw_object->GetClassId();

  switch (cid) {
    case kCompressedStackMapsCid: {
      auto raw_maps = CompressedStackMaps::RawCast(raw_object);
      return compiler::target::CompressedStackMaps::InstanceSize(
          CompressedStackMaps::PayloadSizeOf(raw_maps));
    }
    case kCodeSourceMapCid: {
      auto raw_map = CodeSourceMap::RawCast(raw_object);
      return compiler::target::CodeSourceMap::InstanceSize(
          raw_map->untag()->length_);
    }
    case kPcDescriptorsCid: {
      auto raw_desc = PcDescriptors::RawCast(raw_object);
      return compiler::target::PcDescriptors::InstanceSize(
          raw_desc->untag()->length_);
    }
    case kInstructionsCid: {
      auto raw_insns = Instructions::RawCast(raw_object);
      return compiler::target::Instructions::InstanceSize(
          Instructions::Size(raw_insns));
    }
    case kOneByteStringCid: {
      auto raw_str = String::RawCast(raw_object);
      return compiler::target::String::InstanceSize(
          String::LengthOf(raw_str) * OneByteString::kBytesPerElement);
    }
    case kTwoByteStringCid: {
      auto raw_str = String::RawCast(raw_object);
      return compiler::target::String::InstanceSize(
          String::LengthOf(raw_str) * TwoByteString::kBytesPerElement);
    }
    default: {
      const Class& clazz = Class::Handle(Object::Handle(raw_object).clazz());
      FATAL("Unsupported class %s in rodata section.\n", clazz.ToCString());
      return 0;
    }
  }
}

#if defined(SNAPSHOT_BACKTRACE)
uint32_t ImageWriter::GetDataOffsetFor(ObjectPtr raw_object,
                                       ObjectPtr raw_parent) {
#else
uint32_t ImageWriter::GetDataOffsetFor(ObjectPtr raw_object) {
#endif
  const intptr_t snap_size = SizeInSnapshot(raw_object);
  const intptr_t offset = next_data_offset_;
  next_data_offset_ += snap_size;
#if defined(SNAPSHOT_BACKTRACE)
  objects_.Add(ObjectData(raw_object, raw_parent));
#else
  objects_.Add(ObjectData(raw_object));
#endif
  return offset;
}

uint32_t ImageWriter::AddBytesToData(uint8_t* bytes, intptr_t length) {
  const intptr_t snap_size = SizeInSnapshotForBytes(length);
  const intptr_t offset = next_data_offset_;
  next_data_offset_ += snap_size;
  objects_.Add(ObjectData(bytes, length));
  return offset;
}

intptr_t ImageWriter::GetTextObjectCount() const {
  return instructions_.length();
}

void ImageWriter::GetTrampolineInfo(intptr_t* count, intptr_t* size) const {
  ASSERT(count != nullptr && size != nullptr);
  *count = 0;
  *size = 0;
  for (auto const& data : instructions_) {
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
  REUSABLE_CLASS_HANDLESCOPE(thread_);
  REUSABLE_STRING_HANDLESCOPE(thread_);
  Class& klass = thread_->ClassHandle();
  String& name = thread_->StringHandle();
  klass = object.clazz();
  name = klass.UserVisibleName();
  auto const name_str = name.ToCString();
  return TagObjectTypeAsReadOnly(zone_, name_str);
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
  auto& cls = Class::Handle(zone_);
  auto& lib = Library::Handle(zone_);
  auto& owner = Object::Handle(zone_);
  auto& url = String::Handle(zone_);
  auto& name = String::Handle(zone_);
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
      cls ^= owner.ptr();
      name = cls.ScrubbedName();
      lib = cls.library();
      url = lib.url();
      js.PrintPropertyStr("l", url);
      js.PrintPropertyStr("c", name);
    }
    js.PrintProperty("n",
                     data.code_->QualifiedName(
                         NameFormattingParams::DisambiguatedWithoutClassName(
                             Object::kInternalName)));
    js.PrintProperty("s", SizeInSnapshot(data.insns_->ptr()));
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
    OS::PrintErr("warning: Could not access file callbacks.");
    return;
  }

  const char* filename = FLAG_print_instructions_sizes_to;
  void* file = file_open(filename, /*write=*/true);
  if (file == nullptr) {
    OS::PrintErr("warning: Failed to write instruction sizes: %s\n", filename);
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

void ImageWriter::Write(NonStreamingWriteStream* clustered_stream, bool vm) {
  Heap* heap = thread_->heap();
  TIMELINE_DURATION(thread_, Isolate, "WriteInstructions");

  // Handlify collected raw pointers as building the names below
  // will allocate on the Dart heap.
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    InstructionsData& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    if (is_trampoline) continue;

    data.insns_ = &Instructions::Handle(zone_, data.raw_insns_);
    ASSERT(data.raw_code_ != nullptr);
    data.code_ = &Code::Handle(zone_, data.raw_code_);

    // Reset object id as an isolate snapshot after a VM snapshot will not use
    // the VM snapshot's text image.
    heap->SetObjectId(data.insns_->ptr(), 0);
  }
  for (auto& data : objects_) {
    if (data.is_object()) {
      data.obj = &Object::Handle(zone_, data.raw_obj);
#if defined(SNAPSHOT_BACKTRACE)
      data.parent = &Object::Handle(zone_, data.raw_parent);
#endif
    }
  }

  // Once we have everything handlified we are going to do convert raw bytes
  // to string objects. String is used for simplicity as a bit container,
  // can't use TypedData because it has an internal pointer (data_) field.
  for (auto& data : objects_) {
    if (!data.is_object()) {
      const auto bytes = data.bytes;
      data.obj = &Object::Handle(
          zone_, OneByteString::New(bytes.buf, bytes.length, Heap::kOld));
#if defined(SNAPSHOT_BACKTRACE)
      data.parent = &Object::null_object();
#endif
      data.set_is_object(true);
      String::Cast(*data.obj).Hash();
      free(bytes.buf);
    }
  }

  // Needs to happen before WriteText, as we add information about the
  // BSSsection in the text section as an initial InstructionsSection object.
  WriteBss(vm);

  offset_space_ = vm ? IdSpace::kVmText : IdSpace::kIsolateText;
  WriteText(vm);

  // Append the direct-mapped RO data objects after the clustered snapshot
  // and then for ELF and assembly outputs, add appropriate sections with
  // that combined data.
  offset_space_ = vm ? IdSpace::kVmData : IdSpace::kIsolateData;
  WriteROData(clustered_stream, vm);
}

void ImageWriter::WriteROData(NonStreamingWriteStream* stream, bool vm) {
  ASSERT(Utils::IsAligned(stream->Position(), kRODataAlignment));
  // Heap page starts here.
  intptr_t section_start = stream->Position();

  stream->WriteWord(next_data_offset_);  // Data length.
  stream->WriteWord(Image::kNoInstructionsSection);
  // Zero values for the rest of the Image object header bytes.
  stream->Align(Image::kHeaderSize);
  ASSERT_EQUAL(stream->Position() - section_start, Image::kHeaderSize);
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    // Attribute the Image header to the artificial root.
    profile_writer_->AttributeBytesTo(
        V8SnapshotProfileWriter::kArtificialRootId, Image::kHeaderSize);
  }
#endif

  // Heap page objects start here.

  for (auto entry : objects_) {
    ASSERT(entry.is_object());
    const Object& obj = *entry.obj;
#if defined(DART_PRECOMPILER)
    AutoTraceImage(obj, section_start, stream);
    const char* object_name = namer_.SnapshotNameFor(entry);
#endif
    auto const object_start = stream->Position();

    NoSafepointScope no_safepoint;

    // Write object header with the mark and read-only bits set.
    stream->WriteTargetWord(GetMarkedTags(obj));
    if (obj.IsCompressedStackMaps()) {
      const CompressedStackMaps& map = CompressedStackMaps::Cast(obj);
      const intptr_t payload_size = map.payload_size();
      stream->WriteFixed<uint32_t>(
          map.ptr()->untag()->payload()->flags_and_size());
      stream->WriteBytes(map.ptr()->untag()->payload()->data(), payload_size);
    } else if (obj.IsCodeSourceMap()) {
      const CodeSourceMap& map = CodeSourceMap::Cast(obj);
      stream->WriteTargetWord(map.Length());
      ASSERT_EQUAL(stream->Position() - object_start,
                   compiler::target::CodeSourceMap::HeaderSize());
      stream->WriteBytes(map.Data(), map.Length());
    } else if (obj.IsPcDescriptors()) {
      const PcDescriptors& desc = PcDescriptors::Cast(obj);
      stream->WriteTargetWord(desc.Length());
      ASSERT_EQUAL(stream->Position() - object_start,
                   compiler::target::PcDescriptors::HeaderSize());
      stream->WriteBytes(desc.ptr()->untag()->data(), desc.Length());
    } else if (obj.IsString()) {
      const String& str = String::Cast(obj);
      RELEASE_ASSERT(String::GetCachedHash(str.ptr()) != 0);
      RELEASE_ASSERT(str.IsOneByteString() || str.IsTwoByteString());

#if !defined(HASH_IN_OBJECT_HEADER)
      stream->WriteTargetWord(static_cast<uword>(str.ptr()->untag()->hash()));
#endif
      stream->WriteTargetWord(static_cast<uword>(str.ptr()->untag()->length()));
      ASSERT_EQUAL(stream->Position() - object_start,
                   compiler::target::String::InstanceSize());
      stream->WriteBytes(
          str.IsOneByteString()
              ? static_cast<const void*>(OneByteString::DataStart(str))
              : static_cast<const void*>(TwoByteString::DataStart(str)),
          str.Length() * (str.IsOneByteString()
                              ? OneByteString::kBytesPerElement
                              : TwoByteString::kBytesPerElement));
    } else {
      const Class& clazz = Class::Handle(obj.clazz());
      FATAL("Unsupported class %s in rodata section.\n", clazz.ToCString());
    }
    stream->Align(compiler::target::ObjectAlignment::kObjectAlignment);
    ASSERT_EQUAL(stream->Position() - object_start, SizeInSnapshot(obj));
#if defined(DART_PRECOMPILER)
    AddDataSymbol(object_name, object_start, stream->Position() - object_start);
#endif
  }
}

static constexpr uword kReadOnlyGCBits =
    UntaggedObject::OldBit::encode(true) |
    UntaggedObject::OldAndNotMarkedBit::encode(false) |
    UntaggedObject::OldAndNotRememberedBit::encode(true) |
    UntaggedObject::NewBit::encode(false);

uword ImageWriter::GetMarkedTags(classid_t cid,
                                 intptr_t size,
                                 bool is_canonical /* = false */) {
  // UntaggedObject::SizeTag expects a size divisible by kObjectAlignment and
  // checks this in debug mode, but the size on the target machine may not be
  // divisible by the host machine's object alignment if they differ.
  //
  // We define [adjusted_size] as [size] * m, where m is the host alignment
  // divided by the target alignment. This means [adjusted_size] encodes on the
  // host machine to the same bits that decode to [size] on the target machine.
  // That is,
  //    [adjusted_size] / host align ==
  //    [size] * (host align / target align) / host align ==
  //    [size] / target align
  //
  // Since alignments are always powers of 2, we use shifts and logs.
  const intptr_t adjusted_size =
      size << (kObjectAlignmentLog2 -
               compiler::target::ObjectAlignment::kObjectAlignmentLog2);

  return kReadOnlyGCBits | UntaggedObject::ClassIdTag::encode(cid) |
         UntaggedObject::SizeTag::encode(adjusted_size) |
         UntaggedObject::CanonicalBit::encode(is_canonical);
}

uword ImageWriter::GetMarkedTags(const Object& obj) {
  uword tags = GetMarkedTags(obj.ptr()->untag()->GetClassId(),
                             SizeInSnapshot(obj), obj.IsCanonical());
#if defined(HASH_IN_OBJECT_HEADER)
  tags = UntaggedObject::HashTag::update(obj.ptr()->untag()->GetHeaderHash(),
                                         tags);
#endif
  return tags;
}

const char* ImageWriter::SectionSymbol(ProgramSection section, bool vm) {
  switch (section) {
    case ProgramSection::Text:
      return vm ? kVmSnapshotInstructionsAsmSymbol
                : kIsolateSnapshotInstructionsAsmSymbol;
    case ProgramSection::Data:
      return vm ? kVmSnapshotDataAsmSymbol : kIsolateSnapshotDataAsmSymbol;
    case ProgramSection::Bss:
      return vm ? kVmSnapshotBssAsmSymbol : kIsolateSnapshotBssAsmSymbol;
    case ProgramSection::BuildId:
      return kSnapshotBuildIdAsmSymbol;
  }
  UNREACHABLE();
  return nullptr;
}

#if (defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)) &&    \
    defined(TARGET_ARCH_ARM64)
// When generating ARM64 Mach-O LLVM tends to generate Compact Unwind Info
// (__unwind_info) rather than traditional DWARF unwinding information
// (__eh_frame).
//
// Unfortunately when generating __unwind_info LLVM seems to only apply CFI
// rules to the region between two non-local symbols that contains these CFI
// directives. In other words given:
//
//   Abc:
//   .cfi_startproc
//   .cfi_def_cfa x29, 16
//   .cfi_offset x30, -8
//   .cfi_offset x29, -16
//   ;; ...
//   Xyz:
//   ;; ...
//   .cfi_endproc
//
// __unwind_info would specify proper unwinding information only for the region
// between Abc and Xyz symbols. And the region Xyz onwards will have no
// unwinding information.
//
// There also seems to be a difference in how unwinding information is
// canonicalized and compressed: when building __unwind_info from CFI directives
// LLVM will fold together similar entries, the same does not happen for
// __eh_frame. This means that emitting CFI directives for each function would
// balloon the size of __eh_frame.
//
// Hence to work around the problem of incorrect __unwind_info without
// ballooning snapshot size when __eh_frame is generated we choose to emit CFI
// directives per function specifically on ARM64 Mac OS X and iOS.
//
// See also |useCompactUnwind| method in LLVM (https://github.com/llvm/llvm-project/blob/b27430f9f46b88bcd54d992debc8d72e131e1bd0/llvm/lib/MC/MCObjectFileInfo.cpp#L28-L50)
#define EMIT_UNWIND_DIRECTIVES_PER_FUNCTION 1
#endif

void ImageWriter::WriteText(bool vm) {
  const bool bare_instruction_payloads = FLAG_precompiled_mode;

  // Start snapshot at page boundary.
  intptr_t alignment_padding = 0;
  if (!EnterSection(ProgramSection::Text, vm, ImageWriter::kTextAlignment,
                    &alignment_padding)) {
    return;
  }

  intptr_t text_offset = 0;
#if defined(DART_PRECOMPILER)
  // Parent used for later profile objects. Starts off as the Image. When
  // writing bare instructions payloads, this is later updated with the
  // InstructionsSection object which contains all the bare payloads.
  V8SnapshotProfileWriter::ObjectId parent_id(offset_space_, text_offset);
#endif

  // This head also provides the gap to make the instructions snapshot
  // look like a Page.
  const intptr_t image_size = Utils::RoundUp(
      next_text_offset_, compiler::target::ObjectAlignment::kObjectAlignment);
  text_offset += WriteTargetWord(image_size);
  // Output the offset to the InstructionsSection object from the start of the
  // image, if any.
  text_offset +=
      WriteTargetWord(FLAG_precompiled_mode ? Image::kHeaderSize
                                            : Image::kNoInstructionsSection);
  // Zero values for the rest of the Image object header bytes.
  text_offset += Align(Image::kHeaderSize, 0, text_offset);
  ASSERT_EQUAL(text_offset, Image::kHeaderSize);

#if defined(DART_PRECOMPILER)
  const char* instructions_symbol = SectionSymbol(ProgramSection::Text, vm);
  ASSERT(instructions_symbol != nullptr);
  intptr_t instructions_label = SectionLabel(ProgramSection::Text, vm);
  ASSERT(instructions_label > 0);
  const char* bss_symbol = SectionSymbol(ProgramSection::Bss, vm);
  ASSERT(bss_symbol != nullptr);
  intptr_t bss_label = SectionLabel(ProgramSection::Bss, vm);
  ASSERT(bss_label > 0);

  if (profile_writer_ != nullptr) {
    profile_writer_->SetObjectTypeAndName(parent_id, image_type_,
                                          instructions_symbol);
    profile_writer_->AttributeBytesTo(
        parent_id, ImageWriter::kTextAlignment + alignment_padding);
    profile_writer_->AddRoot(parent_id);
  }

  if (FLAG_precompiled_mode) {
    const intptr_t section_header_length =
        compiler::target::InstructionsSection::HeaderSize();
    // Calculated using next_text_offset_, which doesn't include post-payload
    // padding to object alignment. Note that if not in bare instructions mode,
    // the section has no contents, instead the instructions objects follow it.
    const intptr_t section_payload_length =
        bare_instruction_payloads
            ? next_text_offset_ - text_offset - section_header_length
            : 0;
    const intptr_t section_size =
        compiler::target::InstructionsSection::InstanceSize(
            section_payload_length);

    const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
    if (profile_writer_ != nullptr) {
      profile_writer_->SetObjectTypeAndName(id, instructions_section_type_,
                                            instructions_symbol);
      profile_writer_->AttributeBytesTo(id,
                                        section_size - section_payload_length);
      const intptr_t element_offset = id.nonce() - parent_id.nonce();
      profile_writer_->AttributeReferenceTo(
          parent_id,
          V8SnapshotProfileWriter::Reference::Element(element_offset), id);
      // Later objects will have the InstructionsSection as a parent if in
      // bare instructions mode, otherwise the image.
      if (bare_instruction_payloads) {
        parent_id = id;
      }
    }

    // Add the RawInstructionsSection header.
    text_offset +=
        WriteTargetWord(GetMarkedTags(kInstructionsSectionCid, section_size));
    // An InstructionsSection has five fields:
    // 1) The length of the payload.
    text_offset += WriteTargetWord(section_payload_length);
    // 2) The BSS offset from this section.
    text_offset += Relocation(text_offset, instructions_label, bss_label);
    // 3) The relocated address of the instructions.
    text_offset += RelocatedAddress(text_offset, instructions_label);
    // 4) The GNU build ID note offset from this section.
    text_offset += Relocation(text_offset, instructions_label,
                              SectionLabel(ProgramSection::BuildId, vm));

    const intptr_t section_contents_alignment =
        bare_instruction_payloads
            ? compiler::target::Instructions::kBarePayloadAlignment
            : compiler::target::ObjectAlignment::kObjectAlignment;
    const intptr_t alignment_offset =
        compiler::target::ObjectAlignment::kOldObjectAlignmentOffset;
    const intptr_t expected_size =
        bare_instruction_payloads
            ? compiler::target::InstructionsSection::HeaderSize()
            : compiler::target::InstructionsSection::InstanceSize(0);
    text_offset +=
        Align(section_contents_alignment, alignment_offset, text_offset);
    ASSERT_EQUAL(text_offset - id.nonce(), expected_size);
  }
#endif

#if !defined(EMIT_UNWIND_DIRECTIVES_PER_FUNCTION)
  FrameUnwindPrologue();
#endif

#if defined(DART_PRECOMPILER)
  PcDescriptors& descriptors = PcDescriptors::Handle(zone_);
#endif

  ASSERT(offset_space_ != IdSpace::kSnapshot);
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    auto& data = instructions_[i];
    const bool is_trampoline = data.trampoline_bytes != nullptr;
    ASSERT_EQUAL(data.text_offset_, text_offset);

#if defined(DART_PRECOMPILER)
    const char* object_name = namer_.SnapshotNameFor(data);

    if (profile_writer_ != nullptr) {
      const V8SnapshotProfileWriter::ObjectId id(offset_space_, text_offset);
      auto const type = is_trampoline ? trampoline_type_ : instructions_type_;
      const intptr_t size = is_trampoline ? data.trampoline_length
                                          : SizeInSnapshot(data.insns_->ptr());
      profile_writer_->SetObjectTypeAndName(id, type, object_name);
      profile_writer_->AttributeBytesTo(id, size);
      const intptr_t element_offset = id.nonce() - parent_id.nonce();
      profile_writer_->AttributeReferenceTo(
          parent_id,
          V8SnapshotProfileWriter::Reference::Element(element_offset), id);
    }
#endif

    if (is_trampoline) {
      text_offset += WriteBytes(data.trampoline_bytes, data.trampoline_length);
      delete[] data.trampoline_bytes;
      data.trampoline_bytes = nullptr;
      continue;
    }

    const intptr_t instr_start = text_offset;
    const auto& insns = *data.insns_;

    // 1. Write from the object start to the payload start. This includes the
    // object header and the fixed fields.  Not written for AOT snapshots using
    // bare instructions.
    if (!bare_instruction_payloads) {
      NoSafepointScope no_safepoint;

      // Write Instructions with the mark and read-only bits set.
      text_offset += WriteTargetWord(GetMarkedTags(insns));
      text_offset += WriteFixed(insns.untag()->size_and_flags_);
      text_offset +=
          Align(compiler::target::Instructions::kNonBarePayloadAlignment,
                compiler::target::ObjectAlignment::kOldObjectAlignmentOffset,
                text_offset);
    }

    ASSERT_EQUAL(text_offset - instr_start,
                 compiler::target::Instructions::HeaderSize());

#if defined(DART_PRECOMPILER)
    const auto& code = *data.code_;
    // 2. Add a symbol for the code at the entry point in precompiled snapshots.
    // Linux's perf uses these labels.
    AddCodeSymbol(code, object_name, text_offset);
#endif

#if defined(EMIT_UNWIND_DIRECTIVES_PER_FUNCTION)
    FrameUnwindPrologue();
#endif

    {
      NoSafepointScope no_safepoint;

      // 3. Write from the payload start to payload end. For AOT snapshots
      // with bare instructions, this is the only part serialized other than
      // any padding needed for alignment.
      auto const payload_start =
          reinterpret_cast<const uint8_t*>(insns.PayloadStart());
      // Double-check the payload alignment, since we will load and write
      // target-sized words starting from that address.
      ASSERT(Utils::IsAligned(payload_start, compiler::target::kWordSize));
      const uword payload_size = insns.Size();
      auto const payload_end = payload_start + payload_size;
      auto cursor = payload_start;
#if defined(DART_PRECOMPILER)
      descriptors = code.pc_descriptors();
      PcDescriptors::Iterator iterator(
          descriptors, /*kind_mask=*/UntaggedPcDescriptors::kBSSRelocation);
      while (iterator.MoveNext()) {
        // We only generate BSS relocations in the precompiler.
        ASSERT(FLAG_precompiled_mode);
        auto const next_reloc_offset = iterator.PcOffset();
        auto const next_reloc_address = payload_start + next_reloc_offset;
        // We only generate BSS relocations that are target word-sized and at
        // target word-aligned offsets in the payload. Double-check this.
        ASSERT(
            Utils::IsAligned(next_reloc_address, compiler::target::kWordSize));
        text_offset += WriteBytes(cursor, next_reloc_address - cursor);

        // The instruction stream at the relocation position holds the target
        // offset into the BSS section.
        const auto target_offset =
            *reinterpret_cast<const compiler::target::word*>(
                next_reloc_address);
        text_offset += Relocation(text_offset, instructions_label, text_offset,
                                  bss_label, target_offset);
        cursor = next_reloc_address + compiler::target::kWordSize;
      }
#endif
      text_offset += WriteBytes(cursor, payload_end - cursor);
    }

    // 4. Add appropriate padding. Note we can't simply copy from the object
    // because the host object may have less alignment filler than the target
    // object in the cross-word case.
    const intptr_t alignment =
        bare_instruction_payloads
            ? compiler::target::Instructions::kBarePayloadAlignment
            : compiler::target::ObjectAlignment::kObjectAlignment;
    text_offset += AlignWithBreakInstructions(alignment, text_offset);

    ASSERT_EQUAL(text_offset - instr_start, SizeInSnapshot(insns.ptr()));
#if defined(EMIT_UNWIND_DIRECTIVES_PER_FUNCTION)
    FrameUnwindEpilogue();
#endif
  }

  // Should be a no-op unless writing bare instruction payloads, in which case
  // we need to add post-payload padding for the InstructionsSection object.
  // Since this follows instructions, we'll use break instructions for padding.
  ASSERT(bare_instruction_payloads ||
         Utils::IsAligned(text_offset,
                          compiler::target::ObjectAlignment::kObjectAlignment));
  text_offset += AlignWithBreakInstructions(
      compiler::target::ObjectAlignment::kObjectAlignment, text_offset);

  ASSERT_EQUAL(text_offset, image_size);

#if !defined(EMIT_UNWIND_DIRECTIVES_PER_FUNCTION)
  FrameUnwindEpilogue();
#endif

  ExitSection(ProgramSection::Text, vm, text_offset);
}

intptr_t ImageWriter::AlignWithBreakInstructions(intptr_t alignment,
                                                 intptr_t offset) {
  intptr_t bytes_written = 0;
  uword remaining;
  for (remaining = Utils::RoundUp(offset, alignment) - offset;
       remaining >= compiler::target::kWordSize;
       remaining -= compiler::target::kWordSize) {
    bytes_written += WriteTargetWord(kBreakInstructionFiller);
  }
#if defined(TARGET_ARCH_ARM)
  // All instructions are 4 bytes long on ARM architectures, so on 32-bit ARM
  // there won't be any padding.
  ASSERT_EQUAL(remaining, 0);
#elif defined(TARGET_ARCH_ARM64)
  // All instructions are 4 bytes long on ARM architectures, so on 64-bit ARM
  // there is only 0 or 4 bytes of padding.
  if (remaining != 0) {
    ASSERT_EQUAL(remaining, 4);
    bytes_written += WriteBytes(&kBreakInstructionFiller, remaining);
  }
#elif defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32) ||                 \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
  // The break instruction is a single byte, repeated to fill a word.
  bytes_written += WriteBytes(&kBreakInstructionFiller, remaining);
#else
#error Unexpected architecture.
#endif
  ASSERT_EQUAL(bytes_written, Utils::RoundUp(offset, alignment) - offset);
  return bytes_written;
}

#if defined(DART_PRECOMPILER)

// Indices are log2(size in bytes).
static constexpr const char* kSizeDirectives[] = {".byte", ".2byte", ".long",
                                                  ".quad"};

static constexpr const char* kWordDirective =
    kSizeDirectives[compiler::target::kWordSizeLog2];

class DwarfAssemblyStream : public DwarfWriteStream {
 public:
  explicit DwarfAssemblyStream(Zone* zone,
                               BaseWriteStream* stream,
                               const IntMap<const char*>& label_to_name)
      : zone_(ASSERT_NOTNULL(zone)),
        stream_(ASSERT_NOTNULL(stream)),
        label_to_name_(label_to_name) {}

  void sleb128(intptr_t value) { stream_->Printf(".sleb128 %" Pd "\n", value); }
  void uleb128(uintptr_t value) {
    stream_->Printf(".uleb128 %" Pd "\n", value);
  }
  void u1(uint8_t value) {
    stream_->Printf("%s %u\n", kSizeDirectives[kInt8SizeLog2], value);
  }
  void u2(uint16_t value) {
    stream_->Printf("%s %u\n", kSizeDirectives[kInt16SizeLog2], value);
  }
  void u4(uint32_t value) {
    stream_->Printf("%s %" Pu32 "\n", kSizeDirectives[kInt32SizeLog2], value);
  }
  void u8(uint64_t value) {
    stream_->Printf("%s %" Pu64 "\n", kSizeDirectives[kInt64SizeLog2], value);
  }
  void string(const char* cstr) {               // NOLINT
    stream_->Printf(".string \"%s\"\n", cstr);  // NOLINT
  }
  void WritePrefixedLength(const char* prefix, std::function<void()> body) {
    ASSERT(prefix != nullptr);
    const char* const length_prefix_symbol =
        OS::SCreate(zone_, ".L%s_length_prefix", prefix);
    // Assignment to temp works around buggy Mac assembler.
    stream_->Printf("L%s_size = .L%s_end - .L%s_start\n", prefix, prefix,
                    prefix);
    // We assume DWARF v2 currently, so all sizes are 32-bit.
    stream_->Printf("%s: %s L%s_size\n", length_prefix_symbol,
                    kSizeDirectives[kInt32SizeLog2], prefix);
    // All sizes for DWARF sections measure the size of the section data _after_
    // the size value.
    stream_->Printf(".L%s_start:\n", prefix);
    body();
    stream_->Printf(".L%s_end:\n", prefix);
  }
  void OffsetFromSymbol(intptr_t label, intptr_t offset) {
    const char* symbol = label_to_name_.Lookup(label);
    ASSERT(symbol != nullptr);
    if (offset == 0) {
      PrintNamedAddress(symbol);
    } else {
      PrintNamedAddressWithOffset(symbol, offset);
    }
  }

  // No-op, we'll be using labels.
  void InitializeAbstractOrigins(intptr_t size) {}
  void RegisterAbstractOrigin(intptr_t index) {
    // Label for DW_AT_abstract_origin references
    stream_->Printf(".Lfunc%" Pd ":\n", index);
  }
  void AbstractOrigin(intptr_t index) {
    // Assignment to temp works around buggy Mac assembler.
    stream_->Printf("Ltemp%" Pd " = .Lfunc%" Pd " - %s\n", temp_, index,
                    kDebugInfoLabel);
    stream_->Printf("%s Ltemp%" Pd "\n", kSizeDirectives[kInt32SizeLog2],
                    temp_);
    temp_++;
  }

  // Methods for writing the assembly prologues for various DWARF sections.
  void AbbreviationsPrologue() {
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
    stream_->WriteString(".section __DWARF,__debug_abbrev,regular,debug\n");
#elif defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||      \
    defined(DART_TARGET_OS_FUCHSIA)
    stream_->WriteString(".section .debug_abbrev,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
  }
  void DebugInfoPrologue() {
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
    stream_->WriteString(".section __DWARF,__debug_info,regular,debug\n");
#elif defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||      \
    defined(DART_TARGET_OS_FUCHSIA)
    stream_->WriteString(".section .debug_info,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
    // Used to calculate abstract origin values.
    stream_->Printf("%s:\n", kDebugInfoLabel);
  }
  void LineNumberProgramPrologue() {
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
    stream_->WriteString(".section __DWARF,__debug_line,regular,debug\n");
#elif defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||      \
    defined(DART_TARGET_OS_FUCHSIA)
    stream_->WriteString(".section .debug_line,\"\"\n");
#else
    UNIMPLEMENTED();
#endif
  }

 private:
  static constexpr const char* kDebugInfoLabel = ".Ldebug_info";

  void PrintNamedAddress(const char* name) {
    stream_->Printf("%s \"%s\"\n", kWordDirective, name);
  }
  void PrintNamedAddressWithOffset(const char* name, intptr_t offset) {
    stream_->Printf("%s \"%s\" + %" Pd "\n", kWordDirective, name, offset);
  }

  Zone* const zone_;
  BaseWriteStream* const stream_;
  const IntMap<const char*>& label_to_name_;
  intptr_t temp_ = 0;

  DISALLOW_COPY_AND_ASSIGN(DwarfAssemblyStream);
};

static inline Dwarf* AddDwarfIfUnstripped(
    Zone* zone,
    bool strip,
    Elf* elf,
    const Trie<const char>* deobfuscation_trie) {
  if (!strip) {
    if (elf != nullptr) {
      // Reuse the existing DWARF object.
      ASSERT(elf->dwarf() != nullptr);
      return elf->dwarf();
    }
    return new (zone) Dwarf(zone, deobfuscation_trie);
  }
  return nullptr;
}

AssemblyImageWriter::AssemblyImageWriter(
    Thread* thread,
    BaseWriteStream* stream,
    const Trie<const char>* deobfuscation_trie,
    bool strip,
    Elf* debug_elf)
    : ImageWriter(thread, /*generates_assembly=*/true, deobfuscation_trie),
      assembly_stream_(stream),
      assembly_dwarf_(
          AddDwarfIfUnstripped(zone_, strip, debug_elf, deobfuscation_trie)),
      debug_elf_(debug_elf),
      label_to_symbol_name_(zone_) {
  // Set up the label mappings for the section symbols for use in relocations.
  for (intptr_t i = 0; i < kNumProgramSections; i++) {
    auto const section = static_cast<ProgramSection>(i);

    auto const vm_name = SectionSymbol(section, /*vm=*/true);
    auto const vm_label = SectionLabel(section, /*vm=*/true);
    label_to_symbol_name_.Insert(vm_label, vm_name);

    auto const isolate_name = SectionSymbol(section, /*vm=*/false);
    auto const isolate_label = SectionLabel(section, /*vm=*/false);
    if (vm_label != isolate_label) {
      label_to_symbol_name_.Insert(isolate_label, isolate_name);
    } else {
      // Make sure the names also match.
      ASSERT_EQUAL(strcmp(vm_name, isolate_name), 0);
    }
  }
}

void AssemblyImageWriter::Finalize() {
  if (assembly_dwarf_ != nullptr) {
    DwarfAssemblyStream dwarf_stream(zone_, assembly_stream_,
                                     label_to_symbol_name_);
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

#if defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||        \
    defined(DART_TARGET_OS_FUCHSIA)
  // Non-executable stack.
#if defined(TARGET_ARCH_ARM)
  assembly_stream_->WriteString(".section .note.GNU-stack,\"\",%progbits\n");
#else
  assembly_stream_->WriteString(".section .note.GNU-stack,\"\",@progbits\n");
#endif
#endif
}

void ImageWriter::SnapshotTextObjectNamer::AddNonUniqueNameFor(
    BaseTextBuffer* buffer,
    const Object& object) {
  if (object.IsCode()) {
    const Code& code = Code::Cast(object);
    if (code.IsStubCode()) {
      buffer->AddString("stub ");
      insns_ = code.instructions();
      const char* name = StubCode::NameOfStub(insns_.EntryPoint());
      ASSERT(name != nullptr);
      buffer->AddString(name);
    } else {
      if (code.IsAllocationStubCode()) {
        buffer->AddString("new ");
      } else if (code.IsTypeTestStubCode()) {
        buffer->AddString("assert type is ");
      } else {
        ASSERT(code.IsFunctionCode());
      }
      owner_ = code.owner();
      AddNonUniqueNameFor(buffer, owner_);
    }
  } else if (object.IsClass()) {
    const char* name = Class::Cast(object).UserVisibleNameCString();
    const char* deobfuscated_name =
        ImageWriter::Deobfuscate(zone_, deobfuscation_trie_, name);
    buffer->AddString(deobfuscated_name);
  } else if (object.IsAbstractType()) {
    const AbstractType& type = AbstractType::Cast(object);
    if (deobfuscation_trie_ == nullptr) {
      // Print directly to the output buffer.
      type.PrintName(Object::kUserVisibleName, buffer);
    } else {
      // Use an intermediate buffer for deobfuscation purposes.
      ZoneTextBuffer temp_buffer(zone_);
      type.PrintName(Object::kUserVisibleName, &temp_buffer);
      const char* deobfuscated_name = ImageWriter::Deobfuscate(
          zone_, deobfuscation_trie_, temp_buffer.buffer());
      buffer->AddString(deobfuscated_name);
    }
  } else if (object.IsFunction()) {
    const Function& func = Function::Cast(object);
    NameFormattingParams params(
        {Object::kUserVisibleName, Object::NameDisambiguation::kNo});
    if (deobfuscation_trie_ == nullptr) {
      // Print directly to the output buffer.
      func.PrintName(params, buffer);
    } else {
      // Use an intermediate buffer for deobfuscation purposes.
      ZoneTextBuffer temp_buffer(zone_);
      func.PrintName(params, &temp_buffer);
      const char* deobfuscated_name = ImageWriter::Deobfuscate(
          zone_, deobfuscation_trie_, temp_buffer.buffer());
      buffer->AddString(deobfuscated_name);
    }
  } else if (object.IsCompressedStackMaps()) {
    buffer->AddString("CompressedStackMaps");
  } else if (object.IsPcDescriptors()) {
    buffer->AddString("PcDescriptors");
  } else if (object.IsCodeSourceMap()) {
    buffer->AddString("CodeSourceMap");
  } else if (object.IsString()) {
    const String& str = String::Cast(object);
    if (str.IsOneByteString()) {
      buffer->AddString("OneByteString");
    } else if (str.IsTwoByteString()) {
      buffer->AddString("TwoByteString");
    }
  } else {
    UNREACHABLE();
  }
}

void ImageWriter::SnapshotTextObjectNamer::ModifyForAssembly(
    BaseTextBuffer* buffer) {
  if (buffer->buffer()[0] == 'L') {
    // Assembler treats labels starting with `L` as local which can cause
    // some issues down the line e.g. on Mac the linker might fail to encode
    // compact unwind information because multiple functions end up being
    // treated as a single function. See https://github.com/flutter/flutter/issues/102281.
    //
    // Avoid this by prepending an underscore.
    auto* const result = OS::SCreate(zone_, "_%s", buffer->buffer());
    buffer->Clear();
    buffer->AddString(result);
  }
  auto* const pair = usage_count_.Lookup(buffer->buffer());
  if (pair == nullptr) {
    usage_count_.Insert({buffer->buffer(), 1});
  } else {
    buffer->Printf(" (#%" Pd ")", ++pair->value);
  }
}

const char* ImageWriter::SnapshotTextObjectNamer::SnapshotNameFor(
    const InstructionsData& data) {
  ZoneTextBuffer printer(zone_);
  if (data.trampoline_bytes != nullptr) {
    printer.AddString("Trampoline");
  } else {
    AddNonUniqueNameFor(&printer, *data.code_);
  }
  if (for_assembly_) {
    ModifyForAssembly(&printer);
  }
  return printer.buffer();
}

const char* ImageWriter::SnapshotTextObjectNamer::SnapshotNameFor(
    const ObjectData& data) {
  ASSERT(data.is_object());
  ZoneTextBuffer printer(zone_);
  if (data.is_original_object()) {
    const Object& obj = *data.obj;
    AddNonUniqueNameFor(&printer, obj);
#if defined(SNAPSHOT_BACKTRACE)
    // It's less useful knowing the parent of a String than other read-only
    // data objects, and this avoids us having to handle other classes
    // in AddNonUniqueNameFor.
    if (!obj.IsString()) {
      const Object& parent = *data.parent;
      if (!parent.IsNull()) {
        printer.AddString(" (");
        AddNonUniqueNameFor(&printer, parent);
        printer.AddString(")");
      }
    }
#endif
  } else {
    printer.AddString("RawBytes");
  }
  if (for_assembly_) {
    ModifyForAssembly(&printer);
  }
  return printer.buffer();
}

Trie<const char>* ImageWriter::CreateReverseObfuscationTrie(Thread* thread) {
  auto* const zone = thread->zone();
  auto* const map_array = thread->isolate_group()->obfuscation_map();
  if (map_array == nullptr) return nullptr;

  Trie<const char>* trie = nullptr;
  for (intptr_t i = 0; map_array[i] != nullptr; i += 2) {
    auto const key = map_array[i];
    auto const value = map_array[i + 1];
    ASSERT(value != nullptr);
    // Don't include identity mappings.
    if (strcmp(key, value) == 0) continue;
    // Otherwise, any value in the obfuscation map should be a valid key.
    ASSERT(Trie<const char>::IsValidKey(value));
    trie = Trie<const char>::AddString(zone, trie, value, key);
  }
  return trie;
}

const char* ImageWriter::Deobfuscate(Zone* zone,
                                     const Trie<const char>* trie,
                                     const char* cstr) {
  if (trie == nullptr) return cstr;
  TextBuffer buffer(256);
  // Used to avoid Zone-allocating strings if no deobfuscation was performed.
  bool changed = false;
  intptr_t i = 0;
  while (cstr[i] != '\0') {
    intptr_t offset;
    auto const value = trie->Lookup(cstr + i, &offset);
    if (offset == 0) {
      // The first character was an invalid key element (that isn't the null
      // terminator due to the while condition), copy it and skip to the next.
      buffer.AddChar(cstr[i++]);
    } else if (value != nullptr) {
      changed = true;
      buffer.AddString(value);
    } else {
      buffer.AddRaw(reinterpret_cast<const uint8_t*>(cstr + i), offset);
    }
    i += offset;
  }
  if (!changed) return cstr;
  return OS::SCreate(zone, "%s", buffer.buffer());
}

void AssemblyImageWriter::WriteBss(bool vm) {
  EnterSection(ProgramSection::Bss, vm, ImageWriter::kBssAlignment);
  auto const entry_count =
      vm ? BSS::kVmEntryCount : BSS::kIsolateGroupEntryCount;
  for (intptr_t i = 0; i < entry_count; i++) {
    // All bytes in the .bss section must be zero.
    WriteTargetWord(0);
  }
  ExitSection(ProgramSection::Bss, vm,
              entry_count * compiler::target::kWordSize);
}

void AssemblyImageWriter::WriteROData(NonStreamingWriteStream* clustered_stream,
                                      bool vm) {
  if (!EnterSection(ProgramSection::Data, vm, ImageWriter::kRODataAlignment)) {
    return;
  }
  // The clustered stream already has some data on it from the serializer, so
  // make sure that the read-only objects start at the appropriate alignment
  // within the stream, as we'll write the entire clustered stream to the
  // assembly output (which was aligned in EnterSection).
  const intptr_t start_position = clustered_stream->Position();
  clustered_stream->Align(ImageWriter::kRODataAlignment);
  if (profile_writer_ != nullptr) {
    // Attribute any padding needed to the artificial root.
    const intptr_t padding = clustered_stream->Position() - start_position;
    profile_writer_->AttributeBytesTo(
        V8SnapshotProfileWriter::kArtificialRootId, padding);
  }
  // First write the read-only data objects to the clustered stream.
  ImageWriter::WriteROData(clustered_stream, vm);
  // Next, write the bytes of the clustered stream (along with any symbols
  // if appropriate) to the assembly output.
  const uint8_t* bytes = clustered_stream->buffer();
  const intptr_t len = clustered_stream->bytes_written();
  intptr_t last_position = 0;
  for (const auto& symbol : *current_symbols_) {
    WriteBytes(bytes + last_position, symbol.offset - last_position);
    assembly_stream_->Printf("\"%s\":\n", symbol.name);
#if defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||        \
    defined(DART_TARGET_OS_FUCHSIA)
    // Output size and type of the read-only data symbol to the assembly stream.
    assembly_stream_->Printf(".size \"%s\", %zu\n", symbol.name, symbol.size);
    assembly_stream_->Printf(".type \"%s\", %%object\n", symbol.name);
#elif defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
    // MachO symbol tables don't include the size of the symbol, so don't bother
    // printing it to the assembly output.
#else
    UNIMPLEMENTED();
#endif
    last_position = symbol.offset;
  }
  WriteBytes(bytes + last_position, len - last_position);
  ExitSection(ProgramSection::Data, vm, len);
}

bool AssemblyImageWriter::EnterSection(ProgramSection section,
                                       bool vm,
                                       intptr_t alignment,
                                       intptr_t* alignment_padding) {
  ASSERT(FLAG_precompiled_mode);
  ASSERT(current_symbols_ == nullptr);
  bool global_symbol = false;
  switch (section) {
    case ProgramSection::Text:
      if (debug_elf_ != nullptr) {
        current_symbols_ =
            new (zone_) ZoneGrowableArray<Elf::SymbolData>(zone_, 0);
      }
      assembly_stream_->WriteString(".text\n");
      global_symbol = true;
      break;
    case ProgramSection::Data:
      // We create a SymbolData array even if there is no debug_elf_ because we
      // may be writing RO data symbols, and RO data is written in two steps:
      // 1. Serializing the read-only data objects to the clustered stream
      // 2. Writing the bytes of the clustered stream to the assembly output.
      // Thus, we'll need to interleave the symbols with the cluster bytes
      // during step 2.
      current_symbols_ =
          new (zone_) ZoneGrowableArray<Elf::SymbolData>(zone_, 0);
#if defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||        \
    defined(DART_TARGET_OS_FUCHSIA)
      assembly_stream_->WriteString(".section .rodata\n");
#elif defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
      assembly_stream_->WriteString(".const\n");
#else
      UNIMPLEMENTED();
#endif
      global_symbol = true;
      break;
    case ProgramSection::Bss:
      assembly_stream_->WriteString(".bss\n");
      break;
    case ProgramSection::BuildId:
      break;
  }
  current_section_label_ = SectionLabel(section, vm);
  ASSERT(current_section_label_ > 0);
  if (global_symbol) {
    assembly_stream_->Printf(".globl %s\n", SectionSymbol(section, vm));
  }
  intptr_t padding = Align(alignment, 0, 0);
  if (alignment_padding != nullptr) {
    *alignment_padding = padding;
  }
  assembly_stream_->Printf("%s:\n", SectionSymbol(section, vm));
  return true;
}

static void ElfAddSection(
    Elf* elf,
    ImageWriter::ProgramSection section,
    const char* symbol,
    intptr_t label,
    uint8_t* bytes,
    intptr_t size,
    ZoneGrowableArray<Elf::SymbolData>* symbols,
    ZoneGrowableArray<Elf::Relocation>* relocations = nullptr) {
  if (elf == nullptr) return;
  switch (section) {
    case ImageWriter::ProgramSection::Text:
      elf->AddText(symbol, label, bytes, size, relocations, symbols);
      break;
    case ImageWriter::ProgramSection::Data:
      elf->AddROData(symbol, label, bytes, size, relocations, symbols);
      break;
    default:
      // Other sections are handled by the Elf object internally.
      break;
  }
}

void AssemblyImageWriter::ExitSection(ProgramSection name,
                                      bool vm,
                                      intptr_t size) {
  // We should still be in the same section as the last EnterSection.
  ASSERT_EQUAL(current_section_label_, SectionLabel(name, vm));
#if defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||        \
    defined(DART_TARGET_OS_FUCHSIA)
  // Output the size of the section symbol to the assembly stream.
  assembly_stream_->Printf(".size %s, %zu\n", SectionSymbol(name, vm), size);
  assembly_stream_->Printf(".type %s, %%object\n", SectionSymbol(name, vm));
#elif defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
  // MachO symbol tables don't include the size of the symbol, so don't bother
  // printing it to the assembly output.
#else
  UNIMPLEMENTED();
#endif
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
  ElfAddSection(debug_elf_, name, SectionSymbol(name, vm),
                current_section_label_, /*bytes=*/nullptr, size,
                current_symbols_);
  current_section_label_ = 0;
  current_symbols_ = nullptr;
}

intptr_t AssemblyImageWriter::WriteTargetWord(word value) {
  ASSERT(Utils::BitLength(value) <= compiler::target::kBitsPerWord);
  // Padding is helpful for comparing the .S with --disassemble.
  assembly_stream_->Printf("%s 0x%.*" Px "\n", kWordDirective,
                           2 * compiler::target::kWordSize, value);
  return compiler::target::kWordSize;
}

intptr_t AssemblyImageWriter::Relocation(intptr_t section_offset,
                                         intptr_t source_label,
                                         intptr_t source_offset,
                                         intptr_t target_label,
                                         intptr_t target_offset) {
  // TODO(dartbug.com/43274): Remove once we generate consistent build IDs
  // between assembly snapshots and their debugging information.
  if (target_label == SectionLabel(ProgramSection::BuildId, /*vm=*/false)) {
    return WriteTargetWord(Image::kNoBuildId);
  }

  // All relocations are word-sized.
  assembly_stream_->Printf("%s ", kWordDirective);
  if (target_label == current_section_label_) {
    assembly_stream_->WriteString("(.)");
    target_offset -= section_offset;
  } else {
    const char* target_symbol = label_to_symbol_name_.Lookup(target_label);
    ASSERT(target_symbol != nullptr);
    assembly_stream_->Printf("%s", target_symbol);
  }
  if (target_offset != 0) {
    assembly_stream_->Printf(" + %" Pd "", target_offset);
  }

  if (source_label == current_section_label_) {
    assembly_stream_->WriteString(" - (.)");
    source_offset -= section_offset;
  } else {
    const char* source_symbol = label_to_symbol_name_.Lookup(source_label);
    ASSERT(source_symbol != nullptr);
    assembly_stream_->Printf(" - %s", source_symbol);
  }
  if (source_offset != 0) {
    assembly_stream_->Printf(" - %" Pd "", source_offset);
  }
  assembly_stream_->WriteString("\n");
  return compiler::target::kWordSize;
}

void AssemblyImageWriter::AddCodeSymbol(const Code& code,
                                        const char* symbol,
                                        intptr_t offset) {
  auto const label = next_label_++;
  label_to_symbol_name_.Insert(label, symbol);
  if (assembly_dwarf_ != nullptr) {
    assembly_dwarf_->AddCode(code, label);
  }
  if (debug_elf_ != nullptr) {
    current_symbols_->Add({symbol, elf::STT_FUNC, offset, code.Size(), label});
    debug_elf_->dwarf()->AddCode(code, label);
  }
  assembly_stream_->Printf("\"%s\":\n", symbol);
#if defined(DART_TARGET_OS_LINUX) || defined(DART_TARGET_OS_ANDROID) ||        \
    defined(DART_TARGET_OS_FUCHSIA)
  // Output the size of the code symbol to the assembly stream.
  assembly_stream_->Printf(".size \"%s\", %zu\n", symbol, code.Size());
  assembly_stream_->Printf(".type \"%s\", %%function\n", symbol);
#elif defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
  // MachO symbol tables don't include the size of the symbol, so don't bother
  // printing it to the assembly output.
#else
  UNIMPLEMENTED();
#endif
}

void AssemblyImageWriter::AddDataSymbol(const char* symbol,
                                        intptr_t offset,
                                        size_t size) {
  if (!FLAG_add_readonly_data_symbols) return;
  auto const label = next_label_++;
  label_to_symbol_name_.Insert(label, symbol);
  current_symbols_->Add({symbol, elf::STT_OBJECT, offset, size, label});
}

void AssemblyImageWriter::FrameUnwindPrologue() {
  // Creates DWARF's .debug_frame
  // CFI = Call frame information
  // CFA = Canonical frame address
  assembly_stream_->WriteString(".cfi_startproc\n");

  // Below .cfi_def_cfa defines CFA as caller's SP, while .cfi_offset R, offs
  // tells unwinder that caller's value of register R is stored at address
  // CFA+offs.

  // In the code below we emit .cfi_offset directive in the specific order:
  // PC first then FP. This should not actually matter, but we discovered
  // that LLVM code responsible for emitting compact unwind information
  // expects this specific ordering of CFI directives. If we don't
  // follow the order then LLVM fails to emit compact unwind info and emits
  // __eh_frame instead which is very large.
  // See also https://github.com/llvm/llvm-project/issues/62574 and
  // https://github.com/flutter/flutter/issues/126004.

#if defined(TARGET_ARCH_IA32)
  UNREACHABLE();
#elif defined(TARGET_ARCH_X64)
  assembly_stream_->WriteString(".cfi_def_cfa rbp, 16\n");
  assembly_stream_->WriteString(".cfi_offset rip, -8\n");
  assembly_stream_->WriteString(".cfi_offset rbp, -16\n");
#elif defined(TARGET_ARCH_ARM64)
  COMPILE_ASSERT(R29 == FP);
  COMPILE_ASSERT(R30 == LINK_REGISTER);
  assembly_stream_->WriteString(".cfi_def_cfa x29, 16\n");
  assembly_stream_->WriteString(".cfi_offset x30, -8\n");
  assembly_stream_->WriteString(".cfi_offset x29, -16\n");
#elif defined(TARGET_ARCH_ARM)
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R7);
  assembly_stream_->WriteString(".cfi_def_cfa r7, 8\n");
#else
  COMPILE_ASSERT(FP == R11);
  assembly_stream_->WriteString(".cfi_def_cfa r11, 8\n");
#endif
  assembly_stream_->WriteString(".cfi_offset lr, -4\n");
#if defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R7);
  assembly_stream_->WriteString(".cfi_offset r7, -8\n");
#else
  COMPILE_ASSERT(FP == R11);
  assembly_stream_->WriteString(".cfi_offset r11, -8\n");
#endif
// libunwind on ARM may use .ARM.exidx instead of .debug_frame
#if !defined(DART_TARGET_OS_MACOS) && !defined(DART_TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R11);
  assembly_stream_->WriteString(".fnstart\n");
  assembly_stream_->WriteString(".save {r11, lr}\n");
  assembly_stream_->WriteString(".setfp r11, sp, #0\n");
#endif
#elif defined(TARGET_ARCH_RISCV32)
  assembly_stream_->WriteString(".cfi_def_cfa fp, 0\n");
  assembly_stream_->WriteString(".cfi_offset ra, -4\n");
  assembly_stream_->WriteString(".cfi_offset fp, -8\n");
#elif defined(TARGET_ARCH_RISCV64)
  assembly_stream_->WriteString(".cfi_def_cfa fp, 0\n");
  assembly_stream_->WriteString(".cfi_offset ra, -8\n");
  assembly_stream_->WriteString(".cfi_offset fp, -16\n");
#else
#error Unexpected architecture.
#endif
}

void AssemblyImageWriter::FrameUnwindEpilogue() {
#if defined(TARGET_ARCH_ARM)
#if !defined(DART_TARGET_OS_MACOS) && !defined(DART_TARGET_OS_MACOS_IOS)
  assembly_stream_->WriteString(".fnend\n");
#endif
#endif
  assembly_stream_->WriteString(".cfi_endproc\n");
}

intptr_t AssemblyImageWriter::WriteBytes(const void* bytes, intptr_t size) {
  ASSERT(size >= 0);
  auto const start = reinterpret_cast<const uint8_t*>(bytes);
  auto const end_of_words =
      start + Utils::RoundDown(size, compiler::target::kWordSize);
  for (auto cursor = reinterpret_cast<const compiler::target::word*>(start);
       cursor < reinterpret_cast<const compiler::target::word*>(end_of_words);
       cursor++) {
    WriteTargetWord(*cursor);
  }
  auto const end = start + size;
  if (end != end_of_words) {
    assembly_stream_->WriteString(kSizeDirectives[kInt8SizeLog2]);
    for (auto cursor = end_of_words; cursor < end; cursor++) {
      assembly_stream_->Printf("%s 0x%.2x", cursor != end_of_words ? "," : "",
                               *cursor);
    }
    assembly_stream_->WriteString("\n");
  }
  return size;
}

intptr_t AssemblyImageWriter::Align(intptr_t alignment,
                                    intptr_t offset,
                                    intptr_t position) {
  ASSERT(offset == 0);
  const intptr_t next_position = Utils::RoundUp(position, alignment);
  assembly_stream_->Printf(".balign %" Pd ", 0\n", alignment);
  return next_position - position;
}
#endif  // defined(DART_PRECOMPILER)

#if defined(DART_PRECOMPILER)
BlobImageWriter::BlobImageWriter(Thread* thread,
                                 NonStreamingWriteStream* vm_instructions,
                                 NonStreamingWriteStream* isolate_instructions,
                                 const Trie<const char>* deobfuscation_trie,
                                 Elf* debug_elf,
                                 Elf* elf)
    : ImageWriter(thread, /*generates_assembly=*/false, deobfuscation_trie),
#else
BlobImageWriter::BlobImageWriter(Thread* thread,
                                 NonStreamingWriteStream* vm_instructions,
                                 NonStreamingWriteStream* isolate_instructions,
                                 Elf* debug_elf,
                                 Elf* elf)
    : ImageWriter(thread, /*generates_assembly=*/false),
#endif
      vm_instructions_(vm_instructions),
      isolate_instructions_(isolate_instructions),
      elf_(elf),
      debug_elf_(debug_elf) {
#if defined(DART_PRECOMPILER)
  ASSERT_EQUAL(FLAG_precompiled_mode, elf_ != nullptr);
  ASSERT(debug_elf_ == nullptr || debug_elf_->dwarf() != nullptr);
#else
  RELEASE_ASSERT(elf_ == nullptr);
#endif
}

intptr_t BlobImageWriter::WriteBytes(const void* bytes, intptr_t size) {
  current_section_stream_->WriteBytes(bytes, size);
  return size;
}

void BlobImageWriter::WriteBss(bool vm) {
#if defined(DART_PRECOMPILER)
  // We don't actually write a BSS segment, it's created as part of the
  // Elf constructor.
#endif
}

void BlobImageWriter::WriteROData(NonStreamingWriteStream* clustered_stream,
                                  bool vm) {
#if defined(DART_PRECOMPILER)
  const intptr_t start_position = clustered_stream->Position();
#endif
  current_section_stream_ = ASSERT_NOTNULL(clustered_stream);
  if (!EnterSection(ProgramSection::Data, vm, ImageWriter::kRODataAlignment)) {
    return;
  }
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    // Attribute any padding needed to the artificial root.
    const intptr_t padding = clustered_stream->Position() - start_position;
    profile_writer_->AttributeBytesTo(
        V8SnapshotProfileWriter::kArtificialRootId, padding);
  }
#endif
  ImageWriter::WriteROData(clustered_stream, vm);
  ExitSection(ProgramSection::Data, vm, clustered_stream->bytes_written());
}

bool BlobImageWriter::EnterSection(ProgramSection section,
                                   bool vm,
                                   intptr_t alignment,
                                   intptr_t* alignment_padding) {
#if defined(DART_PRECOMPILER)
  ASSERT_EQUAL(elf_ != nullptr, FLAG_precompiled_mode);
  ASSERT(current_relocations_ == nullptr);
  ASSERT(current_symbols_ == nullptr);
#endif
  ASSERT(section == ProgramSection::Data || current_section_stream_ == nullptr);
  switch (section) {
    case ProgramSection::Text:
      current_section_stream_ =
          ASSERT_NOTNULL(vm ? vm_instructions_ : isolate_instructions_);
#if defined(DART_PRECOMPILER)
      current_relocations_ =
          new (zone_) ZoneGrowableArray<Elf::Relocation>(zone_, 0);
      current_symbols_ =
          new (zone_) ZoneGrowableArray<Elf::SymbolData>(zone_, 0);
#endif
      break;
    case ProgramSection::Data:
      // The stream to use is passed into WriteROData and set there.
      ASSERT(current_section_stream_ != nullptr);
#if defined(DART_PRECOMPILER)
      current_relocations_ =
          new (zone_) ZoneGrowableArray<Elf::Relocation>(zone_, 0);
      current_symbols_ =
          new (zone_) ZoneGrowableArray<Elf::SymbolData>(zone_, 0);
#endif
      break;
    case ProgramSection::Bss:
      // The BSS section is pre-made in the Elf object for precompiled snapshots
      // and unused otherwise, so there's no work that needs doing here.
      return false;
    case ProgramSection::BuildId:
      // The GNU build ID is handled specially in the Elf object, and does not
      // get used for non-precompiled snapshots.
      return false;
  }
  intptr_t padding = current_section_stream_->Align(alignment);
  if (alignment_padding != nullptr) {
    *alignment_padding = padding;
  }
  return true;
}

void BlobImageWriter::ExitSection(ProgramSection name, bool vm, intptr_t size) {
#if defined(DART_PRECOMPILER)
  ElfAddSection(elf_, name, SectionSymbol(name, vm), SectionLabel(name, vm),
                current_section_stream_->buffer(), size, current_symbols_,
                current_relocations_);
  // We create the corresponding segment in the debugging information as well,
  // since it needs the contents to create the correct build ID.
  ElfAddSection(debug_elf_, name, SectionSymbol(name, vm),
                SectionLabel(name, vm), current_section_stream_->buffer(), size,
                current_symbols_, current_relocations_);
  current_relocations_ = nullptr;
  current_symbols_ = nullptr;
#endif
  current_section_stream_ = nullptr;
}

intptr_t BlobImageWriter::WriteTargetWord(word value) {
  current_section_stream_->WriteTargetWord(value);
  return compiler::target::kWordSize;
}

intptr_t BlobImageWriter::Align(intptr_t alignment,
                                intptr_t offset,
                                intptr_t position) {
  const intptr_t stream_padding =
      current_section_stream_->Align(alignment, offset);
  // Double-check that the position has the same alignment.
  ASSERT_EQUAL(Utils::RoundUp(position, alignment, offset) - position,
               stream_padding);
  return stream_padding;
}

#if defined(DART_PRECOMPILER)
intptr_t BlobImageWriter::Relocation(intptr_t section_offset,
                                     intptr_t source_label,
                                     intptr_t source_offset,
                                     intptr_t target_label,
                                     intptr_t target_offset) {
  ASSERT(FLAG_precompiled_mode);
  current_relocations_->Add({compiler::target::kWordSize, section_offset,
                             source_label, source_offset, target_label,
                             target_offset});
  // We write break instructions so it's easy to tell if a relocation doesn't
  // get replaced appropriately.
  return WriteTargetWord(kBreakInstructionFiller);
}

void BlobImageWriter::AddCodeSymbol(const Code& code,
                                    const char* symbol,
                                    intptr_t offset) {
  const intptr_t label = next_label_++;
  current_symbols_->Add({symbol, elf::STT_FUNC, offset, code.Size(), label});
  if (elf_ != nullptr && elf_->dwarf() != nullptr) {
    elf_->dwarf()->AddCode(code, label);
  }
  if (debug_elf_ != nullptr) {
    debug_elf_->dwarf()->AddCode(code, label);
  }
}

void BlobImageWriter::AddDataSymbol(const char* symbol,
                                    intptr_t offset,
                                    size_t size) {
  if (!FLAG_add_readonly_data_symbols) return;
  const intptr_t label = next_label_++;
  current_symbols_->Add({symbol, elf::STT_OBJECT, offset, size, label});
}
#endif  // defined(DART_PRECOMPILER)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

ImageReader::ImageReader(const uint8_t* data_image,
                         const uint8_t* instructions_image)
    : data_image_(ASSERT_NOTNULL(data_image)),
      instructions_image_(ASSERT_NOTNULL(instructions_image)) {}

ApiErrorPtr ImageReader::VerifyAlignment() const {
  if (!Utils::IsAligned(data_image_, kObjectStartAlignment) ||
      !Utils::IsAligned(instructions_image_, kObjectStartAlignment)) {
    return ApiError::New(
        String::Handle(String::New("Snapshot is misaligned", Heap::kOld)),
        Heap::kOld);
  }
  return ApiError::null();
}

#if defined(DART_PRECOMPILED_RUNTIME)
uword ImageReader::GetBareInstructionsAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, Instructions::kBarePayloadAlignment));
  return reinterpret_cast<uword>(instructions_image_) + offset;
}

uword ImageReader::GetBareInstructionsEnd() const {
  Image image(instructions_image_);
  return reinterpret_cast<uword>(image.object_start()) + image.object_size();
}
#endif

InstructionsPtr ImageReader::GetInstructionsAt(uint32_t offset) const {
  ASSERT(!FLAG_precompiled_mode);
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  ObjectPtr result = UntaggedObject::FromAddr(
      reinterpret_cast<uword>(instructions_image_) + offset);
  ASSERT(result->IsInstructions());
  ASSERT(result->untag()->IsMarked());

  return Instructions::RawCast(result);
}

ObjectPtr ImageReader::GetObjectAt(uint32_t offset) const {
  ASSERT(Utils::IsAligned(offset, kObjectAlignment));

  ObjectPtr result =
      UntaggedObject::FromAddr(reinterpret_cast<uword>(data_image_) + offset);
  ASSERT(result->untag()->IsMarked());

  return result;
}

}  // namespace dart
