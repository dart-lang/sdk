// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_SNAPSHOT_H_
#define VM_SNAPSHOT_H_

#include "vm/allocation.h"
#include "vm/assert.h"
#include "vm/bitfield.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class Heap;
class ObjectStore;
class RawClass;
class RawObject;
class Object;

static const int8_t kSerializedBitsPerByte = 7;
static const int8_t kMaxSerializedUnsignedValuePerByte = 127;
static const int8_t kMaxSerializedValuePerByte = 63;
static const int8_t kMinSerializedValuePerByte = -64;
static const uint8_t kEndByteMarker = (255 - kMaxSerializedValuePerByte);
static const int8_t kSerializedByteMask = (1 << kSerializedBitsPerByte) - 1;

// Serialized object header encoding is as follows:
// - Smi: the Smi value is written as is (last bit is not tagged).
// - VM internal type (from VM isolate): (index of type in vm isolate | 0x3)
// - Object that has already been written: (negative id in stream | 0x3)
// - Object that is seen for the first time (inlined in the stream):
//   (a unique id for this object | 0x1)
enum SerializedHeaderType {
  kInlined = 0x1,
  kObjectId = 0x3,
};


typedef uint8_t* (*ReAlloc)(uint8_t* ptr, intptr_t old_size, intptr_t new_size);


class SerializedHeaderTag : public BitField<enum SerializedHeaderType, 0, 2> {
};


class SerializedHeaderData : public BitField<intptr_t, 2, 30> {
};


// Structure capturing the raw snapshot.
class Snapshot {
 public:
  static const int kHeaderSize = 2 * sizeof(int32_t);
  static const int kLengthIndex = 0;
  static const int kSnapshotFlagIndex = 1;

  static Snapshot* SetupFromBuffer(void* raw_memory);

  // Getters.
  uint8_t* content() { return content_; }
  int32_t length() const { return length_; }

  bool IsPartialSnapshot() const { return full_snapshot_ == 0; }
  bool IsFullSnapshot() const { return full_snapshot_ != 0; }
  int32_t Size() const { return length_ + sizeof(Snapshot); }
  uint8_t* Addr() { return reinterpret_cast<uint8_t*>(this); }

  static intptr_t length_offset() { return OFFSET_OF(Snapshot, length_); }
  static intptr_t full_snapshot_offset() {
    return OFFSET_OF(Snapshot, full_snapshot_);
  }

 private:
  Snapshot() : length_(0), full_snapshot_(0) {}

  int32_t length_;  // Stream length.
  int32_t full_snapshot_;  // Classes are serialized too.
  uint8_t content_[];  // Stream content.

  DISALLOW_COPY_AND_ASSIGN(Snapshot);
};


// Stream for reading various types from a buffer.
class ReadStream : public ValueObject {
 public:
  ReadStream(uint8_t* buffer, intptr_t size) : buffer_(buffer),
                                               current_(buffer),
                                               end_(buffer + size)  {}

 private:
  template<typename T>
  T Read() {
    uint8_t b = ReadByte();
    if (b > kMaxSerializedUnsignedValuePerByte) {
      return static_cast<T>(b) - kEndByteMarker;
    }
    T r = 0;
    uint8_t s = 0;
    do {
      r |= static_cast<T>(b) << s;
      s += kSerializedBitsPerByte;
      b = ReadByte();
    } while (b <= kMaxSerializedUnsignedValuePerByte);
    return r | ((static_cast<T>(b) - kEndByteMarker) << s);
  }

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

  uint8_t ReadByte() {
    ASSERT(current_ < end_);
    return *current_++;
  }

 private:
  uint8_t* buffer_;
  uint8_t* current_;
  uint8_t* end_;

  // SnapshotReader needs access to the private Raw classes.
  friend class SnapshotReader;
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
    current_ = *buffer_ + Snapshot::kHeaderSize;
    current_size_ = kBufferIncrementSize;
    end_ = *buffer_ + kBufferIncrementSize;
  }

  uint8_t* buffer() const { return *buffer_; }
  int bytes_written() const { return current_ - *buffer_; }

 private:
  template<typename T>
  void Write(T value) {
    T v = value;
    while (v < kMinSerializedValuePerByte ||
           v > kMaxSerializedValuePerByte) {
      WriteByte(static_cast<uint8_t>(v & kSerializedByteMask));
      v = v >> kSerializedBitsPerByte;
    }
    WriteByte(static_cast<uint8_t>(v + kEndByteMarker));
  }

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

  // MessageWriter and SnapshotWriter needs access to the private Raw
  // classes.
  friend class MessageWriter;
  friend class SnapshotWriter;
  DISALLOW_COPY_AND_ASSIGN(WriteStream);
};


// Reads a snapshot into objects.
class SnapshotReader {
 public:
  SnapshotReader(Snapshot* snapshot, Heap* heap, ObjectStore* object_store)
      : stream_(snapshot->content(), snapshot->length()),
        classes_serialized_(snapshot->IsFullSnapshot()),
        heap_(heap),
        object_store_(object_store),
        backward_references_() { }
  ~SnapshotReader() { }

  // Reads raw data (for basic types).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  T Read() {
    return ReadStream::Raw<sizeof(T), T>::Read(&stream_);
  }

  Heap* heap() const { return heap_; }
  ObjectStore* object_store() const { return object_store_; }

  // Reads an object.
  RawObject* ReadObject();

  RawClass* ReadClassId(intptr_t object_id);

  // Add object to backward references.
  void AddBackwardReference(intptr_t id, Object* obj);

  // Read a full snap shot.
  void ReadFullSnapshot();

 private:
  // Internal implementation of ReadObject once the header value is read.
  RawObject* ReadObjectImpl(intptr_t header);

  // Read an object that was serialized as an Id (singleton, object store,
  // or an object that was already serialized before).
  RawObject* ReadIndexedObject(intptr_t object_id);

  // Read an inlined object from the stream.
  RawObject* ReadInlinedObject(intptr_t object_id);

  // Based on header field check to see if it is an internal VM class.
  RawClass* LookupInternalClass(intptr_t class_header);

  ReadStream stream_;  // input stream.
  bool classes_serialized_;  // Indicates if classes are serialized.
  Heap* heap_;  // Heap into which the objects are deserialized into.
  ObjectStore* object_store_;  // Object store for common classes.
  GrowableArray<Object*> backward_references_;

  DISALLOW_COPY_AND_ASSIGN(SnapshotReader);
};


class MessageWriter {
 public:
  MessageWriter(uint8_t** buffer, ReAlloc alloc) : stream_(buffer, alloc) {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~MessageWriter() { }

  // Writes a message of integers.
  void WriteMessage(intptr_t field_count, intptr_t *data);

 private:
  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }

  // Setup header information for an object.
  void WriteObjectHeader(SerializedHeaderType type, intptr_t id) {
    uword value = 0;
    value = SerializedHeaderTag::update(type, value);
    value = SerializedHeaderData::update(id, value);
    Write<uword>(value);
  }

  // Finalize the serialized buffer by filling in the header information
  // which comprises of a flag(full/partial snaphot) and the length of
  // serialzed bytes.
  void FinalizeBuffer() {
    int32_t* data = reinterpret_cast<int32_t*>(stream_.buffer());
    data[Snapshot::kLengthIndex] = stream_.bytes_written();
    data[Snapshot::kSnapshotFlagIndex] = false;
  }

  WriteStream stream_;

  DISALLOW_COPY_AND_ASSIGN(MessageWriter);
};


class SnapshotWriter {
 public:
  SnapshotWriter(bool full_snapshot, uint8_t** buffer, ReAlloc alloc)
      : stream_(buffer, alloc),
        serialize_classes_(full_snapshot),
        object_store_(Isolate::Current()->object_store()),
        forward_list_() {
    ASSERT(buffer != NULL);
    ASSERT(alloc != NULL);
  }
  ~SnapshotWriter() { }

  // Size of the snapshot.
  intptr_t Size() const { return stream_.bytes_written(); }

  // Finalize the serialized buffer by filling in the header information
  // which comprises of a flag(full/partial snaphot) and the length of
  // serialzed bytes.
  void FinalizeBuffer() {
    int32_t* data = reinterpret_cast<int32_t*>(stream_.buffer());
    data[Snapshot::kLengthIndex] = stream_.bytes_written();
    data[Snapshot::kSnapshotFlagIndex] = serialize_classes_;
    UnmarkAll();
  }

  // Writes raw data to the stream (basic type).
  // sizeof(T) must be in {1,2,4,8}.
  template <typename T>
  void Write(T value) {
    WriteStream::Raw<sizeof(T), T>::Write(&stream_, value);
  }

  // Serialize an object into the buffer.
  void WriteObject(RawObject* raw);

  void WriteClassId(RawClass* cls);

  // Setup header information for an object.
  void WriteObjectHeader(SerializedHeaderType type, intptr_t value);

  // Unmark all objects that were marked as forwarded for serializing.
  void UnmarkAll();

  // Writes a full snapshot of the Isolate.
  void WriteFullSnapshot();

 private:
  class ForwardObjectNode : public ZoneAllocated {
   public:
    ForwardObjectNode(RawObject* raw, RawClass* cls) : raw_(raw), cls_(cls) {}
    RawObject* raw() const { return raw_; }
    RawClass* cls() const { return cls_; }

   private:
    RawObject* raw_;
    RawClass* cls_;

    DISALLOW_COPY_AND_ASSIGN(ForwardObjectNode);
  };

  intptr_t MarkObject(RawObject* raw, RawClass* cls);

  void WriteInlinedObject(RawObject* raw);

  ObjectStore* object_store() const { return object_store_; }

  WriteStream stream_;
  bool serialize_classes_;
  ObjectStore* object_store_;  // Object store for common classes.
  GrowableArray<ForwardObjectNode*> forward_list_;

  DISALLOW_COPY_AND_ASSIGN(SnapshotWriter);
};


// An object pointer visitor implementation which writes out
// objects to a snap shot.
class SnapshotWriterVisitor : public ObjectPointerVisitor {
 public:
  explicit SnapshotWriterVisitor(SnapshotWriter* writer) : writer_(writer) {}

  virtual void VisitPointers(RawObject** first, RawObject** last);

 private:
  SnapshotWriter* writer_;

  DISALLOW_COPY_AND_ASSIGN(SnapshotWriterVisitor);
};

}  // namespace dart

#endif  // VM_SNAPSHOT_H_
