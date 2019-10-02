// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <bin/elf_loader.h>
#include <bin/file.h>
#include <platform/elf.h>
#include <platform/globals.h>
#include <vm/cpu.h>
#include <vm/virtual_memory.h>

#include <memory>

namespace dart {
namespace bin {

namespace elf {

/// A loader for a subset of ELF which may be used to load objects produced by
/// Dart_CreateAppAOTSnapshotAsElf.
class LoadedElf {
 public:
  explicit LoadedElf(const char* filename, uint64_t elf_data_offset)
      : filename_(strdup(filename), std::free),
        elf_data_offset_(elf_data_offset) {}
  ~LoadedElf();

  /// Loads the ELF object into memory. Returns whether the load was successful.
  /// On failure, the error may be retrieved by 'error()'.
  bool Load();

  /// Reads Dart-specific symbols from the loaded ELF.
  ///
  /// Stores the address of the corresponding symbol in each non-null output
  /// parameter.
  ///
  /// Fails if any output parameter is non-null but points to null and the
  /// corresponding symbol was not found, or if the dynamic symbol table could
  /// not be decoded.
  ///
  /// On failure, the error may be retrieved by 'error()'.
  bool ResolveSymbols(const uint8_t** vm_data,
                      const uint8_t** vm_instrs,
                      const uint8_t** isolate_data,
                      const uint8_t** isolate_instrs);

  const char* error() { return error_; }

 private:
  bool ReadHeader();
  bool ReadProgramTable();
  bool LoadSegments();
  bool ReadSectionTable();
  bool ReadSectionStringTable();
  bool ReadSections();

  static uword PageSize() { return VirtualMemory::PageSize(); }

  // Unlike File::Map, allows non-aligned 'start' and 'length'.
  MappedMemory* MapFilePiece(uword start,
                             uword length,
                             const void** mapping_start);

  std::unique_ptr<char, decltype(std::free)*> filename_;
  const uint64_t elf_data_offset_;

  // Initialized on a successful Load().
  File* file_;

  // Initialized on error.
  const char* error_ = nullptr;

  // Initialized by ReadHeader().
  dart::elf::ElfHeader header_;

  // Initialized by ReadProgramTable().
  std::unique_ptr<MappedMemory> program_table_mapping_;
  const dart::elf::ProgramHeader* program_table_ = nullptr;

  // Initialized by LoadSegments().
  std::unique_ptr<VirtualMemory> base_;

  // Initialized by ReadSectionTable().
  std::unique_ptr<MappedMemory> section_table_mapping_;
  const dart::elf::SectionHeader* section_table_ = nullptr;

  // Initialized by ReadSectionStringTable().
  std::unique_ptr<MappedMemory> section_string_table_mapping_;
  const char* section_string_table_ = nullptr;

  // Initialized by ReadSections().
  const char* dynamic_string_table_ = nullptr;
  const dart::elf::Symbol* dynamic_symbol_table_ = nullptr;
  uword dynamic_symbol_count_ = 0;

  DISALLOW_COPY_AND_ASSIGN(LoadedElf);
};

#define CHECK(value)                                                           \
  if (!(value)) {                                                              \
    ASSERT(error_ != nullptr);                                                 \
    return false;                                                              \
  }

#define ERROR(message)                                                         \
  {                                                                            \
    error_ = (message);                                                        \
    return false;                                                              \
  }

#define CHECK_ERROR(value, message)                                            \
  if (!(value)) {                                                              \
    error_ = (message);                                                        \
    return false;                                                              \
  }

bool LoadedElf::Load() {
  VirtualMemory::Init();

  if (error_ != nullptr) {
    return false;
  }

  CHECK_ERROR(Utils::IsAligned(elf_data_offset_, PageSize()),
              "File offset must be page-aligned.");

  file_ = File::Open(/*namespc=*/nullptr, filename_.get(),
                     bin::File::FileOpenMode::kRead);
  CHECK_ERROR(file_ != nullptr, "Cannot open ELF object file.");
  CHECK_ERROR(file_->SetPosition(elf_data_offset_), "Invalid file offset.");

  CHECK(ReadHeader());
  CHECK(ReadProgramTable());
  CHECK(LoadSegments());
  CHECK(ReadSectionTable());
  CHECK(ReadSectionStringTable());
  CHECK(ReadSections());

  return true;
}

LoadedElf::~LoadedElf() {
  // Unmap the image.
  base_.reset();

  // Explicitly destroy all the mappings before closing the file.
  program_table_mapping_.reset();
  section_table_mapping_.reset();
  section_string_table_mapping_.reset();

  if (file_ != nullptr) {
    file_->Close();
    file_->Release();
  }
}

bool LoadedElf::ReadHeader() {
  CHECK_ERROR(file_->ReadFully(&header_, sizeof(dart::elf::ElfHeader)),
              "Could not read ELF file.");

  CHECK_ERROR(header_.ident[dart::elf::EI_DATA] == dart::elf::ELFDATA2LSB,
              "Expected little-endian ELF object.");

  CHECK_ERROR(header_.type == dart::elf::ET_DYN,
              "Can only load dynamic libraries.");

#if defined(TARGET_ARCH_IA32)
  CHECK_ERROR(header_.machine == dart::elf::EM_386, "Architecture mismatch.");
#elif defined(TARGET_ARCH_X64)
  CHECK_ERROR(header_.machine == dart::elf::EM_X86_64,
              "Architecture mismatch.");
#elif defined(TARGET_ARCH_ARM)
  CHECK_ERROR(header_.machine == dart::elf::EM_ARM, "Architecture mismatch.");
#elif defined(TARGET_ARCH_ARM64)
  CHECK_ERROR(header_.machine == dart::elf::EM_AARCH64,
              "Architecture mismatch.");
#else
#error Unsupported architecture architecture.
#endif

  CHECK_ERROR(header_.version == dart::elf::EV_CURRENT,
              "Unexpected ELF version.");
  CHECK_ERROR(header_.header_size == sizeof(dart::elf::ElfHeader),
              "Unexpected header size.");
  CHECK_ERROR(
      header_.program_table_entry_size == sizeof(dart::elf::ProgramHeader),
      "Unexpected program header size.");
  CHECK_ERROR(
      header_.section_table_entry_size == sizeof(dart::elf::SectionHeader),
      "Unexpected section header size.");

  return true;
}

bool LoadedElf::ReadProgramTable() {
  const uword file_start = header_.program_table_offset;
  const uword file_length =
      header_.num_program_headers * sizeof(dart::elf::ProgramHeader);
  program_table_mapping_.reset(
      MapFilePiece(file_start, file_length,
                   reinterpret_cast<const void**>(&program_table_)));
  CHECK_ERROR(program_table_mapping_ != nullptr,
              "Could not mmap the program table.");
  return true;
}

bool LoadedElf::ReadSectionTable() {
  const uword file_start = header_.section_table_offset;
  const uword file_length =
      header_.num_section_headers * sizeof(dart::elf::SectionHeader);
  section_table_mapping_.reset(
      MapFilePiece(file_start, file_length,
                   reinterpret_cast<const void**>(&section_table_)));
  CHECK_ERROR(section_table_mapping_ != nullptr,
              "Could not mmap the section table.");
  return true;
}

bool LoadedElf::ReadSectionStringTable() {
  const dart::elf::SectionHeader header =
      section_table_[header_.shstrtab_section_index];
  section_string_table_mapping_.reset(
      MapFilePiece(header.file_offset, header.file_size,
                   reinterpret_cast<const void**>(&section_string_table_)));
  CHECK_ERROR(section_string_table_mapping_ != nullptr,
              "Could not mmap the section string table.");
  return true;
}

bool LoadedElf::LoadSegments() {
  // Calculate the total amount of virtual memory needed.
  uword total_memory = 0;
  uword maximum_alignment = PageSize();
  for (uword i = 0; i < header_.num_program_headers; ++i) {
    const dart::elf::ProgramHeader header = program_table_[i];

    // Only PT_LOAD segments need to be loaded.
    if (header.type != dart::elf::ProgramHeaderType::PT_LOAD) continue;

    total_memory = Utils::Maximum(
        static_cast<uword>(header.memory_offset + header.memory_size),
        total_memory);
    CHECK_ERROR(Utils::IsPowerOfTwo(header.alignment),
                "Alignment must be a power of two.");
    maximum_alignment =
        Utils::Maximum(maximum_alignment, static_cast<uword>(header.alignment));
  }
  total_memory = Utils::RoundUp(total_memory, PageSize());

  base_.reset(VirtualMemory::AllocateAligned(
      total_memory, /*alignment=*/maximum_alignment,
      /*is_executable=*/false, /*mapping name=*/filename_.get()));
  CHECK_ERROR(base_ != nullptr, "Could not reserve virtual memory.");

  for (uword i = 0; i < header_.num_program_headers; ++i) {
    const dart::elf::ProgramHeader header = program_table_[i];

    // Only PT_LOAD segments need to be loaded.
    if (header.type != dart::elf::ProgramHeaderType::PT_LOAD) continue;

    const uword memory_offset = header.memory_offset,
                file_offset = header.file_offset;
    CHECK_ERROR(
        (memory_offset % PageSize()) == (file_offset % PageSize()),
        "Difference between file and memory offset must be page-aligned.");

    const intptr_t adjustment = header.memory_offset % PageSize();

    void* const memory_start =
        static_cast<char*>(base_->address()) + memory_offset - adjustment;
    const uword file_start = elf_data_offset_ + file_offset - adjustment;
    const uword length = header.memory_size + adjustment;

    File::MapType map_type = File::kReadOnly;
    if (header.flags == (dart::elf::PF_R | dart::elf::PF_W)) {
      map_type = File::kReadWrite;
    } else if (header.flags == (dart::elf::PF_R | dart::elf::PF_X)) {
      map_type = File::kReadExecute;
    } else if (header.flags == dart::elf::PF_R) {
      map_type = File::kReadOnly;
    } else {
      ERROR("Unsupported segment flag set.");
    }

    std::unique_ptr<MappedMemory> memory(
        file_->Map(map_type, file_start, length, memory_start));
    CHECK_ERROR(memory != nullptr, "Could not map segment.");
    CHECK_ERROR(memory->address() == memory_start,
                "Mapping not at requested address.");
  }

  return true;
}

bool LoadedElf::ReadSections() {
  for (uword i = 0; i < header_.num_section_headers; ++i) {
    const dart::elf::SectionHeader header = section_table_[i];
    const char* const name = section_string_table_ + header.name;
    if (strcmp(name, ".dynstr") == 0) {
      CHECK_ERROR(header.memory_offset != 0, ".dynstr must be loaded.");
      dynamic_string_table_ =
          static_cast<const char*>(base_->address()) + header.memory_offset;
    } else if (strcmp(name, ".dynsym") == 0) {
      CHECK_ERROR(header.memory_offset != 0, ".dynsym must be loaded.");
      dynamic_symbol_table_ = reinterpret_cast<const dart::elf::Symbol*>(
          base_->start() + header.memory_offset);
      dynamic_symbol_count_ = header.file_size / sizeof(dart::elf::Symbol);
    }
  }

  CHECK_ERROR(dynamic_string_table_ != nullptr, "Couldn't find .dynstr.");
  CHECK_ERROR(dynamic_symbol_table_ != nullptr, "Couldn't find .dynsym.");
  return true;
}

bool LoadedElf::ResolveSymbols(const uint8_t** vm_data,
                               const uint8_t** vm_instrs,
                               const uint8_t** isolate_data,
                               const uint8_t** isolate_instrs) {
  if (error_ != nullptr) {
    return false;
  }

  // The first entry of the symbol table is reserved.
  for (uword i = 1; i < dynamic_symbol_count_; ++i) {
    const dart::elf::Symbol sym = dynamic_symbol_table_[i];
    const char* name = dynamic_string_table_ + sym.name;
    const uint8_t** output = nullptr;

    if (strcmp(name, kVmSnapshotDataSymbolName) == 0) {
      output = vm_data;
    } else if (strcmp(name, kVmSnapshotInstructionsSymbolName) == 0) {
      output = vm_instrs;
    } else if (strcmp(name, kIsolateSnapshotDataSymbolName) == 0) {
      output = isolate_data;
    } else if (strcmp(name, kIsolateSnapshotInstructionsSymbolName) == 0) {
      output = isolate_instrs;
    }

    if (output != nullptr) {
      *output = reinterpret_cast<const uint8_t*>(base_->start() + sym.value);
    }
  }

  CHECK_ERROR(vm_data == nullptr || *vm_data != nullptr,
              "Could not find VM snapshot data.");
  CHECK_ERROR(vm_instrs == nullptr || *vm_instrs != nullptr,
              "Could not find VM snapshot instructions.");
  CHECK_ERROR(isolate_data == nullptr || *isolate_data != nullptr,
              "Could not find isolate snapshot data.");
  CHECK_ERROR(isolate_instrs == nullptr || *isolate_instrs != nullptr,
              "Could not find isolate instructions.");
  return true;
}

MappedMemory* LoadedElf::MapFilePiece(uword file_start,
                                      uword file_length,
                                      const void** mem_start) {
  const uword adjustment = (elf_data_offset_ + file_start) % PageSize();
  const uword mapping_offset = elf_data_offset_ + file_start - adjustment;
  const uword mapping_length =
      Utils::RoundUp(elf_data_offset_ + file_start + file_length, PageSize()) -
      mapping_offset;
  MappedMemory* const mapping =
      file_->Map(bin::File::kReadOnly, mapping_offset, mapping_length);

  if (mapping != nullptr) {
    *mem_start = reinterpret_cast<uint8_t*>(mapping->start() +
                                            (file_start % PageSize()));
  }

  return mapping;
}

}  // namespace elf
}  // namespace bin
}  // namespace dart

DART_EXPORT Dart_LoadedElf* Dart_LoadELF(const char* filename,
                                         uint64_t file_offset,
                                         const char** error,
                                         const uint8_t** vm_snapshot_data,
                                         const uint8_t** vm_snapshot_instrs,
                                         const uint8_t** vm_isolate_data,
                                         const uint8_t** vm_isolate_instrs) {
  std::unique_ptr<dart::bin::elf::LoadedElf> elf(
      new dart::bin::elf::LoadedElf(filename, file_offset));

  if (!elf->Load() ||
      !elf->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                           vm_isolate_data, vm_isolate_instrs)) {
    *error = elf->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedElf*>(elf.release());
}

DART_EXPORT void Dart_UnloadELF(Dart_LoadedElf* loaded) {
  delete reinterpret_cast<dart::bin::elf::LoadedElf*>(loaded);
}
