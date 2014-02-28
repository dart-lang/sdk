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
#include "vm/stack_frame.h"

namespace dart {


#if defined(USING_SIMULATOR) || defined(TARGET_OS_WINDOWS) || \
    defined(TARGET_OS_ANDROID)
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
            "Maximum number stack frames walked. Minimum 1. Maximum 255.");
DEFINE_FLAG(bool, profile_verify_stack_walk, false,
            "Verify instruction addresses while walking the stack.");

bool Profiler::initialized_ = false;
SampleBuffer* Profiler::sample_buffer_ = NULL;

void Profiler::InitOnce() {
  // Place some sane restrictions on user controlled flags.
  SetSamplePeriod(FLAG_profile_period);
  SetSampleDepth(FLAG_profile_depth);
  if (!FLAG_profile) {
    return;
  }
  ASSERT(!initialized_);
  sample_buffer_ = new SampleBuffer();
  NativeSymbolResolver::InitOnce();
  ThreadInterrupter::SetInterruptPeriod(FLAG_profile_period);
  ThreadInterrupter::Startup();
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


void Profiler::SetSampleDepth(intptr_t depth) {
  const int kMinimumDepth = 1;
  const int kMaximumDepth = kSampleFramesSize - 1;
  if (depth < kMinimumDepth) {
    FLAG_profile_depth = kMinimumDepth;
  } else if (depth > kMaximumDepth) {
    FLAG_profile_depth = kMaximumDepth;
  } else {
    FLAG_profile_depth = depth;
  }
}


void Profiler::SetSamplePeriod(intptr_t period) {
  const int kMinimumProfilePeriod = 250;
  if (period < kMinimumProfilePeriod) {
    FLAG_profile_period = kMinimumProfilePeriod;
  } else {
    FLAG_profile_period = period;
  }
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


struct AddressEntry {
  uword pc;
  intptr_t exclusive_ticks;
  intptr_t inclusive_ticks;

  void tick(bool exclusive) {
    if (exclusive) {
      exclusive_ticks++;
    } else {
      inclusive_ticks++;
    }
  }
};

struct CallEntry {
  intptr_t code_table_index;
  intptr_t count;
};

typedef bool (*RegionCompare)(uword pc, uword region_start, uword region_end);

// A region of code. Each region is a kind of code (Dart, Collected, or Native).
class CodeRegion : public ZoneAllocated {
 public:
  enum Kind {
    kDartCode,
    kCollectedCode,
    kNativeCode
  };

  CodeRegion(Kind kind, uword start, uword end) :
      kind_(kind),
      start_(start),
      end_(end),
      inclusive_ticks_(0),
      exclusive_ticks_(0),
      name_(NULL),
      address_table_(new ZoneGrowableArray<AddressEntry>()),
      callers_table_(new ZoneGrowableArray<CallEntry>()),
      callees_table_(new ZoneGrowableArray<CallEntry>()) {
    ASSERT(start_ < end_);
  }

  ~CodeRegion() {
  }

  uword start() const { return start_; }
  void set_start(uword start) {
    start_ = start;
  }

  uword end() const { return end_; }
  void set_end(uword end) {
    end_ = end;
  }

  void AdjustExtent(uword start, uword end) {
    if (start < start_) {
      start_ = start;
    }
    if (end > end_) {
      end_ = end;
    }
    ASSERT(start_ < end_);
  }

  bool contains(uword pc) const {
    return (pc >= start_) && (pc < end_);
  }

  bool overlaps(const CodeRegion* other) const {
    ASSERT(other != NULL);
    return other->contains(start_)   ||
           other->contains(end_ - 1) ||
           contains(other->start())  ||
           contains(other->end() - 1);
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

  void DebugPrint() const {
    printf("%s [%" Px ", %" Px ") %s\n", KindToCString(kind_), start(), end(),
           name_);
  }

  void AddTickAtAddress(uword pc, bool exclusive, intptr_t serial) {
    // Assert that exclusive ticks are never passed a valid serial number.
    ASSERT((exclusive && (serial == -1)) || (!exclusive && (serial != -1)));
    if (!exclusive && (inclusive_tick_serial_ == serial)) {
      // We've already given this code object an inclusive tick for this sample.
      return;
    }
    // Tick the code object.
    if (exclusive) {
      exclusive_ticks_++;
    } else {
      // Mark the last serial we ticked the inclusive count.
      inclusive_tick_serial_ = serial;
      inclusive_ticks_++;
    }
    // Tick the address entry.
    const intptr_t length = address_table_->length();
    intptr_t i = 0;
    for (; i < length; i++) {
      AddressEntry& entry = (*address_table_)[i];
      if (entry.pc == pc) {
        entry.tick(exclusive);
        return;
      }
      if (entry.pc > pc) {
        break;
      }
    }
    AddressEntry entry;
    entry.pc = pc;
    entry.tick(exclusive);
    if (i < length) {
      // Insert at i.
      address_table_->InsertAt(i, entry);
    } else {
      // Add to end.
      address_table_->Add(entry);
    }
  }

  void AddCaller(intptr_t index) {
    AddCallEntry(callers_table_, index);
  }

  void AddCallee(intptr_t index) {
    AddCallEntry(callees_table_, index);
  }

  void PrintNativeCode(JSONObject* profile_code_obj) {
    ASSERT(kind() == kNativeCode);
    JSONObject obj(profile_code_obj, "code");
    obj.AddProperty("type", "@Code");
    obj.AddProperty("kind", "Native");
    obj.AddProperty("name", name());
    obj.AddProperty("user_name", name());
    obj.AddPropertyF("start", "%" Px "", start());
    obj.AddPropertyF("end", "%" Px "", end());
    obj.AddPropertyF("id", "code/native/%" Px "", start());
  }

  void PrintCollectedCode(JSONObject* profile_code_obj) {
    ASSERT(kind() == kCollectedCode);
    JSONObject obj(profile_code_obj, "code");
    obj.AddProperty("type", "@Code");
    obj.AddProperty("kind", "Collected");
    obj.AddProperty("name", name());
    obj.AddProperty("user_name", name());
    obj.AddPropertyF("start", "%" Px "", start());
    obj.AddPropertyF("end", "%" Px "", end());
    obj.AddPropertyF("id", "code/collected/%" Px "", start());
  }

  void PrintToJSONArray(Isolate* isolate, JSONArray* events, bool full) {
    JSONObject obj(events);
    obj.AddProperty("type", "ProfileCode");
    obj.AddProperty("kind", KindToCString(kind()));
    obj.AddPropertyF("inclusive_ticks", "%" Pd "", inclusive_ticks());
    obj.AddPropertyF("exclusive_ticks", "%" Pd "", exclusive_ticks());
    if (kind() == kDartCode) {
      // Look up code in Dart heap.
      Code& code = Code::Handle();
      code ^= Code::LookupCode(start());
      if (code.IsNull()) {
        // Code is a stub in the Vm isolate.
        code ^= Code::LookupCodeInVmIsolate(start());
      }
      ASSERT(!code.IsNull());
      obj.AddProperty("code", code, !full);
    } else if (kind() == kCollectedCode) {
      if (name() == NULL) {
        // Lazily set generated name.
        GenerateAndSetSymbolName("Collected");
      }
      PrintCollectedCode(&obj);
    } else {
      ASSERT(kind() == kNativeCode);
      if (name() == NULL) {
        // Lazily set generated name.
        GenerateAndSetSymbolName("Native");
      }
      PrintNativeCode(&obj);
    }
    {
      JSONArray ticks(&obj, "ticks");
      for (intptr_t i = 0; i < address_table_->length(); i++) {
        const AddressEntry& entry = (*address_table_)[i];
        ticks.AddValueF("%" Px "", entry.pc);
        ticks.AddValueF("%" Pd "", entry.exclusive_ticks);
        ticks.AddValueF("%" Pd "", entry.inclusive_ticks);
      }
    }
    {
      JSONArray callers(&obj, "callers");
      for (intptr_t i = 0; i < callers_table_->length(); i++) {
        const CallEntry& entry = (*callers_table_)[i];
        callers.AddValueF("%" Pd "", entry.code_table_index);
        callers.AddValueF("%" Pd "", entry.count);
      }
    }
    {
      JSONArray callees(&obj, "callees");
      for (intptr_t i = 0; i < callees_table_->length(); i++) {
        const CallEntry& entry = (*callees_table_)[i];
        callees.AddValueF("%" Pd "", entry.code_table_index);
        callees.AddValueF("%" Pd "", entry.count);
      }
    }
  }

 private:
  void AddCallEntry(ZoneGrowableArray<CallEntry>* table, intptr_t index) {
    const intptr_t length = table->length();
    intptr_t i = 0;
    for (; i < length; i++) {
      CallEntry& entry = (*table)[i];
      if (entry.code_table_index == index) {
        entry.count++;
        return;
      }
      if (entry.code_table_index > index) {
        break;
      }
    }
    CallEntry entry;
    entry.code_table_index = index;
    entry.count = 1;
    if (i < length) {
      table->InsertAt(i, entry);
    } else {
      table->Add(entry);
    }
  }

  void GenerateAndSetSymbolName(const char* prefix) {
    const intptr_t kBuffSize = 512;
    char buff[kBuffSize];
    OS::SNPrint(&buff[0], kBuffSize-1, "%s [%" Px ", %" Px ")",
                prefix, start(), end());
    SetName(buff);
  }

  Kind kind_;
  uword start_;
  uword end_;
  intptr_t inclusive_ticks_;
  intptr_t exclusive_ticks_;
  intptr_t inclusive_tick_serial_;
  const char* name_;
  ZoneGrowableArray<AddressEntry>* address_table_;
  ZoneGrowableArray<CallEntry>* callers_table_;
  ZoneGrowableArray<CallEntry>* callees_table_;
  DISALLOW_COPY_AND_ASSIGN(CodeRegion);
};


class ScopeStopwatch : public ValueObject {
 public:
  explicit ScopeStopwatch(const char* name) : name_(name) {
    start_ = OS::GetCurrentTimeMillis();
  }

  intptr_t GetElapsed() const {
    intptr_t end = OS::GetCurrentTimeMillis();
    ASSERT(end >= start_);
    return end - start_;
  }

  ~ScopeStopwatch() {
    if (FLAG_trace_profiled_isolates) {
      intptr_t elapsed = GetElapsed();
      OS::Print("%s took %" Pd " millis.\n", name_, elapsed);
    }
  }

 private:
  const char* name_;
  intptr_t start_;
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

  void AddTick(uword pc, bool exclusive, intptr_t serial) {
    intptr_t index = FindIndex(pc);
    if (index < 0) {
      CodeRegion* code_region = CreateCodeRegion(pc);
      ASSERT(code_region != NULL);
      index = InsertCodeRegion(code_region);
    }
    ASSERT(index >= 0);
    ASSERT(index < code_region_table_->length());

    // Update code object counters.
    (*code_region_table_)[index]->AddTickAtAddress(pc, exclusive, serial);
  }

  intptr_t Length() const { return code_region_table_->length(); }

  CodeRegion* At(intptr_t idx) {
    return (*code_region_table_)[idx];
  }

  intptr_t FindIndex(uword pc) const {
    intptr_t index = FindRegionIndex(pc, &CompareLowerBound);
    const CodeRegion* code_region = NULL;
    if (index == code_region_table_->length()) {
      // Not present.
      return -1;
    }
    code_region = (*code_region_table_)[index];
    if (code_region->contains(pc)) {
      // Found at index.
      return index;
    }
    return -1;
  }

#if defined(DEBUG)
  void Verify() {
    VerifyOrder();
    VerifyOverlap();
  }
#endif

 private:
  intptr_t FindRegionIndex(uword pc, RegionCompare comparator) const {
    ASSERT(comparator != NULL);
    intptr_t count = code_region_table_->length();
    intptr_t first = 0;
    while (count > 0) {
      intptr_t it = first;
      intptr_t step = count / 2;
      it += step;
      const CodeRegion* code_region = (*code_region_table_)[it];
      if (comparator(pc, code_region->start(), code_region->end())) {
        first = ++it;
        count -= (step + 1);
      } else {
        count = step;
      }
    }
    return first;
  }

  static bool CompareUpperBound(uword pc, uword start, uword end) {
    return pc >= end;
  }

  static bool CompareLowerBound(uword pc, uword start, uword end) {
    return end <= pc;
  }

  CodeRegion* CreateCodeRegion(uword pc) {
    Code& code = Code::Handle();
    code ^= Code::LookupCode(pc);
    if (!code.IsNull()) {
      return new CodeRegion(CodeRegion::kDartCode, code.EntryPoint(),
                            code.EntryPoint() + code.Size());
    }
    code ^= Code::LookupCodeInVmIsolate(pc);
    if (!code.IsNull()) {
      return new CodeRegion(CodeRegion::kDartCode, code.EntryPoint(),
                            code.EntryPoint() + code.Size());
    }
    if (heap_->CodeContains(pc)) {
      const intptr_t kDartCodeAlignment = OS::PreferredCodeAlignment();
      const intptr_t kDartCodeAlignmentMask = ~(kDartCodeAlignment - 1);
      return new CodeRegion(CodeRegion::kCollectedCode, pc,
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

  void HandleOverlap(CodeRegion* region, CodeRegion* code_region,
                     uword start, uword end) {
    // We should never see overlapping Dart code regions.
    ASSERT(region->kind() != CodeRegion::kDartCode);
    // When code regions overlap, they should be of the same kind.
    ASSERT(region->kind() == code_region->kind());
    region->AdjustExtent(start, end);
  }

  intptr_t InsertCodeRegion(CodeRegion* code_region) {
    const uword start = code_region->start();
    const uword end = code_region->end();
    const intptr_t length = code_region_table_->length();
    if (length == 0) {
      code_region_table_->Add(code_region);
      return length;
    }
    // Determine the correct place to insert or merge code_region into table.
    intptr_t lo = FindRegionIndex(start, &CompareLowerBound);
    intptr_t hi = FindRegionIndex(end - 1, &CompareUpperBound);
    if ((lo == length) && (hi == length)) {
      lo = length - 1;
    }
    if (lo == length) {
      CodeRegion* region = (*code_region_table_)[hi];
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return hi;
      }
      code_region_table_->Add(code_region);
      return length;
    } else if (hi == length) {
      CodeRegion* region = (*code_region_table_)[lo];
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      code_region_table_->Add(code_region);
      return length;
    } else if (lo == hi) {
      CodeRegion* region = (*code_region_table_)[lo];
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      code_region_table_->InsertAt(lo, code_region);
      return lo;
    } else {
      CodeRegion* region = (*code_region_table_)[lo];
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return lo;
      }
      region = (*code_region_table_)[hi];
      if (region->overlaps(code_region)) {
        HandleOverlap(region, code_region, start, end);
        return hi;
      }
      code_region_table_->InsertAt(hi, code_region);
      return hi;
    }
    UNREACHABLE();
  }

#if defined(DEBUG)
  void VerifyOrder() {
    const intptr_t length = code_region_table_->length();
    if (length == 0) {
      return;
    }
    uword last = (*code_region_table_)[0]->end();
    for (intptr_t i = 1; i < length; i++) {
      CodeRegion* a = (*code_region_table_)[i];
      ASSERT(last <= a->start());
      last = a->end();
    }
  }

  void VerifyOverlap() {
    const intptr_t length = code_region_table_->length();
    for (intptr_t i = 0; i < length; i++) {
      CodeRegion* a = (*code_region_table_)[i];
      for (intptr_t j = i+1; j < length; j++) {
        CodeRegion* b = (*code_region_table_)[j];
        ASSERT(!a->contains(b->start()) &&
               !a->contains(b->end() - 1) &&
               !b->contains(a->start()) &&
               !b->contains(a->end() - 1));
      }
    }
  }
#endif

  Heap* heap_;
  ZoneGrowableArray<CodeRegion*>* code_region_table_;
};


class CodeRegionTableBuilder : public SampleVisitor {
 public:
  CodeRegionTableBuilder(Isolate* isolate,
                         ProfilerCodeRegionTable* code_region_table)
      : SampleVisitor(isolate), code_region_table_(code_region_table) {
    frames_ = 0;
  }

  void VisitSample(Sample* sample) {
    // Give the bottom frame an exclusive tick.
    code_region_table_->AddTick(sample->At(0), true, -1);
    // Give all frames (including the bottom) an inclusive tick.
    for (intptr_t i = 0; i < FLAG_profile_depth; i++) {
      if (sample->At(i) == 0) {
        break;
      }
      frames_++;
      code_region_table_->AddTick(sample->At(i), false, visited());
    }
  }

  intptr_t frames() const { return frames_; }

 private:
  intptr_t frames_;
  ProfilerCodeRegionTable* code_region_table_;
};


class CodeRegionTableCallersBuilder : public SampleVisitor {
 public:
  CodeRegionTableCallersBuilder(Isolate* isolate,
                                ProfilerCodeRegionTable* code_region_table)
      : SampleVisitor(isolate), code_region_table_(code_region_table) {
    ASSERT(code_region_table_ != NULL);
  }

  void VisitSample(Sample* sample) {
    intptr_t current_index = code_region_table_->FindIndex(sample->At(0));
    ASSERT(current_index != -1);
    CodeRegion* current = code_region_table_->At(current_index);
    intptr_t caller_index = -1;
    CodeRegion* caller = NULL;
    intptr_t callee_index = -1;
    CodeRegion* callee = NULL;
    for (intptr_t i = 1; i < FLAG_profile_depth; i++) {
      if (sample->At(i) == 0) {
        break;
      }
      caller_index = code_region_table_->FindIndex(sample->At(i));
      ASSERT(caller_index != -1);
      caller = code_region_table_->At(caller_index);
      current->AddCaller(caller_index);
      if (callee != NULL) {
        current->AddCallee(callee_index);
      }
      // Move cursors.
      callee_index = current_index;
      callee = current;
      current_index = caller_index;
      current = caller;
    }
  }

 private:
  ProfilerCodeRegionTable* code_region_table_;
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
      CodeRegionTableBuilder builder(isolate, &code_region_table);
      CodeRegionTableCallersBuilder build_callers(isolate, &code_region_table);
      {
        ScopeStopwatch sw("CodeTableBuild");
        sample_buffer->VisitSamples(&builder);
      }
#if defined(DEBUG)
      code_region_table.Verify();
#endif
      {
        ScopeStopwatch sw("CodeTableCallersBuild");
        sample_buffer->VisitSamples(&build_callers);
      }
      // Number of samples we processed.
      intptr_t samples = builder.visited();
      intptr_t frames = builder.frames();
      if (FLAG_trace_profiled_isolates) {
        OS::Print("%" Pd " frames produced %" Pd " code objects.\n",
                  frames, code_region_table.Length());
      }
      {
        ScopeStopwatch sw("CodeTableStream");
        // Serialize to JSON.
        JSONObject obj(stream);
        obj.AddProperty("type", "Profile");
        obj.AddProperty("samples", samples);
        JSONArray codes(&obj, "codes");
        for (intptr_t i = 0; i < code_region_table.Length(); i++) {
          CodeRegion* region = code_region_table.At(i);
          ASSERT(region != NULL);
          region->PrintToJSONArray(isolate, &codes, full);
        }
      }
    }
  }
  // Enable profile interrupts.
  BeginExecution(isolate);
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


Sample* SampleBuffer::ReserveSample() {
  ASSERT(samples_ != NULL);
  uintptr_t cursor = AtomicOperations::FetchAndIncrement(&cursor_);
  // Map back into sample buffer range.
  cursor = cursor % capacity_;
  return At(cursor);
}

// Notes on stack frame walking:
//
// The sampling profiler will collect up to Sample::kNumStackFrames stack frames
// The stack frame walking code uses the frame pointer to traverse the stack.
// If the VM is compiled without frame pointers (which is the default on
// recent GCC versions with optimizing enabled) the stack walking code may
// fail (sometimes leading to a crash).
//
class ProfilerSampleStackWalker : public ValueObject {
 public:
  ProfilerSampleStackWalker(Sample* sample,
                            uword stack_lower,
                            uword stack_upper,
                            uword pc,
                            uword fp,
                            uword sp)
      : sample_(sample),
        stack_upper_(stack_upper),
        original_pc_(pc),
        original_fp_(fp),
        original_sp_(sp),
        lower_bound_(stack_lower) {
    ASSERT(sample_ != NULL);
  }

  int walk(Heap* heap) {
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
      if (FLAG_profile_verify_stack_walk) {
        VerifyCodeAddress(heap, i, reinterpret_cast<uword>(pc));
      }
      sample_->SetAt(i, reinterpret_cast<uword>(pc));
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
      lower_bound_ = reinterpret_cast<uword>(fp);
    }
    return i;
  }

 private:
  void VerifyCodeAddress(Heap* heap, int i, uword pc) {
    if (heap != NULL) {
      if (heap->Contains(pc) && !heap->CodeContains(pc)) {
        for (int j = 0; j < i; j++) {
          OS::Print("%d %" Px "\n", j, sample_->At(j));
        }
        OS::Print("%d %" Px " <--\n", i, pc);
        OS::Print("---ASSERT-FAILED---\n");
        OS::Print("%" Px " %" Px "\n", original_pc_, original_fp_);
        UNREACHABLE();
      }
    }
  }

  uword* CallerPC(uword* fp) const {
    ASSERT(fp != NULL);
    return reinterpret_cast<uword*>(*(fp + kSavedCallerPcSlotFromFp));
  }

  uword* CallerFP(uword* fp) const {
    ASSERT(fp != NULL);
    return reinterpret_cast<uword*>(*(fp + kSavedCallerFpSlotFromFp));
  }

  bool ValidFramePointer(uword* fp) const {
    if (fp == NULL) {
      return false;
    }
    uword cursor = reinterpret_cast<uword>(fp);
    cursor += sizeof(fp);
    bool r = cursor >= lower_bound_ && cursor < stack_upper_;
    return r;
  }


  Sample* sample_;
  const uword stack_upper_;
  const uword original_pc_;
  const uword original_fp_;
  const uword original_sp_;
  uword lower_bound_;
};

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
  sample->Init(isolate, OS::GetCurrentTimeMicros(), state.tid);
  uword stack_lower = 0;
  uword stack_upper = 0;
  isolate->GetStackBounds(&stack_lower, &stack_upper);
  if ((stack_lower == 0) || (stack_upper == 0)) {
    stack_lower = 0;
    stack_upper = 0;
  }
  ProfilerSampleStackWalker stackWalker(sample, stack_lower, stack_upper,
                                        state.pc, state.fp, state.sp);
  stackWalker.walk(isolate->heap());
}


}  // namespace dart
