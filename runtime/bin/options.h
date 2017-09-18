// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_OPTIONS_H_
#define RUNTIME_BIN_OPTIONS_H_

#include "bin/dartutils.h"
#include "bin/log.h"
#include "platform/globals.h"
#include "platform/hashmap.h"

namespace dart {
namespace bin {

typedef bool (*OptionProcessorCallback)(const char* arg,
                                        CommandLineOptions* vm_options);

class OptionProcessor {
 public:
  OptionProcessor() : next_(first_) { first_ = this; }

  virtual ~OptionProcessor() {}

  static bool IsValidFlag(const char* name,
                          const char* prefix,
                          intptr_t prefix_length);

  virtual bool Process(const char* option, CommandLineOptions* options) = 0;

  static bool TryProcess(const char* option, CommandLineOptions* options);

  static const char* ProcessOption(const char* option, const char* name);

  static bool ProcessEnvironmentOption(const char* arg,
                                       CommandLineOptions* vm_options,
                                       dart::HashMap** environment);

 private:
  static OptionProcessor* first_;
  OptionProcessor* next_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(OptionProcessor);
};

class CallbackOptionProcessor : public OptionProcessor {
 public:
  explicit CallbackOptionProcessor(OptionProcessorCallback cb) : cb_(cb) {}
  virtual bool Process(const char* option, CommandLineOptions* vm_options) {
    return cb_(option, vm_options);
  }

 private:
  OptionProcessorCallback cb_;
};

#define DEFINE_CB_OPTION(callback)                                             \
  static CallbackOptionProcessor option_##callback(&callback);

#define DEFINE_STRING_OPTION_CB(name, callback)                                \
  class OptionProcessor_##name : public OptionProcessor {                      \
   public:                                                                     \
    virtual bool Process(const char* option, CommandLineOptions* vm_options) { \
      const char* value =                                                      \
          OptionProcessor::ProcessOption(option, "--" #name "=");              \
      if (value == NULL) {                                                     \
        return false;                                                          \
      }                                                                        \
      if (*value == '\0') {                                                    \
        Log::PrintErr("Empty value for option " #name "\n");                   \
        return false;                                                          \
      }                                                                        \
      callback;                                                                \
      return true;                                                             \
    }                                                                          \
  };                                                                           \
  static OptionProcessor_##name option_##name;

#define DEFINE_STRING_OPTION(name, variable)                                   \
  DEFINE_STRING_OPTION_CB(name, { variable = value; })

#define DEFINE_ENUM_OPTION(name, enum_name, variable)                          \
  DEFINE_STRING_OPTION_CB(name, {                                              \
    const char** kNames = k##enum_name##Names;                                 \
    for (intptr_t i = 0; kNames[i] != NULL; i++) {                             \
      if (strcmp(value, kNames[i]) == 0) {                                     \
        variable = static_cast<enum_name>(i);                                  \
        return true;                                                           \
      }                                                                        \
    }                                                                          \
    Log::PrintErr(                                                             \
        "Unrecognized value for " #name ": '%s'\nValid values are: ", value);  \
    for (intptr_t i = 0; kNames[i] != NULL; i++) {                             \
      Log::PrintErr("%s%s", i > 0 ? ", " : "", kNames[i]);                     \
    }                                                                          \
    Log::PrintErr("\n");                                                       \
  })

#define DEFINE_BOOL_OPTION_CB(name, callback)                                  \
  class OptionProcessor_##name : public OptionProcessor {                      \
   public:                                                                     \
    virtual bool Process(const char* option, CommandLineOptions* vm_options) { \
      const char* value = OptionProcessor::ProcessOption(option, "--" #name);  \
      if (value == NULL) {                                                     \
        return false;                                                          \
      }                                                                        \
      if (*value == '=') {                                                     \
        Log::PrintErr("Non-empty value for option " #name "\n");               \
        return false;                                                          \
      }                                                                        \
      if (*value != '\0') {                                                    \
        return false;                                                          \
      }                                                                        \
      callback;                                                                \
      return true;                                                             \
    }                                                                          \
  };                                                                           \
  static OptionProcessor_##name option_##name;

#define DEFINE_BOOL_OPTION(name, variable)                                     \
  DEFINE_BOOL_OPTION_CB(name, { variable = true; })

#define DEFINE_BOOL_OPTION_SHORT(short_name, long_name, variable)              \
  class OptionProcessor_##long_name : public OptionProcessor {                 \
   public:                                                                     \
    virtual bool Process(const char* option, CommandLineOptions* vm_options) { \
      const char* value =                                                      \
          OptionProcessor::ProcessOption(option, "-" #short_name);             \
      if (value == NULL) {                                                     \
        value = OptionProcessor::ProcessOption(option, "--" #long_name);       \
      }                                                                        \
      if (value == NULL) {                                                     \
        return false;                                                          \
      }                                                                        \
      if (*value == '=') {                                                     \
        Log::PrintErr("Non-empty value for option " #long_name "\n");          \
        return false;                                                          \
      }                                                                        \
      if (*value != '\0') {                                                    \
        return false;                                                          \
      }                                                                        \
      variable = true;                                                         \
      return true;                                                             \
    }                                                                          \
  };                                                                           \
  static OptionProcessor_##long_name option_##long_name;

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_OPTIONS_H_
