// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DATASTREAM_H_
#define VM_DATASTREAM_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

static const int8_t kDataBitsPerByte = 7;
static const int8_t kByteMask = (1 << kDataBitsPerByte) - 1;
static const int8_t kMaxUnsignedDataPerByte = kByteMask;
static const int8_t kMinDataPerByte = -(1 << (kDataBitsPerByte - 1));
static const int8_t kMaxDataPerByte = (~kMinDataPerByte & kByteMask);
static const uint8_t kEndByteMarker = (255 - kMaxDataPerByte);

typedef uint8_t* (*ReAlloc)(uint8_t* ptr, intptr_t old_size, intptr_t new_size);

// Stream for reading various types from a buffer.
class ReadStream : public ValueObject {
 public:
  ReadStream(const uint8_t* buffer, intptr_t size) : buffer_(buffer),
                                                     current_(buffer),
                                                     end_(buffer + size)  {}

  template<int N, typename T>
  class Raw { };

  template<typename T>
  class Raw<1, T> {
   public:
    static T Read(ReadStream* st) {
      return bit_cast<T>(st->ReadByte());
    }
  };

  template<typename T>
  class Raw<2, T> {
   public:
    static T Read(ReadStream* st) {
      return bit_cast<T>(st->Read<int16_t>());
    }
  };

  template<typename T>
  class Raw<4, T> {
   public:
    static T Read(ReadStream* st) {
      return bit_cast<T>(st->Read<int32_t>());
    }
  };

  template<typename T>
  class Raw<8, T> {
   public:
    static T Read(ReadStream* st) {
      return bit_cast<T>(st->Read<int64_t>());
    }
  };

  void ReadBytes(uint8_t* addr, intptr_t len) {
    ASSERT((current_ + len) < end_);
    memmove(addr, current_, len);
    current_ += len;
  }

 private:
  template<typename T>
  T Read() {
    uint8_t b = ReadByte();
    if (b > kMaxUnsignedDataPerByte) {
      return static_cast<T>(b) - kEndByteMarker;
    }
    T r = 0;
    uint8_t s = 0;
    do {
      r |= static_cast<T>(b) << s;
      s += kDataBitsPerByte;
      b = ReadByte();
    } while (b <= kMaxUnsignedDataPerByte);
    return r | ((static_cast<T>(b) - kEndByteMarker) << s);
  }

  uint8_t ReadByte() {
    ASSERT(current_ < end_);
    return *current_++;
  }

 private:
  const uint8_t* buffer_;
  const uint8_t* current_;
  const uint8_t* end_;

  DISALLOW_COPY_AND_ASSIGN(ReadStream);
};


// Stream for writing various types into a buffer.
class WriteStream : public ValueObject {
 public:
  static const int kBufferIncrementSize = 64 * KB;

  WriteStream(uint8_t** buffer, ReAlloc alloc) :
      buffer_(buffer),
      end_(NULL),
      current_(NULL),
      current_size_(0),
      alloc_(alloc) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
    *buffer_ = reinterpret_cast<uint8_t*>(alloc_(NULL,
                                                 0,
                                                 kBufferIncrementSize));
    ASSERT(*buffer_ != NULL);
    current_ = *buffer_;
    current_size_ = kBufferIncrementSize;
    end_ = *buffer_ + kBufferIncrementSize;
  }

  uint8_t* buffer() const { return *buffer_; }
  int bytes_written() const { return current_ - *buffer_; }

  void set_current(uint8_t* value) { current_ = value; }

  template<int N, typename T>
  class Raw { };

  template<typename T>
  class Raw<1, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->WriteByte(bit_cast<int8_t>(value));
    }
  };

  template<typename T>
  class Raw<2, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->Write<int16_t>(bit_cast<int16_t>(value));
    }
  };

  template<typename T>
  class Raw<4, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->Write<int32_t>(bit_cast<int32_t>(value));
    }
  };

  template<typename T>
  class Raw<8, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->Write<int64_t>(bit_cast<int64_t>(value));
    }
  };

 private:
  template<typename T>
  void Write(T value) {
    T v = value;
    while (v < kMinDataPerByte ||
           v > kMaxDataPerByte) {
      WriteByte(static_cast<uint8_t>(v & kByteMask));
      v = v >> kDataBitsPerByte;
    }
    WriteByte(static_cast<uint8_t>(v + kEndByteMarker));
  }

  void WriteByte(uint8_t value) {
    if (current_ >= end_) {
      intptr_t new_size = (current_size_ + kBufferIncrementSize);
      *buffer_ = reinterpret_cast<uint8_t*>(alloc_(*buffer_,
                                                   current_size_,
                                                   new_size));
      ASSERT(*buffer_ != NULL);
      current_ = *buffer_ + current_size_;
      current_size_ = new_size;
      end_ = *buffer_ + new_size;
    }
    ASSERT(current_ < end_);
    *current_++ = value;
  }

 private:
  uint8_t** const buffer_;
  uint8_t* end_;
  uint8_t* current_;
  intptr_t current_size_;
  ReAlloc alloc_;

  DISALLOW_COPY_AND_ASSIGN(WriteStream);
};

}  // namespace dart

#endif  // VM_DATASTREAM_H_
