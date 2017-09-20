// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_TEXT_BUFFER_H_
#define RUNTIME_PLATFORM_TEXT_BUFFER_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

// TextBuffer maintains a dynamic character buffer with a printf-style way to
// append text.
class TextBuffer : ValueObject {
 public:
  explicit TextBuffer(intptr_t buf_size);
  ~TextBuffer();

  intptr_t Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void AddChar(char ch);
  void EscapeAndAddUTF16CodeUnit(uint16_t cu);
  void EscapeAndAddCodeUnit(uint32_t cu);
  void AddString(const char* s);
  void AddEscapedString(const char* s);
  void AddRaw(const uint8_t* buffer, intptr_t buffer_length);

  void Clear();

  char* buf() { return buf_; }
  intptr_t length() { return msg_len_; }
  void set_length(intptr_t len) {
    ASSERT(len >= 0);
    ASSERT(len <= msg_len_);
    msg_len_ = len;
  }

  // Steal ownership of the buffer pointer.
  // NOTE: TextBuffer is empty afterwards.
  char* Steal();

 private:
  void EnsureCapacity(intptr_t len);
  char* buf_;
  intptr_t buf_size_;
  intptr_t msg_len_;
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_TEXT_BUFFER_H_
