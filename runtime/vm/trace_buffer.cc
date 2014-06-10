// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/os.h"
#include "vm/trace_buffer.h"

namespace dart {

TraceBuffer::TraceBuffer(Isolate* isolate, intptr_t capacity)
    : isolate_(isolate), ring_capacity_(capacity) {
  ring_cursor_ = 0;
  ring_ = reinterpret_cast<TraceBufferEntry*>(
      calloc(ring_capacity_, sizeof(TraceBufferEntry)));  // NOLINT
}


TraceBuffer::~TraceBuffer() {
  ASSERT(ring_ != NULL);
  Clear();
  free(ring_);
  if (isolate_ != NULL) {
    isolate_->set_trace_buffer(NULL);
    isolate_ = NULL;
  }
}


void TraceBuffer::Init(Isolate* isolate, intptr_t capacity) {
  TraceBuffer* trace_buffer = new TraceBuffer(isolate, capacity);
  isolate->set_trace_buffer(trace_buffer);
}


void TraceBuffer::Clear() {
  for (intptr_t i = 0; i < ring_capacity_; i++) {
    TraceBufferEntry& entry = ring_[i];
    entry.micros = 0;
    free(entry.message);
    entry.message = NULL;
  }
  ring_cursor_ = 0;
}


void TraceBuffer::Fill(TraceBufferEntry* entry, int64_t micros, char* msg) {
  if (entry->message != NULL) {
    // Recycle TraceBufferEntry.
    free(entry->message);
  }
  entry->message = msg;
  entry->micros = micros;
}


void TraceBuffer::AppendTrace(int64_t micros, char* message) {
  const intptr_t index = ring_cursor_;
  TraceBufferEntry* trace_entry = &ring_[index];
  Fill(trace_entry, micros, message);
  ring_cursor_ = RingIndex(ring_cursor_ + 1);
}


void TraceBuffer::Trace(int64_t micros, const char* message) {
  ASSERT(message != NULL);
  char* message_copy = strdup(message);
  AppendTrace(micros, message_copy);
}


void TraceBuffer::Trace(const char* message) {
  Trace(OS::GetCurrentTimeMicros(), message);
}


void TraceBuffer::TraceF(const char* format, ...) {
  int64_t micros = OS::GetCurrentTimeMicros();
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);
  char* p = reinterpret_cast<char*>(malloc(len+1));
  va_start(args, format);
  intptr_t len2 = OS::VSNPrint(p, len+1, format, args);
  va_end(args);
  ASSERT(len == len2);
  AppendTrace(micros, p);
}


void TraceBuffer::PrintToJSONStream(JSONStream* stream) const {
  JSONObject json_trace_buffer(stream);
  json_trace_buffer.AddProperty("type", "TraceBuffer");
  // TODO(johnmccutchan): Send cursor position in response.
  JSONArray json_trace_buffer_array(&json_trace_buffer, "members");
  // Scan forward until we find the first entry which isn't empty.
  // TODO(johnmccutchan): Accept cursor start position as input.
  intptr_t start = -1;
  for (intptr_t i = 0; i < ring_capacity_; i++) {
    intptr_t index = RingIndex(i + ring_cursor_);
    if (!ring_[index].empty()) {
      start = index;
      break;
    }
  }
  // No messages in trace buffer.
  if (start == -1) {
    return;
  }
  for (intptr_t i = 0; i < ring_capacity_; i++) {
    intptr_t index = RingIndex(start + i);
    const TraceBufferEntry& entry = ring_[index];
    if (entry.empty()) {
      // Empty entry, stop.
      break;
    }
    JSONObject trace_entry(&json_trace_buffer_array);
    trace_entry.AddProperty("type", "TraceBufferEntry");
    double seconds = static_cast<double>(entry.micros) /
                     static_cast<double>(kMicrosecondsPerSecond);
    trace_entry.AddProperty("time", seconds);
    trace_entry.AddProperty("message", entry.message);
  }
}

}  // namespace dart
