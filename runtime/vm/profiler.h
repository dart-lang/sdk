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
class ProfilerCodeRegionTable;
class Sample;
class SampleBuffer;

// Profiler
class Profiler : public AllStatic {
 public:
  static void InitOnce();
  static void Shutdown();

  static void InitProfilingForIsolate(Isolate* isolate,
                                      bool shared_buffer = true);
  static void ShutdownProfilingForIsolate(Isolate* isolate);

  static void BeginExecution(Isolate* isolate);
  static void EndExecution(Isolate* isolate);

  static void PrintToJSONStream(Isolate* isolate, JSONStream* stream,
                                bool full);
  static void WriteProfile(Isolate* isolate);

  static SampleBuffer* sample_buffer() {
    return sample_buffer_;
  }

 private:
  static bool initialized_;
  static Monitor* monitor_;

  static intptr_t ProcessSamples(Isolate* isolate,
                                 ProfilerCodeRegionTable* code_region_table,
                                 SampleBuffer* sample_buffer);

  static intptr_t ProcessSample(Isolate* isolate,
                                ProfilerCodeRegionTable* code_region_table,
                                Sample* sample);

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
class Sample {
 public:
  enum SampleType {
    kIsolateSample,
  };

  static void InitOnce();

  uintptr_t At(intptr_t i) const;
  void SetAt(intptr_t i, uintptr_t pc);
  void Init(SampleType type, Isolate* isolate, int64_t timestamp, ThreadId tid);
  void CopyInto(Sample* dst) const;

  static Sample* Allocate();
  static intptr_t instance_size() {
    return instance_size_;
  }

  SampleType type() const {
    return type_;
  }

  Isolate* isolate() const {
    return isolate_;
  }

  int64_t timestamp() const {
    return timestamp_;
  }

 private:
  static intptr_t instance_size_;
  int64_t timestamp_;
  ThreadId tid_;
  Isolate* isolate_;
  SampleType type_;
  // Note: This class has a size determined at run-time. The pcs_ array
  // must be the final field.
  uintptr_t pcs_[0];

  DISALLOW_COPY_AND_ASSIGN(Sample);
};


// Ring buffer of samples.
class SampleBuffer {
 public:
  static const intptr_t kDefaultBufferCapacity = 120000;  // 2 minutes @ 1000hz.

  explicit SampleBuffer(intptr_t capacity = kDefaultBufferCapacity);
  ~SampleBuffer();

  intptr_t capacity() const { return capacity_; }
  Sample* ReserveSample();
  void CopySample(intptr_t i, Sample* sample) const;
  Sample* At(intptr_t idx) const;

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
