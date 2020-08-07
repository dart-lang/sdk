// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_TEXT_BUFFER_H_
#define RUNTIME_PLATFORM_TEXT_BUFFER_H_

#include "platform/allocation.h"
#include "platform/globals.h"

namespace dart {

// BaseTextBuffer maintains a dynamic character buffer with a printf-style way
// to append text. Internal buffer management is handled by subclasses.
class BaseTextBuffer : public ValueObject {
 public:
  virtual ~BaseTextBuffer() {}

  intptr_t Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void AddChar(char ch);
  void EscapeAndAddUTF16CodeUnit(uint16_t cu);
  void EscapeAndAddCodeUnit(uint32_t cu);
  void AddString(const char* s);
  void AddEscapedString(const char* s);
  void AddRaw(const uint8_t* buffer, intptr_t buffer_length);

  // Returns a pointer to the current internal buffer. Whether the pointer is
  // still valid after the BaseTextBuffer dies depends on the subclass.
  char* buffer() const { return buffer_; }
  intptr_t length() const { return length_; }

  // Clears the stored contents. Unless specified otherwise by the subclass,
  // should be assumed to invalidate the contents of previous calls to buffer().
  virtual void Clear() = 0;

 protected:
  virtual void EnsureCapacity(intptr_t len) = 0;

  char* buffer_ = nullptr;
  intptr_t capacity_ = 0;
  intptr_t length_ = 0;
};

// TextBuffer uses manual memory management for the character buffer. Unless
// Steal() is used, the internal buffer is deallocated when the object dies.
class TextBuffer : public BaseTextBuffer {
 public:
  explicit TextBuffer(intptr_t buf_size);
  ~TextBuffer();

  // Resets the contents of the internal buffer.
  void Clear() { set_length(0); }

  void set_length(intptr_t len) {
    ASSERT(len >= 0);
    ASSERT(len <= length_);
    length_ = len;
    buffer_[len] = '\0';
  }

  // Take ownership of the buffer contents. Future uses of the TextBuffer object
  // will not affect the contents of the returned buffer.
  // NOTE: TextBuffer is empty afterwards.
  char* Steal();

 private:
  void EnsureCapacity(intptr_t len);
};

class BufferFormatter : public ValueObject {
 public:
  BufferFormatter(char* buffer, intptr_t size)
      : position_(0), buffer_(buffer), size_(size) {}

  void VPrint(const char* format, va_list args);
  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

 private:
  intptr_t position_;
  char* buffer_;
  const intptr_t size_;

  DISALLOW_COPY_AND_ASSIGN(BufferFormatter);
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_TEXT_BUFFER_H_
