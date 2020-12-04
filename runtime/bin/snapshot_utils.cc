// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>

#include "bin/snapshot_utils.h"

#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/elf_loader.h"
#include "bin/error_exit.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "include/dart_api.h"
#include "platform/utils.h"

#define LOG_SECTION_BOUNDARIES false

namespace dart {
namespace bin {

static const int64_t kAppSnapshotHeaderSize = 5 * kInt64Size;
static const int64_t kAppSnapshotPageSize = 16 * KB;

class MappedAppSnapshot : public AppSnapshot {
 public:
  MappedAppSnapshot(MappedMemory* vm_snapshot_data,
                    MappedMemory* vm_snapshot_instructions,
                    MappedMemory* isolate_snapshot_data,
                    MappedMemory* isolate_snapshot_instructions)
      : vm_data_mapping_(vm_snapshot_data),
        vm_instructions_mapping_(vm_snapshot_instructions),
        isolate_data_mapping_(isolate_snapshot_data),
        isolate_instructions_mapping_(isolate_snapshot_instructions) {}

  ~MappedAppSnapshot() {
    delete vm_data_mapping_;
    delete vm_instructions_mapping_;
    delete isolate_data_mapping_;
    delete isolate_instructions_mapping_;
  }

  void SetBuffers(const uint8_t** vm_data_buffer,
                  const uint8_t** vm_instructions_buffer,
                  const uint8_t** isolate_data_buffer,
                  const uint8_t** isolate_instructions_buffer) {
    if (vm_data_mapping_ != NULL) {
      *vm_data_buffer =
          reinterpret_cast<const uint8_t*>(vm_data_mapping_->address());
    }
    if (vm_instructions_mapping_ != NULL) {
      *vm_instructions_buffer =
          reinterpret_cast<const uint8_t*>(vm_instructions_mapping_->address());
    }
    if (isolate_data_mapping_ != NULL) {
      *isolate_data_buffer =
          reinterpret_cast<const uint8_t*>(isolate_data_mapping_->address());
    }
    if (isolate_instructions_mapping_ != NULL) {
      *isolate_instructions_buffer = reinterpret_cast<const uint8_t*>(
          isolate_instructions_mapping_->address());
    }
  }

 private:
  MappedMemory* vm_data_mapping_;
  MappedMemory* vm_instructions_mapping_;
  MappedMemory* isolate_data_mapping_;
  MappedMemory* isolate_instructions_mapping_;
};

static AppSnapshot* TryReadAppSnapshotBlobs(const char* script_name,
                                            File* file) {
  if ((file->Length() - file->Position()) < kAppSnapshotHeaderSize) {
    return nullptr;
  }

  int64_t header[5];
  ASSERT(sizeof(header) == kAppSnapshotHeaderSize);
  if (!file->ReadFully(&header, kAppSnapshotHeaderSize)) {
    return nullptr;
  }
  ASSERT(sizeof(header[0]) == appjit_magic_number.length);
  if (memcmp(&header[0], appjit_magic_number.bytes,
             appjit_magic_number.length) != 0) {
    return nullptr;
  }

  int64_t vm_data_size = header[1];
  int64_t vm_data_position =
      Utils::RoundUp(file->Position(), kAppSnapshotPageSize);
  int64_t vm_instructions_size = header[2];
  int64_t vm_instructions_position = vm_data_position + vm_data_size;
  if (vm_instructions_size != 0) {
    vm_instructions_position =
        Utils::RoundUp(vm_instructions_position, kAppSnapshotPageSize);
  }
  int64_t isolate_data_size = header[3];
  int64_t isolate_data_position = Utils::RoundUp(
      vm_instructions_position + vm_instructions_size, kAppSnapshotPageSize);
  int64_t isolate_instructions_size = header[4];
  int64_t isolate_instructions_position =
      isolate_data_position + isolate_data_size;
  if (isolate_instructions_size != 0) {
    isolate_instructions_position =
        Utils::RoundUp(isolate_instructions_position, kAppSnapshotPageSize);
  }

  MappedMemory* vm_data_mapping = nullptr;
  if (vm_data_size != 0) {
    vm_data_mapping =
        file->Map(File::kReadOnly, vm_data_position, vm_data_size);
    if (vm_data_mapping == nullptr) {
      FATAL1("Failed to memory map snapshot: %s\n", script_name);
    }
  }

  MappedMemory* vm_instr_mapping = nullptr;
  if (vm_instructions_size != 0) {
    vm_instr_mapping = file->Map(File::kReadExecute, vm_instructions_position,
                                 vm_instructions_size);
    if (vm_instr_mapping == nullptr) {
      FATAL1("Failed to memory map snapshot: %s\n", script_name);
    }
  }

  MappedMemory* isolate_data_mapping = nullptr;
  if (isolate_data_size != 0) {
    isolate_data_mapping =
        file->Map(File::kReadOnly, isolate_data_position, isolate_data_size);
    if (isolate_data_mapping == nullptr) {
      FATAL1("Failed to memory map snapshot: %s\n", script_name);
    }
  }

  MappedMemory* isolate_instr_mapping = nullptr;
  if (isolate_instructions_size != 0) {
    isolate_instr_mapping =
        file->Map(File::kReadExecute, isolate_instructions_position,
                  isolate_instructions_size);
    if (isolate_instr_mapping == nullptr) {
      FATAL1("Failed to memory map snapshot: %s\n", script_name);
    }
  }

  return new MappedAppSnapshot(vm_data_mapping, vm_instr_mapping,
                               isolate_data_mapping, isolate_instr_mapping);
}

static AppSnapshot* TryReadAppSnapshotBlobs(const char* script_name) {
  File* file = File::Open(NULL, script_name, File::kRead);
  if (file == nullptr) {
    return nullptr;
  }
  RefCntReleaseScope<File> rs(file);
  return TryReadAppSnapshotBlobs(script_name, file);
}

#if defined(DART_PRECOMPILED_RUNTIME)
class ElfAppSnapshot : public AppSnapshot {
 public:
  ElfAppSnapshot(Dart_LoadedElf* elf,
                 const uint8_t* vm_snapshot_data,
                 const uint8_t* vm_snapshot_instructions,
                 const uint8_t* isolate_snapshot_data,
                 const uint8_t* isolate_snapshot_instructions)
      : elf_(elf),
        vm_snapshot_data_(vm_snapshot_data),
        vm_snapshot_instructions_(vm_snapshot_instructions),
        isolate_snapshot_data_(isolate_snapshot_data),
        isolate_snapshot_instructions_(isolate_snapshot_instructions) {}

  virtual ~ElfAppSnapshot() { Dart_UnloadELF(elf_); }

  void SetBuffers(const uint8_t** vm_data_buffer,
                  const uint8_t** vm_instructions_buffer,
                  const uint8_t** isolate_data_buffer,
                  const uint8_t** isolate_instructions_buffer) {
    *vm_data_buffer = vm_snapshot_data_;
    *vm_instructions_buffer = vm_snapshot_instructions_;
    *isolate_data_buffer = isolate_snapshot_data_;
    *isolate_instructions_buffer = isolate_snapshot_instructions_;
  }

 private:
  Dart_LoadedElf* elf_;
  const uint8_t* vm_snapshot_data_;
  const uint8_t* vm_snapshot_instructions_;
  const uint8_t* isolate_snapshot_data_;
  const uint8_t* isolate_snapshot_instructions_;
};

static AppSnapshot* TryReadAppSnapshotElf(
    const char* script_name,
    uint64_t file_offset,
    bool force_load_elf_from_memory = false) {
  const char* error = nullptr;
  const uint8_t *vm_data_buffer = nullptr, *vm_instructions_buffer = nullptr,
                *isolate_data_buffer = nullptr,
                *isolate_instructions_buffer = nullptr;
  Dart_LoadedElf* handle = nullptr;
#if !defined(HOST_OS_FUCHSIA)
  if (force_load_elf_from_memory) {
#endif
    File* const file =
        File::Open(/*namespc=*/nullptr, script_name, File::kRead);
    if (file == nullptr) return nullptr;
    MappedMemory* memory = file->Map(File::kReadOnly, /*position=*/0,
                                     /*length=*/file->Length());
    if (memory == nullptr) return nullptr;
    const uint8_t* address =
        reinterpret_cast<const uint8_t*>(memory->address());
    handle =
        Dart_LoadELF_Memory(address + file_offset, file->Length(), &error,
                            &vm_data_buffer, &vm_instructions_buffer,
                            &isolate_data_buffer, &isolate_instructions_buffer);
    delete memory;
    file->Release();
#if !defined(HOST_OS_FUCHSIA)
  } else {
    handle = Dart_LoadELF(script_name, file_offset, &error, &vm_data_buffer,
                          &vm_instructions_buffer, &isolate_data_buffer,
                          &isolate_instructions_buffer);
  }
#endif
  if (handle == nullptr) {
    Syslog::PrintErr("Loading failed: %s\n", error);
    return nullptr;
  }
  return new ElfAppSnapshot(handle, vm_data_buffer, vm_instructions_buffer,
                            isolate_data_buffer, isolate_instructions_buffer);
  return nullptr;
}

AppSnapshot* Snapshot::TryReadAppendedAppSnapshotElf(
    const char* container_path) {
  File* file = File::Open(NULL, container_path, File::kRead);
  if (file == nullptr) {
    return nullptr;
  }
  RefCntReleaseScope<File> rs(file);

  // Check for payload appended at the end of the container file.
  // If header is found, jump to payload offset.
  int64_t appended_header[2];
  if (!file->SetPosition(file->Length() - sizeof(appended_header))) {
    return nullptr;
  }
  if (!file->ReadFully(&appended_header, sizeof(appended_header))) {
    return nullptr;
  }
  // Length is always encoded as Little Endian.
  const uint64_t appended_offset =
      Utils::LittleEndianToHost64(appended_header[0]);
  if (memcmp(&appended_header[1], appjit_magic_number.bytes,
             appjit_magic_number.length) != 0 ||
      appended_offset <= 0) {
    return nullptr;
  }

  return TryReadAppSnapshotElf(container_path, appended_offset);
}

class DylibAppSnapshot : public AppSnapshot {
 public:
  DylibAppSnapshot(void* library,
                   const uint8_t* vm_snapshot_data,
                   const uint8_t* vm_snapshot_instructions,
                   const uint8_t* isolate_snapshot_data,
                   const uint8_t* isolate_snapshot_instructions)
      : library_(library),
        vm_snapshot_data_(vm_snapshot_data),
        vm_snapshot_instructions_(vm_snapshot_instructions),
        isolate_snapshot_data_(isolate_snapshot_data),
        isolate_snapshot_instructions_(isolate_snapshot_instructions) {}

  ~DylibAppSnapshot() { Extensions::UnloadLibrary(library_); }

  void SetBuffers(const uint8_t** vm_data_buffer,
                  const uint8_t** vm_instructions_buffer,
                  const uint8_t** isolate_data_buffer,
                  const uint8_t** isolate_instructions_buffer) {
    *vm_data_buffer = vm_snapshot_data_;
    *vm_instructions_buffer = vm_snapshot_instructions_;
    *isolate_data_buffer = isolate_snapshot_data_;
    *isolate_instructions_buffer = isolate_snapshot_instructions_;
  }

 private:
  void* library_;
  const uint8_t* vm_snapshot_data_;
  const uint8_t* vm_snapshot_instructions_;
  const uint8_t* isolate_snapshot_data_;
  const uint8_t* isolate_snapshot_instructions_;
};

static AppSnapshot* TryReadAppSnapshotDynamicLibrary(const char* script_name) {
  void* library = Extensions::LoadExtensionLibrary(script_name);
  if (library == NULL) {
    return NULL;
  }

  const uint8_t* vm_data_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kVmSnapshotDataCSymbol));

  const uint8_t* vm_instructions_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kVmSnapshotInstructionsCSymbol));

  const uint8_t* isolate_data_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kIsolateSnapshotDataCSymbol));
  if (isolate_data_buffer == NULL) {
    FATAL1("Failed to resolve symbol '%s'\n", kIsolateSnapshotDataCSymbol);
  }

  const uint8_t* isolate_instructions_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kIsolateSnapshotInstructionsCSymbol));
  if (isolate_instructions_buffer == NULL) {
    FATAL1("Failed to resolve symbol '%s'\n",
           kIsolateSnapshotInstructionsCSymbol);
  }

  return new DylibAppSnapshot(library, vm_data_buffer, vm_instructions_buffer,
                              isolate_data_buffer, isolate_instructions_buffer);
}

#endif  // defined(DART_PRECOMPILED_RUNTIME)

AppSnapshot* Snapshot::TryReadAppSnapshot(const char* script_uri,
                                          bool force_load_elf_from_memory) {
  auto decoded_path = File::UriToPath(script_uri);
  if (decoded_path == nullptr) {
    return nullptr;
  }

  const char* script_name = decoded_path.get();
  if (File::GetType(nullptr, script_name, true) != File::kIsFile) {
    // If 'script_name' refers to a pipe, don't read to check for an app
    // snapshot since we cannot rewind if it isn't (and couldn't mmap it in
    // anyway if it was).
    return nullptr;
  }
  AppSnapshot* snapshot = TryReadAppSnapshotBlobs(script_name);
  if (snapshot != nullptr) {
    return snapshot;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  // For testing AOT with the standalone embedder, we also support loading
  // from a dynamic library to simulate what happens on iOS.

#if defined(TARGET_OS_LINUX) || defined(TARGET_OS_MACOS)
  // On Linux and OSX, resolve the script path before passing into dlopen()
  // since dlopen will not search the filesystem for paths like 'libtest.so'.
  std::unique_ptr<char, decltype(std::free)*> absolute_path{
      realpath(script_name, nullptr), std::free};
  script_name = absolute_path.get();
#endif

  if (!force_load_elf_from_memory) {
    snapshot = TryReadAppSnapshotDynamicLibrary(script_name);
    if (snapshot != nullptr) {
      return snapshot;
    }
  }

  snapshot = TryReadAppSnapshotElf(script_name, /*file_offset=*/0,
                                   force_load_elf_from_memory);
  if (snapshot != nullptr) {
    return snapshot;
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
  return nullptr;
}

#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM) && !defined(TESTING)
static void WriteSnapshotFile(const char* filename,
                              const uint8_t* buffer,
                              const intptr_t size) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s for writing snapshot\n",
              filename);
  }

  if (!file->WriteFully(buffer, size)) {
    ErrorExit(kErrorExitCode, "Unable to write file %s for writing snapshot\n",
              filename);
  }
  file->Release();
}
#endif

static bool WriteInt64(File* file, int64_t size) {
  return file->WriteFully(&size, sizeof(size));
}

void Snapshot::WriteAppSnapshot(const char* filename,
                                uint8_t* vm_data_buffer,
                                intptr_t vm_data_size,
                                uint8_t* vm_instructions_buffer,
                                intptr_t vm_instructions_size,
                                uint8_t* isolate_data_buffer,
                                intptr_t isolate_data_size,
                                uint8_t* isolate_instructions_buffer,
                                intptr_t isolate_instructions_size) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  file->WriteFully(appjit_magic_number.bytes, appjit_magic_number.length);
  WriteInt64(file, vm_data_size);
  WriteInt64(file, vm_instructions_size);
  WriteInt64(file, isolate_data_size);
  WriteInt64(file, isolate_instructions_size);
  ASSERT(file->Position() == kAppSnapshotHeaderSize);

  file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
  if (LOG_SECTION_BOUNDARIES) {
    Syslog::PrintErr("%" Px64 ": VM Data\n", file->Position());
  }
  if (!file->WriteFully(vm_data_buffer, vm_data_size)) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  if (vm_instructions_size != 0) {
    file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
    if (LOG_SECTION_BOUNDARIES) {
      Syslog::PrintErr("%" Px64 ": VM Instructions\n", file->Position());
    }
    if (!file->WriteFully(vm_instructions_buffer, vm_instructions_size)) {
      ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n",
                filename);
    }
  }

  file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
  if (LOG_SECTION_BOUNDARIES) {
    Syslog::PrintErr("%" Px64 ": Isolate Data\n", file->Position());
  }
  if (!file->WriteFully(isolate_data_buffer, isolate_data_size)) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  if (isolate_instructions_size != 0) {
    file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
    if (LOG_SECTION_BOUNDARIES) {
      Syslog::PrintErr("%" Px64 ": Isolate Instructions\n", file->Position());
    }
    if (!file->WriteFully(isolate_instructions_buffer,
                          isolate_instructions_size)) {
      ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n",
                filename);
    }
  }

  file->Flush();
  file->Release();
}

void Snapshot::GenerateKernel(const char* snapshot_filename,
                              const char* script_name,
                              const char* package_config) {
#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM) && !defined(TESTING)
  uint8_t* kernel_buffer = NULL;
  intptr_t kernel_buffer_size = 0;
  dfe.ReadScript(script_name, &kernel_buffer, &kernel_buffer_size);
  if (kernel_buffer != NULL) {
    WriteSnapshotFile(snapshot_filename, kernel_buffer, kernel_buffer_size);
    free(kernel_buffer);
  } else {
    Dart_KernelCompilationResult result =
        dfe.CompileScript(script_name, false, package_config);
    if (result.status != Dart_KernelCompilationStatus_Ok) {
      ErrorExit(kErrorExitCode, "%s\n", result.error);
    }
    WriteSnapshotFile(snapshot_filename, result.kernel, result.kernel_size);
    free(result.kernel);
  }
#else
  UNREACHABLE();
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM) && !defined(TESTING)
}

void Snapshot::GenerateAppJIT(const char* snapshot_filename) {
#if defined(TARGET_ARCH_IA32)
  // Snapshots with code are not supported on IA32.
  uint8_t* isolate_buffer = NULL;
  intptr_t isolate_size = 0;

  Dart_Handle result = Dart_CreateSnapshot(NULL, NULL, &isolate_buffer,
                                           &isolate_size, /*is_core=*/false);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }

  WriteAppSnapshot(snapshot_filename, NULL, 0, NULL, 0, isolate_buffer,
                   isolate_size, NULL, 0);
#else
  uint8_t* isolate_data_buffer = NULL;
  intptr_t isolate_data_size = 0;
  uint8_t* isolate_instructions_buffer = NULL;
  intptr_t isolate_instructions_size = 0;
  Dart_Handle result = Dart_CreateAppJITSnapshotAsBlobs(
      &isolate_data_buffer, &isolate_data_size, &isolate_instructions_buffer,
      &isolate_instructions_size);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }
  WriteAppSnapshot(snapshot_filename, NULL, 0, NULL, 0, isolate_data_buffer,
                   isolate_data_size, isolate_instructions_buffer,
                   isolate_instructions_size);
#endif
}

static void StreamingWriteCallback(void* callback_data,
                                   const uint8_t* buffer,
                                   intptr_t size) {
  File* file = reinterpret_cast<File*>(callback_data);
  if (!file->WriteFully(buffer, size)) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file\n");
  }
}

void Snapshot::GenerateAppAOTAsAssembly(const char* snapshot_filename) {
  File* file = File::Open(NULL, snapshot_filename, File::kWriteTruncate);
  RefCntReleaseScope<File> rs(file);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s for writing snapshot\n",
              snapshot_filename);
  }
  Dart_Handle result = Dart_CreateAppAOTSnapshotAsAssembly(
      StreamingWriteCallback, file, /*strip=*/false,
      /*debug_callback_data=*/nullptr);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }
}

bool Snapshot::IsAOTSnapshot(const char* snapshot_filename) {
  // Header is simply "ELF" prefixed with the DEL character.
  const char elf_header[] = {0x7F, 0x45, 0x4C, 0x46, 0x0};
  const int64_t elf_header_len = strlen(elf_header);
  File* file = File::Open(NULL, snapshot_filename, File::kRead);
  if (file == nullptr) {
    return false;
  }
  if (file->Length() < elf_header_len) {
    file->Release();
    return false;
  }
  auto buf = std::unique_ptr<char[]>(new char[elf_header_len]);
  bool success = file->ReadFully(buf.get(), elf_header_len);
  file->Release();
  ASSERT(success);
  return (strncmp(elf_header, buf.get(), elf_header_len) == 0);
}

}  // namespace bin
}  // namespace dart
