// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"
#include "vm/source_report.h"
#include "vm/symbols.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, profile_vm);
DECLARE_FLAG(bool, profile_vm_allocation);
DECLARE_FLAG(int, max_profile_depth);
DECLARE_FLAG(int, optimization_counter_threshold);

// SampleVisitor ignores samples with timestamp == 0.
const int64_t kValidTimeStamp = 1;

// SampleVisitor ignores samples with pc == 0.
const uword kValidPc = 0xFF;

// Some tests are written assuming native stack trace profiling is disabled.
class DisableNativeProfileScope : public ValueObject {
 public:
  DisableNativeProfileScope()
      : FLAG_profile_vm_(FLAG_profile_vm),
        FLAG_profile_vm_allocation_(FLAG_profile_vm_allocation) {
    FLAG_profile_vm = false;
    FLAG_profile_vm_allocation = false;
  }

  ~DisableNativeProfileScope() {
    FLAG_profile_vm = FLAG_profile_vm_;
    FLAG_profile_vm_allocation = FLAG_profile_vm_allocation_;
  }

 private:
  const bool FLAG_profile_vm_;
  const bool FLAG_profile_vm_allocation_;
};

// Temporarily adjust the maximum profile depth.
class MaxProfileDepthScope : public ValueObject {
 public:
  explicit MaxProfileDepthScope(intptr_t new_max_depth)
      : FLAG_max_profile_depth_(FLAG_max_profile_depth) {
    Profiler::SetSampleDepth(new_max_depth);
  }

  ~MaxProfileDepthScope() { Profiler::SetSampleDepth(FLAG_max_profile_depth_); }

 private:
  const intptr_t FLAG_max_profile_depth_;
};

class ProfileSampleBufferTestHelper : public SampleVisitor {
 public:
  explicit ProfileSampleBufferTestHelper(Dart_Port port)
      : SampleVisitor(port) {}

  void VisitSample(Sample* sample) { sum_ += sample->At(0); }

  void Reset() {
    sum_ = 0;
    SampleVisitor::Reset();
  }

  intptr_t sum() const { return sum_; }

 private:
  intptr_t sum_ = 0;
};

static void VisitSamples(SampleBlockBuffer* buffer, SampleVisitor* visitor) {
  visitor->Reset();
  buffer->VisitSamples(visitor);
}

class SampleBlockBufferOverrideScope {
 public:
  explicit SampleBlockBufferOverrideScope(SampleBlockBuffer* buffer)
      : override_(buffer) {
    orig_ = Profiler::sample_block_buffer();
    Profiler::set_sample_block_buffer(override_);
  }

  ~SampleBlockBufferOverrideScope() {
    Profiler::set_sample_block_buffer(orig_);
    delete override_;
  }

 private:
  SampleBlockBuffer* orig_;
  SampleBlockBuffer* override_;
};

TEST_CASE(Profiler_SampleBufferWrapTest) {
  Isolate* isolate = Isolate::Current();

  SampleBlockBufferOverrideScope sbbos(new SampleBlockBuffer(3, 1));
  SampleBlockBuffer* sample_buffer = Profiler::sample_block_buffer();

  Dart_Port i = 123;
  ProfileSampleBufferTestHelper visitor(i);

  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(0, visitor.sum());
  Sample* s;

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, 2);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(2, visitor.sum());

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, 4);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(6, visitor.sum());

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, 6);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(12, visitor.sum());

  // Mark the completed blocks as free so they can be re-used.
  sample_buffer->FreeCompletedBlocks();

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, 8);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(18, visitor.sum());

  // The overridden sample buffer will be freed before isolate shutdown.
  isolate->set_current_sample_block(nullptr);
}

TEST_CASE(Profiler_SampleBufferIterateTest) {
  Isolate* isolate = Isolate::Current();

  SampleBlockBufferOverrideScope sbbos(new SampleBlockBuffer(3, 1));
  SampleBlockBuffer* sample_buffer = Profiler::sample_block_buffer();

  Dart_Port i = 123;
  ProfileSampleBufferTestHelper visitor(i);

  sample_buffer->VisitSamples(&visitor);
  EXPECT_EQ(0, visitor.visited());
  Sample* s;
  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, kValidPc);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(1, visitor.visited());

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, kValidPc);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(2, visitor.visited());

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, kValidPc);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(3, visitor.visited());

  s = sample_buffer->ReserveCPUSample(isolate);
  EXPECT_NOTNULL(s);
  s->Init(i, kValidTimeStamp, 0);
  s->SetAt(0, kValidPc);
  VisitSamples(sample_buffer, &visitor);
  EXPECT_EQ(3, visitor.visited());

  // The overridden sample buffer will be freed before isolate shutdown.
  isolate->set_current_sample_block(nullptr);
}

TEST_CASE(Profiler_AllocationSampleTest) {
  Isolate* isolate = Isolate::Current();
  SampleBlockBuffer* sample_buffer = new SampleBlockBuffer(1, 1);
  Sample* sample = sample_buffer->ReserveAllocationSample(isolate);
  sample->Init(isolate->main_port(), 0, 0);
  sample->set_metadata(99);
  sample->set_is_allocation_sample(true);
  EXPECT_EQ(99, sample->allocation_cid());
  isolate->set_current_allocation_sample_block(nullptr);
  delete sample_buffer;
}

static LibraryPtr LoadTestScript(const char* script) {
  Dart_Handle api_lib;
  {
    TransitionVMToNative transition(Thread::Current());
    api_lib = TestCase::LoadTestScript(script, nullptr);
    EXPECT_VALID(api_lib);
  }
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(api_lib);
  return lib.ptr();
}

static ClassPtr GetClass(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  const Class& cls = Class::Handle(
      lib.LookupClassAllowPrivate(String::Handle(Symbols::New(thread, name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.ptr();
}

static FunctionPtr GetFunction(const Library& lib, const char* name) {
  Thread* thread = Thread::Current();
  const Function& func = Function::Handle(lib.LookupFunctionAllowPrivate(
      String::Handle(Symbols::New(thread, name))));
  EXPECT(!func.IsNull());  // No ambiguity error expected.
  return func.ptr();
}

static void Invoke(const Library& lib,
                   const char* name,
                   intptr_t argc = 0,
                   Dart_Handle* argv = nullptr) {
  Thread* thread = Thread::Current();
  Dart_Handle api_lib = Api::NewHandle(thread, lib.ptr());
  TransitionVMToNative transition(thread);
  Dart_Handle result = Dart_Invoke(api_lib, NewString(name), argc, argv);
  EXPECT_VALID(result);
}

class AllocationFilter : public SampleFilter {
 public:
  AllocationFilter(Dart_Port port,
                   intptr_t cid,
                   int64_t time_origin_micros = -1,
                   int64_t time_extent_micros = -1)
      : SampleFilter(port,
                     Thread::kMutatorTask,
                     time_origin_micros,
                     time_extent_micros),
        cid_(cid),
        enable_vm_ticks_(false) {}

  bool FilterSample(Sample* sample) {
    if (!enable_vm_ticks_ && (sample->vm_tag() == VMTag::kVMTagId)) {
      // We don't want to see embedder ticks in the test.
      return false;
    }
    return sample->is_allocation_sample() && (sample->allocation_cid() == cid_);
  }

  void set_enable_vm_ticks(bool enable) { enable_vm_ticks_ = enable; }

 private:
  intptr_t cid_;
  bool enable_vm_ticks_;
};

static void EnableProfiler() {
  if (!FLAG_profiler) {
    FLAG_profiler = true;
    Profiler::Init();
  }
}

class ProfileStackWalker {
 public:
  explicit ProfileStackWalker(Profile* profile, bool as_func = false)
      : profile_(profile),
        as_functions_(as_func),
        index_(0),
        sample_(profile->SampleAt(0)) {
    ClearInliningData();
  }

  bool Down() {
    if (as_functions_) {
      return UpdateFunctionIndex();
    } else {
      ++index_;
      return (index_ < sample_->length());
    }
  }

  const char* CurrentName() {
    if (as_functions_) {
      ProfileFunction* func = GetFunction();
      EXPECT(func != nullptr);
      return func->Name();
    } else {
      ProfileCode* code = GetCode();
      EXPECT(code != nullptr);
      return code->name();
    }
  }

  const char* CurrentToken() {
    if (!as_functions_) {
      return nullptr;
    }
    ProfileFunction* func = GetFunction();
    const Function& function = *(func->function());
    if (function.IsNull()) {
      // No function.
      return nullptr;
    }
    Zone* zone = Thread::Current()->zone();
    const Script& script = Script::Handle(zone, function.script());
    if (script.IsNull()) {
      // No script.
      return nullptr;
    }
    ProfileFunctionSourcePosition pfsp(TokenPosition::kNoSource);
    if (!func->GetSinglePosition(&pfsp)) {
      // Not exactly one source position.
      return nullptr;
    }

    const TokenPosition& token_pos = pfsp.token_pos();
    intptr_t line, column;
    if (script.GetTokenLocation(token_pos, &line, &column)) {
      const intptr_t token_len = script.GetTokenLength(token_pos);
      const auto& str = String::Handle(
          zone, script.GetSnippet(line, column, line, column + token_len));
      if (!str.IsNull()) return str.ToCString();
    }
    // Couldn't get line/number information.
    return nullptr;
  }

  intptr_t CurrentInclusiveTicks() {
    if (as_functions_) {
      ProfileFunction* func = GetFunction();
      EXPECT(func != nullptr);
      return func->inclusive_ticks();
    } else {
      ProfileCode* code = GetCode();
      ASSERT(code != nullptr);
      return code->inclusive_ticks();
    }
  }

  intptr_t CurrentExclusiveTicks() {
    if (as_functions_) {
      ProfileFunction* func = GetFunction();
      EXPECT(func != nullptr);
      return func->exclusive_ticks();
    } else {
      ProfileCode* code = GetCode();
      ASSERT(code != nullptr);
      return code->exclusive_ticks();
    }
  }

  const char* VMTagName() { return VMTag::TagName(sample_->vm_tag()); }

 private:
  ProfileCode* GetCode() {
    uword pc = sample_->At(index_);
    int64_t timestamp = sample_->timestamp();
    return profile_->GetCodeFromPC(pc, timestamp);
  }

  static constexpr intptr_t kInvalidInlinedIndex = -1;

  bool UpdateFunctionIndex() {
    if (inlined_index_ != kInvalidInlinedIndex) {
      if (inlined_index_ - 1 >= 0) {
        --inlined_index_;
        return true;
      }
      ClearInliningData();
    }
    ++index_;
    return (index_ < sample_->length());
  }

  void ClearInliningData() {
    inlined_index_ = kInvalidInlinedIndex;
    inlined_functions_ = nullptr;
    inlined_token_positions_ = nullptr;
  }

  ProfileFunction* GetFunction() {
    // Check to see if we're currently processing inlined functions. If so,
    // return the next inlined function.
    ProfileFunction* function = GetInlinedFunction();
    if (function != nullptr) {
      return function;
    }

    const uword pc = sample_->At(index_);
    ProfileCode* profile_code =
        profile_->GetCodeFromPC(pc, sample_->timestamp());
    ASSERT(profile_code != nullptr);
    function = profile_code->function();
    ASSERT(function != nullptr);

    TokenPosition token_position = TokenPosition::kNoSource;
    Code& code = Code::ZoneHandle();
    if (profile_code->code().IsCode()) {
      code ^= profile_code->code().ptr();
      inlined_functions_cache_.Get(pc, code, sample_, index_,
                                   &inlined_functions_,
                                   &inlined_token_positions_, &token_position);
    }

    if (code.IsNull() || (inlined_functions_ == nullptr) ||
        (inlined_functions_->length() <= 1)) {
      ClearInliningData();
      // No inlined functions.
      return function;
    }

    ASSERT(code.is_optimized());
    inlined_index_ = inlined_functions_->length() - 1;
    function = GetInlinedFunction();
    ASSERT(function != nullptr);
    return function;
  }

  ProfileFunction* GetInlinedFunction() {
    if ((inlined_index_ != kInvalidInlinedIndex) &&
        (inlined_index_ < inlined_functions_->length())) {
      return profile_->FindFunction(*(*inlined_functions_)[inlined_index_]);
    }
    return nullptr;
  }

  Profile* profile_;
  bool as_functions_;
  intptr_t index_;
  ProcessedSample* sample_;
  ProfileCodeInlinedFunctionsCache inlined_functions_cache_;
  GrowableArray<const Function*>* inlined_functions_;
  GrowableArray<TokenPosition>* inlined_token_positions_;
  intptr_t inlined_index_;
};

ISOLATE_UNIT_TEST_CASE(Profiler_TrivialRecordAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const int64_t before_allocations_micros = Dart_TimelineGetMicros();
  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());
  class_a.SetTraceAllocation(true);

  Invoke(root_library, "main");

  const int64_t after_allocations_micros = Dart_TimelineGetMicros();
  const int64_t allocation_extent_micros =
      after_allocations_micros - before_allocations_micros;
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    // Filter for the class in the time range.
    AllocationFilter filter(isolate->main_port(), class_a.id(),
                            before_allocations_micros,
                            allocation_extent_micros);
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    // Move down from the root.
    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] main", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Query with a time filter where no allocations occurred.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id(),
                            Dart_TimelineGetMicros(), 16000);
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples because none occurred within
    // the specified time range.
    EXPECT_EQ(0, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_NullSampleBuffer) {
  Isolate* isolate = thread->isolate();

  SampleFilter filter(isolate->main_port(), Thread::kMutatorTask, -1, -1);
  Profile profile;
  profile.Build(thread, isolate, &filter, nullptr);

  EXPECT_EQ(0, profile.sample_count());
}

ISOLATE_UNIT_TEST_CASE(Profiler_ToggleRecordAllocation) {
  EnableProfiler();

  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] main", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Turn off allocation tracing for A.
  class_a.SetTraceAllocation(false);

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_CodeTicks) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate three times.
  Invoke(root_library, "main");
  Invoke(root_library, "main");
  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileStackWalker walker(&profile);

    // Move down from the root.
    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());
  }
}
ISOLATE_UNIT_TEST_CASE(Profiler_FunctionTicks) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  return B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate three times.
  Invoke(root_library, "main");
  Invoke(root_library, "main");
  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());

#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_IntrinsicAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript = "double foo(double a, double b) => a + b;";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& double_class =
      Class::Handle(isolate->group()->object_store()->double_class());
  EXPECT(!double_class.IsNull());

  Dart_Handle args[2];
  {
    TransitionVMToNative transition(thread);
    args[0] = Dart_NewDouble(1.0);
    args[1] = Dart_NewDouble(2.0);
  }

  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  double_class.SetTraceAllocation(true);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("Double_add", walker.VMTagName());
    EXPECT_STREQ("[Unoptimized] double._add", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] double.+", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  double_class.SetTraceAllocation(false);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_ArrayAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "List foo() => List.filled(4, null);\n"
      "List bar() => List.filled(0, null, growable: true);\n";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& array_class =
      Class::Handle(isolate->group()->object_store()->array_class());
  EXPECT(!array_class.IsNull());

  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  array_class.SetTraceAllocation(true);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("DRT_AllocateArray", walker.VMTagName());
    EXPECT_STREQ("[Stub] AllocateArray", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] new _List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  array_class.SetTraceAllocation(false);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  // Clear the samples.
  ProfilerService::ClearSamples();

  // Compile bar (many List objects allocated).
  Invoke(root_library, "bar");

  // Enable again.
  array_class.SetTraceAllocation(true);

  // Run bar.
  Invoke(root_library, "bar");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples, since empty
    // growable lists use a shared backing.
    EXPECT_EQ(0, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_ContextAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "var msg1 = 'a';\n"
      "foo() {\n"
      "  var msg = msg1 + msg1;\n"
      "  return (x) { return '$msg + $msg'; }(msg);\n"
      "}\n";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& context_class = Class::Handle(Object::context_class());
  EXPECT(!context_class.IsNull());

  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  context_class.SetTraceAllocation(true);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("DRT_AllocateContext", walker.VMTagName());
    EXPECT_STREQ("[Stub] AllocateContext", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  context_class.SetTraceAllocation(false);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_ClosureAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "var msg1 = 'a';\n"
      "\n"
      "foo() {\n"
      "  var msg = msg1 + msg1;\n"
      "  var msg2 = msg + msg;\n"
      "  return (x, y, z, w) { return '$x + $y + $z'; }(msg, msg2, msg, msg);\n"
      "}\n"
      "bar() {\n"
      "  var msg = msg1 + msg1;\n"
      "  var msg2 = msg + msg;\n"
      "  return (x, y) { return '$x + $y'; }(msg, msg2);\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& closure_class =
      Class::Handle(IsolateGroup::Current()->object_store()->closure_class());
  EXPECT(!closure_class.IsNull());
  closure_class.SetTraceAllocation(true);

  // Invoke "foo" which during compilation, triggers a closure allocation.
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), closure_class.id());
    filter.set_enable_vm_ticks(true);
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_SUBSTRING("DRT_AllocateClosure", walker.VMTagName());
    EXPECT_STREQ("[Stub] AllocateClosure", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Disable allocation tracing for Closure.
  closure_class.SetTraceAllocation(false);

  // Invoke "bar" which during compilation, triggers a closure allocation.
  Invoke(root_library, "bar");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), closure_class.id());
    filter.set_enable_vm_ticks(true);
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_TypedArrayAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "import 'dart:typed_data';\n"
      "List foo() => new Float32List(4);\n";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Library& typed_data_library =
      Library::Handle(isolate->group()->object_store()->typed_data_library());

  const Class& float32_list_class =
      Class::Handle(GetClass(typed_data_library, "_Float32List"));
  EXPECT(!float32_list_class.IsNull());

  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("DRT_AllocateTypedData", walker.VMTagName());
    EXPECT_STREQ("[Stub] AllocateFloat32Array", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] new Float32List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  float32_list_class.SetTraceAllocation(false);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  Invoke(root_library, "foo");

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_StringAllocation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript = "String foo(String a, String b) => a + b;";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& one_byte_string_class =
      Class::Handle(isolate->group()->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2];
  {
    TransitionVMToNative transition(thread);
    args[0] = NewString("a");
    args[1] = NewString("b");
  }

  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("String_concat", walker.VMTagName());
    EXPECT_STREQ("[Unoptimized] _StringBase.+", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  one_byte_string_class.SetTraceAllocation(false);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_StringInterpolation) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript = "String foo(String a, String b) => '$a | $b';";
  const Library& root_library = Library::Handle(LoadTestScript(kScript));
  Isolate* isolate = thread->isolate();

  const Class& one_byte_string_class =
      Class::Handle(isolate->group()->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2];
  {
    TransitionVMToNative transition(thread);
    args[0] = NewString("a");
    args[1] = NewString("b");
  }

  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("Internal_allocateOneByteString", walker.VMTagName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] String._allocate", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] String._concatAll", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] _StringBase._interpolate",
                 walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  one_byte_string_class.SetTraceAllocation(false);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  Invoke(root_library, "foo", 2, &args[0]);

  {
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_FunctionInline) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 30000);

  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static choo(bool alloc) {\n"
      "    if (alloc) return new A();\n"
      "    return alloc && alloc && !alloc;\n"
      "  }\n"
      "  static foo(bool alloc) {\n"
      "    choo(alloc);\n"
      "  }\n"
      "  static boo(bool alloc) {\n"
      "    for (var i = 0; i < 50000; i++) {\n"
      "      foo(alloc);\n"
      "    }\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  B.boo(false);\n"
      "}\n"
      "mainA() {\n"
      "  B.boo(true);\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  // Compile "main".
  Invoke(root_library, "main");
  // Compile "mainA".
  Invoke(root_library, "mainA");
  // At this point B.boo should be optimized and inlined B.foo and B.choo.

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate 50,000 instances of A.
  Invoke(root_library, "mainA");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have 50,000 allocation samples.
    EXPECT_EQ(50000, profile.sample_count());
    {
      ProfileStackWalker walker(&profile);
      // We have two code objects: mainA and B.boo.
      EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
      EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
      EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
      EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("[Optimized] B.boo", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("[Unoptimized] mainA", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT_EQ(0, walker.CurrentExclusiveTicks());
      EXPECT(!walker.Down());
    }
    {
      ProfileStackWalker walker(&profile, true);
      // Inline expansion should show us the complete call chain:
      // mainA -> B.boo -> B.foo -> B.choo.
      EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
      EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
      EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
      EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("B.choo", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("B.foo", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT_EQ(0, walker.CurrentExclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("B.boo", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT_EQ(0, walker.CurrentExclusiveTicks());
      EXPECT(walker.Down());
      EXPECT_STREQ("mainA", walker.CurrentName());
      EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
      EXPECT_EQ(0, walker.CurrentExclusiveTicks());
      EXPECT(!walker.Down());
    }
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_InliningIntervalBoundary) {
  // The PC of frames below the top frame is a call's return address,
  // which can belong to a different inlining interval than the call.
  // This test checks the profiler service takes this into account; see
  // ProfileBuilder::ProcessFrame.

  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 30000);

  const char* kScript =
      "class A {\n"
      "}\n"
      "bool alloc = false;"
      "maybeAlloc() {\n"
      "  try {\n"
      "    if (alloc) new A();\n"
      "  } catch (e) {\n"
      "  }\n"
      "}\n"
      "right() => maybeAlloc();\n"
      "doNothing() {\n"
      "  try {\n"
      "  } catch (e) {\n"
      "  }\n"
      "}\n"
      "wrong() => doNothing();\n"
      "a() {\n"
      "  try {\n"
      "    right();\n"
      "    wrong();\n"
      "  } catch (e) {\n"
      "  }\n"
      "}\n"
      "mainNoAlloc() {\n"
      "  for (var i = 0; i < 20000; i++) {\n"
      "    a();\n"
      "  }\n"
      "}\n"
      "mainAlloc() {\n"
      "  alloc = true;\n"
      "  a();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  // Compile and optimize.
  Invoke(root_library, "mainNoAlloc");
  Invoke(root_library, "mainAlloc");

  // At this point a should be optimized and have inlined both right and wrong,
  // but not maybeAllocate or doNothing.
  Function& func = Function::Handle();
  func = GetFunction(root_library, "a");
  EXPECT(!func.is_inlinable());
  EXPECT(func.HasOptimizedCode());
  func = GetFunction(root_library, "right");
  EXPECT(func.is_inlinable());
  func = GetFunction(root_library, "wrong");
  EXPECT(func.is_inlinable());
  func = GetFunction(root_library, "doNothing");
  EXPECT(!func.is_inlinable());
  func = GetFunction(root_library, "maybeAlloc");
  EXPECT(!func.is_inlinable());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  Invoke(root_library, "mainAlloc");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    // Inline expansion should show us the complete call chain:
    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT(walker.Down());
    EXPECT_STREQ("maybeAlloc", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("right", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("a", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainAlloc", walker.CurrentName());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_ChainedSamples) {
  EnableProfiler();
  MaxProfileDepthScope mpds(32);
  DisableNativeProfileScope dnps;

  // Each sample holds 8 stack frames.
  // This chain is 20 stack frames deep.
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "}\n"
      "class B {\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "go() => init();\n"
      "init() => secondInit();\n"
      "secondInit() => apple();\n"
      "apple() => banana();\n"
      "banana() => cantaloupe();\n"
      "cantaloupe() => dog();\n"
      "dog() => elephant();\n"
      "elephant() => fred();\n"
      "fred() => granola();\n"
      "granola() => haystack();\n"
      "haystack() => ice();\n"
      "ice() => jeep();\n"
      "jeep() => kindle();\n"
      "kindle() => lemon();\n"
      "lemon() => mayo();\n"
      "mayo() => napkin();\n"
      "napkin() => orange();\n"
      "orange() => B.boo();\n"
      "main() {\n"
      "  return go();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());
  class_a.SetTraceAllocation(true);

  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] orange", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] napkin", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] mayo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] lemon", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] kindle", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] jeep", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] ice", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] haystack", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] granola", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] fred", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] elephant", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] dog", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] cantaloupe", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] banana", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] apple", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] secondInit", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] init", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] go", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized] main", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_BasicSourcePosition) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_BasicSourcePositionOptimized) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  B.boo();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Optimize quickly.
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 5);
  // Warm up function.
  while (true) {
    Invoke(root_library, "main");
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    // Move down from the root.
    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_SourcePosition) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:never-inline')\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @pragma('vm:never-inline') bacon() {\n"
      "    return fox();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_SourcePositionOptimized) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:never-inline')\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @pragma('vm:never-inline') bacon() {\n"
      "    return fox();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Optimize quickly.
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 5);
  // Warm up function.
  while (true) {
    Invoke(root_library, "main");
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_BinaryOperatorSourcePosition) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:never-inline')\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @pragma('vm:never-inline') bacon() {\n"
      "    return this + this;\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') operator+(C other) {\n"
      "    return fox();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Invoke(root_library, "main");

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.+", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("+", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

ISOLATE_UNIT_TEST_CASE(Profiler_BinaryOperatorSourcePositionOptimized) {
  EnableProfiler();
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;

  const char* kScript =
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @pragma('vm:never-inline') A() { }\n"
      "}\n"
      "class B {\n"
      "  @pragma('vm:never-inline')\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline')\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @pragma('vm:never-inline') bacon() {\n"
      "    return this + this;\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') operator+(C other) {\n"
      "    return fox();\n"
      "  }\n"
      "  @pragma('vm:prefer-inline') fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Optimize quickly.
  SetFlagScope<int> sfs(&FLAG_optimization_counter_threshold, 5);
  // Warm up function.
  while (true) {
    Invoke(root_library, "main");
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Invoke(root_library, "main");

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    Profile profile;
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, isolate, &filter, Profiler::sample_block_buffer());
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileStackWalker walker(&profile, true);

    EXPECT_STREQ("DRT_AllocateObject", walker.VMTagName());
#if defined(TARGET_ARCH_IA32)  // Alloc. stub not impl. for ia32.
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
#else
    EXPECT_STREQ("[Stub] AllocateObjectSlow", walker.CurrentName());
#endif
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.+", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("+", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}

static void InsertFakeSample(uword* pc_offsets) {
  Isolate* isolate = Isolate::Current();
  ASSERT(Profiler::sample_block_buffer() != nullptr);
  Sample* sample = Profiler::sample_block_buffer()->ReserveCPUSample(isolate);
  ASSERT(sample != nullptr);
  sample->Init(isolate->main_port(), OS::GetCurrentMonotonicMicros(),
               OSThread::Current()->trace_id());
  sample->set_thread_task(Thread::kMutatorTask);

  intptr_t i = 0;
  while (pc_offsets[i] != 0) {
    // When we collect a real stack trace, all PCs collected aside from the
    // executing one (i == 0) are actually return addresses. Return addresses
    // are one byte beyond the call instruction that is executing. The profiler
    // accounts for this and subtracts one from these addresses when querying
    // inline and token position ranges. To be consistent with real stack
    // traces, we add one byte to all PCs except the executing one.
    // See OffsetForPC in profiler_service.cc for more context.
    const intptr_t return_address_offset = i > 0 ? 1 : 0;
    sample->SetAt(i, pc_offsets[i] + return_address_offset);
    i++;
  }
  sample->SetAt(i, 0);
}

static uword FindPCForTokenPosition(const Code& code, TokenPosition tp) {
  GrowableArray<const Function*> functions;
  GrowableArray<TokenPosition> token_positions;
  for (uword pc_offset = 0; pc_offset < code.Size(); pc_offset++) {
    code.GetInlinedFunctionsAtInstruction(pc_offset, &functions,
                                          &token_positions);
    if (token_positions[0] == tp) {
      return code.PayloadStart() + pc_offset;
    }
  }

  return 0;
}

ISOLATE_UNIT_TEST_CASE(Profiler_GetSourceReport) {
  EnableProfiler();
  const char* kScript =
      "int doWork(i) => i * i;\n"
      "int main() {\n"
      "  int sum = 0;\n"
      "  for (int i = 0; i < 100; i++) {\n"
      "     sum += doWork(i);\n"
      "  }\n"
      "  return sum;\n"
      "}\n";

  // Token position of * in `i * i`.
  const TokenPosition squarePosition = TokenPosition::Deserialize(19);

  // Token position of the call to `doWork`.
  const TokenPosition callPosition = TokenPosition::Deserialize(95);

  DisableNativeProfileScope dnps;
  // Disable profiling for this thread.
  DisableThreadInterruptsScope dtis(Thread::Current());

  DisableBackgroundCompilationScope dbcs;

  SampleBlockBuffer* sample_block_buffer = Profiler::sample_block_buffer();
  ASSERT(sample_block_buffer != nullptr);

  const Library& root_library = Library::Handle(LoadTestScript(kScript));

  // Invoke main so that it gets compiled.
  Invoke(root_library, "main");

  {
    // Clear the profile for this isolate.
    ClearProfileVisitor cpv(Isolate::Current());
    sample_block_buffer->VisitSamples(&cpv);
  }

  // Query the code object for main and determine the PC at some token
  // positions.
  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  const Function& do_work =
      Function::Handle(GetFunction(root_library, "doWork"));
  EXPECT(!do_work.IsNull());

  const Script& script = Script::Handle(main.script());
  EXPECT(!script.IsNull());

  const Code& main_code = Code::Handle(main.CurrentCode());
  EXPECT(!main_code.IsNull());

  const Code& do_work_code = Code::Handle(do_work.CurrentCode());
  EXPECT(!do_work_code.IsNull());

  // Dump code source map.
  do_work_code.DumpSourcePositions();
  main_code.DumpSourcePositions();

  // Look up some source token position's pc.
  uword squarePositionPc = FindPCForTokenPosition(do_work_code, squarePosition);
  EXPECT(squarePositionPc != 0);

  uword callPositionPc = FindPCForTokenPosition(main_code, callPosition);
  EXPECT(callPositionPc != 0);

  // Look up some classifying token position's pc.
  uword controlFlowPc =
      FindPCForTokenPosition(do_work_code, TokenPosition::kControlFlow);
  EXPECT(controlFlowPc != 0);

  // Insert fake samples.

  // Sample 1:
  // squarePositionPc exclusive.
  // callPositionPc inclusive.
  uword sample1[] = {squarePositionPc,  // doWork.
                     callPositionPc,    // main.
                     0};

  // Sample 2:
  // squarePositionPc exclusive.
  uword sample2[] = {
      squarePositionPc,  // doWork.
      0,
  };

  // Sample 3:
  // controlFlowPc exclusive.
  // callPositionPc inclusive.
  uword sample3[] = {controlFlowPc,   // doWork.
                     callPositionPc,  // main.
                     0};

  InsertFakeSample(&sample1[0]);
  InsertFakeSample(&sample2[0]);
  InsertFakeSample(&sample3[0]);

  // Generate source report for main.
  JSONStream js;
  {
    SourceReport sourceReport(SourceReport::kProfile);
    sourceReport.PrintJSON(&js, script, do_work.token_pos(),
                           main.end_token_pos());
  }

  // Verify positions in do_work.
  EXPECT_SUBSTRING("\"positions\":[\"ControlFlow\",19]", js.ToCString());
  // Verify exclusive ticks in do_work.
  EXPECT_SUBSTRING("\"exclusiveTicks\":[1,2]", js.ToCString());
  // Verify inclusive ticks in do_work.
  EXPECT_SUBSTRING("\"inclusiveTicks\":[1,2]", js.ToCString());

  // Verify positions in main.
  EXPECT_SUBSTRING("\"positions\":[95]", js.ToCString());
  // Verify exclusive ticks in main.
  EXPECT_SUBSTRING("\"exclusiveTicks\":[0]", js.ToCString());
  // Verify inclusive ticks in main.
  EXPECT_SUBSTRING("\"inclusiveTicks\":[2]", js.ToCString());
}

ISOLATE_UNIT_TEST_CASE(Profiler_ProfileCodeTableTest) {
  Zone* Z = Thread::Current()->zone();

  ProfileCodeTable* table = new (Z) ProfileCodeTable();
  EXPECT_EQ(table->length(), 0);
  EXPECT_EQ(table->FindCodeForPC(42), static_cast<ProfileCode*>(nullptr));

  int64_t timestamp = 0;
  const AbstractCode null_code(Code::null());

  ProfileCode* code1 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 50, 60, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code1), 0);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(55), code1);
  EXPECT_EQ(table->FindCodeForPC(59), code1);
  EXPECT_EQ(table->FindCodeForPC(60), static_cast<ProfileCode*>(nullptr));

  // Insert below all.
  ProfileCode* code2 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 10, 20, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code2), 0);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(19), code2);
  EXPECT_EQ(table->FindCodeForPC(20), static_cast<ProfileCode*>(nullptr));

  // Insert above all.
  ProfileCode* code3 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 80, 90, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code3), 2);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(80), code3);
  EXPECT_EQ(table->FindCodeForPC(89), code3);
  EXPECT_EQ(table->FindCodeForPC(90), static_cast<ProfileCode*>(nullptr));

  // Insert between.
  ProfileCode* code4 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 65, 75, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code4), 2);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(80), code3);
  EXPECT_EQ(table->FindCodeForPC(65), code4);
  EXPECT_EQ(table->FindCodeForPC(74), code4);
  EXPECT_EQ(table->FindCodeForPC(75), static_cast<ProfileCode*>(nullptr));

  // Insert overlapping left.
  ProfileCode* code5 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 15, 25, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code5), 0);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(80), code3);
  EXPECT_EQ(table->FindCodeForPC(65), code4);
  EXPECT_EQ(table->FindCodeForPC(15), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(24), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(25), static_cast<ProfileCode*>(nullptr));

  // Insert overlapping right.
  ProfileCode* code6 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 45, 55, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code6), 1);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(80), code3);
  EXPECT_EQ(table->FindCodeForPC(65), code4);
  EXPECT_EQ(table->FindCodeForPC(15), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(24), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(45), code1);  // Merged right.
  EXPECT_EQ(table->FindCodeForPC(54), code1);  // Merged right.
  EXPECT_EQ(table->FindCodeForPC(55), code1);

  // Insert overlapping both.
  ProfileCode* code7 = new (Z)
      ProfileCode(ProfileCode::kNativeCode, 20, 50, timestamp, null_code);
  EXPECT_EQ(table->InsertCode(code7), 0);
  EXPECT_EQ(table->FindCodeForPC(0), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(100), static_cast<ProfileCode*>(nullptr));
  EXPECT_EQ(table->FindCodeForPC(50), code1);
  EXPECT_EQ(table->FindCodeForPC(10), code2);
  EXPECT_EQ(table->FindCodeForPC(80), code3);
  EXPECT_EQ(table->FindCodeForPC(65), code4);
  EXPECT_EQ(table->FindCodeForPC(15), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(24), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(45), code1);  // Merged right.
  EXPECT_EQ(table->FindCodeForPC(54), code1);  // Merged right.
  EXPECT_EQ(table->FindCodeForPC(20), code2);  // Merged left.
  EXPECT_EQ(table->FindCodeForPC(49), code1);  // Truncated.
  EXPECT_EQ(table->FindCodeForPC(50), code1);
}

#endif  // !PRODUCT

}  // namespace dart
