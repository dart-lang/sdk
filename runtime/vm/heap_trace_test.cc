// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <iostream>
#include <sstream>
#include <string>
#include "vm/dart_api_impl.h"
#include "vm/growable_array.h"
#include "vm/heap.h"
#include "vm/heap_trace.h"
#include "vm/unit_test.h"

namespace dart {

// only ia32 can run heap trace tests.
#if defined(TARGET_ARCH_IA32)
static std::stringstream* global_stream;

static void* OpenTraceFile(const char* name) {
  ASSERT(global_stream == NULL);
  global_stream = new std::stringstream;
  return reinterpret_cast<void*>(global_stream);
}


static void WriteToTraceFile(const void* data, intptr_t length, void* stream) {
  ASSERT(stream == global_stream);
  std::stringstream* sstream = reinterpret_cast<std::stringstream*>(stream);
  sstream->write(reinterpret_cast<const char*>(data), length);
}


static void CloseTraceFile(void *stream) {
  ASSERT(stream == global_stream);
  global_stream = NULL;
  delete reinterpret_cast<std::stringstream*>(stream);
}


bool DoesAllocationRecordExist(uword addr, const std::string& trace_string) {
  const char* raw_trace = trace_string.c_str();
  for (size_t i = 0; i < trace_string.length(); ++i) {
    if ((raw_trace[i] == 'A') && (i + 4 < trace_string.length())) {
      const uword candidate_address =
          *(reinterpret_cast<const uword*>(raw_trace + i + 1));
      if (candidate_address == addr) {
        return true;
      }
    }
  }
  return false;
}


bool DoesSweepRecordExist(uword addr, const std::string& trace_string) {
  const char* raw_trace = trace_string.c_str();
  for (size_t i = 0; i < trace_string.length(); ++i) {
    if ((raw_trace[i] == 'S') && (i + 4 < trace_string.length())) {
      const uword candidate_address =
          *(reinterpret_cast<const uword*>(raw_trace + i + 1));
      if (candidate_address == addr) {
        return true;
      }
    }
  }
  return false;
}


TEST_CASE(GCTraceAllocate) {
  HeapTrace::InitOnce(OpenTraceFile,
                      WriteToTraceFile,
                      CloseTraceFile);

  Isolate* isolate = Isolate::Current();
  isolate->heap()->trace()->Init(isolate);

  const int kArrayLen = 5;
  RawArray* raw_arr = Array::New(kArrayLen);
  uword addr = RawObject::ToAddr(raw_arr);

  ASSERT(DoesAllocationRecordExist(addr, global_stream->str()));
}


TEST_CASE(GCTraceSweep) {
  HeapTrace::InitOnce(OpenTraceFile,
                      WriteToTraceFile,
                      CloseTraceFile);

  Isolate* isolate = Isolate::Current();
  isolate->heap()->trace()->Init(isolate);

  const int kArrayLen = 5;
  RawArray* raw_arr = Array::New(kArrayLen, Heap::kOld);
  uword addr = RawObject::ToAddr(raw_arr);

  Isolate::Current()->heap()->CollectGarbage(Heap::kOld);
  DoesSweepRecordExist(addr, global_stream->str());
}
#endif

}  // namespace dart
