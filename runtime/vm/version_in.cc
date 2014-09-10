// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/version.h"

#include "vm/cpu.h"
#include "vm/os.h"

namespace dart {

// TODO(iposva): Avoid racy initialization.
static const char* formatted_version = NULL;

const char* Version::String() {
  if (formatted_version == NULL) {
    const char* format = "%s on \"%s_%s\"";
    const char* os = OS::Name();
    const char* arch = CPU::Id();

    intptr_t len = OS::SNPrint(NULL, 0, format, str_, os, arch);
    char* buffer = reinterpret_cast<char*>(malloc(len + 1));
    OS::SNPrint(buffer, (len + 1), format, str_, os, arch);
    formatted_version = buffer;
  }
  return formatted_version;
}


const char* Version::SnapshotString() {
  return snapshot_hash_;
}

const char* Version::snapshot_hash_ = "{{SNAPSHOT_HASH}}";
const char* Version::str_ = "{{VERSION_STR}} ({{BUILD_TIME}})";

}  // namespace dart
