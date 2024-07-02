// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/version.h"

#include "vm/globals.h"

namespace dart {

const char* Version::String() {
  return str_;
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

const char* Version::Channel() {
  return channel_;
}

const char* Version::snapshot_hash_ = "{{SNAPSHOT_HASH}}";
const char* Version::str_ =
    "{{VERSION_STR}} ({{CHANNEL}}) ({{COMMIT_TIME}})"
    " on \"" kHostOperatingSystemName
    "_"
#if defined(USING_SIMULATOR)
    "sim"
#endif
    kTargetArchitectureName "\"";
const char* Version::commit_ = "{{VERSION_STR}}";
const char* Version::git_short_hash_ = "{{GIT_HASH}}";
const char* Version::channel_ = "{{CHANNEL}}";

}  // namespace dart
