// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/atomic.h"

#include "vm/cpu.h"
#include "vm/os.h"
#include "vm/version.h"

namespace dart {

// We use acquire-release semantics to ensure initializing stores to the string
// are visible when the string becomes visible.
static AcqRelAtomic<const char*> formatted_version = nullptr;

const char* Version::String() {
  if (formatted_version.load() == nullptr) {
    const char* os = OS::Name();
    const char* arch = CPU::Id();
    char* version_string =
        OS::SCreate(nullptr, "%s on \"%s_%s\"", str_, os, arch);
    const char* expect_old_is_null = nullptr;
    if (!formatted_version.compare_exchange_strong(expect_old_is_null,
                                                   version_string)) {
      free(version_string);
    }
  }
  return formatted_version.load();
}

const char* Version::SnapshotString() {
  return snapshot_hash_;
}

const char* Version::CommitString() {
  return commit_;
}

const char* Version::SdkHash() {
  return git_short_hash_;
}

const char* Version::snapshot_hash_ = "{{SNAPSHOT_HASH}}";
const char* Version::str_ = "{{VERSION_STR}} ({{CHANNEL}}) ({{COMMIT_TIME}})";
const char* Version::commit_ = "{{VERSION_STR}}";
const char* Version::git_short_hash_ = "{{GIT_HASH}}";

}  // namespace dart
