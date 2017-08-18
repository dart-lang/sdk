// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DATASTREAM_H_
#define RUNTIME_VM_DATASTREAM_H_

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/os.h"

namespace dart {

static const int8_t kDataBitsPerByte = 7;
static const int8_t kByteMask = (1 << kDataBitsPerByte) - 1;
static const int8_t kMaxUnsignedDataPerByte = kByteMask;
static const int8_t kMinDataPerByte = -(1 << (kDataBitsPerByte - 1));
static const int8_t kMaxDataPerByte = (~kMinDataPerByte & kByteMask);  // NOLINT
static const uint8_t kEndByteMarker = (255 - kMaxDataPerByte);
static const uint8_t kEndUnsignedByteMarker = (255 - kMaxUnsignedDataPerByte);

typedef uint8_t* (*ReAlloc)(uint8_t* ptr, intptr_t old_size, intptr_t new_size);
typedef void (*DeAlloc)(uint8_t* ptr);

// Stream for reading various types from a buffer.
class ReadStream : public ValueObject {
 public:
  ReadStream(const uint8_t* buffer, intptr_t size)
      : buffer_(buffer), current_(buffer), end_(buffer + size) {}

  void SetStream(const uint8_t* buffer, intptr_t size) {
    buffer_ = buffer;
    current_ = buffer;
    end_ = buffer + size;
  }

  template <int N, typename T>
  class Raw {};

  template <typename T>
  class Raw<1, T> {
   public:
    static T Read(ReadStream* st) { return bit_cast<T>(st->ReadByte()); }
  };

  template <typename T>
  class Raw<2, T> {
   public:
    static T Read(ReadStream* st) { return bit_cast<T>(st->Read16()); }
  };

  template <typename T>
  class Raw<4, T> {
   public:
    static T Read(ReadStream* st) { return bit_cast<T>(st->Read32()); }
  };

  template <typename T>
  class Raw<8, T> {
   public:
    static T Read(ReadStream* st) { return bit_cast<T>(st->Read64()); }
  };

  // Reads 'len' bytes from the stream.
  void ReadBytes(uint8_t* addr, intptr_t len) {
    ASSERT((end_ - current_) >= len);
    memmove(addr, current_, len);
    current_ += len;
  }

  intptr_t ReadUnsigned() { return Read<intptr_t>(kEndUnsignedByteMarker); }

  intptr_t Position() const { return current_ - buffer_; }

  void SetPosition(intptr_t value) {
    ASSERT((end_ - buffer_) > value);
    current_ = buffer_ + value;
  }

  const uint8_t* AddressOfCurrentPosition() const { return current_; }

  void Advance(intptr_t value) {
    ASSERT((end_ - current_) > value);
    current_ = current_ + value;
  }

  intptr_t PendingBytes() const {
    ASSERT(end_ >= current_);
    return (end_ - current_);
  }

  template <typename T>
  T Read() {
    return Read<T>(kEndByteMarker);
  }

 private:
  int16_t Read16() { return Read16(kEndByteMarker); }

  int32_t Read32() { return Read32(kEndByteMarker); }

  int64_t Read64() { return Read64(kEndByteMarker); }

  template <typename T>
  T Read(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint8_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return static_cast<T>(b) - end_byte_marker;
    }
    T r = 0;
    uint8_t s = 0;
    do {
      r |= static_cast<T>(b) << s;
      s += kDataBitsPerByte;
      ASSERT(c < end_);
      b = *c++;
    } while (b <= kMaxUnsignedDataPerByte);
    current_ = c;
    return r | ((static_cast<T>(b) - end_byte_marker) << s);
  }

  int16_t Read16(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint8_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return static_cast<int16_t>(b) - end_byte_marker;
    }
    int16_t r = 0;
    r |= static_cast<int16_t>(b);
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int16_t>(b) - end_byte_marker) << 7);
    }

    r |= static_cast<int16_t>(b) << 7;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | ((static_cast<int16_t>(b) - end_byte_marker) << 14);
  }

  int32_t Read32(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint8_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return static_cast<int32_t>(b) - end_byte_marker;
    }

    int32_t r = 0;
    r |= static_cast<int32_t>(b);
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int32_t>(b) - end_byte_marker) << 7);
    }

    r |= static_cast<int32_t>(b) << 7;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int32_t>(b) - end_byte_marker) << 14);
    }

    r |= static_cast<int32_t>(b) << 14;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int32_t>(b) - end_byte_marker) << 21);
    }

    r |= static_cast<int32_t>(b) << 21;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | ((static_cast<int32_t>(b) - end_byte_marker) << 28);
  }

  int64_t Read64(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint8_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return static_cast<int64_t>(b) - end_byte_marker;
    }
    int64_t r = 0;

    r |= static_cast<int64_t>(b);
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 7);
    }

    r |= static_cast<int64_t>(b) << 7;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 14);
    }

    r |= static_cast<int64_t>(b) << 14;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 21);
    }

    r |= static_cast<int64_t>(b) << 21;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 28);
    }

    r |= static_cast<int64_t>(b) << 28;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 35);
    }

    r |= static_cast<int64_t>(b) << 35;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 42);
    }

    r |= static_cast<int64_t>(b) << 42;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 49);
    }

    r |= static_cast<int64_t>(b) << 49;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | ((static_cast<int64_t>(b) - end_byte_marker) << 56);
    }

    r |= static_cast<int64_t>(b) << 56;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | ((static_cast<int64_t>(b) - end_byte_marker) << 63);
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
  WriteStream(uint8_t** buffer, ReAlloc alloc, intptr_t initial_size)
      : buffer_(buffer),
        end_(NULL),
        current_(NULL),
        current_size_(0),
        alloc_(alloc),
        initial_size_(initial_size) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
    *buffer_ = reinterpret_cast<uint8_t*>(alloc_(NULL, 0, initial_size_));
    if (*buffer_ == NULL) {
      Exceptions::ThrowOOM();
    }
    current_ = *buffer_;
    current_size_ = initial_size_;
    end_ = *buffer_ + initial_size_;
  }

  uint8_t* buffer() const { return *buffer_; }
  void set_buffer(uint8_t* value) { *buffer_ = value; }
  intptr_t bytes_written() const { return current_ - *buffer_; }

  void set_current(uint8_t* value) { current_ = value; }

  void Align(intptr_t alignment) {
    intptr_t position = current_ - *buffer_;
    position = Utils::RoundUp(position, alignment);
    current_ = *buffer_ + position;
  }

  template <int N, typename T>
  class Raw {};

  template <typename T>
  class Raw<1, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->WriteByte(bit_cast<int8_t>(value));
    }
  };

  template <typename T>
  class Raw<2, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->Write<int16_t>(bit_cast<int16_t>(value));
    }
  };

  template <typename T>
  class Raw<4, T> {
   public:
    static void Write(WriteStream* st, T value) {
      st->Write<int32_t>(bit_cast<int32_t>(value));
    }
  };

  template <typename T>
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

  void WriteWord(uword value) {
    const intptr_t len = sizeof(uword);
    if ((end_ - current_) < len) {
      Resize(len);
    }
    ASSERT((end_ - current_) >= len);
    *reinterpret_cast<uword*>(current_) = value;
    current_ += len;
  }

  void Print(const char* format, ...) {
    va_list args;
    va_start(args, format);
    VPrint(format, args);
    va_end(args);
  }

  void VPrint(const char* format, va_list args) {
    // Measure.
    va_list measure_args;
    va_copy(measure_args, args);
    intptr_t len = OS::VSNPrint(NULL, 0, format, measure_args);
    va_end(measure_args);

    // Alloc.
    if ((end_ - current_) < (len + 1)) {
      Resize(len + 1);
    }
    ASSERT((end_ - current_) >= (len + 1));

    // Print.
    va_list print_args;
    va_copy(print_args, args);
    OS::VSNPrint(reinterpret_cast<char*>(current_), len + 1, format,
                 print_args);
    va_end(print_args);
    current_ += len;  // Not len + 1 to swallow the terminating NUL.
  }

  template <typename T>
  void Write(T value) {
    T v = value;
    while (v < kMinDataPerByte || v > kMaxDataPerByte) {
      WriteByte(static_cast<uint8_t>(v & kByteMask));
      v = v >> kDataBitsPerByte;
    }
    WriteByte(static_cast<uint8_t>(v + kEndByteMarker));
  }

 private:
  DART_FORCE_INLINE void WriteByte(uint8_t value) {
    if (current_ >= end_) {
      Resize(1);
    }
    ASSERT(current_ < end_);
    *current_++ = value;
  }

  void Resize(intptr_t size_needed) {
    intptr_t position = current_ - *buffer_;
    intptr_t increment_size = current_size_;
    if (size_needed > increment_size) {
      increment_size = Utils::RoundUp(size_needed, initial_size_);
    }
    intptr_t new_size = current_size_ + increment_size;
    ASSERT(new_size > current_size_);
    *buffer_ =
        reinterpret_cast<uint8_t*>(alloc_(*buffer_, current_size_, new_size));
    if (*buffer_ == NULL) {
      Exceptions::ThrowOOM();
    }
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
  intptr_t initial_size_;

  DISALLOW_COPY_AND_ASSIGN(WriteStream);
};

}  // namespace dart

#endif  // RUNTIME_VM_DATASTREAM_H_
