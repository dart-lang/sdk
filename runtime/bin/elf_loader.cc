// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <bin/elf_loader.h>
#include <bin/file.h>
#include <platform/elf.h>
#include <platform/globals.h>
#include <vm/bss_relocs.h>
#include <vm/cpu.h>
#include <vm/virtual_memory.h>

#if defined(HOST_OS_FUCHSIA)
#include <sys/mman.h>
#endif

#include <memory>
#include <utility>

namespace dart {
namespace bin {

namespace elf {

class Mappable {
 public:
  static Mappable* FromPath(const char* path);
#if defined(HOST_OS_FUCHSIA) || defined(HOST_OS_LINUX)
  static Mappable* FromFD(int fd);
#endif
  static Mappable* FromMemory(const uint8_t* memory, size_t size);

  virtual MappedMemory* Map(File::MapType type,
                            uint64_t position,
                            uint64_t length,
                            void* start = nullptr) = 0;

  virtual bool SetPosition(uint64_t position) = 0;
  virtual bool ReadFully(void* dest, int64_t length) = 0;

  virtual ~Mappable() {}

 protected:
  Mappable() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(Mappable);
};

class FileMappable : public Mappable {
 public:
  explicit FileMappable(File* file) : Mappable(), file_(file) {}

  ~FileMappable() override { file_->Release(); }

  MappedMemory* Map(File::MapType type,
                    uint64_t position,
                    uint64_t length,
                    void* start = nullptr) override {
    return file_->Map(type, position, length, start);
  }

  bool SetPosition(uint64_t position) override {
    return file_->SetPosition(position);
  }

  bool ReadFully(void* dest, int64_t length) override {
    return file_->ReadFully(dest, length);
  }

 private:
  File* const file_;
  DISALLOW_COPY_AND_ASSIGN(FileMappable);
};

class MemoryMappable : public Mappable {
 public:
  MemoryMappable(const uint8_t* memory, size_t size)
      : Mappable(), memory_(memory), size_(size), position_(memory) {}

  ~MemoryMappable() override {}

  MappedMemory* Map(File::MapType type,
                    uint64_t position,
                    uint64_t length,
                    void* start = nullptr) override {
    if (position > size_) return nullptr;
    MappedMemory* result = nullptr;
    const uword map_size = Utils::RoundUp(length, VirtualMemory::PageSize());
    if (start == nullptr) {
      auto* memory = VirtualMemory::Allocate(
          map_size, type == File::kReadExecute, "dart-compiled-image");
      if (memory == nullptr) return nullptr;
      result = new MappedMemory(memory->address(), memory->size());
      memory->release();
      delete memory;
    } else {
      result = new MappedMemory(start, map_size,
                                /*should_unmap=*/false);
    }

    size_t remainder = 0;
    if ((position + length) > size_) {
      remainder = position + length - size_;
      length = size_ - position;
    }
    memcpy(result->address(), memory_ + position, length);  // NOLINT
    memset(reinterpret_cast<uint8_t*>(result->address()) + length, 0,
           remainder);

    auto mode = VirtualMemory::kReadOnly;
    switch (type) {
      case File::kReadExecute:
        mode = VirtualMemory::kReadExecute;
        break;
      case File::kReadWrite:
        mode = VirtualMemory::kReadWrite;
        break;
      case File::kReadOnly:
        mode = VirtualMemory::kReadOnly;
        break;
      default:
        UNREACHABLE();
    }

    VirtualMemory::Protect(result->address(), result->size(), mode);

    return result;
  }

  bool SetPosition(uint64_t position) override {
    if (position > size_) return false;
    position_ = memory_ + position;
    return true;
  }

  bool ReadFully(void* dest, int64_t length) override {
    if ((position_ + length) > (memory_ + size_)) return false;
    memcpy(dest, position_, length);
    return true;
  }

 private:
  const uint8_t* const memory_;
  const size_t size_;
  const uint8_t* position_;
  DISALLOW_COPY_AND_ASSIGN(MemoryMappable);
};

Mappable* Mappable::FromPath(const char* path) {
  return new FileMappable(File::Open(/*namespc=*/nullptr, path, File::kRead));
}

#if defined(HOST_OS_FUCHSIA) || defined(HOST_OS_LINUX)
Mappable* Mappable::FromFD(int fd) {
  return new FileMappable(File::OpenFD(fd));
}
#endif

Mappable* Mappable::FromMemory(const uint8_t* memory, size_t size) {
  return new MemoryMappable(memory, size);
}

/// A loader for a subset of ELF which may be used to load objects produced by
/// Dart_CreateAppAOTSnapshotAsElf.
class LoadedElf {
 public:
  explicit LoadedElf(std::unique_ptr<Mappable> mappable,
                     uint64_t elf_data_offset)
      : mappable_(std::move(mappable)), elf_data_offset_(elf_data_offset) {}

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
  /// Has the side effect of initializing the relocated addresses for the text
  /// sections corresponding to non-null output parameters in the BSS segment.
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

  // Initialized on a successful Load().
  std::unique_ptr<Mappable> mappable_;
  const uint64_t elf_data_offset_;

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
  uword* vm_bss_ = nullptr;
  uword* isolate_bss_ = nullptr;

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

  ASSERT(mappable_ != nullptr);
  CHECK_ERROR(mappable_->SetPosition(elf_data_offset_), "Invalid file offset.");

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
}

bool LoadedElf::ReadHeader() {
  CHECK_ERROR(mappable_->ReadFully(&header_, sizeof(dart::elf::ElfHeader)),
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
      /*is_executable=*/false, "dart-compiled-image"));
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

#if defined(HOST_OS_FUCHSIA)
    // mmap is less flexible on Fuchsia than on Linux and Darwin, in (at least)
    // two important ways:
    //
    // 1. We cannot map a file opened as RX into an RW mapping, even if the
    //    mode is MAP_PRIVATE (which implies copy-on-write).
    // 2. We cannot atomically replace an existing anonymous mapping with a
    //    file mapping: we must first unmap the existing mapping.

    if (map_type == File::kReadWrite) {
      CHECK_ERROR(mappable_->SetPosition(file_start),
                  "Could not advance file position.");
      CHECK_ERROR(mappable_->ReadFully(memory_start, length),
                  "Could not read file.");
      continue;
    }

    CHECK_ERROR(munmap(memory_start, length) == 0,
                "Could not unmap reservation.");
#endif

    std::unique_ptr<MappedMemory> memory(
        mappable_->Map(map_type, file_start, length, memory_start));
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
    } else if (strcmp(name, ".bss") == 0) {
      auto const bss_size =
          (BSS::kVmEntryCount + BSS::kIsolateEntryCount) * kWordSize;
      CHECK_ERROR(header.memory_offset != 0, ".bss must be loaded.");
      CHECK_ERROR(header.file_size >= bss_size,
                  ".bss does not have enough space.");
      vm_bss_ = reinterpret_cast<uword*>(base_->start() + header.memory_offset);
      isolate_bss_ = vm_bss_ + BSS::kVmEntryCount;
    }
  }

  CHECK_ERROR(dynamic_string_table_ != nullptr, "Couldn't find .dynstr.");
  CHECK_ERROR(dynamic_symbol_table_ != nullptr, "Couldn't find .dynsym.");
  CHECK_ERROR(vm_bss_ != nullptr, "Couldn't find .bss.");
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

    if (strcmp(name, kVmSnapshotDataAsmSymbol) == 0) {
      output = vm_data;
    } else if (strcmp(name, kVmSnapshotInstructionsAsmSymbol) == 0) {
      output = vm_instrs;
    } else if (strcmp(name, kIsolateSnapshotDataAsmSymbol) == 0) {
      output = isolate_data;
    } else if (strcmp(name, kIsolateSnapshotInstructionsAsmSymbol) == 0) {
      output = isolate_instrs;
    }

    if (output != nullptr) {
      *output = reinterpret_cast<const uint8_t*>(base_->start() + sym.value);
    }
  }

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
      mappable_->Map(bin::File::kReadOnly, mapping_offset, mapping_length);

  if (mapping != nullptr) {
    *mem_start = reinterpret_cast<uint8_t*>(mapping->start() +
                                            (file_start % PageSize()));
  }

  return mapping;
}

}  // namespace elf
}  // namespace bin
}  // namespace dart

using namespace dart::bin::elf;  // NOLINT

#if defined(HOST_OS_FUCHSIA) || defined(HOST_OS_LINUX)
DART_EXPORT Dart_LoadedElf* Dart_LoadELF_Fd(int fd,
                                            uint64_t file_offset,
                                            const char** error,
                                            const uint8_t** vm_snapshot_data,
                                            const uint8_t** vm_snapshot_instrs,
                                            const uint8_t** vm_isolate_data,
                                            const uint8_t** vm_isolate_instrs) {
  std::unique_ptr<Mappable> mappable(Mappable::FromFD(fd));
  std::unique_ptr<LoadedElf> elf(
      new LoadedElf(std::move(mappable), file_offset));

  if (!elf->Load() ||
      !elf->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                           vm_isolate_data, vm_isolate_instrs)) {
    *error = elf->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedElf*>(elf.release());
}
#endif

#if !defined(HOST_OS_FUCHSIA)
DART_EXPORT Dart_LoadedElf* Dart_LoadELF(const char* filename,
                                         uint64_t file_offset,
                                         const char** error,
                                         const uint8_t** vm_snapshot_data,
                                         const uint8_t** vm_snapshot_instrs,
                                         const uint8_t** vm_isolate_data,
                                         const uint8_t** vm_isolate_instrs) {
  std::unique_ptr<Mappable> mappable(Mappable::FromPath(filename));
  if (mappable == nullptr) {
    *error = "Couldn't open file.";
    return nullptr;
  }
  std::unique_ptr<LoadedElf> elf(
      new LoadedElf(std::move(mappable), file_offset));

  if (!elf->Load() ||
      !elf->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                           vm_isolate_data, vm_isolate_instrs)) {
    *error = elf->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedElf*>(elf.release());
}
#endif

DART_EXPORT Dart_LoadedElf* Dart_LoadELF_Memory(
    const uint8_t* snapshot,
    uint64_t snapshot_size,
    const char** error,
    const uint8_t** vm_snapshot_data,
    const uint8_t** vm_snapshot_instrs,
    const uint8_t** vm_isolate_data,
    const uint8_t** vm_isolate_instrs) {
  std::unique_ptr<Mappable> mappable(
      Mappable::FromMemory(snapshot, snapshot_size));
  if (mappable == nullptr) {
    *error = "Couldn't open file.";
    return nullptr;
  }
  std::unique_ptr<LoadedElf> elf(
      new LoadedElf(std::move(mappable), /*file_offset=*/0));

  if (!elf->Load() ||
      !elf->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                           vm_isolate_data, vm_isolate_instrs)) {
    *error = elf->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedElf*>(elf.release());
}

DART_EXPORT void Dart_UnloadELF(Dart_LoadedElf* loaded) {
  delete reinterpret_cast<LoadedElf*>(loaded);
}
