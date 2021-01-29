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
  BaseTextBuffer() : buffer_(nullptr), capacity_(0), length_(0) {}
  BaseTextBuffer(char* buffer, intptr_t capacity)
      : buffer_(buffer), capacity_(capacity), length_(0) {}
  virtual ~BaseTextBuffer() {}

  intptr_t Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  intptr_t VPrintf(const char* format, va_list args);
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
  virtual bool EnsureCapacity(intptr_t len) = 0;

  char* buffer_;
  intptr_t capacity_;
  intptr_t length_;

  DISALLOW_COPY_AND_ASSIGN(BaseTextBuffer);
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
  bool EnsureCapacity(intptr_t len);

  DISALLOW_COPY_AND_ASSIGN(TextBuffer);
};

class BufferFormatter : public BaseTextBuffer {
 public:
  BufferFormatter(char* buffer, intptr_t size) : BaseTextBuffer(buffer, size) {
    buffer_[length_] = '\0';
  }

  void Clear() {
    length_ = 0;
    buffer_[length_] = '\0';
  }

 private:
  // We can't extend, so only return true if there's room.
  bool EnsureCapacity(intptr_t len) { return length_ + len <= capacity_ - 1; }

  DISALLOW_COPY_AND_ASSIGN(BufferFormatter);
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_TEXT_BUFFER_H_
