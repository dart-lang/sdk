// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_JSON_WRITER_H_
#define RUNTIME_VM_JSON_WRITER_H_

#include "platform/allocation.h"
#include "platform/text_buffer.h"

namespace dart {

class String;

class JSONWriter : ValueObject {
 public:
  explicit JSONWriter(intptr_t buf_size = 256);

  TextBuffer* buffer() { return &buffer_; }
  const char* ToCString() { return buffer_.buf(); }

  void Steal(char** buffer, intptr_t* buffer_length);

  void PrintCommaIfNeeded();

  // Append |serialized_object| to the stream.
  void AppendSerializedObject(const char* serialized_object);

  // Append |buffer| to the stream.
  void AppendSerializedObject(const uint8_t* buffer, intptr_t buffer_length);

  // Append |serialized_object| to the stream with |property_name|.
  void AppendSerializedObject(const char* property_name,
                              const char* serialized_object);

  void OpenObject(const char* property_name = NULL);
  void CloseObject();
  void UncloseObject();

  void OpenArray(const char* property_name = NULL);
  void CloseArray();

  void Clear();

  void PrintValueNull();
  void PrintValueBool(bool b);
  void PrintValue(intptr_t i);
  void PrintValue64(int64_t i);
  void PrintValue(double d);
  void PrintValueBase64(const uint8_t* bytes, intptr_t length);
  void PrintValue(const char* s);
  void PrintValue(const char* s, intptr_t len);
  void PrintValueNoEscape(const char* s);
  void PrintfValue(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void VPrintfValue(const char* format, va_list args);
  bool PrintValueStr(const String& s, intptr_t offset, intptr_t count);

  void PrintPropertyBool(const char* name, bool b);
  void PrintProperty(const char* name, intptr_t i);
  void PrintProperty64(const char* name, int64_t i);
  void PrintProperty(const char* name, double d);
  void PrintPropertyBase64(const char* name,
                           const uint8_t* bytes,
                           intptr_t length);
  void PrintProperty(const char* name, const char* s);
  bool PrintPropertyStr(const char* name,
                        const String& s,
                        intptr_t offset = 0,
                        intptr_t count = -1);
  void PrintPropertyNoEscape(const char* name, const char* s);
  void PrintfProperty(const char* name, const char* format, ...)
      PRINTF_ATTRIBUTE(3, 4);
  void VPrintfProperty(const char* name, const char* format, va_list args);

  void PrintPropertyName(const char* name);

  void AddEscapedUTF8String(const char* s);
  void AddEscapedUTF8String(const char* s, intptr_t len);

 private:
  bool NeedComma();
  bool AddDartString(const String& s, intptr_t offset, intptr_t count);

  // Debug only fatal assertion.
  static void EnsureIntegerIsRepresentableInJavaScript(int64_t i);

  intptr_t open_objects_;
  TextBuffer buffer_;
};

}  // namespace dart

#endif  // RUNTIME_VM_JSON_WRITER_H_
