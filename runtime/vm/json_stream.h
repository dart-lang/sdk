// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_JSON_STREAM_H_
#define VM_JSON_STREAM_H_

#include "platform/json.h"

namespace dart {

class Object;

class JSONStream : ValueObject {
 public:
  explicit JSONStream(TextBuffer* buffer);
  ~JSONStream();

  void Clear();

  void OpenObject(const char* property_name = NULL);
  void CloseObject();

  void OpenArray(const char* property_name = NULL);
  void CloseArray();

  void PrintValueBool(bool b);
  void PrintValue(intptr_t i);
  void PrintValue(double d);
  void PrintValue(const char* s);
  void PrintfValue(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void PrintValue(const Object& o, bool ref = true);

  void PrintPropertyBool(const char* name, bool b);
  void PrintProperty(const char* name, intptr_t i);
  void PrintProperty(const char* name, double d);
  void PrintProperty(const char* name, const char* s);
  void PrintfProperty(const char* name, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void PrintProperty(const char* name, const Object& o, bool ref = true);

  void SetArguments(const char** arguments, intptr_t num_arguments);
  void SetOptions(const char** option_keys, const char** option_values,
                  intptr_t num_options);

  intptr_t num_arguments() const { return num_arguments_; }
  const char* GetArgument(intptr_t i) const {
    return arguments_[i];
  }
  intptr_t num_options() const { return num_options_; }
  const char* GetOptionKey(intptr_t i) const {
    return option_keys_[i];
  }
  const char* GetOptionValue(intptr_t i) const {
    return option_values_[i];
  }

 private:
  void PrintPropertyName(const char* name);
  void PrintCommaIfNeeded();
  bool NeedComma();
  intptr_t open_objects_;
  TextBuffer* buffer_;
  const char** arguments_;
  intptr_t num_arguments_;
  const char** option_keys_;
  const char** option_values_;
  intptr_t num_options_;
};

}  // namespace dart

#endif  // VM_JSON_STREAM_H_
