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

typedef struct {
  const char* command;
  const char* snapshot_name;
} DartDevCommandMapping;

static const DartDevCommandMapping dart_dev_commands[] = {
    {"format", "dartfmt.dart.snapshot"},
    {"pub", "pub.dart.snapshot"},
};

static const DartDevCommandMapping* FindCommandMapping(const char* command) {
  intptr_t num_commands =
      sizeof(dart_dev_commands) / sizeof(dart_dev_commands[0]);
  for (intptr_t i = 0; i < num_commands; i++) {
    const DartDevCommandMapping& command_mapping = dart_dev_commands[i];
    if (strcmp(command, command_mapping.command) == 0) {
      return &command_mapping;
    }
  }
  return nullptr;
}

bool DartDevUtils::ShouldParseCommand(const char* script_uri) {
  return !File::ExistsUri(nullptr, script_uri);
}

bool DartDevUtils::TryParseCommandFromScriptName(char** script_name) {
  const DartDevCommandMapping* command = FindCommandMapping(*script_name);

  // Either the command doesn't exist or we've been given an HTTP resource.
  if (command == nullptr) {
    return true;
  }

  // |dir_prefix| includes the last path seperator.
  auto dir_prefix = std::unique_ptr<char, void (*)(void*)>(
      EXEUtils::GetDirectoryPrefixFromExeName(), free);

  // First assume we're in dart-sdk/bin.
  char* snapshot_path = Utils::SCreate("%s/snapshots/%s", dir_prefix.get(),
                                       command->snapshot_name);
  if (File::Exists(nullptr, snapshot_path)) {
    free(*script_name);
    *script_name = snapshot_path;
    return true;
  }
  free(snapshot_path);

  // If we're not in dart-sdk/bin, we might be in one of the $SDK/out/*
  // directories. Try to use a snapshot from a previously built SDK.
  snapshot_path = Utils::SCreate("%s/dart-sdk/bin/snapshots/%s",
                                 dir_prefix.get(), command->snapshot_name);
  if (File::Exists(nullptr, snapshot_path)) {
    free(*script_name);
    *script_name = snapshot_path;
    return true;
  }
  free(snapshot_path);
  Syslog::PrintErr("Could not find snapshot for command '%s': %s\n",
                   *script_name, command->snapshot_name);
  return false;
}

}  // namespace bin
}  // namespace dart
