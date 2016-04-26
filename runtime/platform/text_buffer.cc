// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/text_buffer.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"
#include "vm/os.h"

namespace dart {

TextBuffer::TextBuffer(intptr_t buf_size) {
  ASSERT(buf_size > 0);
  buf_ = reinterpret_cast<char*>(malloc(buf_size));
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


const char* TextBuffer::Steal() {
  const char* r = buf_;
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


void TextBuffer::AddRaw(const uint8_t* buffer,
                        intptr_t buffer_length) {
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


// Write a UTF-16 code unit so it can be read by a JSON parser in a string
// literal. Use escape sequences for characters other than printable ASCII.
void TextBuffer::EscapeAndAddCodeUnit(uint32_t codeunit) {
  switch (codeunit) {
    case '"':
      Printf("%s", "\\\"");
      break;
    case '\\':
      Printf("%s", "\\\\");
      break;
    case '/':
      Printf("%s", "\\/");
      break;
    case '\b':
      Printf("%s", "\\b");
      break;
    case '\f':
      Printf("%s", "\\f");
      break;
    case '\n':
      Printf("%s", "\\n");
      break;
    case '\r':
      Printf("%s", "\\r");
      break;
    case '\t':
      Printf("%s", "\\t");
      break;
    default:
      if (codeunit < 0x20) {
        // Encode character as \u00HH.
        uint32_t digit2 = (codeunit >> 4) & 0xf;
        uint32_t digit3 = (codeunit & 0xf);
        Printf("\\u00%c%c",
               digit2 > 9 ? 'A' + (digit2 - 10) : '0' + digit2,
               digit3 > 9 ? 'A' + (digit3 - 10) : '0' + digit3);
      } else if (codeunit > 127) {
        // Encode character as \uHHHH.
        uint32_t digit0 = (codeunit >> 12) & 0xf;
        uint32_t digit1 = (codeunit >> 8) & 0xf;
        uint32_t digit2 = (codeunit >> 4) & 0xf;
        uint32_t digit3 = (codeunit & 0xf);
        Printf("\\u%c%c%c%c",
               digit0 > 9 ? 'A' + (digit0 - 10) : '0' + digit0,
               digit1 > 9 ? 'A' + (digit1 - 10) : '0' + digit1,
               digit2 > 9 ? 'A' + (digit2 - 10) : '0' + digit2,
               digit3 > 9 ? 'A' + (digit3 - 10) : '0' + digit3);
      } else {
        AddChar(codeunit);
      }
  }
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
    ASSERT(new_buf != NULL);
    buf_ = new_buf;
    buf_size_ = new_size;
  }
}

}  // namespace dart
