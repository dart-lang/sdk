// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/mappable.h"

#include "platform/globals.h"

#include "bin/file.h"

namespace dart {
namespace bin {

Mappable* Mappable::FromPath(const char* path) {
  return new FileMappable(File::Open(/*namespc=*/nullptr, path, File::kRead,
                                     /*executable=*/true));
}

#if defined(DART_HOST_OS_FUCHSIA) || defined(DART_HOST_OS_LINUX)
Mappable* Mappable::FromFD(int fd) {
  return new FileMappable(File::OpenFD(fd));
}
#endif

Mappable* Mappable::FromMemory(const uint8_t* memory, size_t size) {
  return new MemoryMappable(memory, size);
}

}  // namespace bin
}  // namespace dart
