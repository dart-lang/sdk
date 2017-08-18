// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/os.h"
#include "vm/unicode.h"

namespace dart {

TextBuffer::TextBuffer(intptr_t buf_size) {
  ASSERT(buf_size > 0);
  buf_ = reinterpret_cast<char*>(malloc(buf_size));
  if (buf_ == NULL) {
    OUT_OF_MEMORY();
  }
  buf_size_ = buf_size;
  Clear();
}

TextBuffer::~TextBuffer() {
  free(buf_);
  buf_ = NULL;
}

void TextBuffer::Clear() {
  msg_len_ = 0;
  buf_[0] = '\0';
}

char* TextBuffer::Steal() {
  char* r = buf_;
  buf_ = NULL;
  buf_size_ = 0;
  msg_len_ = 0;
  return r;
}

void TextBuffer::AddChar(char ch) {
  EnsureCapacity(sizeof(ch));
  buf_[msg_len_] = ch;
  msg_len_++;
  buf_[msg_len_] = '\0';
}

void TextBuffer::AddRaw(const uint8_t* buffer, intptr_t buffer_length) {
  EnsureCapacity(buffer_length);
  memmove(&buf_[msg_len_], buffer, buffer_length);
  msg_len_ += buffer_length;
  buf_[msg_len_] = '\0';
}

intptr_t TextBuffer::Printf(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t remaining = buf_size_ - msg_len_;
  ASSERT(remaining >= 0);
  intptr_t len = OS::VSNPrint(buf_ + msg_len_, remaining, format, args);
  va_end(args);
  if (len >= remaining) {
    EnsureCapacity(len);
    remaining = buf_size_ - msg_len_;
    ASSERT(remaining > len);
    va_list args2;
    va_start(args2, format);
    intptr_t len2 = OS::VSNPrint(buf_ + msg_len_, remaining, format, args2);
    va_end(args2);
    ASSERT(len == len2);
  }
  msg_len_ += len;
  buf_[msg_len_] = '\0';
  return len;
}

// Write a UTF-32 code unit so it can be read by a JSON parser in a string
// literal. Use official encoding from JSON specification. http://json.org/
void TextBuffer::EscapeAndAddCodeUnit(uint32_t codeunit) {
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
void TextBuffer::EscapeAndAddUTF16CodeUnit(uint16_t codeunit) {
  Printf("\\u%04X", codeunit);
}

void TextBuffer::AddString(const char* s) {
  Printf("%s", s);
}

void TextBuffer::AddEscapedString(const char* s) {
  intptr_t len = strlen(s);
  for (int i = 0; i < len; i++) {
    EscapeAndAddCodeUnit(s[i]);
  }
}

void TextBuffer::EnsureCapacity(intptr_t len) {
  intptr_t remaining = buf_size_ - msg_len_;
  if (remaining <= len) {
    const int kBufferSpareCapacity = 64;  // Somewhat arbitrary.
    // TODO(turnidge): do we need to guard against overflow or other
    // security issues here? Text buffers are used by the debugger
    // to send user-controlled data (e.g. values of string variables) to
    // the debugger front-end.
    intptr_t new_size = buf_size_ + len + kBufferSpareCapacity;
    char* new_buf = reinterpret_cast<char*>(realloc(buf_, new_size));
    if (new_buf == NULL) {
      OUT_OF_MEMORY();
    }
    buf_ = new_buf;
    buf_size_ = new_size;
  }
}

}  // namespace dart
