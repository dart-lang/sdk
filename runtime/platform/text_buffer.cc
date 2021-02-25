// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/unicode.h"
#include "platform/utils.h"

namespace dart {

intptr_t BaseTextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = VPrintf(format, args);
  va_end(args);
  return len;
}

intptr_t BaseTextBuffer::VPrintf(const char* format, va_list args) {
  va_list args1;
  va_copy(args1, args);
  intptr_t remaining = capacity_ - length_;
  ASSERT(remaining >= 0);
  intptr_t len = Utils::VSNPrint(buffer_ + length_, remaining, format, args1);
  va_end(args1);
  if (len >= remaining) {
    if (!EnsureCapacity(len)) {
      length_ = capacity_ - 1;
      buffer_[length_] = '\0';
      return remaining - 1;
    }
    remaining = capacity_ - length_;
    ASSERT(remaining > len);
    va_list args2;
    va_copy(args2, args);
    intptr_t len2 =
        Utils::VSNPrint(buffer_ + length_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  length_ += len;
  buffer_[length_] = '\0';
  return len;
}

void BaseTextBuffer::AddChar(char ch) {
  if (!EnsureCapacity(sizeof(ch))) return;
  buffer_[length_] = ch;
  length_++;
  buffer_[length_] = '\0';
}

void BaseTextBuffer::AddRaw(const uint8_t* buffer, intptr_t buffer_length) {
  if (!EnsureCapacity(buffer_length)) {
    buffer_length = capacity_ - length_ - 1;  // Copy what fits.
  }
  memmove(&buffer_[length_], buffer, buffer_length);
  length_ += buffer_length;
  buffer_[length_] = '\0';
}

// Write a UTF-32 code unit so it can be read by a JSON parser in a string
// literal. Use official encoding from JSON specification. http://json.org/
void BaseTextBuffer::EscapeAndAddCodeUnit(uint32_t codeunit) {
  switch (codeunit) {
    case '"':
      AddRaw(reinterpret_cast<uint8_t const*>("\\\""), 2);
      break;
    case '\\':
      AddRaw(reinterpret_cast<uint8_t const*>("\\\\"), 2);
      break;
    case '/':
      AddRaw(reinterpret_cast<uint8_t const*>("\\/"), 2);
      break;
    case '\b':
      AddRaw(reinterpret_cast<uint8_t const*>("\\b"), 2);
      break;
    case '\f':
      AddRaw(reinterpret_cast<uint8_t const*>("\\f"), 2);
      break;
    case '\n':
      AddRaw(reinterpret_cast<uint8_t const*>("\\n"), 2);
      break;
    case '\r':
      AddRaw(reinterpret_cast<uint8_t const*>("\\r"), 2);
      break;
    case '\t':
      AddRaw(reinterpret_cast<uint8_t const*>("\\t"), 2);
      break;
    default:
      if (codeunit < 0x20) {
        EscapeAndAddUTF16CodeUnit(codeunit);
      } else {
        char encoded[6];
        intptr_t length = Utf8::Length(codeunit);
        Utf8::Encode(codeunit, encoded);
        AddRaw(reinterpret_cast<uint8_t const*>(encoded), length);
      }
  }
}

// Write an incomplete UTF-16 code unit so it can be read by a JSON parser in a
// string literal.
void BaseTextBuffer::EscapeAndAddUTF16CodeUnit(uint16_t codeunit) {
  Printf("\\u%04X", codeunit);
}

void BaseTextBuffer::AddString(const char* s) {
  Printf("%s", s);
}

void BaseTextBuffer::AddEscapedString(const char* s) {
  intptr_t len = strlen(s);
  for (int i = 0; i < len; i++) {
    EscapeAndAddCodeUnit(s[i]);
  }
}

TextBuffer::TextBuffer(intptr_t buf_size) {
  ASSERT(buf_size > 0);
  buffer_ = reinterpret_cast<char*>(malloc(buf_size));
  capacity_ = buf_size;
  Clear();
}

TextBuffer::~TextBuffer() {
  free(buffer_);
  buffer_ = nullptr;
}

char* TextBuffer::Steal() {
  char* r = buffer_;
  buffer_ = nullptr;
  capacity_ = 0;
  length_ = 0;
  return r;
}

bool TextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = capacity_ - length_;
  if (remaining <= len) {
    intptr_t new_size = capacity_ + Utils::Maximum(capacity_, len + 1);
    char* new_buf = reinterpret_cast<char*>(realloc(buffer_, new_size));
    buffer_ = new_buf;
    capacity_ = new_size;
  }
  return true;
}

}  // namespace dart
