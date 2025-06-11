// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/macho_loader.h"

#include <memory>
#include <utility>

#include "platform/globals.h"

#if defined(DART_HOST_OS_FUCHSIA)
#include <sys/mman.h>
#endif

#include "platform/mach_o.h"
#include "platform/unwinding_records.h"

#include "bin/file.h"
#include "bin/mappable.h"
#include "bin/virtual_memory.h"

namespace dart {
namespace bin {

namespace mach_o {

class LoadCommandIterator : public ValueObject {
 public:
  LoadCommandIterator(const void* start, size_t size)
      : end_(reinterpret_cast<const void*>(reinterpret_cast<uword>(start) +
                                           size)),
        current_(start) {}

  void Advance() {
    ASSERT(!Done());
    const uint32_t size = current()->cmdsize;
    current_ =
        reinterpret_cast<const void*>(reinterpret_cast<uword>(current_) + size);
  }

  bool Done() { return current_ >= end_; }

  const dart::mach_o::load_command* current() const {
    return reinterpret_cast<const dart::mach_o::load_command*>(current_);
  }

 private:
  const void* end_;
  const void* current_;

  DISALLOW_COPY_AND_ASSIGN(LoadCommandIterator);
};

// For MachO structs of constant size that are contiguous in memory.
template <typename T>
class MachOStructIterator : public ValueObject {
 public:
  MachOStructIterator(const T* start, size_t size_in_bytes)
      : start_(start),
        end_(reinterpret_cast<const T*>(reinterpret_cast<uword>(start) +
                                        size_in_bytes)) {
    ASSERT_EQUAL(0, size_in_bytes % sizeof(T));
  }

  const T* begin() const { return start_; }
  const T* end() const { return end_; }

 private:
  const T* start_;
  const T* end_;

  DISALLOW_COPY_AND_ASSIGN(MachOStructIterator);
};

/// A loader for a subset of Mach-O which may be used to load objects produced
/// by Dart_CreateAppAOTSnapshotAsMachO.
class LoadedMachODylib {
 public:
  LoadedMachODylib(std::unique_ptr<Mappable> mappable,
                   uint64_t macho_data_offset)
      : mappable_(std::move(mappable)), macho_data_offset_(macho_data_offset) {}

  ~LoadedMachODylib();

  /// Loads the Mach-O dynamic library object into memory. Returns whether the
  /// load was successful. On failure, the error may be retrieved by 'error()'.
  bool Load();

  /// Reads Dart-specific symbols from the loaded Mach-O dynamic library.
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
  bool LoadSegments();
  bool ReadDynamicSymbolTable();

  static uword PageSize() { return VirtualMemory::PageSize(); }

  // Unlike File::Map, allows non-aligned 'start' and 'length'.
  MappedMemory* MapFilePiece(uword start,
                             uword length,
                             const void** mapping_start);

  // Initialized on a successful Load().
  std::unique_ptr<Mappable> mappable_;
  const uint64_t macho_data_offset_;

  // Initialized on error.
  const char* error_ = nullptr;

  // Initialized by ReadHeader().
  dart::mach_o::mach_header header_;
  std::unique_ptr<MappedMemory> load_commands_mapping_;
  const void* load_commands_ = nullptr;

  // Initialized by LoadSegments().
  std::unique_ptr<VirtualMemory> base_;

  // Initialized by ReadDynamicSymbolTable().
  const char* string_table_ = nullptr;
  std::unique_ptr<MappedMemory> string_table_mapping_;
  const dart::mach_o::nlist* external_symbols_ = nullptr;
  uword external_symbol_count_ = 0;
  std::unique_ptr<MappedMemory> external_symbols_mapping_;

#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
  // Dynamic table for looking up unwinding exceptions info.
  // Initialized by LoadSegments as we load executable segment.
  MallocGrowableArray<void*> dynamic_runtime_function_tables_;
#endif

  DISALLOW_COPY_AND_ASSIGN(LoadedMachODylib);
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

bool LoadedMachODylib::Load() {
  VirtualMemory::Init();

  if (error_ != nullptr) {
    return false;
  }

  CHECK_ERROR(Utils::IsAligned(macho_data_offset_, PageSize()),
              "File offset must be page-aligned.");

  ASSERT(mappable_ != nullptr);
  CHECK_ERROR(mappable_->SetPosition(macho_data_offset_),
              "Invalid file offset.");

  CHECK(ReadHeader());
  CHECK(LoadSegments());
  CHECK(ReadDynamicSymbolTable());

  mappable_.reset();

  return true;
}

LoadedMachODylib::~LoadedMachODylib() {
#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
  for (intptr_t i = 0; i < dynamic_runtime_function_tables_.length(); i++) {
    UnwindingRecordsPlatform::UnregisterDynamicTable(
        dynamic_runtime_function_tables_[i]);
  }
#endif

  // Unmap the image.
  base_.reset();

  // Explicitly destroy all the mappings before closing the file.
  load_commands_mapping_.reset();
  string_table_mapping_.reset();
  external_symbols_mapping_.reset();
}

bool LoadedMachODylib::ReadHeader() {
  CHECK_ERROR(mappable_->ReadFully(&header_, sizeof(dart::mach_o::mach_header)),
              "Could not read Mach-O file.");

  CHECK_ERROR(header_.magic == dart::mach_o::MH_MAGIC ||
                  header_.magic == dart::mach_o::MH_MAGIC_64,
              "Expected a host-endian Mach-O object.");

  CHECK_ERROR(header_.filetype == dart::mach_o::MH_DYLIB,
              "Can only load Mach-O dynamic libraries.");

#if defined(TARGET_ARCH_IA32)
  CHECK_ERROR(header_.cputype == dart::mach_o::CPU_TYPE_I386,
              "Architecture mismatch.");
  CHECK_ERROR(header_.cpusubtype == dart::mach_o::CPU_SUBTYPE_I386_ALL,
              "Unexpected subtype of X86 specified");
#elif defined(TARGET_ARCH_X64)
  CHECK_ERROR(header_.cputype == dart::mach_o::CPU_TYPE_X86_64,
              "Architecture mismatch.");
  CHECK_ERROR(header_.cpusubtype == dart::mach_o::CPU_SUBTYPE_X86_64_ALL,
              "Unexpected subtype of X86_64 specified");
#elif defined(TARGET_ARCH_ARM)
  CHECK_ERROR(header_.cputype == dart::mach_o::CPU_TYPE_ARM,
              "Architecture mismatch.");
  CHECK_ERROR(header_.cpusubtype == dart::mach_o::CPU_SUBTYPE_ARM_ALL,
              "Unexpected subtype of ARM specified");
#elif defined(TARGET_ARCH_ARM64)
  CHECK_ERROR(header_.cputype == dart::mach_o::CPU_TYPE_ARM64,
              "Architecture mismatch.");
  CHECK_ERROR(header_.cpusubtype == dart::mach_o::CPU_SUBTYPE_ARM64_ALL,
              "Unexpected subtype of ARM64 specified");
#else
  // Not an architecture with appropriate constants defined in <mach/machine.h>,
  // which means we set the cpu type and subtype to ANY as the snapshot header
  // check after loading also catches any architecture mismatches.
  CHECK_ERROR(header_.cputype == dart::mach_o::CPU_TYPE_ANY,
              "Architecture mismatch.");
  CHECK_ERROR(header_.cpusubtype == dart::mach_o::CPU_SUBTYPE_ANY,
              "Unexpected subtype specified");
#endif

  const uword file_start = header_.magic == dart::mach_o::MH_MAGIC_64
                               ? sizeof(dart::mach_o::mach_header_64)
                               : sizeof(dart::mach_o::mach_header);
  const uword file_length = header_.sizeofcmds;
  load_commands_mapping_.reset(
      MapFilePiece(file_start, file_length,
                   reinterpret_cast<const void**>(&load_commands_)));
  CHECK_ERROR(load_commands_mapping_ != nullptr,
              "Could not mmap the load commands.");
  return true;
}

bool LoadedMachODylib::LoadSegments() {
  // Calculate the total amount of virtual memory needed.
  uint64_t total_memory = 0;
  {
    LoadCommandIterator it(load_commands_, header_.sizeofcmds);
    while (!it.Done()) {
      auto* const current = it.current();
      if (current->cmd == dart::mach_o::LC_SEGMENT) {
        auto* const segment =
            reinterpret_cast<const dart::mach_o::segment_command*>(current);
        total_memory = Utils::Maximum<uint64_t>(
            segment->vmaddr + segment->vmsize, total_memory);
      } else if (current->cmd == dart::mach_o::LC_SEGMENT_64) {
        auto* const segment_64 =
            reinterpret_cast<const dart::mach_o::segment_command_64*>(current);
        total_memory = Utils::Maximum<uint64_t>(
            segment_64->vmaddr + segment_64->vmsize, total_memory);
      }
      it.Advance();
    }
  }
  total_memory = Utils::RoundUp(total_memory, PageSize());

  base_.reset(VirtualMemory::Allocate(total_memory,
                                      /*is_executable=*/false,
                                      "dart-compiled-image"));
  CHECK_ERROR(base_ != nullptr, "Could not reserve virtual memory.");

  {
    LoadCommandIterator it(load_commands_, header_.sizeofcmds);
    while (!it.Done()) {
      auto* const current = it.current();
      uint64_t memory_offset, memory_size, file_offset, file_size;
      dart::mach_o::vm_prot_t initprot;
#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
      uint64_t records_address = 0, records_size = 0;
#endif
      if (current->cmd == dart::mach_o::LC_SEGMENT) {
        auto* const segment =
            reinterpret_cast<const dart::mach_o::segment_command*>(current);
        memory_offset = segment->vmaddr;
        memory_size = segment->vmsize;
        file_offset = segment->fileoff;
        file_size = segment->filesize;
        initprot = segment->initprot;
#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
        if ((initprot & dart::mach_o::VM_PROT_EXECUTE) != 0) {
          auto* const start =
              reinterpret_cast<const dart::mach_o::section*>(segment + 1);
          const size_t size_in_bytes = segment->cmdsize - sizeof(*segment);
          MachOStructIterator sections(start, size_in_bytes);
          for (const auto& section : sections) {
            if (strcmp(section.sectname, dart::mach_o::SECT_UNWIND_INFO) == 0) {
              records_address = section.addr;
              records_size = section.size;
              break;
            }
          }
        }
#endif
      } else if (current->cmd == dart::mach_o::LC_SEGMENT_64) {
        auto* const segment_64 =
            reinterpret_cast<const dart::mach_o::segment_command_64*>(current);
        memory_offset = segment_64->vmaddr;
        memory_size = segment_64->vmsize;
        file_offset = segment_64->fileoff;
        file_size = segment_64->filesize;
        initprot = segment_64->initprot;
#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
        if ((initprot & dart::mach_o::VM_PROT_EXECUTE) != 0) {
          auto* const start =
              reinterpret_cast<const dart::mach_o::section_64*>(segment_64 + 1);
          const size_t size_in_bytes =
              segment_64->cmdsize - sizeof(*segment_64);
          MachOStructIterator sections(start, size_in_bytes);
          for (const auto& section : sections) {
            if (strcmp(section.sectname, dart::mach_o::SECT_UNWIND_INFO) == 0) {
              records_address = section.addr;
              records_size = section.size;
              break;
            }
          }
        }
#endif
      } else {
        it.Advance();
        continue;
      }

      const uint64_t adjustment = memory_offset % PageSize();
      CHECK_ERROR(
          adjustment == (file_offset % PageSize()),
          "Difference between file and memory offset must be page-aligned.");

      void* const memory_start =
          static_cast<char*>(base_->address()) + memory_offset - adjustment;
      const uword file_start = macho_data_offset_ + file_offset - adjustment;
      const uword length = memory_size + adjustment;

      File::MapType map_type = File::kReadOnly;
      if (initprot ==
          (dart::mach_o::VM_PROT_READ | dart::mach_o::VM_PROT_WRITE)) {
        map_type = File::kReadWrite;
      } else if (initprot ==
                 (dart::mach_o::VM_PROT_READ | dart::mach_o::VM_PROT_EXECUTE)) {
        map_type = File::kReadExecute;
      } else if (initprot == dart::mach_o::VM_PROT_READ) {
        map_type = File::kReadOnly;
      } else {
        Syslog::PrintErr("VM protection flags were: 0x%x\n", initprot);
        ERROR("Unsupported VM protection flags set.");
      }

#if defined(DART_HOST_OS_FUCHSIA)
      // mmap is less flexible on Fuchsia than on Linux and Darwin, in
      // (at least) two important ways:
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
        it.Advance();
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
#if defined(UNWINDING_RECORDS_WINDOWS_HOST)
      // For executable pages register unwinding information that should be
      // present on the page.
      if (map_type == File::kReadExecute) {
        CHECK_ERROR(records_address != 0,
                    "No __unwind_info section found in segment");
        CHECK_ERROR(records_size == UnwindingRecordsPlatform::SizeInBytes(),
                    "__unwind_info section does not contain expected "
                    "unwinding records");
        void* ptable = nullptr;
        void* start = memory->address();
        void* records_start = reinterpret_cast<void*>(
            reinterpret_cast<uword>(memory->address()) + adjustment +
            (records_address - memory_offset));
        UnwindingRecordsPlatform::RegisterExecutableMemory(
            start, length, records_start, &ptable);
        dynamic_runtime_function_tables_.Add(ptable);
      }
#else
      USE(file_size);
#endif
      it.Advance();
    }
  }

  return true;
}

bool LoadedMachODylib::ReadDynamicSymbolTable() {
  const dart::mach_o::symtab_command* symtab = nullptr;
  const dart::mach_o::dysymtab_command* dysymtab = nullptr;
  LoadCommandIterator it(load_commands_, header_.sizeofcmds);
  while (!it.Done()) {
    auto* const c = it.current();
    if (c->cmd == dart::mach_o::LC_SYMTAB) {
      symtab = reinterpret_cast<const dart::mach_o::symtab_command*>(c);
    } else if (c->cmd == dart::mach_o::LC_DYSYMTAB) {
      dysymtab = reinterpret_cast<const dart::mach_o::dysymtab_command*>(c);
    }
    it.Advance();
  }
  CHECK_ERROR(symtab != nullptr, "Could not locate symbol table.");
  CHECK_ERROR(dysymtab != nullptr, "Could not locate dynamic symbol table.");
  CHECK_ERROR(dysymtab->iextdefsym + dysymtab->nextdefsym <= symtab->nsyms,
              "Dynamic symbol table offsets are out of range.");

  {
    const uword file_start = symtab->stroff;
    const uword file_length = symtab->strsize;
    string_table_mapping_.reset(
        MapFilePiece(file_start, file_length,
                     reinterpret_cast<const void**>(&string_table_)));
    CHECK_ERROR(string_table_mapping_ != nullptr,
                "Could not mmap the string table.");
  }
  external_symbol_count_ = dysymtab->nextdefsym;
  {
    // Note that the offset iextdefsym is the offset into the symbol table in
    // terms of symbols, not in terms of raw bytes.
    const intptr_t symbol_size = sizeof(dart::mach_o::nlist);
    const uword file_start =
        symtab->symoff + dysymtab->iextdefsym * symbol_size;
    const uword file_length = dysymtab->nextdefsym * symbol_size;
    external_symbols_mapping_.reset(
        MapFilePiece(file_start, file_length,
                     reinterpret_cast<const void**>(&external_symbols_)));
    CHECK_ERROR(external_symbols_mapping_ != nullptr,
                "Could not mmap the external symbols.");
  }
  return true;
}

bool LoadedMachODylib::ResolveSymbols(const uint8_t** vm_data,
                                      const uint8_t** vm_instrs,
                                      const uint8_t** isolate_data,
                                      const uint8_t** isolate_instrs) {
  if (error_ != nullptr) {
    return false;
  }

  for (uword i = 0; i < external_symbol_count_; ++i) {
    const auto& sym = external_symbols_[i];
    const char* name = string_table_ + sym.n_idx;
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
      *output = reinterpret_cast<const uint8_t*>(base_->start() + sym.n_value);
    }
  }

  CHECK_ERROR(isolate_data == nullptr || *isolate_data != nullptr,
              "Could not find isolate snapshot data.");
  CHECK_ERROR(isolate_instrs == nullptr || *isolate_instrs != nullptr,
              "Could not find isolate instructions.");
  return true;
}

MappedMemory* LoadedMachODylib::MapFilePiece(uword file_start,
                                             uword file_length,
                                             const void** mem_start) {
  const uword adjustment = (macho_data_offset_ + file_start) % PageSize();
  const uword mapping_offset = macho_data_offset_ + file_start - adjustment;
  const uword mapping_length =
      Utils::RoundUp(macho_data_offset_ + file_start + file_length,
                     PageSize()) -
      mapping_offset;
  MappedMemory* const mapping =
      mappable_->Map(bin::File::kReadOnly, mapping_offset, mapping_length);

  if (mapping != nullptr) {
    *mem_start = reinterpret_cast<uint8_t*>(mapping->start() +
                                            (file_start % PageSize()));
  }

  return mapping;
}

}  // namespace mach_o
}  // namespace bin
}  // namespace dart

using namespace dart::bin::mach_o;  // NOLINT
using Mappable = dart::bin::Mappable;

#if defined(DART_HOST_OS_FUCHSIA) || defined(DART_HOST_OS_LINUX)
DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib_Fd(
    int fd,
    uint64_t file_offset,
    const char** error,
    const uint8_t** vm_snapshot_data,
    const uint8_t** vm_snapshot_instrs,
    const uint8_t** vm_isolate_data,
    const uint8_t** vm_isolate_instrs) {
  std::unique_ptr<Mappable> mappable(Mappable::FromFD(fd));
  std::unique_ptr<LoadedMachODylib> macho(
      new LoadedMachODylib(std::move(mappable), file_offset));

  if (!macho->Load() ||
      !macho->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                             vm_isolate_data, vm_isolate_instrs)) {
    *error = macho->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedMachODylib*>(macho.release());
}
#endif

DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib(
    const char* filename,
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
  std::unique_ptr<LoadedMachODylib> macho(
      new LoadedMachODylib(std::move(mappable), file_offset));

  if (!macho->Load() ||
      !macho->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                             vm_isolate_data, vm_isolate_instrs)) {
    *error = macho->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedMachODylib*>(macho.release());
}

DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib_Memory(
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
  std::unique_ptr<LoadedMachODylib> macho(
      new LoadedMachODylib(std::move(mappable), /*macho_data_offset=*/0));

  if (!macho->Load() ||
      !macho->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                             vm_isolate_data, vm_isolate_instrs)) {
    *error = macho->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedMachODylib*>(macho.release());
}

DART_EXPORT void Dart_UnloadMachODylib(Dart_LoadedMachODylib* loaded) {
  delete reinterpret_cast<LoadedMachODylib*>(loaded);
}
