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

const char* Version::snapshot_hash_ = "{{SNAPSHOT_HASH}}";
const char* Version::str_ =
    "{{VERSION_STR}} ({{CHANNEL}}) ({{COMMIT_TIME}})"
    " on \""
#if defined(DART_HOST_OS_ANDROID)
    "android"
#elif defined(DART_HOST_OS_FUCHSIA)
    "fuchsia"
#elif defined(DART_HOST_OS_LINUX)
    "linux"
#elif defined(DART_HOST_OS_MACOS)
#if DART_HOST_OS_IOS
    "ios"
#else
    "macos"
#endif
#elif defined(DART_HOST_OS_WINDOWS)
    "windows"
#else
#error Unknown OS
#endif
    "_"
#if defined(USING_SIMULATOR)
    "sim"
#endif
#if defined(TARGET_ARCH_IA32)
    "ia32"
#elif defined(TARGET_ARCH_X64)
    "x64"
#elif defined(TARGET_ARCH_ARM)
    "arm"
#elif defined(TARGET_ARCH_ARM64)
    "arm64"
#elif defined(TARGET_ARCH_RISCV32)
    "riscv32"
#elif defined(TARGET_ARCH_RISCV64)
    "riscv64"
#else
#error Unknown arch
#endif
    "\"";
const char* Version::commit_ = "{{VERSION_STR}}";
const char* Version::git_short_hash_ = "{{GIT_HASH}}";

}  // namespace dart
