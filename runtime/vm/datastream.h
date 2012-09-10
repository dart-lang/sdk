// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_DATASTREAM_H_
#define VM_DATASTREAM_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

static const int8_t kDataBitsPerByte = 7;
static const int8_t kByteMask = (1 << kDataBitsPerByte) - 1;
static const int8_t kMaxUnsignedDataPerByte = kByteMask;
static const int8_t kMinDataPerByte = -(1 << (kDataBitsPerByte - 1));
static const int8_t kMaxDataPerByte = (~kMinDataPerByte & kByteMask);
static const uint8_t kEndByteMarker = (255 - kMaxDataPerByte);
static const uint8_t kEndUnsignedByteMarker = (255 - kMaxUnsignedDataPerByte);

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

  // Reads 'len' bytes from the stream.
  void ReadBytes(uint8_t* addr, intptr_t len) {
    ASSERT((end_ - current_) >= len);
    memmove(addr, current_, len);
    current_ += len;
  }

  intptr_t ReadUnsigned() {
    return Read<intptr_t>(kEndUnsignedByteMarker);
  }

  intptr_t Position() const { return current_ - buffer_; }

  void SetPosition(intptr_t value) {
    ASSERT((end_ - buffer_) > value);
    current_ = buffer_ + value;
  }

  const uint8_t* AddressOfCurrentPosition() const {
    return current_;
  }

  void Advance(intptr_t value) {
    ASSERT((end_ - current_) > value);
    current_ = current_ + value;
  }

 private:
  template<typename T>
  T Read() {
    return Read<T>(kEndByteMarker);
  }

  template<typename T>
  T Read(uint8_t end_byte_marker) {
    uint8_t b = ReadByte();
    if (b > kMaxUnsignedDataPerByte) {
      return static_cast<T>(b) - end_byte_marker;
    }
    T r = 0;
    uint8_t s = 0;
    do {
      r |= static_cast<T>(b) << s;
      s += kDataBitsPerByte;
      b = ReadByte();
    } while (b <= kMaxUnsignedDataPerByte);
    return r | ((static_cast<T>(b) - end_byte_marker) << s);
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
  static const intptr_t kBufferIncrementSize = 64 * KB;

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

  void WriteUnsigned(intptr_t value) {
    ASSERT((value >= 0) && (value <= kIntptrMax));
    while (value > kMaxUnsignedDataPerByte) {
      WriteByte(static_cast<uint8_t>(value & kByteMask));
      value = value >> kDataBitsPerByte;
    }
    WriteByte(static_cast<uint8_t>(value + kEndUnsignedByteMarker));
  }

  void WriteBytes(const uint8_t* addr, intptr_t len) {
    if ((end_ - current_) < len) {
      Resize(len);
    }
    ASSERT((end_ - current_) >= len);
    memmove(current_, addr, len);
    current_ += len;
  }

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
      Resize(1);
    }
    ASSERT(current_ < end_);
    *current_++ = value;
  }

  void Resize(intptr_t size_needed) {
    intptr_t position = current_ - *buffer_;
    intptr_t new_size = current_size_ +
        Utils::RoundUp(size_needed, kBufferIncrementSize);
    *buffer_ = reinterpret_cast<uint8_t*>(alloc_(*buffer_,
                                                 current_size_,
                                                 new_size));
    ASSERT(*buffer_ != NULL);
    current_ = *buffer_ + position;
    current_size_ = new_size;
    end_ = *buffer_ + new_size;
    ASSERT(end_ > *buffer_);
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
