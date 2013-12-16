// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PROFILER_H_
#define VM_PROFILER_H_

#include "vm/allocation.h"
#include "vm/code_observers.h"
#include "vm/globals.h"
#include "vm/thread.h"
#include "vm/thread_interrupter.h"

namespace dart {

// Forward declarations.
class JSONArray;
class JSONStream;
struct Sample;

// Profiler
class Profiler : public AllStatic {
 public:
  static void InitOnce();
  static void Shutdown();

  static void InitProfilingForIsolate(Isolate* isolate,
                                      bool shared_buffer = false);
  static void ShutdownProfilingForIsolate(Isolate* isolate);

  static void BeginExecution(Isolate* isolate);
  static void EndExecution(Isolate* isolate);

  static void PrintToJSONStream(Isolate* isolate, JSONStream* stream);

  static void WriteTracing(Isolate* isolate);

  static SampleBuffer* sample_buffer() {
    return sample_buffer_;
  }

 private:
  static bool initialized_;
  static Monitor* monitor_;

  static void WriteTracingSample(Isolate* isolate, intptr_t pid,
                                 Sample* sample, JSONArray& events);

  static void RecordTickInterruptCallback(const InterruptedThreadState& state,
                                          void* data);

  static void RecordSampleInterruptCallback(const InterruptedThreadState& state,
                                            void* data);

  static SampleBuffer* sample_buffer_;
};


class IsolateProfilerData {
 public:
  IsolateProfilerData(SampleBuffer* sample_buffer, bool own_sample_buffer);
  ~IsolateProfilerData();

  SampleBuffer* sample_buffer() const { return sample_buffer_; }

  void set_sample_buffer(SampleBuffer* sample_buffer) {
    sample_buffer_ = sample_buffer;
  }

 private:
  SampleBuffer* sample_buffer_;
  bool own_sample_buffer_;
  DISALLOW_COPY_AND_ASSIGN(IsolateProfilerData);
};


// Profile sample.
struct Sample {
  static const char* kLookupSymbol;
  static const char* kNoSymbol;
  static const char* kNoFrame;
  static const intptr_t kNumStackFrames = 6;
  enum SampleType {
    kIsolateStart,
    kIsolateStop,
    kIsolateSample,
  };
  int64_t timestamp;
  ThreadId tid;
  Isolate* isolate;
  uintptr_t pcs[kNumStackFrames];
  SampleType type;
  uint16_t vm_tags;
  uint16_t runtime_tags;

  void Init(SampleType type, Isolate* isolate, int64_t timestamp, ThreadId tid);
};


// Ring buffer of samples.
class SampleBuffer {
 public:
  static const intptr_t kDefaultBufferCapacity = 120000;  // 2 minutes @ 1000hz.

  explicit SampleBuffer(intptr_t capacity = kDefaultBufferCapacity);
  ~SampleBuffer();

  intptr_t capacity() const { return capacity_; }

  Sample* ReserveSample();

  Sample* GetSample(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < capacity_);
    return &samples_[i];
  }

 private:
  Sample* samples_;
  intptr_t capacity_;
  uintptr_t cursor_;

  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};


class ProfilerSampleStackWalker : public ValueObject {
 public:
  ProfilerSampleStackWalker(Sample* sample,
                            uintptr_t stack_lower,
                            uintptr_t stack_upper,
                            uintptr_t pc,
                            uintptr_t fp,
                            uintptr_t sp);

  int walk();

 private:
  uword* CallerPC(uword* fp);
  uword* CallerFP(uword* fp);

  bool ValidInstructionPointer(uword* pc);

  bool ValidFramePointer(uword* fp);

  Sample* sample_;
  const uintptr_t stack_lower_;
  const uintptr_t stack_upper_;
  const uintptr_t original_pc_;
  const uintptr_t original_fp_;
  const uintptr_t original_sp_;
  uintptr_t lower_bound_;
};


}  // namespace dart

#endif  // VM_PROFILER_H_
