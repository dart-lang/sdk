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

  uword At(intptr_t i) const;
  void SetAt(intptr_t i, uword pc);
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
  uword pcs_[0];

  DISALLOW_COPY_AND_ASSIGN(Sample);
};


class SampleVisitor {
 public:
  explicit SampleVisitor(Isolate* isolate) : isolate_(isolate), visited_(0) { }
  virtual ~SampleVisitor() {}

  virtual void VisitSample(Sample* sample) = 0;

  intptr_t visited() const {
    return visited_;
  }

  void IncrementVisited() {
    visited_++;
  }

  Isolate* isolate() const {
    return isolate_;
  }

 private:
  Isolate* isolate_;
  intptr_t visited_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(SampleVisitor);
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

  void VisitSamples(SampleVisitor* visitor);

 private:
  Sample* samples_;
  intptr_t capacity_;
  uintptr_t cursor_;

  DISALLOW_COPY_AND_ASSIGN(SampleBuffer);
};


}  // namespace dart

#endif  // VM_PROFILER_H_
