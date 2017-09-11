// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/options.h"

namespace dart {
namespace bin {

OptionProcessor* OptionProcessor::first_ = NULL;

bool OptionProcessor::IsValidFlag(const char* name,
                                  const char* prefix,
                                  intptr_t prefix_length) {
  const intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}

const char* OptionProcessor::ProcessOption(const char* option,
                                           const char* name) {
  const intptr_t length = strlen(name);
  for (intptr_t i = 0; i < length; i++) {
    if (option[i] != name[i]) {
      if ((name[i] == '_') && (option[i] == '-')) {
        continue;
      }
      return NULL;
    }
  }
  return option + length;
}

bool OptionProcessor::TryProcess(const char* option,
                                 CommandLineOptions* vm_options) {
  for (OptionProcessor* p = first_; p != NULL; p = p->next_) {
    if (p->Process(option, vm_options)) {
      return true;
    }
  }
  return false;
}

static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}

bool OptionProcessor::ProcessEnvironmentOption(const char* arg,
                                               CommandLineOptions* vm_options,
                                               dart::HashMap** environment) {
  ASSERT(arg != NULL);
  ASSERT(environment != NULL);
  if (*arg == '\0') {
    return false;
  }
  if (*arg != '-') {
    return false;
  }
  if (*(arg + 1) != 'D') {
    return false;
  }
  arg = arg + 2;
  if (*arg == '\0') {
    return true;
  }
  if (*environment == NULL) {
    *environment = new HashMap(&HashMap::SameStringValue, 4);
  }
  // Split the name=value part of the -Dname=value argument.
  char* name;
  char* value = NULL;
  const char* equals_pos = strchr(arg, '=');
  if (equals_pos == NULL) {
    // No equal sign (name without value) currently not supported.
    Log::PrintErr("No value given to -D option\n");
    return false;
  } else {
    int name_len = equals_pos - arg;
    if (name_len == 0) {
      Log::PrintErr("No name given to -D option\n");
      return false;
    }
    // Split name=value into name and value.
    name = reinterpret_cast<char*>(malloc(name_len + 1));
    strncpy(name, arg, name_len);
    name[name_len] = '\0';
    value = strdup(equals_pos + 1);
  }
  HashMap::Entry* entry = (*environment)
                              ->Lookup(GetHashmapKeyFromString(name),
                                       HashMap::StringHash(name), true);
  ASSERT(entry != NULL);  // Lookup adds an entry if key not found.
  entry->value = value;
  return true;
}

}  // namespace bin
}  // namespace dart
