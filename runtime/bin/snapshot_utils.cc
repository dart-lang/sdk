// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/snapshot_utils.h"

#include "bin/dartutils.h"
#include "bin/error_exit.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "include/dart_api.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

extern const char* kVmSnapshotDataSymbolName;
extern const char* kVmSnapshotInstructionsSymbolName;
extern const char* kIsolateSnapshotDataSymbolName;
extern const char* kIsolateSnapshotInstructionsSymbolName;

static const int64_t kAppSnapshotHeaderSize = 5 * kInt64Size;
static const int64_t kAppSnapshotMagicNumber = 0xf6f6dcdc;
static const int64_t kAppSnapshotPageSize = 4 * KB;

static bool ReadAppSnapshotBlobs(const char* script_name,
                                 const uint8_t** vm_data_buffer,
                                 const uint8_t** vm_instructions_buffer,
                                 const uint8_t** isolate_data_buffer,
                                 const uint8_t** isolate_instructions_buffer) {
  File* file = File::Open(script_name, File::kRead);
  if (file == NULL) {
    return false;
  }
  if (file->Length() < kAppSnapshotHeaderSize) {
    file->Release();
    return false;
  }
  int64_t header[5];
  ASSERT(sizeof(header) == kAppSnapshotHeaderSize);
  if (!file->ReadFully(&header, kAppSnapshotHeaderSize)) {
    file->Release();
    return false;
  }
  if (header[0] != kAppSnapshotMagicNumber) {
    file->Release();
    return false;
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

  if (vm_data_size != 0) {
    *vm_data_buffer = reinterpret_cast<const uint8_t*>(
        file->Map(File::kReadOnly, vm_data_position, vm_data_size));
    if (vm_data_buffer == NULL) {
      Log::PrintErr("Failed to memory map snapshot\n");
      Platform::Exit(kErrorExitCode);
    }
  }

  if (vm_instructions_size != 0) {
    *vm_instructions_buffer = reinterpret_cast<const uint8_t*>(file->Map(
        File::kReadExecute, vm_instructions_position, vm_instructions_size));
    if (*vm_instructions_buffer == NULL) {
      Log::PrintErr("Failed to memory map snapshot\n");
      Platform::Exit(kErrorExitCode);
    }
  }

  *isolate_data_buffer = reinterpret_cast<const uint8_t*>(
      file->Map(File::kReadOnly, isolate_data_position, isolate_data_size));
  if (isolate_data_buffer == NULL) {
    Log::PrintErr("Failed to memory map snapshot\n");
    Platform::Exit(kErrorExitCode);
  }

  if (isolate_instructions_size == 0) {
    *isolate_instructions_buffer = NULL;
  } else {
    *isolate_instructions_buffer = reinterpret_cast<const uint8_t*>(
        file->Map(File::kReadExecute, isolate_instructions_position,
                  isolate_instructions_size));
    if (*isolate_instructions_buffer == NULL) {
      Log::PrintErr("Failed to memory map snapshot\n");
      Platform::Exit(kErrorExitCode);
    }
  }

  file->Release();
  return true;
}


#if defined(DART_PRECOMPILED_RUNTIME)
static bool ReadAppSnapshotDynamicLibrary(
    const char* script_name,
    const uint8_t** vm_data_buffer,
    const uint8_t** vm_instructions_buffer,
    const uint8_t** isolate_data_buffer,
    const uint8_t** isolate_instructions_buffer) {
  void* library = Extensions::LoadExtensionLibrary(script_name);
  if (library == NULL) {
    return false;
  }

  *vm_data_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kVmSnapshotDataSymbolName));
  if (*vm_data_buffer == NULL) {
    Log::PrintErr("Failed to resolve symbol '%s'\n", kVmSnapshotDataSymbolName);
    Platform::Exit(kErrorExitCode);
  }

  *vm_instructions_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kVmSnapshotInstructionsSymbolName));
  if (*vm_instructions_buffer == NULL) {
    Log::PrintErr("Failed to resolve symbol '%s'\n",
                  kVmSnapshotInstructionsSymbolName);
    Platform::Exit(kErrorExitCode);
  }

  *isolate_data_buffer = reinterpret_cast<const uint8_t*>(
      Extensions::ResolveSymbol(library, kIsolateSnapshotDataSymbolName));
  if (*isolate_data_buffer == NULL) {
    Log::PrintErr("Failed to resolve symbol '%s'\n",
                  kIsolateSnapshotDataSymbolName);
    Platform::Exit(kErrorExitCode);
  }

  *isolate_instructions_buffer =
      reinterpret_cast<const uint8_t*>(Extensions::ResolveSymbol(
          library, kIsolateSnapshotInstructionsSymbolName));
  if (*isolate_instructions_buffer == NULL) {
    Log::PrintErr("Failed to resolve symbol '%s'\n",
                  kIsolateSnapshotInstructionsSymbolName);
    Platform::Exit(kErrorExitCode);
  }

  return true;
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)


bool Snapshot::ReadAppSnapshot(const char* script_name,
                               const uint8_t** vm_data_buffer,
                               const uint8_t** vm_instructions_buffer,
                               const uint8_t** isolate_data_buffer,
                               const uint8_t** isolate_instructions_buffer) {
  if (File::GetType(script_name, true) != File::kIsFile) {
    // If 'script_name' refers to a pipe, don't read to check for an app
    // snapshot since we cannot rewind if it isn't (and couldn't mmap it in
    // anyway if it was).
    return false;
  }
  if (ReadAppSnapshotBlobs(script_name, vm_data_buffer, vm_instructions_buffer,
                           isolate_data_buffer, isolate_instructions_buffer)) {
    return true;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  // For testing AOT with the standalone embedder, we also support loading
  // from a dynamic library to simulate what happens on iOS.
  return ReadAppSnapshotDynamicLibrary(
      script_name, vm_data_buffer, vm_instructions_buffer, isolate_data_buffer,
      isolate_instructions_buffer);
#else
  return false;
#endif  //  defined(DART_PRECOMPILED_RUNTIME)
}


static void WriteSnapshotFile(const char* filename,
                              bool write_magic_number,
                              const uint8_t* buffer,
                              const intptr_t size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s for writing snapshot\n",
              filename);
  }

  if (write_magic_number) {
    // Write the magic number to indicate file is a script snapshot.
    DartUtils::WriteMagicNumber(file);
  }

  if (!file->WriteFully(buffer, size)) {
    ErrorExit(kErrorExitCode, "Unable to write file %s for writing snapshot\n",
              filename);
  }
  file->Release();
}


static bool WriteInt64(File* file, int64_t size) {
  return file->WriteFully(&size, sizeof(size));
}


static void WriteAppSnapshot(const char* filename,
                             uint8_t* vm_data_buffer,
                             intptr_t vm_data_size,
                             uint8_t* vm_instructions_buffer,
                             intptr_t vm_instructions_size,
                             uint8_t* isolate_data_buffer,
                             intptr_t isolate_data_size,
                             uint8_t* isolate_instructions_buffer,
                             intptr_t isolate_instructions_size) {
  File* file = File::Open(filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  file->WriteFully(&kAppSnapshotMagicNumber, sizeof(kAppSnapshotMagicNumber));
  WriteInt64(file, vm_data_size);
  WriteInt64(file, vm_instructions_size);
  WriteInt64(file, isolate_data_size);
  WriteInt64(file, isolate_instructions_size);
  ASSERT(file->Position() == kAppSnapshotHeaderSize);

  file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
  if (!file->WriteFully(vm_data_buffer, vm_data_size)) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  if (vm_instructions_size != 0) {
    file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
    if (!file->WriteFully(vm_instructions_buffer, vm_instructions_size)) {
      ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n",
                filename);
    }
  }

  file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
  if (!file->WriteFully(isolate_data_buffer, isolate_data_size)) {
    ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n", filename);
  }

  if (isolate_instructions_size != 0) {
    file->SetPosition(Utils::RoundUp(file->Position(), kAppSnapshotPageSize));
    if (!file->WriteFully(isolate_instructions_buffer,
                          isolate_instructions_size)) {
      ErrorExit(kErrorExitCode, "Unable to write snapshot file '%s'\n",
                filename);
    }
  }

  file->Flush();
  file->Release();
}


void Snapshot::GenerateScript(const char* snapshot_filename) {
  // First create a snapshot.
  uint8_t* buffer = NULL;
  intptr_t size = 0;
  Dart_Handle result = Dart_CreateScriptSnapshot(&buffer, &size);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }

  WriteSnapshotFile(snapshot_filename, true, buffer, size);
}


void Snapshot::GenerateAppJIT(const char* snapshot_filename) {
#if defined(TARGET_ARCH_X64)
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
#else
  uint8_t* isolate_buffer = NULL;
  intptr_t isolate_size = 0;

  Dart_Handle result =
      Dart_CreateSnapshot(NULL, NULL, &isolate_buffer, &isolate_size);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }

  WriteAppSnapshot(snapshot_filename, NULL, 0, NULL, 0, isolate_buffer,
                   isolate_size, NULL, 0);
#endif  // defined(TARGET_ARCH_X64)
}


void Snapshot::GenerateAppAOTAsBlobs(const char* snapshot_filename) {
  uint8_t* vm_data_buffer = NULL;
  intptr_t vm_data_size = 0;
  uint8_t* vm_instructions_buffer = NULL;
  intptr_t vm_instructions_size = 0;
  uint8_t* isolate_data_buffer = NULL;
  intptr_t isolate_data_size = 0;
  uint8_t* isolate_instructions_buffer = NULL;
  intptr_t isolate_instructions_size = 0;
  Dart_Handle result = Dart_CreateAppAOTSnapshotAsBlobs(
      &vm_data_buffer, &vm_data_size, &vm_instructions_buffer,
      &vm_instructions_size, &isolate_data_buffer, &isolate_data_size,
      &isolate_instructions_buffer, &isolate_instructions_size);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }
  WriteAppSnapshot(snapshot_filename, vm_data_buffer, vm_data_size,
                   vm_instructions_buffer, vm_instructions_size,
                   isolate_data_buffer, isolate_data_size,
                   isolate_instructions_buffer, isolate_instructions_size);
}


void Snapshot::GenerateAppAOTAsAssembly(const char* snapshot_filename) {
  uint8_t* assembly_buffer = NULL;
  intptr_t assembly_size = 0;
  Dart_Handle result =
      Dart_CreateAppAOTSnapshotAsAssembly(&assembly_buffer, &assembly_size);
  if (Dart_IsError(result)) {
    ErrorExit(kErrorExitCode, "%s\n", Dart_GetError(result));
  }
  WriteSnapshotFile(snapshot_filename, false, assembly_buffer, assembly_size);
}

}  // namespace bin
}  // namespace dart
