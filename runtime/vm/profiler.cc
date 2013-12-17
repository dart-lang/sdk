// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdio>

#include "platform/utils.h"

#include "vm/atomic.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"

namespace dart {


// Notes on stack frame walking:
//
// The sampling profiler will collect up to Sample::kNumStackFrames stack frames
// The stack frame walking code uses the frame pointer to traverse the stack.
// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail (sometimes leading to a crash).
//

#if defined(USING_SIMULATOR) || defined(TARGET_OS_WINDOWS) || \
    defined(TARGET_OS_MACOS) || defined(TARGET_OS_ANDROID)
  DEFINE_FLAG(bool, profile, false, "Enable Sampling Profiler");
#else
  DEFINE_FLAG(bool, profile, true, "Enable Sampling Profiler");
#endif
DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");
DEFINE_FLAG(charp, profile_dir, NULL,
            "Enable writing profile data into specified directory.");

bool Profiler::initialized_ = false;
Monitor* Profiler::monitor_ = NULL;
SampleBuffer* Profiler::sample_buffer_ = NULL;

void Profiler::InitOnce() {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(!initialized_);
  initialized_ = true;
  monitor_ = new Monitor();
  sample_buffer_ = new SampleBuffer();
  NativeSymbolResolver::InitOnce();
  ThreadInterrupter::InitOnce();
}


void Profiler::Shutdown() {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Shutdown();
  NativeSymbolResolver::ShutdownOnce();
}


void Profiler::InitProfilingForIsolate(Isolate* isolate, bool shared_buffer) {
  if (!FLAG_profile) {
    return;
  }
  ASSERT(isolate != NULL);
  ASSERT(sample_buffer_ != NULL);
  MonitorLocker ml(monitor_);
  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    SampleBuffer* sample_buffer = sample_buffer_;
    if (!shared_buffer) {
      sample_buffer = new SampleBuffer();
    }
    IsolateProfilerData* profiler_data =
        new IsolateProfilerData(sample_buffer, !shared_buffer);
    ASSERT(profiler_data != NULL);
    isolate->set_profiler_data(profiler_data);
    if (FLAG_trace_profiled_isolates) {
      OS::Print("Profiler Setup %p %s\n", isolate, isolate->name());
    }
  }
}


void Profiler::ShutdownProfilingForIsolate(Isolate* isolate) {
  ASSERT(isolate != NULL);
  if (!FLAG_profile) {
    return;
  }
  // We do not have a current isolate.
  ASSERT(Isolate::Current() == NULL);
  MonitorLocker ml(monitor_);
  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if (profiler_data == NULL) {
      // Already freed.
      return;
    }
    isolate->set_profiler_data(NULL);
    profiler_data->set_sample_buffer(NULL);
    delete profiler_data;
    if (FLAG_trace_profiled_isolates) {
      OS::Print("Profiler Shutdown %p %s\n", isolate, isolate->name());
    }
  }
}


void Profiler::BeginExecution(Isolate* isolate) {
  if (isolate == NULL) {
    return;
  }
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  if (sample_buffer == NULL) {
    return;
  }
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(Sample::kIsolateStart, isolate, OS::GetCurrentTimeMicros(),
               Thread::GetCurrentThreadId());
  ThreadInterrupter::Register(RecordSampleInterruptCallback, isolate);
}


void Profiler::EndExecution(Isolate* isolate) {
  if (isolate == NULL) {
    return;
  }
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  ThreadInterrupter::Unregister();
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  if (sample_buffer == NULL) {
    return;
  }
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(Sample::kIsolateStop, isolate, OS::GetCurrentTimeMicros(),
               Thread::GetCurrentThreadId());
}


void Profiler::RecordTickInterruptCallback(const InterruptedThreadState& state,
                                           void* data) {
  Isolate* isolate = reinterpret_cast<Isolate*>(data);
  if (isolate == NULL) {
    return;
  }
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  if (sample_buffer == NULL) {
    return;
  }
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(Sample::kIsolateSample, isolate, OS::GetCurrentTimeMicros(),
               state.tid);
}


void Profiler::RecordSampleInterruptCallback(
    const InterruptedThreadState& state,
    void* data) {
  Isolate* isolate = reinterpret_cast<Isolate*>(data);
  if (isolate == NULL) {
    return;
  }
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  if (sample_buffer == NULL) {
    return;
  }
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(Sample::kIsolateSample, isolate, OS::GetCurrentTimeMicros(),
               state.tid);
  uintptr_t stack_lower = 0;
  uintptr_t stack_upper = 0;
  isolate->GetStackBounds(&stack_lower, &stack_upper);
  if ((stack_lower == 0) || (stack_upper == 0)) {
    stack_lower = 0;
    stack_upper = 0;
  }
  ProfilerSampleStackWalker stackWalker(sample, stack_lower, stack_upper,
                                        state.pc, state.fp, state.sp);
  stackWalker.walk();
}


void Profiler::PrintToJSONStream(Isolate* isolate, JSONStream* stream) {
  ASSERT(isolate == Isolate::Current());
  UNIMPLEMENTED();
}


static char* FindSymbolName(uintptr_t pc, bool* native_symbol) {
  // TODO(johnmccutchan): Differentiate between symbols which can't be found
  // and symbols which were GCed. (Heap::CodeContains).
  ASSERT(native_symbol != NULL);
  const char* symbol_name = "Unknown";
  *native_symbol = false;
  if (pc == 0) {
    return const_cast<char*>(Sample::kNoFrame);
  }
  const Code& code = Code::Handle(Code::LookupCode(pc));
  if (code.IsNull()) {
    // Possibly a native symbol.
    char* native_name = NativeSymbolResolver::LookupSymbolName(pc);
    if (native_name != NULL) {
      symbol_name = native_name;
      *native_symbol = true;
    }
  } else {
    const Function& function = Function::Handle(code.function());
    if (!function.IsNull()) {
      const String& name = String::Handle(function.QualifiedUserVisibleName());
      if (!name.IsNull()) {
        symbol_name = name.ToCString();
      }
    }
  }
  return const_cast<char*>(symbol_name);
}


void Profiler::WriteTracingSample(Isolate* isolate, intptr_t pid,
                                  Sample* sample, JSONArray& events) {
  Sample::SampleType type = sample->type;
  intptr_t tid = Thread::ThreadIdToIntPtr(sample->tid);
  double timestamp = static_cast<double>(sample->timestamp);
  const char* isolate_name = isolate->name();
  switch (type) {
    case Sample::kIsolateStart: {
      JSONObject begin(&events);
      begin.AddProperty("ph", "B");
      begin.AddProperty("tid", tid);
      begin.AddProperty("pid", pid);
      begin.AddProperty("name", isolate_name);
      begin.AddProperty("ts", timestamp);
    }
    break;
    case Sample::kIsolateStop: {
      JSONObject begin(&events);
      begin.AddProperty("ph", "E");
      begin.AddProperty("tid", tid);
      begin.AddProperty("pid", pid);
      begin.AddProperty("name", isolate_name);
      begin.AddProperty("ts", timestamp);
    }
    break;
    case Sample::kIsolateSample:
      // Write "B" events.
      for (int i = Sample::kNumStackFrames - 1; i >= 0; i--) {
        bool native_symbol = false;
        char* symbol_name = FindSymbolName(sample->pcs[i], &native_symbol);
        {
          JSONObject begin(&events);
          begin.AddProperty("ph", "B");
          begin.AddProperty("tid", tid);
          begin.AddProperty("pid", pid);
          begin.AddProperty("name", symbol_name);
          begin.AddProperty("ts", timestamp);
        }
        if (native_symbol) {
          NativeSymbolResolver::FreeSymbolName(symbol_name);
        }
      }
      // Write "E" events.
      for (int i = 0; i < Sample::kNumStackFrames; i++) {
        bool native_symbol = false;
        char* symbol_name = FindSymbolName(sample->pcs[i], &native_symbol);
        {
          JSONObject begin(&events);
          begin.AddProperty("ph", "E");
          begin.AddProperty("tid", tid);
          begin.AddProperty("pid", pid);
          begin.AddProperty("name", symbol_name);
          begin.AddProperty("ts", timestamp);
        }
        if (native_symbol) {
          NativeSymbolResolver::FreeSymbolName(symbol_name);
        }
      }
    break;
    default:
      UNIMPLEMENTED();
  }
}


void Profiler::WriteTracing(Isolate* isolate) {
  if (isolate == NULL) {
    return;
  }
  if (!FLAG_profile) {
    return;
  }
  ASSERT(initialized_);
  if (FLAG_profile_dir == NULL) {
    return;
  }
  Dart_FileOpenCallback file_open = Isolate::file_open_callback();
  Dart_FileCloseCallback file_close = Isolate::file_close_callback();
  Dart_FileWriteCallback file_write = Isolate::file_write_callback();
  if ((file_open == NULL) || (file_close == NULL) || (file_write == NULL)) {
    // Embedder has not provided necessary callbacks.
    return;
  }
  // We will be looking up code objects within the isolate.
  ASSERT(Isolate::Current() != NULL);
  // We do not want to be interrupted while processing the buffer.
  EndExecution(isolate);
  MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  JSONStream stream(10 * MB);
  intptr_t pid = OS::ProcessId();
  {
    JSONArray events(&stream);
    {
      JSONObject process_name(&events);
      process_name.AddProperty("name", "process_name");
      process_name.AddProperty("ph", "M");
      process_name.AddProperty("pid", pid);
      {
        JSONObject args(&process_name, "args");
        args.AddProperty("name", "Dart VM");
      }
    }
    for (intptr_t i = 0; i < sample_buffer->capacity(); i++) {
      Sample* sample = sample_buffer->GetSample(i);
      if (sample->isolate != isolate) {
        continue;
      }
      if (sample->timestamp == 0) {
        continue;
      }
      WriteTracingSample(isolate, pid, sample, events);
    }
  }
  const char* format = "%s/dart-profile-%" Pd "-%" Pd ".json";
  intptr_t len = OS::SNPrint(NULL, 0, format,
                             FLAG_profile_dir, pid, isolate->main_port());
  char* filename = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
  OS::SNPrint(filename, len + 1, format,
              FLAG_profile_dir, pid, isolate->main_port());
  void* f = file_open(filename, true);
  if (f == NULL) {
    // Cannot write.
    return;
  }
  TextBuffer* buffer = stream.buffer();
  ASSERT(buffer != NULL);
  file_write(buffer->buf(), buffer->length(), f);
  file_close(f);
  BeginExecution(isolate);
}


IsolateProfilerData::IsolateProfilerData(SampleBuffer* sample_buffer,
                                         bool own_sample_buffer) {
  sample_buffer_ = sample_buffer;
  own_sample_buffer_ = own_sample_buffer;
}


IsolateProfilerData::~IsolateProfilerData() {
  if (own_sample_buffer_) {
    delete sample_buffer_;
    sample_buffer_ = NULL;
    own_sample_buffer_ = false;
  }
}


const char* Sample::kLookupSymbol = "Symbol Not Looked Up";
const char* Sample::kNoSymbol = "No Symbol Found";
const char* Sample::kNoFrame = "<no frame>";

void Sample::Init(SampleType type, Isolate* isolate, int64_t timestamp,
                  ThreadId tid) {
  this->timestamp = timestamp;
  this->tid = tid;
  this->isolate = isolate;
  for (intptr_t i = 0; i < kNumStackFrames; i++) {
    pcs[i] = 0;
  }
  this->type = type;
  vm_tags = 0;
  runtime_tags = 0;
}

SampleBuffer::SampleBuffer(intptr_t capacity) {
  capacity_ = capacity;
  samples_ = reinterpret_cast<Sample*>(calloc(capacity, sizeof(Sample)));
  cursor_ = 0;
}


SampleBuffer::~SampleBuffer() {
  if (samples_ != NULL) {
    free(samples_);
    samples_ = NULL;
    cursor_ = 0;
    capacity_ = 0;
  }
}


Sample* SampleBuffer::ReserveSample() {
  ASSERT(samples_ != NULL);
  uintptr_t cursor = AtomicOperations::FetchAndIncrement(&cursor_);
  // Map back into sample buffer range.
  cursor = cursor % capacity_;
  return &samples_[cursor];
}


ProfilerSampleStackWalker::ProfilerSampleStackWalker(Sample* sample,
                                                     uintptr_t stack_lower,
                                                     uintptr_t stack_upper,
                                                     uintptr_t pc,
                                                     uintptr_t fp,
                                                     uintptr_t sp) :
    sample_(sample),
    stack_lower_(stack_lower),
    stack_upper_(stack_upper),
    original_pc_(pc),
    original_fp_(fp),
    original_sp_(sp),
    lower_bound_(stack_lower) {
  ASSERT(sample_ != NULL);
}


int ProfilerSampleStackWalker::walk() {
  const intptr_t kMaxStep = 0x1000;  // 4K.
  uword* pc = reinterpret_cast<uword*>(original_pc_);
#define WALK_STACK
#if defined(WALK_STACK)
  uword* fp = reinterpret_cast<uword*>(original_fp_);
  uword* previous_fp = fp;
  if (original_sp_ > original_fp_) {
    // Stack pointer should not be above frame pointer.
    return 0;
  }
  if ((original_fp_ - original_sp_) >= kMaxStep) {
    // Gap between frame pointer and stack pointer is
    // too large.
    return 0;
  }
  if (original_sp_ < lower_bound_) {
    // The stack pointer gives us a better lower bound than
    // the isolates stack limit.
    lower_bound_ = original_sp_;
  }
  int i = 0;
  for (; i < Sample::kNumStackFrames; i++) {
    sample_->pcs[i] = reinterpret_cast<uintptr_t>(pc);
    if (!ValidFramePointer(fp)) {
      break;
    }
    pc = CallerPC(fp);
    previous_fp = fp;
    fp = CallerFP(fp);
    intptr_t step = fp - previous_fp;
    if ((step >= kMaxStep) || (fp <= previous_fp) || !ValidFramePointer(fp)) {
      // Frame pointer step is too large.
      // Frame pointer did not move to a higher address.
      // Frame pointer is outside of isolate stack bounds.
      break;
    }
    // Move the lower bound up.
    lower_bound_ = reinterpret_cast<uintptr_t>(fp);
  }
  return i;
#else
  sample_->pcs[0] = reinterpret_cast<uintptr_t>(pc);
  return 0;
#endif
}


uword* ProfilerSampleStackWalker::CallerPC(uword* fp) {
  ASSERT(fp != NULL);
  return reinterpret_cast<uword*>(*(fp + 1));
}


uword* ProfilerSampleStackWalker::CallerFP(uword* fp) {
  ASSERT(fp != NULL);
  return reinterpret_cast<uword*>(*fp);
}


bool ProfilerSampleStackWalker::ValidFramePointer(uword* fp) {
  if (fp == NULL) {
    return false;
  }
  uintptr_t cursor = reinterpret_cast<uintptr_t>(fp);
  cursor += sizeof(fp);
  bool r = cursor >= lower_bound_ && cursor < stack_upper_;
  return r;
}


}  // namespace dart
