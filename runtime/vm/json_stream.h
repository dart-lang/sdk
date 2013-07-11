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
  void PrintValue(const Object& o, bool ref = true);

  void PrintPropertyBool(const char* name, bool b);
  void PrintProperty(const char* name, intptr_t i);
  void PrintProperty(const char* name, double d);
  void PrintProperty(const char* name, const char* s);
  void PrintProperty(const char* name, const Object& o, bool ref = true);

 private:
  void PrintPropertyName(const char* name);
  void PrintCommaIfNeeded();
  bool NeedComma();
  intptr_t open_objects_;
  TextBuffer* buffer_;
};

}  // namespace dart

#endif  // VM_JSON_STREAM_H_
