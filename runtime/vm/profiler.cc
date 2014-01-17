// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/utils.h"

#include "vm/allocation.h"
#include "vm/atomic.h"
#include "vm/code_patcher.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/signal_handler.h"
#include "vm/simulator.h"

namespace dart {


#if defined(USING_SIMULATOR) || defined(TARGET_OS_WINDOWS) || \
    defined(TARGET_OS_MACOS) || defined(TARGET_OS_ANDROID)
  DEFINE_FLAG(bool, profile, false, "Enable Sampling Profiler");
#else
  DEFINE_FLAG(bool, profile, true, "Enable Sampling Profiler");
#endif
DEFINE_FLAG(bool, trace_profiled_isolates, false, "Trace profiled isolates.");
DEFINE_FLAG(charp, profile_dir, NULL,
            "Enable writing profile data into specified directory.");
DEFINE_FLAG(int, profile_period, 1000,
            "Time between profiler samples in microseconds. Minimum 250.");
DEFINE_FLAG(int, profile_depth, 8,
            "Maximum number stack frames walked. Minimum 1. Maximum 128.");

bool Profiler::initialized_ = false;
SampleBuffer* Profiler::sample_buffer_ = NULL;

void Profiler::InitOnce() {
  const int kMinimumProfilePeriod = 250;
  const int kMinimumDepth = 1;
  const int kMaximumDepth = 128;
  // Place some sane restrictions on user controlled flags.
  if (FLAG_profile_period < kMinimumProfilePeriod) {
    FLAG_profile_period = kMinimumProfilePeriod;
  }
  if (FLAG_profile_depth < kMinimumDepth) {
    FLAG_profile_depth = kMinimumDepth;
  } else if (FLAG_profile_depth > kMaximumDepth) {
    FLAG_profile_depth = kMaximumDepth;
  }
  Sample::InitOnce();
  if (!FLAG_profile) {
    return;
  }
  ASSERT(!initialized_);
  sample_buffer_ = new SampleBuffer();
  NativeSymbolResolver::InitOnce();
  ThreadInterrupter::InitOnce();
  ThreadInterrupter::SetInterruptPeriod(FLAG_profile_period);
  initialized_ = true;
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
  {
    MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
    IsolateProfilerData* profiler_data = isolate->profiler_data();
    if (profiler_data == NULL) {
      // Already freed.
      return;
    }
    isolate->set_profiler_data(NULL);
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


struct AddressEntry {
  uintptr_t pc;
  uintptr_t ticks;
};


// A region of code. Each region is a kind of code (Dart, Collected, or Native).
class CodeRegion : public ZoneAllocated {
 public:
  enum Kind {
    kDartCode,
    kCollectedCode,
    kNativeCode
  };

  CodeRegion(Kind kind, uintptr_t start, uintptr_t end) :
      kind_(kind),
      start_(start),
      end_(end),
      inclusive_ticks_(0),
      exclusive_ticks_(0),
      name_(NULL),
      address_table_(new ZoneGrowableArray<AddressEntry>()) {
  }

  ~CodeRegion() {
  }

  uintptr_t start() const { return start_; }
  void set_start(uintptr_t start) {
    start_ = start;
  }

  uintptr_t end() const { return end_; }
  void set_end(uintptr_t end) {
    end_ = end;
  }

  void AdjustExtent(uintptr_t start, uintptr_t end) {
    if (start < start_) {
      start_ = start;
    }
    if (end > end_) {
      end_ = end;
    }
  }

  bool contains(uintptr_t pc) const {
    return (pc >= start_) && (pc < end_);
  }

  intptr_t inclusive_ticks() const { return inclusive_ticks_; }
  void set_inclusive_ticks(intptr_t inclusive_ticks) {
    inclusive_ticks_ = inclusive_ticks;
  }

  intptr_t exclusive_ticks() const { return exclusive_ticks_; }
  void set_exclusive_ticks(intptr_t exclusive_ticks) {
    exclusive_ticks_ = exclusive_ticks;
  }

  const char* name() const { return name_; }
  void SetName(const char* name) {
    if (name == NULL) {
      name_ = NULL;
    }
    intptr_t len = strlen(name);
    name_ = Isolate::Current()->current_zone()->Alloc<const char>(len + 1);
    strncpy(const_cast<char*>(name_), name, len);
    const_cast<char*>(name_)[len] = '\0';
  }

  Kind kind() const { return kind_; }

  static const char* KindToCString(Kind kind) {
    switch (kind) {
      case kDartCode:
        return "Dart";
      case kCollectedCode:
        return "Collected";
      case kNativeCode:
        return "Native";
    }
    UNREACHABLE();
    return NULL;
  }

  void AddTick(bool exclusive) {
    if (exclusive) {
      exclusive_ticks_++;
    } else {
      inclusive_ticks_++;
    }
  }

  void AddTickAtAddress(uintptr_t pc) {
    const intptr_t length = address_table_->length();
    intptr_t i = 0;
    for (; i < length; i++) {
      AddressEntry& entry = (*address_table_)[i];
      if (entry.pc == pc) {
        entry.ticks++;
        return;
      }
      if (entry.pc > pc) {
        break;
      }
    }
    AddressEntry entry;
    entry.pc = pc;
    entry.ticks = 1;
    if (i < length) {
      // Insert at i.
      address_table_->InsertAt(i, entry);
    } else {
      // Add to end.
      address_table_->Add(entry);
    }
  }


  void PrintToJSONArray(JSONArray* events, bool full) {
    JSONObject obj(events);
    obj.AddProperty("type", "ProfileCode");
    obj.AddProperty("kind", KindToCString(kind()));
    obj.AddPropertyF("inclusive_ticks", "%" Pd "", inclusive_ticks());
    obj.AddPropertyF("exclusive_ticks", "%" Pd "", exclusive_ticks());
    if (kind() == kDartCode) {
      // Look up code in Dart heap.
      Code& code = Code::Handle(Code::LookupCode(start()));
      Function& func = Function::Handle();
      ASSERT(!code.IsNull());
      func ^= code.function();
      if (func.IsNull()) {
        if (name() == NULL) {
          GenerateAndSetSymbolName("Stub");
        }
        obj.AddPropertyF("start", "%" Px "", start());
        obj.AddPropertyF("end", "%" Px "", end());
        obj.AddProperty("name", name());
      } else {
        obj.AddProperty("code", code, !full);
      }
    } else if (kind() == kCollectedCode) {
      if (name() == NULL) {
        GenerateAndSetSymbolName("Collected");
      }
      obj.AddPropertyF("start", "%" Px "", start());
      obj.AddPropertyF("end", "%" Px "", end());
      obj.AddProperty("name", name());
    } else {
      ASSERT(kind() == kNativeCode);
      if (name() == NULL) {
        GenerateAndSetSymbolName("Native");
      }
      obj.AddPropertyF("start", "%" Px "", start());
      obj.AddPropertyF("end", "%" Px "", end());
      obj.AddProperty("name", name());
    }
    {
      JSONArray ticks(&obj, "ticks");
      for (intptr_t i = 0; i < address_table_->length(); i++) {
        const AddressEntry& entry = (*address_table_)[i];
        ticks.AddValueF("%" Px "", entry.pc);
        ticks.AddValueF("%" Pd "", entry.ticks);
      }
    }
  }

 private:
  void GenerateAndSetSymbolName(const char* prefix) {
    const intptr_t kBuffSize = 512;
    char buff[kBuffSize];
    OS::SNPrint(&buff[0], kBuffSize-1, "%s [%" Px ", %" Px ")",
                prefix, start(), end());
    SetName(buff);
  }

  Kind kind_;
  uintptr_t start_;
  uintptr_t end_;
  intptr_t inclusive_ticks_;
  intptr_t exclusive_ticks_;
  const char* name_;
  ZoneGrowableArray<AddressEntry>* address_table_;

  DISALLOW_COPY_AND_ASSIGN(CodeRegion);
};


// All code regions. Code region tables are built on demand when a profile
// is requested (through the service or on isolate shutdown).
class ProfilerCodeRegionTable : public ValueObject {
 public:
  explicit ProfilerCodeRegionTable(Isolate* isolate) :
      heap_(isolate->heap()),
      code_region_table_(new ZoneGrowableArray<CodeRegion*>(64)) {
  }

  ~ProfilerCodeRegionTable() {
  }

  void AddTick(uintptr_t pc, bool exclusive, bool tick_address) {
    intptr_t index = FindIndex(pc);
    if (index < 0) {
      CodeRegion* code_region = CreateCodeRegion(pc);
      ASSERT(code_region != NULL);
      index = InsertCodeRegion(code_region);
    }
    ASSERT(index >= 0);
    ASSERT(index < code_region_table_->length());
    (*code_region_table_)[index]->AddTick(exclusive);
    if (tick_address) {
      (*code_region_table_)[index]->AddTickAtAddress(pc);
    }
  }

  intptr_t Length() const { return code_region_table_->length(); }

  CodeRegion* At(intptr_t idx) {
    return (*code_region_table_)[idx];
  }

 private:
  intptr_t FindIndex(uintptr_t pc) {
    const intptr_t length = code_region_table_->length();
    for (intptr_t i = 0; i < length; i++) {
      const CodeRegion* code_region = (*code_region_table_)[i];
      if (code_region->contains(pc)) {
        return i;
      }
    }
    return -1;
  }

  CodeRegion* CreateCodeRegion(uintptr_t pc) {
    Code& code = Code::Handle(Code::LookupCode(pc));
    if (!code.IsNull()) {
      return new CodeRegion(CodeRegion::kDartCode, code.EntryPoint(),
                            code.EntryPoint() + code.Size());
    }
    if (heap_->CodeContains(pc)) {
      const intptr_t kDartCodeAlignment = 0x10;
      const intptr_t kDartCodeAlignmentMask = ~(kDartCodeAlignment - 1);
      return new CodeRegion(CodeRegion::kCollectedCode,
                            (pc & kDartCodeAlignmentMask),
                            (pc & kDartCodeAlignmentMask) + kDartCodeAlignment);
    }
    uintptr_t native_start = 0;
    char* native_name = NativeSymbolResolver::LookupSymbolName(pc,
                                                               &native_start);
    if (native_name == NULL) {
      return new CodeRegion(CodeRegion::kNativeCode, pc, pc + 1);
    }
    ASSERT(pc >= native_start);
    CodeRegion* code_region =
        new CodeRegion(CodeRegion::kNativeCode, native_start, pc + 1);
    code_region->SetName(native_name);
    free(native_name);
    return code_region;
  }

  intptr_t InsertCodeRegion(CodeRegion* code_region) {
    const intptr_t length = code_region_table_->length();
    const uintptr_t start = code_region->start();
    const uintptr_t end = code_region->end();
    intptr_t i = 0;
    for (; i < length; i++) {
      CodeRegion* region = (*code_region_table_)[i];
      if (region->contains(start) || region->contains(end - 1)) {
        // We should only see overlapping native code regions.
        ASSERT(region->kind() == CodeRegion::kNativeCode);
        // When code regions overlap, they should be of the same kind.
        ASSERT(region->kind() == code_region->kind());
        // Overlapping code region.
        region->AdjustExtent(start, end);
        return i;
      } else if (start >= region->end()) {
        // Insert here.
        break;
      }
    }
    if (i != length) {
      code_region_table_->InsertAt(i, code_region);
      return i;
    }
    code_region_table_->Add(code_region);
    return code_region_table_->length() - 1;
  }

  Heap* heap_;
  ZoneGrowableArray<CodeRegion*>* code_region_table_;
};


void Profiler::PrintToJSONStream(Isolate* isolate, JSONStream* stream,
                                 bool full) {
  ASSERT(isolate == Isolate::Current());
  // Disable profile interrupts while processing the buffer.
  EndExecution(isolate);
  MutexLocker profiler_data_lock(isolate->profiler_data_mutex());
  IsolateProfilerData* profiler_data = isolate->profiler_data();
  if (profiler_data == NULL) {
    JSONObject error(stream);
    error.AddProperty("type", "Error");
    error.AddProperty("text", "Isolate does not have profiling enabled.");
    return;
  }
  SampleBuffer* sample_buffer = profiler_data->sample_buffer();
  ASSERT(sample_buffer != NULL);
  {
    StackZone zone(isolate);
    {
      // Build code region table.
      ProfilerCodeRegionTable code_region_table(isolate);
      intptr_t samples =
          ProcessSamples(isolate, &code_region_table, sample_buffer);
      {
        // Serialize to JSON.
        JSONObject obj(stream);
        obj.AddProperty("type", "Profile");
        obj.AddProperty("samples", samples);
        JSONArray codes(&obj, "codes");
        for (intptr_t i = 0; i < code_region_table.Length(); i++) {
          CodeRegion* region = code_region_table.At(i);
          ASSERT(region != NULL);
          region->PrintToJSONArray(&codes, full);
        }
      }
    }
  }
  // Enable profile interrupts.
  BeginExecution(isolate);
}


intptr_t Profiler::ProcessSamples(Isolate* isolate,
                                  ProfilerCodeRegionTable* code_region_table,
                                  SampleBuffer* sample_buffer) {
  int64_t start = OS::GetCurrentTimeMillis();
  intptr_t samples = 0;
  Sample* sample = Sample::Allocate();
  for (intptr_t i = 0; i < sample_buffer->capacity(); i++) {
    sample_buffer->CopySample(i, sample);
    if (sample->isolate() != isolate) {
      continue;
    }
    if (sample->timestamp() == 0) {
      continue;
    }
    samples += ProcessSample(isolate, code_region_table, sample);
  }
  free(sample);
  int64_t end = OS::GetCurrentTimeMillis();
  if (FLAG_trace_profiled_isolates) {
    int64_t delta = end - start;
    OS::Print("Processed %" Pd " samples from %s in %" Pd64 " milliseconds.\n",
        samples,
        isolate->name(),
        delta);
  }
  return samples;
}


intptr_t Profiler::ProcessSample(Isolate* isolate,
                                 ProfilerCodeRegionTable* code_region_table,
                                Sample* sample) {
  if (sample->type() != Sample::kIsolateSample) {
    return 0;
  }
  if (sample->At(0) == 0) {
    // No frames in this sample.
    return 0;
  }
  // i points to the leaf (exclusive) PC sample. Do not tick the address.
  code_region_table->AddTick(sample->At(0), true, false);
  // Give all frames an inclusive tick and tick the address.
  for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
    if (sample->At(i) == 0) {
      break;
    }
    code_region_table->AddTick(sample->At(i), false, true);
  }
  return 1;
}


void Profiler::WriteProfile(Isolate* isolate) {
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
  ASSERT(Isolate::Current() == isolate);
  JSONStream stream(10 * MB);
  intptr_t pid = OS::ProcessId();
  PrintToJSONStream(isolate, &stream, true);
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
}


IsolateProfilerData::IsolateProfilerData(SampleBuffer* sample_buffer,
                                         bool own_sample_buffer) {
  ASSERT(sample_buffer != NULL);
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


intptr_t Sample::instance_size_ = 0;

void Sample::InitOnce() {
  ASSERT(FLAG_profile_depth >= 1);
  instance_size_ =
     sizeof(Sample) + (sizeof(intptr_t) * FLAG_profile_depth);  // NOLINT.
}


uintptr_t Sample::At(intptr_t i) const {
  ASSERT(i >= 0);
  ASSERT(i < FLAG_profile_depth);
  return pcs_[i];
}


void Sample::SetAt(intptr_t i, uintptr_t pc) {
  ASSERT(i >= 0);
  ASSERT(i < FLAG_profile_depth);
  pcs_[i] = pc;
}


void Sample::Init(SampleType type, Isolate* isolate, int64_t timestamp,
                  ThreadId tid) {
  timestamp_ = timestamp;
  tid_ = tid;
  isolate_ = isolate;
  type_ = type;
  for (int i = 0; i < FLAG_profile_depth; i++) {
    pcs_[i] = 0;
  }
}


void Sample::CopyInto(Sample* dst) const {
  ASSERT(dst != NULL);
  dst->timestamp_ = timestamp_;
  dst->tid_ = tid_;
  dst->isolate_ = isolate_;
  dst->type_ = type_;
  for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
    dst->pcs_[i] = pcs_[i];
  }
}


Sample* Sample::Allocate() {
  return reinterpret_cast<Sample*>(malloc(instance_size()));
}


SampleBuffer::SampleBuffer(intptr_t capacity) {
  capacity_ = capacity;
  samples_ = reinterpret_cast<Sample*>(
      calloc(capacity, Sample::instance_size()));
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
  return At(cursor);
}


void SampleBuffer::CopySample(intptr_t i, Sample* sample) const {
  At(i)->CopyInto(sample);
}


Sample* SampleBuffer::At(intptr_t idx) const {
  ASSERT(idx >= 0);
  ASSERT(idx < capacity_);
  intptr_t offset = idx * Sample::instance_size();
  uint8_t* samples = reinterpret_cast<uint8_t*>(samples_);
  return reinterpret_cast<Sample*>(samples + offset);
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


// Notes on stack frame walking:
//
// The sampling profiler will collect up to Sample::kNumStackFrames stack frames
// The stack frame walking code uses the frame pointer to traverse the stack.
// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail (sometimes leading to a crash).
//

int ProfilerSampleStackWalker::walk() {
  const intptr_t kMaxStep = 0x1000;  // 4K.
  const bool kWalkStack = true;  // Walk the stack.
  // Always store the exclusive PC.
  sample_->SetAt(0, original_pc_);
  if (!kWalkStack) {
    // Not walking the stack, only took exclusive sample.
    return 1;
  }
  uword* pc = reinterpret_cast<uword*>(original_pc_);
  uword* fp = reinterpret_cast<uword*>(original_fp_);
  uword* previous_fp = fp;
  if (original_sp_ > original_fp_) {
    // Stack pointer should not be above frame pointer.
    return 1;
  }
  intptr_t gap = original_fp_ - original_sp_;
  if (gap >= kMaxStep) {
    // Gap between frame pointer and stack pointer is
    // too large.
    return 1;
  }
  if (original_sp_ < lower_bound_) {
    // The stack pointer gives us a better lower bound than
    // the isolates stack limit.
    lower_bound_ = original_sp_;
  }
  int i = 0;
  for (; i < FLAG_profile_depth; i++) {
    sample_->SetAt(i, reinterpret_cast<uintptr_t>(pc));
    if (!ValidFramePointer(fp)) {
      return i + 1;
    }
    pc = CallerPC(fp);
    previous_fp = fp;
    fp = CallerFP(fp);
    intptr_t step = fp - previous_fp;
    if ((step >= kMaxStep) || (fp <= previous_fp) || !ValidFramePointer(fp)) {
      // Frame pointer step is too large.
      // Frame pointer did not move to a higher address.
      // Frame pointer is outside of isolate stack bounds.
      return i + 1;
    }
    // Move the lower bound up.
    lower_bound_ = reinterpret_cast<uintptr_t>(fp);
  }
  return i;
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
