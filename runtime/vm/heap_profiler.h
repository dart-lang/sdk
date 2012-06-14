// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_HEAP_PROFILER_H_
#define VM_HEAP_PROFILER_H_

#include <set>

#include "include/dart_api.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/object.h"
#include "vm/visitor.h"

namespace dart {

// A HeapProfiler writes a snapshot of the heap for off-line analysis.
// The heap is written in binary HPROF format, which is a sequence of
// self describing records.  A description of the HPROF format can be
// found at
//
// http://java.net/downloads/heap-snapshot/hprof-binary-format.html
//
// HPROF was not designed for Dart, but most Dart concepts can be
// mapped directly into HPROF.  Some features, such as immediate
// objects and variable length objects, require a translation.
class HeapProfiler {
 public:
  enum Tag {
    kStringInUtf8 = 0x01,
    kLoadClass = 0x02,
    kUnloadClass = 0x03,
    kStackFrame = 0x04,
    kStackTrace = 0x05,
    kAllocSites = 0x06,
    kHeapSummary = 0x07,
    kStartThread = 0x0A,
    kEndThread = 0x0B,
    kHeapDump = 0x0C,
    kCpuSamples = 0x0D,
    kControlSettings = 0x0E,
    kHeapDumpSummary = 0x1C,
    kHeapDumpEnd = 0x2C
  };

  // Sub-record tags describe sub-records within a heap dump.
  enum Subtag {
    kRootJniGlobal = 0x01,
    kRootJniLocal = 0x01,
    kRootJavaFrame = 0x03,
    kRootNativeStack = 0x04,
    kRootStickyClass = 0x05,
    kRootThreadBlock = 0x06,
    kRootMonitorUsed = 0x07,
    kRootThreadObject = 0x08,
    kClassDump = 0x20,
    kInstanceDump = 0x21,
    kObjectArrayDump = 0x22,
    kPrimitiveArrayDump = 0x23,
    kRootUnknown = 0xFF
  };

  // Tags for describing element and field types.
  enum BasicType {
    kObject = 2,
    kBoolean = 4,
    kChar = 5,
    kFloat = 6,
    kDouble = 7,
    kByte = 8,
    kShort = 9,
    kInt = 10,
    kLong = 11
  };

  HeapProfiler(Dart_HeapProfileWriteCallback callback, void* stream);
  ~HeapProfiler();

  // Writes a root to the heap dump.
  void WriteRoot(const RawObject* raw_obj);

  // Writes a object to the heap dump.
  void WriteObject(const RawObject* raw_obj);

 private:
  // Record tags describe top-level records.
  // A growable array of bytes used to build a record body.
  class Buffer {
   public:
    Buffer() : data_(0), size_(0), capacity_(0) {
    }
    ~Buffer();

    // Writes an array of bytes to the buffer, increasing the capacity
    // as needed.
    void Write(const uint8_t* data, intptr_t length);

    // Returns the underlying element storage.
    const uint8_t* Data() const {
      return data_;
    }

    // Returns the number of elements written to the buffer.
    intptr_t Size() const {
      return size_;
    }

   private:
    // Resizes the element storage, if needed.
    void EnsureCapacity(intptr_t size);

    uint8_t* data_;

    intptr_t size_;

    // Size of the element storage.
    intptr_t capacity_;

    DISALLOW_COPY_AND_ASSIGN(Buffer);
  };

  // A top-level data record.
  class Record {
   public:
    Record(uint8_t tag, HeapProfiler* profiler)
        : tag_(tag), profiler_(profiler) {
    }
    ~Record() {
      profiler_->WriteRecord(*this);
    }

    // Returns the tag describing the record format.
    uint8_t Tag() const {
      return tag_;
    }

    // Returns a millisecond time delta, always 0.
    uint8_t Time() const {
      return 0;
    }

    // Returns the record length in bytes.
    uint32_t Length() const {
      return body_.Size();
    }

    // Returns the record body.
    const uint8_t* Body() const {
      return body_.Data();
    }

    // Appends an array of 8-bit values to the record body.
    void Write(const uint8_t* value, intptr_t size);

    // Appends an 8-, 16-, 32- or 64-bit value to the body in
    // big-endian format.
    void Write8(uint8_t value);
    void Write16(uint16_t value);
    void Write32(uint32_t value);
    void Write64(uint64_t value);

    // Appends an ID to the body.
    void WritePointer(const void* value);

   private:
    // A tag value that describes the record format.
    uint8_t tag_;

    // The payload of the record as described by the tag.
    Buffer body_;

    // Parent object.
    HeapProfiler* profiler_;

    DISALLOW_COPY_AND_ASSIGN(Record);
  };

  // A sub-record within a heap dump record.  Write calls are
  // forwarded to the profilers heap dump record instance.
  class SubRecord {
   public:
    // Starts a new sub-record within the heap dump record.
    SubRecord(uint8_t sub_tag, HeapProfiler* profiler);
    ~SubRecord();

    // Appends an array of 8-bit values to the heap dump record.
    void Write(const uint8_t* value, intptr_t size);

    // Appends an 8-, 16-, 32- or 64-bit value to the heap dump
    // record.
    void Write8(uint8_t value);
    void Write16(uint16_t value);
    void Write32(uint32_t value);
    void Write64(uint64_t value);

    // Appends an ID to the current heap dump record.
    void WritePointer(const void* value);

   private:
    // The record instance that receives forwarded write calls.
    Record* record_;
  };

  // Id canonizers.
  const RawClass* ClassId(const RawClass* raw_class);
  const RawObject* ObjectId(const RawObject* raw_obj);
  const char* StringId(const char* c_string);
  const RawString* StringId(const RawString* raw_string);

  // Invokes the write callback.
  void Write(const void* data, intptr_t size);

  // Writes the binary hprof header to the output stream.
  void WriteHeader();

  // Writes a record to the output stream.
  void WriteRecord(const Record& record);


  // Writes a string in utf-8 record to the output stream.
  void WriteStringInUtf8(const char* c_string);
  void WriteStringInUtf8(const RawString* raw_string);


  // Writes a load class record to the output stream.
  void WriteLoadClass(const RawClass* raw_class);

  // Writes an empty stack trace to the output stream.
  void WriteStackTrace();

  // Writes a heap summary record to the output stream.
  void WriteHeapSummary(uint32_t total_live_bytes,
                        uint32_t total_live_instances,
                        uint64_t total_bytes_allocated,
                        uint64_t total_instances_allocated);

  // Writes a heap dump record to the output stream.
  void WriteHeapDump();

  // Writes a sub-record to the heap dump record.
  void WriteClassDump(const RawClass* raw_class);
  void WriteInstanceDump(const RawObject* raw_obj);
  void WriteObjectArrayDump(const RawArray* raw_array);
  void WritePrimitiveArrayDump(const RawByteArray* raw_byte_array,
                               uint8_t tag,
                               const void* data);

  static const RawClass* GetClass(const RawObject* raw_obj);
  static const RawClass* GetSuperClass(const RawClass* raw_class);

  Dart_HeapProfileWriteCallback write_callback_;

  void* output_stream_;

  Record* heap_dump_record_;

  std::set<const RawSmi*> smi_table_;
  std::set<const RawClass*> class_table_;
  std::set<const RawString*> string_table_;

  DISALLOW_COPY_AND_ASSIGN(HeapProfiler);
};


// Writes a root sub-record to the heap dump for every strong handle.
class HeapProfilerRootVisitor : public ObjectPointerVisitor {
 public:
  explicit HeapProfilerRootVisitor(HeapProfiler* profiler)
      : ObjectPointerVisitor(Isolate::Current()),
        profiler_(profiler) {
  }

  virtual void VisitPointers(RawObject** first, RawObject** last);

 private:
  HeapProfiler* profiler_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(HeapProfilerRootVisitor);
};


// Writes a root sub-record to the heap dump for every weak handle.
class HeapProfilerWeakRootVisitor : public HandleVisitor {
 public:
  explicit HeapProfilerWeakRootVisitor(HeapProfilerRootVisitor* visitor)
      : visitor_(visitor) {
  }

  virtual void VisitHandle(uword addr);

 private:
  HeapProfilerRootVisitor* visitor_;
  DISALLOW_COPY_AND_ASSIGN(HeapProfilerWeakRootVisitor);
};


// Writes a sub-record to the heap dump for every object in the heap.
class HeapProfilerObjectVisitor : public ObjectVisitor {
 public:
  explicit HeapProfilerObjectVisitor(HeapProfiler* profiler)
      : profiler_(profiler) {
  }

  virtual void VisitObject(RawObject* obj);

 private:
  HeapProfiler* profiler_;
  DISALLOW_COPY_AND_ASSIGN(HeapProfilerObjectVisitor);
};

}  // namespace dart

#endif  // VM_HEAP_PROFILER_H_
