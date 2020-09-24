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
#include "vm/zone.h"

namespace dart {

static const int8_t kDataBitsPerByte = 7;
static const int8_t kByteMask = (1 << kDataBitsPerByte) - 1;
static const int8_t kMaxUnsignedDataPerByte = kByteMask;
static const int8_t kMinDataPerByte = -(1 << (kDataBitsPerByte - 1));
static const int8_t kMaxDataPerByte = (~kMinDataPerByte & kByteMask);  // NOLINT
static const uint8_t kEndByteMarker = (255 - kMaxDataPerByte);
static const uint8_t kEndUnsignedByteMarker = (255 - kMaxUnsignedDataPerByte);

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

// Base class for streams that writing various types into a buffer, possibly
// flushing data out periodically to a more permanent store.
class BaseWriteStream : public ValueObject {
 public:
  explicit BaseWriteStream(intptr_t initial_size)
      : initial_size_(Utils::RoundUpToPowerOfTwo(initial_size)) {}
  virtual ~BaseWriteStream() {}

  DART_FORCE_INLINE intptr_t bytes_written() const { return Position(); }
  virtual intptr_t Position() const { return current_ - buffer_; }

  void Align(intptr_t alignment) {
    const intptr_t position_before = Position();
    const intptr_t position_after = Utils::RoundUp(position_before, alignment);
    const intptr_t length = position_after - position_before;
    EnsureSpace(length);
    memset(current_, 0, length);
    SetPosition(position_after);
  }

  template <int N, typename T>
  class Raw {};

  template <typename T>
  class Raw<1, T> {
   public:
    static void Write(BaseWriteStream* st, T value) {
      st->WriteByte(bit_cast<uint8_t>(value));
    }
  };

  template <typename T>
  class Raw<2, T> {
   public:
    static void Write(BaseWriteStream* st, T value) {
      st->Write<int16_t>(bit_cast<int16_t>(value));
    }
  };

  template <typename T>
  class Raw<4, T> {
   public:
    static void Write(BaseWriteStream* st, T value) {
      st->Write<int32_t>(bit_cast<int32_t>(value));
    }
  };

  template <typename T>
  class Raw<8, T> {
   public:
    static void Write(BaseWriteStream* st, T value) {
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
    EnsureSpace(len);
    if (len != 0) {
      memmove(current_, addr, len);
    }
    current_ += len;
  }

  void WriteWord(uword value) { WriteFixed(value); }

  void WriteTargetWord(uword value) {
#if defined(IS_SIMARM_X64)
    RELEASE_ASSERT(Utils::IsInt(32, static_cast<word>(value)));
    WriteFixed(static_cast<uint32_t>(value));
#else
    WriteFixed(value);
#endif
  }

  void Printf(const char* format, ...) PRINTF_ATTRIBUTE(2, 3) {
    va_list args;
    va_start(args, format);
    VPrintf(format, args);
    va_end(args);
  }

  void VPrintf(const char* format, va_list args) {
    // Measure.
    va_list measure_args;
    va_copy(measure_args, args);
    intptr_t len = Utils::VSNPrint(NULL, 0, format, measure_args);
    va_end(measure_args);

    // Alloc.
    EnsureSpace(len + 1);

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
    WriteBytes(&value, sizeof(value));
  }

  DART_FORCE_INLINE void WriteByte(uint8_t value) {
    EnsureSpace(1);
    *current_++ = value;
  }

  void WriteString(const char* cstr) { WriteBytes(cstr, strlen(cstr)); }

 protected:
  void EnsureSpace(intptr_t size_needed) {
    if (Remaining() >= size_needed) return;
    intptr_t increment_size = capacity_;
    if (size_needed > increment_size) {
      increment_size = Utils::RoundUp(size_needed, initial_size_);
    }
    intptr_t new_size = capacity_ + increment_size;
    ASSERT(new_size > capacity_);
    Realloc(new_size);
    if (buffer_ == nullptr) {
      Exceptions::ThrowOOM();
    }
    ASSERT(Remaining() >= size_needed);
  }

  virtual void SetPosition(intptr_t value) {
    EnsureSpace(value - BaseWriteStream::Position());
    current_ = buffer_ + value;
  }

  DART_FORCE_INLINE intptr_t Remaining() const {
    return capacity_ - BaseWriteStream::Position();
  }

  // Resizes the internal buffer to the requested new capacity. Should set
  // buffer_, capacity_, and current_ appropriately.
  //
  // Instead of templating over an Allocator (which would then cause users
  // of the templated class to need to be templated, etc.), we just add an
  // Realloc method to override appropriately in subclasses. Less flexible,
  // but requires less changes throughout the codebase.
  virtual void Realloc(intptr_t new_capacity) = 0;

  const intptr_t initial_size_;
  uint8_t* buffer_ = nullptr;
  uint8_t* current_ = nullptr;
  intptr_t capacity_ = 0;

  DISALLOW_COPY_AND_ASSIGN(BaseWriteStream);
};

// A base class for non-streaming write streams. Since these streams are
// not flushed periodically, the internal buffer contains all written data
// and can be retrieved via buffer(). NonStreamingWriteStream also provides
// SetPosition as part of its public API for non-sequential writing.
class NonStreamingWriteStream : public BaseWriteStream {
 public:
  explicit NonStreamingWriteStream(intptr_t initial_size)
      : BaseWriteStream(initial_size) {}

 public:
  uint8_t* buffer() const { return buffer_; }

  // Sets the position of the buffer
  DART_FORCE_INLINE void SetPosition(intptr_t value) {
    BaseWriteStream::SetPosition(value);
  }
};

// A non-streaming write stream that uses realloc for reallocation, and frees
// the buffer when destructed unless ownership is transfered using Steal().
class MallocWriteStream : public NonStreamingWriteStream {
 public:
  explicit MallocWriteStream(intptr_t initial_size)
      : NonStreamingWriteStream(initial_size) {
    // Go ahead and allocate initial space at construction.
    EnsureSpace(initial_size_);
  }
  ~MallocWriteStream();

  // Resets the stream and returns the original buffer, which is now considered
  // owned by the caller. Sets [*length] to the length of the returned buffer.
  uint8_t* Steal(intptr_t* length) {
    ASSERT(length != nullptr);
    *length = bytes_written();
    uint8_t* const old_buffer = buffer_;
    // We don't immediately reallocate a new space just in case this steal
    // is the last use of this stream.
    current_ = buffer_ = nullptr;
    capacity_ = 0;
    return old_buffer;
  }

 private:
  virtual void Realloc(intptr_t new_size);

  DISALLOW_COPY_AND_ASSIGN(MallocWriteStream);
};

// A non-streaming write stream that uses a zone for reallocation.
class ZoneWriteStream : public NonStreamingWriteStream {
 public:
  ZoneWriteStream(Zone* zone, intptr_t initial_size)
      : NonStreamingWriteStream(initial_size), zone_(zone) {
    // Go ahead and allocate initial space at construction.
    EnsureSpace(initial_size_);
  }

 private:
  virtual void Realloc(intptr_t new_size);

  Zone* const zone_;

  DISALLOW_COPY_AND_ASSIGN(ZoneWriteStream);
};

// A streaming write stream that uses the internal buffer only for non-flushed
// data. Like MallocWriteStream, uses realloc for reallocation, and flushes and
// frees the internal buffer when destructed. Since part or all of the written
// data may be flushed and no longer in the internal buffer, it does not provide
// a way to retrieve the written contents.
class StreamingWriteStream : public BaseWriteStream {
 public:
  explicit StreamingWriteStream(intptr_t initial_capacity,
                                Dart_StreamingWriteCallback callback,
                                void* callback_data)
      : BaseWriteStream(initial_capacity),
        callback_(callback),
        callback_data_(callback_data) {
    // Go ahead and allocate initial space at construction.
    EnsureSpace(initial_capacity);
  }
  ~StreamingWriteStream();

 private:
  // Flushes any unflushed data to callback_data and resets the internal
  // buffer. Changes current_ and flushed_size_ accordingly.
  virtual void Flush();

  virtual void Realloc(intptr_t new_size);

  virtual intptr_t Position() const {
    return flushed_size_ + BaseWriteStream::Position();
  }

  virtual void SetPosition(intptr_t value) {
    // Make sure we're not trying to set the position to already-flushed data.
    ASSERT(value >= flushed_size_);
    BaseWriteStream::SetPosition(value - flushed_size_);
  }

  const Dart_StreamingWriteCallback callback_;
  void* const callback_data_;
  intptr_t flushed_size_ = 0;

  DISALLOW_COPY_AND_ASSIGN(StreamingWriteStream);
};

}  // namespace dart

#endif  // RUNTIME_VM_DATASTREAM_H_
