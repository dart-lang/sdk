// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/options.h"

namespace dart {
namespace bin {

OptionProcessor* OptionProcessor::first_ = nullptr;

bool OptionProcessor::IsValidFlag(const char* name) {
  return name[0] == '-' && name[1] == '-' && name[2] != '\0';
}

bool OptionProcessor::IsValidShortFlag(const char* name) {
  return name[0] == '-' && name[1] != '\0';
}

const char* OptionProcessor::ProcessOption(const char* option,
                                           const char* name) {
  const intptr_t length = strlen(name);
  for (intptr_t i = 0; i < length; i++) {
    if (option[i] != name[i]) {
      if ((name[i] == '_') && (option[i] == '-')) {
        continue;
      }
      return nullptr;
    }
  }
  return option + length;
}

bool OptionProcessor::TryProcess(const char* option,
                                 CommandLineOptions* vm_options) {
  for (OptionProcessor* p = first_; p != nullptr; p = p->next_) {
    if (p->Process(option, vm_options)) {
      return true;
    }
  }
  return false;
}

static bool IsPrefix(const char* prefix, size_t prefix_len, const char* str) {
  ASSERT(prefix != nullptr);
  ASSERT(str != nullptr);
  const size_t str_len = strlen(str);
  if (str_len < prefix_len) {
    return false;
  }
  return strncmp(prefix, str, prefix_len) == 0;
}

bool OptionProcessor::ProcessEnvironmentOption(
    const char* arg,
    CommandLineOptions* vm_options,
    dart::SimpleHashMap** environment) {
  ASSERT(arg != nullptr);
  ASSERT(environment != nullptr);
  const char* kShortPrefix = "-D";
  const char* kLongPrefix = "--define=";
  const int kShortPrefixLen = strlen(kShortPrefix);
  const int kLongPrefixLen = strlen(kLongPrefix);
  const bool is_short_form = IsPrefix(kShortPrefix, kShortPrefixLen, arg);
  const bool is_long_form = IsPrefix(kLongPrefix, kLongPrefixLen, arg);
  if (is_short_form) {
    arg = arg + kShortPrefixLen;
  } else if (is_long_form) {
    arg = arg + kLongPrefixLen;
  } else {
    return false;
  }
  if (*arg == '\0') {
    return true;
  }
  if (*environment == nullptr) {
    *environment = new SimpleHashMap(&SimpleHashMap::SameStringValue, 4);
  }
  // Split the name=value part of the -Dname=value argument.
  char* name;
  char* value = nullptr;
  const char* equals_pos = strchr(arg, '=');
  if (equals_pos == nullptr) {
    // No equal sign (name without value) currently not supported.
    if (is_short_form) {
      Syslog::PrintErr("No value given to -D option\n");
    } else {
      Syslog::PrintErr("No value given to --define option\n");
    }
    return true;
  }
  int name_len = equals_pos - arg;
  if (name_len == 0) {
    if (is_short_form) {
      Syslog::PrintErr("No name given to -D option\n");
    } else {
      Syslog::PrintErr("No name given to --define option\n");
    }
    return true;
  }
  // Split name=value into name and value.
  name = reinterpret_cast<char*>(malloc(name_len + 1));
  strncpy(name, arg, name_len);
  name[name_len] = '\0';
  value = Utils::StrDup(equals_pos + 1);
  SimpleHashMap::Entry* entry =
      (*environment)
          ->Lookup(GetHashmapKeyFromString(name),
                   SimpleHashMap::StringHash(name), true);
  ASSERT(entry != nullptr);  // Lookup adds an entry if key not found.
  if (entry->value != nullptr) {
    free(name);
    free(entry->value);
  }
  entry->value = value;
  return true;
}

}  // namespace bin
}  // namespace dart
