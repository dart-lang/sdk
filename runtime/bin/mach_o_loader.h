// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_MACH_O_LOADER_H_
#define RUNTIME_BIN_MACH_O_LOADER_H_

#include "../include/dart_api.h"

typedef struct {
} Dart_LoadedMachO;

/// Load an Mach-O object from a file.
///
/// On success, return a handle to the library which may be used to close it
/// in Dart_UnloadMachO. On error, returns 'nullptr' and sets 'error'. The error
/// string should not be 'free'-d.
///
/// Look up the Dart snapshot symbols "_kVmSnapshotData",
/// "_kVmSnapshotInstructions", "_kVmIsolateData" and "_kVmIsolateInstructions"
/// into the respectively named out-parameters.
///
DART_EXPORT Dart_LoadedMachO* Dart_LoadMachO(const char* filename,
                                         const char** error,
                                         const uint8_t** vm_snapshot_data,
                                         const uint8_t** vm_snapshot_instrs,
                                         const uint8_t** vm_isolate_data,
                                         const uint8_t** vm_isolate_instrs);

/// Unloads an ELF object loaded through Dart_LoadELF{_Fd, _Memory}.
///
/// Unlike dlclose(), this does not use reference counting.
/// Dart_LoadELF{_Fd, _Memory} will return load the target library separately
/// each time it is called, and the results must be unloaded separately.
DART_EXPORT void Dart_UnloadMachO(Dart_LoadedMachO* loaded);

#endif  // RUNTIME_BIN_ELF_LOADER_H_
