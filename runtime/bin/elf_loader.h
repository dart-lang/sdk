// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ELF_LOADER_H_
#define RUNTIME_BIN_ELF_LOADER_H_

#include "../include/dart_api.h"

typedef struct {
} Dart_LoadedElf;

/// Load an ELF object from a file.
///
/// On success, return a handle to the library which may be used to close it
/// in Dart_UnloadELF. On error, returns 'nullptr' and sets 'error'. The error
/// string should not be 'free'-d.
///
/// `file_offset` may be non-zero to read an ELF object embedded inside another
/// type of file.
///
/// Look up the Dart snapshot symbols "_kVmSnapshotData",
/// "_kVmSnapshotInstructions", "_kVmIsolateData" and "_kVmIsolateInstructions"
/// into the respectively named out-parameters.
///
/// On Fuchsia, Dart_LoadELF_Fd takes ownership of the file descriptor.
#if defined(__Fuchsia__)
DART_EXPORT Dart_LoadedElf* Dart_LoadELF_Fd(int fd,
                                            uint64_t file_offset,
                                            const char** error,
                                            const uint8_t** vm_snapshot_data,
                                            const uint8_t** vm_snapshot_instrs,
                                            const uint8_t** vm_isolate_data,
                                            const uint8_t** vm_isolate_instrs);
#else
DART_EXPORT Dart_LoadedElf* Dart_LoadELF(const char* filename,
                                         uint64_t file_offset,
                                         const char** error,
                                         const uint8_t** vm_snapshot_data,
                                         const uint8_t** vm_snapshot_instrs,
                                         const uint8_t** vm_isolate_data,
                                         const uint8_t** vm_isolate_instrs);
#endif

DART_EXPORT void Dart_UnloadELF(Dart_LoadedElf* loaded);

#endif  // RUNTIME_BIN_ELF_LOADER_H_
