// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/json_writer.h"
#include "vm/object.h"
#include "vm/unicode.h"

namespace dart {

class MaybeOnStackBuffer {
 public:
  explicit MaybeOnStackBuffer(intptr_t size) {
    if (size > kOnStackBufferCapacity) {
      p_ = reinterpret_cast<char*>(malloc(size));
    } else {
      p_ = &buffer_[0];
    }
  }
  ~MaybeOnStackBuffer() {
    if (p_ != &buffer_[0]) free(p_);
  }

  char* p() { return p_; }

 private:
  static const intptr_t kOnStackBufferCapacity = 4096;
  char* p_;
  char buffer_[kOnStackBufferCapacity];
};

JSONWriter::JSONWriter(intptr_t buf_size)
    : open_objects_(0), buffer_(buf_size) {}

void JSONWriter::AppendSerializedObject(const char* serialized_object) {
  PrintCommaIfNeeded();
  buffer_.AddString(serialized_object);
}

void JSONWriter::AppendSerializedObject(const uint8_t* buffer,
                                        intptr_t buffer_length) {
  buffer_.AddRaw(buffer, buffer_length);
}

void JSONWriter::AppendSerializedObject(const char* property_name,
                                        const char* serialized_object) {
  PrintCommaIfNeeded();
  PrintPropertyName(property_name);
  buffer_.AddString(serialized_object);
}

void JSONWriter::Clear() {
  buffer_.Clear();
  open_objects_ = 0;
}

void JSONWriter::OpenObject(const char* property_name) {
  PrintCommaIfNeeded();
  open_objects_++;
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  buffer_.AddChar('{');
}

void JSONWriter::UncloseObject() {
  intptr_t len = buffer_.length();
  ASSERT(len > 0);
  ASSERT(buffer_.buf()[len - 1] == '}');
  open_objects_++;
  buffer_.set_length(len - 1);
}

void JSONWriter::CloseObject() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_.AddChar('}');
}

void JSONWriter::OpenArray(const char* property_name) {
  PrintCommaIfNeeded();
  if (property_name != NULL) {
    PrintPropertyName(property_name);
  }
  open_objects_++;
  buffer_.AddChar('[');
}

void JSONWriter::CloseArray() {
  ASSERT(open_objects_ > 0);
  open_objects_--;
  buffer_.AddChar(']');
}

void JSONWriter::PrintValueNull() {
  PrintCommaIfNeeded();
  buffer_.Printf("null");
}

void JSONWriter::PrintValueBool(bool b) {
  PrintCommaIfNeeded();
  buffer_.Printf("%s", b ? "true" : "false");
}

void JSONWriter::PrintValue(intptr_t i) {
  EnsureIntegerIsRepresentableInJavaScript(static_cast<int64_t>(i));
  PrintCommaIfNeeded();
  buffer_.Printf("%" Pd "", i);
}

void JSONWriter::PrintValue64(int64_t i) {
  EnsureIntegerIsRepresentableInJavaScript(i);
  PrintCommaIfNeeded();
  buffer_.Printf("%" Pd64 "", i);
}

void JSONWriter::PrintValue(double d) {
  PrintCommaIfNeeded();
  buffer_.Printf("%f", d);
}

static const char base64_digits[65] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char base64_pad = '=';

void JSONWriter::PrintValueBase64(const uint8_t* bytes, intptr_t length) {
  PrintCommaIfNeeded();
  buffer_.AddChar('"');

  intptr_t odd_bits = length % 3;
  intptr_t even_bits = length - odd_bits;
  for (intptr_t i = 0; i < even_bits; i += 3) {
    intptr_t triplet = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
    buffer_.AddChar(base64_digits[triplet >> 18]);
    buffer_.AddChar(base64_digits[(triplet >> 12) & 63]);
    buffer_.AddChar(base64_digits[(triplet >> 6) & 63]);
    buffer_.AddChar(base64_digits[triplet & 63]);
  }
  if (odd_bits == 1) {
    intptr_t triplet = bytes[even_bits] << 16;
    buffer_.AddChar(base64_digits[triplet >> 18]);
    buffer_.AddChar(base64_digits[(triplet >> 12) & 63]);
    buffer_.AddChar(base64_pad);
    buffer_.AddChar(base64_pad);
  } else if (odd_bits == 2) {
    intptr_t triplet = (bytes[even_bits] << 16) | (bytes[even_bits + 1] << 8);
    buffer_.AddChar(base64_digits[triplet >> 18]);
    buffer_.AddChar(base64_digits[(triplet >> 12) & 63]);
    buffer_.AddChar(base64_digits[(triplet >> 6) & 63]);
    buffer_.AddChar(base64_pad);
  }

  buffer_.AddChar('"');
}

void JSONWriter::PrintValue(const char* s) {
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  AddEscapedUTF8String(s);
  buffer_.AddChar('"');
}

bool JSONWriter::PrintValueStr(const String& s,
                               intptr_t offset,
                               intptr_t count) {
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  bool did_truncate = AddDartString(s, offset, count);
  buffer_.AddChar('"');
  return did_truncate;
}

void JSONWriter::PrintValueNoEscape(const char* s) {
  PrintCommaIfNeeded();
  buffer_.Printf("%s", s);
}

void JSONWriter::PrintfValue(const char* format, ...) {
  va_list args;
  va_start(args, format);
  VPrintfValue(format, args);
  va_end(args);
}

void JSONWriter::VPrintfValue(const char* format, va_list args) {
  PrintCommaIfNeeded();

  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  MaybeOnStackBuffer mosb(len + 1);
  char* p = mosb.p();

  va_list print_args;
  va_copy(print_args, args);
  intptr_t len2 = OS::VSNPrint(p, len + 1, format, print_args);
  va_end(print_args);
  ASSERT(len == len2);

  buffer_.AddChar('"');
  AddEscapedUTF8String(p, len);
  buffer_.AddChar('"');
}

void JSONWriter::PrintPropertyBool(const char* name, bool b) {
  PrintPropertyName(name);
  PrintValueBool(b);
}

void JSONWriter::PrintProperty(const char* name, intptr_t i) {
  PrintPropertyName(name);
  PrintValue(i);
}

void JSONWriter::PrintProperty64(const char* name, int64_t i) {
  PrintPropertyName(name);
  PrintValue64(i);
}

void JSONWriter::PrintProperty(const char* name, double d) {
  PrintPropertyName(name);
  PrintValue(d);
}

void JSONWriter::PrintProperty(const char* name, const char* s) {
  PrintPropertyName(name);
  PrintValue(s);
}

void JSONWriter::PrintPropertyBase64(const char* name,
                                     const uint8_t* b,
                                     intptr_t len) {
  PrintPropertyName(name);
  PrintValueBase64(b, len);
}

bool JSONWriter::PrintPropertyStr(const char* name,
                                  const String& s,
                                  intptr_t offset,
                                  intptr_t count) {
  PrintPropertyName(name);
  return PrintValueStr(s, offset, count);
}

void JSONWriter::PrintPropertyNoEscape(const char* name, const char* s) {
  PrintPropertyName(name);
  PrintValueNoEscape(s);
}

void JSONWriter::PrintfProperty(const char* name, const char* format, ...) {
  va_list args;
  va_start(args, format);
  VPrintfProperty(name, format, args);
  va_end(args);
}

void JSONWriter::VPrintfProperty(const char* name,
                                 const char* format,
                                 va_list args) {
  PrintPropertyName(name);

  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  MaybeOnStackBuffer mosb(len + 1);
  char* p = mosb.p();

  va_list print_args;
  va_copy(print_args, args);
  intptr_t len2 = OS::VSNPrint(p, len + 1, format, print_args);
  va_end(print_args);
  ASSERT(len == len2);

  buffer_.AddChar('"');
  AddEscapedUTF8String(p, len);
  buffer_.AddChar('"');
}

void JSONWriter::Steal(char** buffer, intptr_t* buffer_length) {
  ASSERT(buffer != NULL);
  ASSERT(buffer_length != NULL);
  *buffer_length = buffer_.length();
  *buffer = buffer_.Steal();
}

void JSONWriter::PrintPropertyName(const char* name) {
  ASSERT(name != NULL);
  PrintCommaIfNeeded();
  buffer_.AddChar('"');
  AddEscapedUTF8String(name);
  buffer_.AddChar('"');
  buffer_.AddChar(':');
}

void JSONWriter::PrintCommaIfNeeded() {
  if (NeedComma()) {
    buffer_.AddChar(',');
  }
}

bool JSONWriter::NeedComma() {
  const char* buffer = buffer_.buf();
  intptr_t length = buffer_.length();
  if (length == 0) {
    return false;
  }
  char ch = buffer[length - 1];
  return (ch != '[') && (ch != '{') && (ch != ':') && (ch != ',');
}

void JSONWriter::EnsureIntegerIsRepresentableInJavaScript(int64_t i) {
#ifdef DEBUG
  if (!Utils::IsJavascriptInt(i)) {
    OS::Print(
        "JSONWriter::EnsureIntegerIsRepresentableInJavaScript failed on "
        "%" Pd64 "\n",
        i);
    UNREACHABLE();
  }
#endif
}

void JSONWriter::AddEscapedUTF8String(const char* s) {
  if (s == NULL) {
    return;
  }
  intptr_t len = strlen(s);
  AddEscapedUTF8String(s, len);
}

void JSONWriter::AddEscapedUTF8String(const char* s, intptr_t len) {
  if (s == NULL) {
    return;
  }
  const uint8_t* s8 = reinterpret_cast<const uint8_t*>(s);
  intptr_t i = 0;
  for (; i < len;) {
    // Extract next UTF8 character.
    int32_t ch = 0;
    int32_t ch_len = Utf8::Decode(&s8[i], len - i, &ch);
    ASSERT(ch_len != 0);
    buffer_.EscapeAndAddCodeUnit(ch);
    // Move i forward.
    i += ch_len;
  }
  ASSERT(i == len);
}

bool JSONWriter::AddDartString(const String& s,
                               intptr_t offset,
                               intptr_t count) {
  intptr_t length = s.Length();
  ASSERT(offset >= 0);
  if (offset > length) {
    offset = length;
  }
  if (!Utils::RangeCheck(offset, count, length)) {
    count = length - offset;
  }
  intptr_t limit = offset + count;
  for (intptr_t i = offset; i < limit; i++) {
    uint16_t code_unit = s.CharAt(i);
    if (Utf16::IsTrailSurrogate(code_unit)) {
      buffer_.EscapeAndAddUTF16CodeUnit(code_unit);
    } else if (Utf16::IsLeadSurrogate(code_unit)) {
      if (i + 1 == limit) {
        buffer_.EscapeAndAddUTF16CodeUnit(code_unit);
      } else {
        uint16_t next_code_unit = s.CharAt(i + 1);
        if (Utf16::IsTrailSurrogate(next_code_unit)) {
          uint32_t decoded = Utf16::Decode(code_unit, next_code_unit);
          buffer_.EscapeAndAddCodeUnit(decoded);
          i++;
        } else {
          buffer_.EscapeAndAddUTF16CodeUnit(code_unit);
        }
      }
    } else {
      buffer_.EscapeAndAddCodeUnit(code_unit);
    }
  }
  // Return value indicates whether the string is truncated.
  return (offset > 0) || (limit < length);
}

}  // namespace dart
