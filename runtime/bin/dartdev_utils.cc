// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartdev_utils.h"

#include <memory>

#include "bin/directory.h"
#include "bin/exe_utils.h"
#include "bin/file.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

// TODO(bkonyi): re-enable after 2.8 release.
const bool kDartDevEnabled = false;

bool DartDevUtils::ShouldParseCommand(const char* script_uri) {
  // If script_uri is not a file path or of a known URI scheme, we can assume
  // that this is a DartDev command.
  return (kDartDevEnabled && !File::ExistsUri(nullptr, script_uri) &&
          (strncmp(script_uri, "http://", 7) != 0) &&
          (strncmp(script_uri, "https://", 8) != 0) &&
          (strncmp(script_uri, "file://", 7) != 0) &&
          (strncmp(script_uri, "package:", 8) != 0) &&
          (strncmp(script_uri, "google3://", 10) != 0));
}

bool DartDevUtils::TryResolveDartDevSnapshotPath(char** script_name) {
  // |dir_prefix| includes the last path seperator.
  auto dir_prefix = EXEUtils::GetDirectoryPrefixFromExeName();

  // First assume we're in dart-sdk/bin.
  char* snapshot_path =
      Utils::SCreate("%ssnapshots/dartdev.dart.snapshot", dir_prefix.get());
  if (File::Exists(nullptr, snapshot_path)) {
    *script_name = snapshot_path;
    return true;
  }
  free(snapshot_path);

  // If we're not in dart-sdk/bin, we might be in one of the $SDK/out/*
  // directories. Try to use a snapshot from a previously built SDK.
  snapshot_path = Utils::SCreate(
      "%sdart-sdk/bin/snapshots/dartdev.dart.snapshot", dir_prefix.get());
  if (File::Exists(nullptr, snapshot_path)) {
    *script_name = snapshot_path;
    return true;
  }
  free(snapshot_path);
  return false;
}

}  // namespace bin
}  // namespace dart
