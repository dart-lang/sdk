// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/syslog.h"
#include "vm/globals.h"

namespace dart {
namespace compiler {
namespace ffi {

#if defined(DART_TARGET_OS_WINDOWS)
const char* kOs = "win";
#else
const char* kOs = kTargetOperatingSystemName;
#endif

void WriteToFile(char* path, const char* contents) {
  FILE* file;
  file = fopen(path, "w");
  if (file != nullptr) {
    fprintf(file, "%s", contents);
  } else {
    Syslog::Print("Error %d \n", errno);
  }
  fclose(file);
}

void ReadFromFile(char* path, char** buffer_pointer) {
  FILE* file = fopen(path, "rb");
  if (file == nullptr) {
    Syslog::Print("Error %d \n", errno);
    return;
  }

  fseek(file, 0, SEEK_END);
  size_t size = ftell(file);
  rewind(file);

  char* buffer = reinterpret_cast<char*>(malloc(sizeof(char) * (size + 1)));

  fread(buffer, 1, size, file);
  buffer[size] = 0;

  fclose(file);
  *buffer_pointer = buffer;
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
