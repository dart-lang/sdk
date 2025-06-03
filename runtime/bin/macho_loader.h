// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_MACHO_LOADER_H_
#define RUNTIME_BIN_MACHO_LOADER_H_

#include "../include/dart_api.h"

typedef struct {
} Dart_LoadedMachODylib;

/// Load an Mach-O dynamic library object from a file.
///
/// On success, return a handle to the library which may be used to close it
/// in Dart_UnloadMachODylib. On error, returns 'nullptr' and sets 'error'. The
/// error string should not be 'free'-d.
///
/// `file_offset` may be non-zero to read an snapshot embedded inside another
/// type of file.
///
/// Look up the Dart snapshot symbols "_kVmSnapshotData",
/// "_kVmSnapshotInstructions", "_kVmIsolateData" and "_kVmIsolateInstructions"
/// into the respectively named out-parameters.
///
/// Dart_LoadMachODylib_Fd takes ownership of the file descriptor.
/// Dart_LoadMachODylib_Memory does not take ownership of the memory, but
/// borrows it for the duration of the call. The memory can be release as soon
// as Dart_LoadAOTSnapshot_Memory returns.
#if defined(__Fuchsia__) || defined(__linux__) || defined(__FreeBSD__)
DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib_Fd(
    int fd,
    uint64_t file_offset,
    const char** error,
    const uint8_t** vm_snapshot_data,
    const uint8_t** vm_snapshot_instrs,
    const uint8_t** vm_isolate_data,
    const uint8_t** vm_isolate_instrs);
#endif

/// Please see documentation for Dart_LoadMachODylib_Fd.
DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib(
    const char* filename,
    uint64_t file_offset,
    const char** error,
    const uint8_t** vm_snapshot_data,
    const uint8_t** vm_snapshot_instrs,
    const uint8_t** vm_isolate_data,
    const uint8_t** vm_isolate_instrs);

/// Please see documentation for Dart_LoadMachODylib_Fd.
DART_EXPORT Dart_LoadedMachODylib* Dart_LoadMachODylib_Memory(
    const uint8_t* snapshot,
    uint64_t snapshot_size,
    const char** error,
    const uint8_t** vm_snapshot_data,
    const uint8_t** vm_snapshot_instrs,
    const uint8_t** vm_isolate_data,
    const uint8_t** vm_isolate_instrs);

/// Unloads an MachO dynamic library object loaded through
/// Dart_LoadMachODylib{_Fd, _Memory}.
///
/// Unlike dlclose(), this does not use reference counting.
/// Dart_LoadMachODylib{_Fd, _Memory} will return load the target library
/// separately each time it is called, and the results must be unloaded
/// separately.
DART_EXPORT void Dart_UnloadMachODylib(Dart_LoadedMachODylib* loaded);

#endif  // RUNTIME_BIN_MACHO_LOADER_H_
