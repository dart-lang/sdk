// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_TRACE_BUFFER_H_
#define VM_TRACE_BUFFER_H_

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/json_stream.h"

namespace dart {

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
  static const intptr_t kDefaultCapacity = 1024;

  static void Init(Isolate* isolate, intptr_t capacity = kDefaultCapacity);

  ~TraceBuffer();

  void Clear();

  // Internally message is copied.
  void Trace(int64_t micros, const char* message);
  // Internally message is copied.
  void Trace(const char* message);
  void TraceF(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  void PrintToJSONStream(JSONStream* stream) const;

 private:
  TraceBuffer(Isolate* isolate, intptr_t capacity);
  void Cleanup();
  void Fill(TraceBufferEntry* entry, int64_t micros, char* msg);
  void AppendTrace(int64_t micros, char* message);

  Isolate* isolate_;
  TraceBufferEntry* ring_;
  const intptr_t ring_capacity_;
  intptr_t ring_cursor_;

  intptr_t RingIndex(intptr_t i) const {
    return i % ring_capacity_;
  }

  DISALLOW_COPY_AND_ASSIGN(TraceBuffer);
};


}  // namespace dart

#endif  // VM_TRACE_BUFFER_H_
