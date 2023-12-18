// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#ifndef RUNTIME_BIN_FFI_TEST_FFI_TEST_FIELDS_H_
#define RUNTIME_BIN_FFI_TEST_FFI_TEST_FIELDS_H_

#include <stdint.h>

#if defined(_WIN32)
#define DART_EXPORT_FIELD __declspec(dllexport)
#else
#define DART_EXPORT_FIELD __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct Coord {
  double x;
  double y;
  struct Coord* next;
};

// These fields and structs are being accessed by @Native Dart variables in
// tests, so they must be defined with C linkage to avoid name mangling.
// MSVC doesn't seem to like extern "C" fields in C++ files, so the files are
// moved into a separate C file.
extern DART_EXPORT_FIELD int32_t globalInt;
extern DART_EXPORT_FIELD struct Coord globalStruct;

#ifdef __cplusplus
}
#endif

#endif  // RUNTIME_BIN_FFI_TEST_FFI_TEST_FIELDS_H_
