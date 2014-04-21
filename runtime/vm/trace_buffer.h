// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TRACE_BUFFER_H_
#define VM_TRACE_BUFFER_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/json_stream.h"

namespace dart {

class JSONObject;
class JSONStream;

struct TraceBufferEntry {
  int64_t micros;
  char* message;
  bool empty() const {
    return message == NULL;
  }
};

class TraceBuffer {
 public:
  static const intptr_t kInitialCapacity = 16;
  static const intptr_t kMaximumCapacity = 1024;

  // TraceBuffer starts with kInitialCapacity and will expand itself until
  // it reaches kMaximumCapacity.
  TraceBuffer(intptr_t initial_capacity = kInitialCapacity,
              intptr_t maximum_capacity = kMaximumCapacity);
  ~TraceBuffer();

  void Clear();

  // Internally message is copied.
  void Trace(int64_t micros, const char* message);
  // Internally message is copied.
  void Trace(const char* message);
  void TraceF(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  void PrintToJSONObject(JSONObject* obj) const;
  void PrintToJSONStream(JSONStream* stream) const;

  intptr_t capacity() const { return capacity_; }

 private:
  void Init();
  void Resize(intptr_t capacity);
  void Cleanup();
  void Fill(TraceBufferEntry* entry, int64_t micros, char* msg);
  void AppendTrace(int64_t micros, char* message);

  TraceBufferEntry* ring_;
  intptr_t size_;
  intptr_t capacity_;
  intptr_t ring_cursor_;
  const intptr_t max_capacity_;

  intptr_t RingIndex(intptr_t i) const {
    return i % capacity_;
  }

  DISALLOW_COPY_AND_ASSIGN(TraceBuffer);
};


}  // namespace dart

#endif  // VM_TRACE_BUFFER_H_
