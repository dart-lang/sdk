// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/mach_o_loader.h"
#include <sys/types.h>

#include "platform/globals.h"

#include <cstdio>
#include <functional>
#include <memory>
#include <utility>

#include "bin/file.h"
#include "bin/virtual_memory.h"
#include "platform/utils.h"

#include "platform/mach_o.h"
#include "platform/syslog.h"
#include "platform/unwinding_records.h"
#include "vm/compiler/runtime_api.h"

namespace dart {
namespace bin {

namespace mach_o {

// This mappable abstraction matches what ElfLoader uses, but probably
// could be removed since we don't need to support loading from memory.
class Mappable {
 public:
  static Mappable* FromPath(const char* path);

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

Mappable* Mappable::FromPath(const char* path) {
  return new FileMappable(File::Open(/*namespc=*/nullptr, path, File::kRead));
}

/// A loader for a subset of Mach-O which can be used to load AOT snapshots
/// built for iOS by XCode from the output of gen_snapshot in app-aot-assembly
/// or vm-aot-assembly mode.
class LoadedMachO {
 public:
  // Unlike LoadedElf, LoadedMachO does not take an offset, it uses
  // the offset from the fat header to the Mach-O header.  This could be
  // easily changed if needed.
  explicit LoadedMachO(std::unique_ptr<Mappable> mappable)
      : mappable_(std::move(mappable)) {}

  ~LoadedMachO();

  /// Loads the Mach-O object into memory. Returns whether the load was
  /// successful. On failure, the error may be retrieved by 'error()'.
  bool Load();

  /// Reads Dart-specific symbols from the loaded Mach-O file.
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
  bool ReadFatHeader(dart::mach_o::fat_header& fat_header);
  bool LoadArch(const dart::mach_o::fat_header& fat_header,
                dart::mach_o::fat_arch& fat_arch,
                dart::mach_o::cpu_type_t cpu_type);
  bool ReadMachOHeader();
  bool ReadLoadCommands();
  bool LoadSegments();

  bool ForEachLoadCommand(
      std::function<bool(const dart::mach_o::load_command*)> callback);
  bool LoadSegment(const dart::mach_o::segment_command_64& segment);

  // TODO(eseidel): LoadedMachO is intended for analysis (not execution) and
  // should work on machines with different page size than the target.
  // This should probably just hardcode to 16KB, matching iOS and MacOS.
  static uword PageSize() { return VirtualMemory::PageSize(); }

  // Unlike File::Map, allows non-aligned 'start' and 'length'.
  MappedMemory* MapFilePiece(uword start,
                             uword length,
                             const void** mapping_start);

  // Initialized on a successful Load().
  // mappable_ is the entire file.
  std::unique_ptr<Mappable> mappable_;
  // mach_o_data_offset is the offset into mapped_ where the mach-o header
  // starts. For a fat file, this will be the offset of the architecture
  // being loaded, for a "thin" file it will be 0.
  uint64_t mach_o_data_offset_ = 0;

  // Initialized on error.
  const char* error_ = nullptr;

  // Initialized by ReadMachOHeader().
  dart::mach_o::mach_header_64 header_;

  // Initialized by ReadLoadCommands().
  std::unique_ptr<MappedMemory> load_commands_mapping_;
  const dart::mach_o::load_command* load_commands_ = nullptr;

  // Initialized by LoadSegments().
  std::unique_ptr<VirtualMemory> base_;
  dart::mach_o::segment_command_64 link_edit_segment_ = {0};
  dart::mach_o::nlist_64* symbol_table_ = nullptr;
  uint32_t symbol_table_length_ = 0;
  const char* string_table_ = nullptr;

  DISALLOW_COPY_AND_ASSIGN(LoadedMachO);
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

bool LoadedMachO::Load() {
  VirtualMemory::Init();
  if (error_ != nullptr) {
    return false;
  }
  ASSERT(mappable_ != nullptr);
  // Read the fat header if it exists and jump to the architecture we are
  // reading.  Failure of ReadFatHeader may mean this is a "thin" file
  // and we should just read try reading the Mach-O header directly.
  // iOS and MacOS seem to use a 32-bit fat header even for 64-bit binaries.
  dart::mach_o::fat_header fat_header;
  if (ReadFatHeader(fat_header)) {
    dart::mach_o::fat_arch fat_arch;
    CHECK_ERROR(LoadArch(fat_header, fat_arch, dart::mach_o::CPU_TYPE_ARM64),
                "Failed to load ARM64 architecture.");
    mach_o_data_offset_ = fat_arch.offset;
  }

  // Whether we read a fat header or not, we now try to read the Mach-O header.
  CHECK_ERROR(Utils::IsAligned(mach_o_data_offset_, PageSize()),
              "Mach-O data offset must be page-aligned.");
  CHECK_ERROR(mappable_->SetPosition(mach_o_data_offset_),
              "Invalid file offset.");
  CHECK(ReadMachOHeader());
  CHECK(ReadLoadCommands());
  CHECK(LoadSegments());
  return true;
}

bool LoadedMachO::LoadArch(const dart::mach_o::fat_header& fat_header,
                           dart::mach_o::fat_arch& fat_arch,
                           dart::mach_o::cpu_type_t cpu_type) {
  if (fat_header.magic != dart::mach_o::FAT_MAGIC) {
    ERROR("Not a 32-bit Mach-O fat header.");
  }
  for (uint32_t i = 0; i < fat_header.nfat_arch; i++) {
    CHECK(mappable_->ReadFully(&fat_arch, sizeof(fat_arch)));
    // Mach-O fat header is big endian.
    fat_arch.cputype = Utils::BigEndianToHost32(fat_arch.cputype);
    fat_arch.cpusubtype = Utils::BigEndianToHost32(fat_arch.cpusubtype);
    fat_arch.offset = Utils::BigEndianToHost32(fat_arch.offset);
    fat_arch.size = Utils::BigEndianToHost32(fat_arch.size);
    fat_arch.align = Utils::BigEndianToHost32(fat_arch.align);
    if (fat_arch.cputype == cpu_type) {
      return true;
    }
  }
  return false;
}

bool LoadedMachO::ReadFatHeader(dart::mach_o::fat_header& fat_header) {
  CHECK(mappable_->ReadFully(&fat_header, sizeof(fat_header)));
  // Mach-O fat file header is big endian.
  fat_header.magic = Utils::BigEndianToHost32(fat_header.magic);
  fat_header.nfat_arch = Utils::BigEndianToHost32(fat_header.nfat_arch);
  CHECK_ERROR(fat_header.magic != dart::mach_o::FAT_MAGIC_64,
              "64 bit fat files not supported.");
  CHECK_ERROR(fat_header.magic == dart::mach_o::FAT_MAGIC,
              "Not a Mach-O fat file.");
  return true;
}

bool LoadedMachO::ReadMachOHeader() {
  // Mach-O header and beyond is little endian.
  CHECK(mappable_->ReadFully(&header_, sizeof(header_)));
  CHECK_ERROR(header_.magic == dart::mach_o::MH_MAGIC_64,
              "Not a 64-bit Mach-O file.")
  return true;
}

bool LoadedMachO::ReadLoadCommands() {
  // Mach-O header and beyond is little endian.
  uint64_t commands_start = sizeof(header_);
  uint64_t commands_length = header_.sizeofcmds;
  load_commands_mapping_.reset(
      MapFilePiece(commands_start, commands_length,
                   reinterpret_cast<const void**>(&load_commands_)));
  CHECK(load_commands_mapping_ != nullptr);
  return true;
}

bool LoadedMachO::ForEachLoadCommand(
    std::function<bool(const dart::mach_o::load_command*)> callback) {
  uint64_t commands_length = header_.sizeofcmds;
  const dart::mach_o::load_command* command = load_commands_;
  while (commands_length > 0) {
    if (!callback(command)) {
      return false;
    }
    commands_length -= command->cmdsize;
    command = reinterpret_cast<const dart::mach_o::load_command*>(
        reinterpret_cast<const uint8_t*>(command) + command->cmdsize);
  }
  return true;
}

bool LoadedMachO::LoadSegment(const dart::mach_o::segment_command_64& segment) {
  const uword memory_offset = segment.vmaddr, file_offset = segment.fileoff;
  CHECK_ERROR(
      (memory_offset % PageSize()) == (file_offset % PageSize()),
      "Difference between file and memory offset must be page-aligned.");

  const intptr_t adjustment = segment.vmaddr % PageSize();

  void* const memory_start =
      static_cast<char*>(base_->address()) + memory_offset - adjustment;
  const uword file_start = mach_o_data_offset_ + file_offset - adjustment;
  const uword length = segment.vmsize + adjustment;

  // Even though we only want to read the snapshot, we still need to load
  // the DATA segment RW, or the Dart VM will crash when it tries to write
  // to the BSS segment.
  File::MapType map_type = File::kReadOnly;
  if (segment.initprot ==
      (dart::mach_o::VM_PROT_READ | dart::mach_o::VM_PROT_WRITE)) {
    map_type = File::kReadWrite;
  } else if (segment.initprot ==
             (dart::mach_o::VM_PROT_READ | dart::mach_o::VM_PROT_EXECUTE)) {
    // Ignoring the execute bit for now.
    map_type = File::kReadOnly;
  } else if (segment.initprot == dart::mach_o::VM_PROT_READ) {
    map_type = File::kReadOnly;
  } else {
    ERROR("Unsupported segment initprot set.");
  }

  std::unique_ptr<MappedMemory> memory(
      mappable_->Map(map_type, file_start, length, memory_start));
  CHECK_ERROR(memory != nullptr, "Could not map segment.");
  CHECK_ERROR(memory->address() == memory_start,
              "Mapping not at requested address.");
  return true;
}

bool LoadedMachO::LoadSegments() {
  // Calculate the total amount of virtual memory needed.
  uword total_memory = 0;
  ForEachLoadCommand([&](const dart::mach_o::load_command* command) {
    if (command->cmd == dart::mach_o::LC_SEGMENT_64) {
      const dart::mach_o::segment_command_64* segment =
          reinterpret_cast<const dart::mach_o::segment_command_64*>(command);
      total_memory += segment->vmsize;
    }
    return true;
  });
  total_memory = Utils::RoundUp(total_memory, PageSize());
  base_.reset(VirtualMemory::Allocate(total_memory,
                                      /*is_executable=*/false,
                                      "dart-compiled-image"));
  CHECK_ERROR(base_ != nullptr, "Could not reserve virtual memory.");

  CHECK(ForEachLoadCommand([&](const dart::mach_o::load_command* command) {
    if (command->cmd == dart::mach_o::LC_SEGMENT_64) {
      const dart::mach_o::segment_command_64& segment =
          *reinterpret_cast<const dart::mach_o::segment_command_64*>(command);
      LoadSegment(segment);

      if (strcmp(segment.segname, "__LINKEDIT") == 0) {
        // Remember the link_edit_segment so we can compute the memory location
        // of it's contents (symbol table, string table, etc) which are provided
        // as file offsets in the load commands.
        link_edit_segment_ = segment;
      }
    } else if (command->cmd == dart::mach_o::LC_SYMTAB) {
      CHECK_ERROR(link_edit_segment_.cmd != 0, "Link edit segment not found.");
      CHECK_ERROR(symbol_table_ == nullptr, "Multiple symbol tables found.");
      const dart::mach_o::symtab_command& symtab =
          *reinterpret_cast<const dart::mach_o::symtab_command*>(command);

      uint64_t linkedit_offset =
          link_edit_segment_.vmaddr - link_edit_segment_.fileoff;
      symbol_table_ = reinterpret_cast<dart::mach_o::nlist_64*>(
          base_->start() + symtab.symoff + linkedit_offset);
      symbol_table_length_ = symtab.nsyms;
      string_table_ = reinterpret_cast<const char*>(
          base_->start() + symtab.stroff + linkedit_offset);
    }
    return true;
  }));

  // If we didn't find a symbol table, then we can't resolve symbols.
  CHECK_ERROR(symbol_table_ != nullptr, "No symbol table found.");
  return true;
}

LoadedMachO::~LoadedMachO() {}

bool LoadedMachO::ResolveSymbols(const uint8_t** vm_data,
                                 const uint8_t** vm_instrs,
                                 const uint8_t** isolate_data,
                                 const uint8_t** isolate_instrs) {
  if (error_ != nullptr) {
    return false;
  }

  for (uint32_t i = 0; i < symbol_table_length_; i++) {
    const dart::mach_o::nlist_64& symbol = symbol_table_[i];
    const char* name = string_table_ + symbol.n_un.n_strx;

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
      *output =
          reinterpret_cast<const uint8_t*>(base_->start() + symbol.n_value);
    }
  }

  CHECK_ERROR(isolate_data == nullptr || *isolate_data != nullptr,
              "Could not find isolate snapshot data.");
  CHECK_ERROR(isolate_instrs == nullptr || *isolate_instrs != nullptr,
              "Could not find isolate instructions.");

  return true;
}

MappedMemory* LoadedMachO::MapFilePiece(uword file_start,
                                        uword file_length,
                                        const void** mem_start) {
  const uword adjustment = (mach_o_data_offset_ + file_start) % PageSize();
  const uword mapping_offset = mach_o_data_offset_ + file_start - adjustment;
  const uword mapping_length =
      Utils::RoundUp(mach_o_data_offset_ + file_start + file_length,
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

using namespace dart::bin::mach_o;

DART_EXPORT Dart_LoadedMachO* Dart_LoadMachO(
    const char* filename,
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
  std::unique_ptr<LoadedMachO> mach_o(new LoadedMachO(std::move(mappable)));

  if (!mach_o->Load() ||
      !mach_o->ResolveSymbols(vm_snapshot_data, vm_snapshot_instrs,
                              vm_isolate_data, vm_isolate_instrs)) {
    *error = mach_o->error();
    return nullptr;
  }

  return reinterpret_cast<Dart_LoadedMachO*>(mach_o.release());
}

DART_EXPORT void Dart_UnloadMachO(Dart_LoadedMachO* loaded) {
  delete reinterpret_cast<Dart_LoadedMachO*>(loaded);
}
