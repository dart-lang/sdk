// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DATASTREAM_H_
#define RUNTIME_VM_DATASTREAM_H_

#include "include/dart_api.h"
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
    if (len != 0) {
      memmove(addr, current_, len);
    }
    current_ += len;
  }

  template <typename T = intptr_t>
  T ReadUnsigned() {
    return Read<T>(kEndUnsignedByteMarker);
  }

  intptr_t Position() const { return current_ - buffer_; }
  void SetPosition(intptr_t value) {
    ASSERT((end_ - buffer_) > value);
    current_ = buffer_ + value;
  }

  void Align(intptr_t alignment) {
    intptr_t position_before = Position();
    intptr_t position_after = Utils::RoundUp(position_before, alignment);
    Advance(position_after - position_before);
  }

  const uint8_t* AddressOfCurrentPosition() const { return current_; }

  void Advance(intptr_t value) {
    ASSERT((end_ - current_) >= value);
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

  uword ReadWordWith32BitReads() {
    constexpr intptr_t kNumBytesPerRead32 = sizeof(uint32_t);
    constexpr intptr_t kNumRead32PerWord = sizeof(uword) / kNumBytesPerRead32;
    constexpr intptr_t kNumBitsPerRead32 = kNumBytesPerRead32 * kBitsPerByte;

    uword value = 0;
    for (intptr_t j = 0; j < kNumRead32PerWord; j++) {
      const auto partial_value = Raw<kNumBytesPerRead32, uint32_t>::Read(this);
      value |= (static_cast<uword>(partial_value) << (j * kNumBitsPerRead32));
    }
    return value;
  }

 private:
  uint16_t Read16() { return Read16(kEndByteMarker); }

  uint32_t Read32() { return Read32(kEndByteMarker); }

  uint64_t Read64() { return Read64(kEndByteMarker); }

  template <typename T>
  T Read(uint8_t end_byte_marker) {
    using Unsigned = typename std::make_unsigned<T>::type;
    const uint8_t* c = current_;
    ASSERT(c < end_);
    Unsigned b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return b - end_byte_marker;
    }
    T r = 0;
    uint8_t s = 0;
    do {
      r |= static_cast<Unsigned>(b) << s;
      s += kDataBitsPerByte;
      ASSERT(c < end_);
      b = *c++;
    } while (b <= kMaxUnsignedDataPerByte);
    current_ = c;
    return r | (static_cast<Unsigned>(b - end_byte_marker) << s);
  }

  uint16_t Read16(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint16_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return b - end_byte_marker;
    }
    uint16_t r = b;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint16_t>(b - end_byte_marker) << 7);
    }

    r |= b << 7;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | (static_cast<uint16_t>(b - end_byte_marker) << 14);
  }

  uint32_t Read32(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint32_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return b - end_byte_marker;
    }

    uint32_t r = b;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint32_t>(b - end_byte_marker) << 7);
    }

    r |= b << 7;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint32_t>(b - end_byte_marker) << 14);
    }

    r |= b << 14;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint32_t>(b - end_byte_marker) << 21);
    }

    r |= b << 21;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | (static_cast<uint32_t>(b - end_byte_marker) << 28);
  }

  uint64_t Read64(uint8_t end_byte_marker) {
    const uint8_t* c = current_;
    ASSERT(c < end_);
    uint64_t b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return b - end_byte_marker;
    }
    uint64_t r = b;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 7);
    }

    r |= b << 7;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 14);
    }

    r |= b << 14;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 21);
    }

    r |= b << 21;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 28);
    }

    r |= b << 28;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 35);
    }

    r |= b << 35;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 42);
    }

    r |= b << 42;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 49);
    }

    r |= b << 49;
    ASSERT(c < end_);
    b = *c++;
    if (b > kMaxUnsignedDataPerByte) {
      current_ = c;
      return r | (static_cast<uint64_t>(b - end_byte_marker) << 56);
    }

    r |= b << 56;
    ASSERT(c < end_);
    b = *c++;
    ASSERT(b > kMaxUnsignedDataPerByte);
    current_ = c;
    return r | (static_cast<uint64_t>(b - end_byte_marker) << 63);
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

  intptr_t Position() const { return current_ - *buffer_; }
  void SetPosition(intptr_t value) { current_ = *buffer_ + value; }

  void Align(intptr_t alignment) {
    intptr_t position_before = Position();
    intptr_t position_after = Utils::RoundUp(position_before, alignment);
    memset(current_, 0, position_after - position_before);
    SetPosition(position_after);
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

  void WriteWordWith32BitWrites(uword value) {
    constexpr intptr_t kNumBytesPerWrite32 = sizeof(uint32_t);
    constexpr intptr_t kNumWrite32PerWord = sizeof(uword) / kNumBytesPerWrite32;
    constexpr intptr_t kNumBitsPerWrite32 = kNumBytesPerWrite32 * kBitsPerByte;

    const uint32_t mask = Utils::NBitMask(kNumBitsPerWrite32);
    for (intptr_t j = 0; j < kNumWrite32PerWord; j++) {
      const uint32_t shifted_value = (value >> (j * kNumBitsPerWrite32));
      Raw<kNumBytesPerWrite32, uint32_t>::Write(this, shifted_value & mask);
    }
  }

  template <typename T>
  void WriteUnsigned(T value) {
    ASSERT(value >= 0);
    while (value > kMaxUnsignedDataPerByte) {
      WriteByte(static_cast<uint8_t>(value & kByteMask));
      value = value >> kDataBitsPerByte;
    }
    WriteByte(static_cast<uint8_t>(value + kEndUnsignedByteMarker));
  }

  void WriteBytes(const void* addr, intptr_t len) {
    if ((end_ - current_) < len) {
      Resize(len);
    }
    ASSERT((end_ - current_) >= len);
    if (len != 0) {
      memmove(current_, addr, len);
    }
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

  void WriteTargetWord(uword value) {
#if defined(IS_SIMARM_X64)
    RELEASE_ASSERT(Utils::IsInt(32, static_cast<word>(value)));
    const intptr_t len = sizeof(uint32_t);
    if ((end_ - current_) < len) {
      Resize(len);
    }
    ASSERT((end_ - current_) >= len);
    *reinterpret_cast<uint32_t*>(current_) = static_cast<uint32_t>(value);
    current_ += len;
#else   // defined(IS_SIMARM_X64)
    WriteWord(value);
#endif  // defined(IS_SIMARM_X64)
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
    intptr_t len = Utils::VSNPrint(NULL, 0, format, measure_args);
    va_end(measure_args);

    // Alloc.
    if ((end_ - current_) < (len + 1)) {
      Resize(len + 1);
    }
    ASSERT((end_ - current_) >= (len + 1));

    // Print.
    va_list print_args;
    va_copy(print_args, args);
    Utils::VSNPrint(reinterpret_cast<char*>(current_), len + 1, format,
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

  template <typename T>
  void WriteFixed(T value) {
    const intptr_t len = sizeof(T);
    if ((end_ - current_) < len) {
      Resize(len);
    }
    ASSERT((end_ - current_) >= len);
    *reinterpret_cast<T*>(current_) = static_cast<T>(value);
    current_ += len;
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

class StreamingWriteStream : public ValueObject {
 public:
  explicit StreamingWriteStream(intptr_t initial_capacity,
                                Dart_StreamingWriteCallback callback,
                                void* callback_data);
  ~StreamingWriteStream();

  intptr_t position() const { return flushed_size_ + (cursor_ - buffer_); }

  void Align(intptr_t alignment) {
    intptr_t padding = Utils::RoundUp(position(), alignment) - position();
    EnsureAvailable(padding);
    memset(cursor_, 0, padding);
    cursor_ += padding;
  }

  void Print(const char* format, ...) {
    va_list args;
    va_start(args, format);
    VPrint(format, args);
    va_end(args);
  }
  void VPrint(const char* format, va_list args);

  void WriteBytes(const uint8_t* buffer, intptr_t size) {
    EnsureAvailable(size);
    if (size != 0) {
      memmove(cursor_, buffer, size);
    }
    cursor_ += size;
  }

 private:
  void EnsureAvailable(intptr_t needed) {
    intptr_t available = limit_ - cursor_;
    if (available >= needed) return;
    EnsureAvailableSlowPath(needed);
  }

  void EnsureAvailableSlowPath(intptr_t needed);
  void Flush();

  uint8_t* buffer_;
  uint8_t* cursor_;
  uint8_t* limit_;
  intptr_t flushed_size_;
  Dart_StreamingWriteCallback callback_;
  void* callback_data_;

  DISALLOW_COPY_AND_ASSIGN(StreamingWriteStream);
};

}  // namespace dart

#endif  // RUNTIME_VM_DATASTREAM_H_
