// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ELF_LOADER_H_
#define RUNTIME_BIN_ELF_LOADER_H_

#include <include/dart_api.h>

typedef void* LoadedElfLibrary;

/// Loads an ELF object in 'filename'.
///
/// On success, returns a handle to the library which may be used to close it
/// in Dart_UnloadELF. On error, returns 'nullptr' and sets 'error'. The error
/// string should not be 'free'-d.
///
/// Looks up the Dart snapshot symbols "_kVmSnapshotData",
/// "_kVmSnapshotInstructions", "_kVmIsoalteData" and "_kVmIsolateInstructions"
/// into the respectively named out-parameters.
DART_EXPORT LoadedElfLibrary Dart_LoadELF(const char* filename,
                                          const char** error,
                                          const uint8_t** vm_snapshot_data,
                                          const uint8_t** vm_snapshot_instrs,
                                          const uint8_t** vm_isolate_data,
                                          const uint8_t** vm_isolate_instrs);

DART_EXPORT void Dart_UnloadELF(LoadedElfLibrary loaded);

#endif  // RUNTIME_BIN_ELF_LOADER_H_
