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
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

DECLARE_FLAG(bool, profile_vm);
DECLARE_FLAG(int, max_profile_depth);
DECLARE_FLAG(bool, enable_inlining_annotations);
DECLARE_FLAG(int, optimization_counter_threshold);

// Some tests are written assuming native stack trace profiling is disabled.
class DisableNativeProfileScope : public ValueObject {
 public:
  DisableNativeProfileScope() : FLAG_profile_vm_(FLAG_profile_vm) {
    FLAG_profile_vm = false;
  }

  ~DisableNativeProfileScope() { FLAG_profile_vm = FLAG_profile_vm_; }

 private:
  const bool FLAG_profile_vm_;
};


class DisableBackgroundCompilationScope : public ValueObject {
 public:
  DisableBackgroundCompilationScope()
      : FLAG_background_compilation_(FLAG_background_compilation) {
    FLAG_background_compilation = false;
  }

  ~DisableBackgroundCompilationScope() {
    FLAG_background_compilation = FLAG_background_compilation_;
  }

 private:
  const bool FLAG_background_compilation_;
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


class ProfileSampleBufferTestHelper {
 public:
  static intptr_t IterateCount(const Dart_Port port,
                               const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (intptr_t i = 0; i < sample_buffer.capacity(); i++) {
      Sample* sample = sample_buffer.At(i);
      if (sample->port() != port) {
        continue;
      }
      c++;
    }
    return c;
  }


  static intptr_t IterateSumPC(const Dart_Port port,
                               const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (intptr_t i = 0; i < sample_buffer.capacity(); i++) {
      Sample* sample = sample_buffer.At(i);
      if (sample->port() != port) {
        continue;
      }
      c += sample->At(0);
    }
    return c;
  }
};


TEST_CASE(Profiler_SampleBufferWrapTest) {
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  Dart_Port i = 123;
  EXPECT_EQ(0, ProfileSampleBufferTestHelper::IterateSumPC(i, *sample_buffer));
  Sample* s;
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  s->SetAt(0, 2);
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateSumPC(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  s->SetAt(0, 4);
  EXPECT_EQ(6, ProfileSampleBufferTestHelper::IterateSumPC(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  s->SetAt(0, 6);
  EXPECT_EQ(12, ProfileSampleBufferTestHelper::IterateSumPC(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  s->SetAt(0, 8);
  EXPECT_EQ(18, ProfileSampleBufferTestHelper::IterateSumPC(i, *sample_buffer));
  delete sample_buffer;
}


TEST_CASE(Profiler_SampleBufferIterateTest) {
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  Dart_Port i = 123;
  EXPECT_EQ(0, ProfileSampleBufferTestHelper::IterateCount(i, *sample_buffer));
  Sample* s;
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  EXPECT_EQ(1, ProfileSampleBufferTestHelper::IterateCount(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  EXPECT_EQ(2, ProfileSampleBufferTestHelper::IterateCount(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  EXPECT_EQ(3, ProfileSampleBufferTestHelper::IterateCount(i, *sample_buffer));
  s = sample_buffer->ReserveSample();
  s->Init(i, 0, 0);
  EXPECT_EQ(3, ProfileSampleBufferTestHelper::IterateCount(i, *sample_buffer));
  delete sample_buffer;
}


TEST_CASE(Profiler_AllocationSampleTest) {
  Isolate* isolate = Isolate::Current();
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  Sample* sample = sample_buffer->ReserveSample();
  sample->Init(isolate->main_port(), 0, 0);
  sample->set_metadata(99);
  sample->set_is_allocation_sample(true);
  EXPECT_EQ(99, sample->allocation_cid());
  delete sample_buffer;
}


static RawClass* GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(lib.LookupClassAllowPrivate(
      String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.raw();
}


static RawFunction* GetFunction(const Library& lib, const char* name) {
  const Function& func = Function::Handle(lib.LookupFunctionAllowPrivate(
      String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!func.IsNull());  // No ambiguity error expected.
  return func.raw();
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


TEST_CASE(Profiler_TrivialRecordAllocation) {
  DisableNativeProfileScope dnps;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const int64_t before_allocations_micros = Dart_TimelineGetMicros();
  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());
  class_a.SetTraceAllocation(true);

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  const int64_t after_allocations_micros = Dart_TimelineGetMicros();
  const int64_t allocation_extent_micros =
      after_allocations_micros - before_allocations_micros;
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    // Filter for the class in the time range.
    AllocationFilter filter(isolate->main_port(), class_a.id(),
                            before_allocations_micros,
                            allocation_extent_micros);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inclusive code: main -> B.boo.
    walker.Reset(Profile::kInclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inclusive function: main -> B.boo.
    walker.Reset(Profile::kInclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Query with a time filter where no allocations occurred.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id(),
                            Dart_TimelineGetMicros(), 16000);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples because none occured within
    // the specified time range.
    EXPECT_EQ(0, profile.sample_count());
  }
}

#if defined(DART_USE_TCMALLOC) && defined(HOST_OS_LINUX) && defined(DEBUG) &&  \
    defined(HOST_ARCH_x64)

DART_NOINLINE static void NativeAllocationSampleHelper(char** result) {
  ASSERT(result != NULL);
  *result = static_cast<char*>(malloc(sizeof(char) * 1024));
}


ISOLATE_UNIT_TEST_CASE(Profiler_NativeAllocation) {
  bool enable_malloc_hooks_saved = FLAG_profiler_native_memory;
  FLAG_profiler_native_memory = true;

  MallocHooks::InitOnce();
  MallocHooks::ResetStats();
  bool stack_trace_collection_enabled =
      MallocHooks::stack_trace_collection_enabled();
  MallocHooks::set_stack_trace_collection_enabled(true);

  char* result = NULL;
  const int64_t before_allocations_micros = Dart_TimelineGetMicros();
  NativeAllocationSampleHelper(&result);

  // Disable stack allocation stack trace collection to avoid muddying up
  // results.
  MallocHooks::set_stack_trace_collection_enabled(false);
  const int64_t after_allocations_micros = Dart_TimelineGetMicros();
  const int64_t allocation_extent_micros =
      after_allocations_micros - before_allocations_micros;

  // Walk the trie and do a sanity check of the allocation values associated
  // with each node.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);

    // Filter for the class in the time range.
    NativeAllocationSampleFilter filter(before_allocations_micros,
                                        allocation_extent_micros);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: NativeAllocationSampleHelper -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("[Native]", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 1024);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::Dart_TestProfiler_NativeAllocation()",
                 walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCase::Run()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunTest()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunAll()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(!walker.Down());

    // Inclusive code: main -> NativeAllocationSampleHelper.
    walker.Reset(Profile::kInclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunAll()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunTest()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCase::Run()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::Dart_TestProfiler_NativeAllocation()",
                 walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("[Native]", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 1024);
    EXPECT(!walker.Down());

    // Exclusive function: NativeAllocationSampleHelper -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("[Native]", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 1024);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::Dart_TestProfiler_NativeAllocation()",
                 walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCase::Run()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunTest()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunAll()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(!walker.Down());

    // Inclusive function: main -> NativeAllocationSampleHelper.
    walker.Reset(Profile::kInclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunAll()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCaseBase::RunTest()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::TestCase::Run()", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_STREQ("dart::Dart_TestProfiler_NativeAllocation()",
                 walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 0);
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("[Native]", walker.CurrentName());
    EXPECT_EQ(walker.CurrentInclusiveAllocations(), 1024);
    EXPECT_EQ(walker.CurrentExclusiveAllocations(), 1024);
    EXPECT(!walker.Down());
  }

  MallocHooks::set_stack_trace_collection_enabled(true);
  free(result);
  MallocHooks::set_stack_trace_collection_enabled(false);

  // Check to see that the native allocation sample associated with the memory
  // freed above is marked as free and is no longer reported.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);

    // Filter for the class in the time range.
    NativeAllocationSampleFilter filter(before_allocations_micros,
                                        allocation_extent_micros);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have 0 allocation samples since we freed the memory.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Query with a time filter where no allocations occurred.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    NativeAllocationSampleFilter filter(Dart_TimelineGetMicros(), 16000);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples because none occured within
    // the specified time range.
    EXPECT_EQ(0, profile.sample_count());
  }

  MallocHooks::set_stack_trace_collection_enabled(
      stack_trace_collection_enabled);
  MallocHooks::TearDown();
  FLAG_profiler_native_memory = enable_malloc_hooks_saved;
}
#endif  // defined(DART_USE_TCMALLOC) && !defined(PRODUCT) &&
        // !defined(TARGET_ARCH_DBC) && !defined(HOST_OS_FUCHSIA)


TEST_CASE(Profiler_ToggleRecordAllocation) {
  DisableNativeProfileScope dnps;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);


  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inclusive code: main -> B.boo.
    walker.Reset(Profile::kInclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());

    // Exclusive function: boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inclusive function: main -> boo.
    walker.Reset(Profile::kInclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Turn off allocation tracing for A.
  class_a.SetTraceAllocation(false);

  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}


TEST_CASE(Profiler_CodeTicks) {
  DisableNativeProfileScope dnps;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate three times.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());

    // Inclusive code: main -> B.boo.
    walker.Reset(Profile::kInclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_FunctionTicks) {
  DisableNativeProfileScope dnps;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate three times.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());

    // Inclusive function: main -> B.boo.
    walker.Reset(Profile::kInclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_IntrinsicAllocation) {
  DisableNativeProfileScope dnps;
  const char* kScript = "double foo(double a, double b) => a + b;";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& double_class =
      Class::Handle(isolate->object_store()->double_class());
  EXPECT(!double_class.IsNull());

  Dart_Handle args[2] = {
      Dart_NewDouble(1.0), Dart_NewDouble(2.0),
  };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  double_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("Double_add", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_Double._add", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_Double.+", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  double_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), double_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}


TEST_CASE(Profiler_ArrayAllocation) {
  DisableNativeProfileScope dnps;
  const char* kScript =
      "List foo() => new List(4);\n"
      "List bar() => new List();\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& array_class =
      Class::Handle(isolate->object_store()->array_class());
  EXPECT(!array_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  array_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateArray", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] AllocateArray", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new _List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new List._internal", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  array_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  // Clear the samples.
  ProfilerService::ClearSamples();

  // Compile bar (many List objects allocated).
  result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);

  // Enable again.
  array_class.SetTraceAllocation(true);

  // Run bar.
  result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), array_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateArray", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] AllocateArray", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new _List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new _GrowableList", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new List._internal", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("bar", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_ContextAllocation) {
  DisableNativeProfileScope dnps;
  const char* kScript =
      "var msg1 = 'a';\n"
      "foo() {\n"
      "  var msg = msg1 + msg1;\n"
      "  return (x) { return '$msg + $msg'; }(msg);\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& context_class = Class::Handle(Object::context_class());
  EXPECT(!context_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  context_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateContext", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] AllocateContext", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  context_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), context_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}


TEST_CASE(Profiler_ClosureAllocation) {
  DisableNativeProfileScope dnps;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& closure_class =
      Class::Handle(Isolate::Current()->object_store()->closure_class());
  EXPECT(!closure_class.IsNull());
  closure_class.SetTraceAllocation(true);

  // Invoke "foo" which during compilation, triggers a closure allocation.
  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), closure_class.id());
    filter.set_enable_vm_ticks(true);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate _Closure", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_SUBSTRING("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Disable allocation tracing for Closure.
  closure_class.SetTraceAllocation(false);

  // Invoke "bar" which during compilation, triggers a closure allocation.
  result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), closure_class.id());
    filter.set_enable_vm_ticks(true);
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}


TEST_CASE(Profiler_TypedArrayAllocation) {
  DisableNativeProfileScope dnps;
  const char* kScript =
      "import 'dart:typed_data';\n"
      "List foo() => new Float32List(4);\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Library& typed_data_library =
      Library::Handle(isolate->object_store()->typed_data_library());

  const Class& float32_list_class =
      Class::Handle(GetClass(typed_data_library, "_Float32List"));
  EXPECT(!float32_list_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("TypedData_Float32Array_new", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("new Float32List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  float32_list_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), float32_list_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}


TEST_CASE(Profiler_StringAllocation) {
  DisableNativeProfileScope dnps;
  const char* kScript = "String foo(String a, String b) => a + b;";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& one_byte_string_class =
      Class::Handle(isolate->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2] = {
      NewString("a"), NewString("b"),
  };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("String_concat", walker.CurrentName());
    EXPECT(walker.Down());
#if 1
    EXPECT_STREQ("_StringBase.+", walker.CurrentName());
    EXPECT(walker.Down());
#endif
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  one_byte_string_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}


TEST_CASE(Profiler_StringInterpolation) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript = "String foo(String a, String b) => '$a | $b';";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = thread->isolate();

  const Class& one_byte_string_class =
      Class::Handle(isolate->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2] = {
      NewString("a"), NewString("b"),
  };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("OneByteString_allocate", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_OneByteString._allocate", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_OneByteString._concatAll", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_StringBase._interpolate", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  one_byte_string_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), one_byte_string_class.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}


TEST_CASE(Profiler_FunctionInline) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;

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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  // Compile "main".
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  // Compile "mainA".
  result = Dart_Invoke(lib, NewString("mainA"), 0, NULL);
  EXPECT_VALID(result);
  // At this point B.boo should be optimized and inlined B.foo and B.choo.

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate 50,000 instances of A.
  result = Dart_Invoke(lib, NewString("mainA"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have 50,000 allocation samples.
    EXPECT_EQ(50000, profile.sample_count());
    ProfileTrieWalker walker(&profile);
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("*B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kInclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("*B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kExclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.choo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.foo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kInclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.foo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.choo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  // Test code transition tags.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags,
                  ProfilerService::kCodeTransitionTagsBit);
    // We should have 50,000 allocation samples.
    EXPECT_EQ(50000, profile.sample_count());
    ProfileTrieWalker walker(&profile);
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("*B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Optimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(!walker.Down());
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kInclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Optimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("*B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kExclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Inline End]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.choo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.foo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Inline Start]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Optimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kInclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("mainA", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Optimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Inline Start]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.foo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.choo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Inline End]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_InliningIntervalBoundry) {
  // The PC of frames below the top frame is a call's return address,
  // which can belong to a different inlining interval than the call.
  // This test checks the profiler service takes this into account; see
  // ProfileBuilder::ProcessFrame.

  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  // Compile and optimize.
  Dart_Handle result = Dart_Invoke(lib, NewString("mainNoAlloc"), 0, NULL);
  EXPECT_VALID(result);
  result = Dart_Invoke(lib, NewString("mainAlloc"), 0, NULL);
  EXPECT_VALID(result);

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
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  result = Dart_Invoke(lib, NewString("mainAlloc"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Inline expansion should show us the complete call chain:
    walker.Reset(Profile::kExclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("maybeAlloc", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("right", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("a", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mainAlloc", walker.CurrentName());
    EXPECT(walker.Down());  // Account for "[Native] [xxxxxxx, xxxxxxx)"
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    walker.Reset(Profile::kInclusiveFunction);
    EXPECT(walker.Down());  // Account for "[Native] [xxxxxxx, xxxxxxx)"
    EXPECT(walker.Down());
    EXPECT_STREQ("mainAlloc", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("a", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("right", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("maybeAlloc", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_ChainedSamples) {
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

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());
  class_a.SetTraceAllocation(true);

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);


  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("orange", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("napkin", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("mayo", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("lemon", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("kindle", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("jeep", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("ice", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("haystack", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("granola", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("fred", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("elephant", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("dog", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("cantaloupe", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("banana", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("apple", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("secondInit", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("init", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("go", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_BasicSourcePosition) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  B.boo();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_BasicSourcePositionOptimized) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  // We use the AlwaysInline and NeverInline annotations in this test.
  SetFlagScope<bool> sfs(&FLAG_enable_inlining_annotations, true);
  // Optimize quickly.
  SetFlagScope<int> sfs2(&FLAG_optimization_counter_threshold, 5);
  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  B.boo();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Warm up function.
  while (true) {
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_SourcePosition) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @NeverInline\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @NeverInline bacon() {\n"
      "    return fox();\n"
      "  }\n"
      "  @AlwaysInline fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_SourcePositionOptimized) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  // We use the AlwaysInline and NeverInline annotations in this test.
  SetFlagScope<bool> sfs(&FLAG_enable_inlining_annotations, true);
  // Optimize quickly.
  SetFlagScope<int> sfs2(&FLAG_optimization_counter_threshold, 5);

  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @NeverInline\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @NeverInline bacon() {\n"
      "    return fox();\n"
      "  }\n"
      "  @AlwaysInline fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Warm up function.
  while (true) {
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_BinaryOperatorSourcePosition) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @NeverInline\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @NeverInline bacon() {\n"
      "    return this + this;\n"
      "  }\n"
      "  @AlwaysInline operator+(C other) {\n"
      "    return fox();\n"
      "  }\n"
      "  @AlwaysInline fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.+", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("+", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


TEST_CASE(Profiler_BinaryOperatorSourcePositionOptimized) {
  DisableNativeProfileScope dnps;
  DisableBackgroundCompilationScope dbcs;
  // We use the AlwaysInline and NeverInline annotations in this test.
  SetFlagScope<bool> sfs(&FLAG_enable_inlining_annotations, true);
  // Optimize quickly.
  SetFlagScope<int> sfs2(&FLAG_optimization_counter_threshold, 5);

  const char* kScript =
      "const AlwaysInline = 'AlwaysInline';\n"
      "const NeverInline = 'NeverInline';\n"
      "class A {\n"
      "  var a;\n"
      "  var b;\n"
      "  @NeverInline A() { }\n"
      "}\n"
      "class B {\n"
      "  @NeverInline\n"
      "  static oats() {\n"
      "    return boo();\n"
      "  }\n"
      "  @AlwaysInline\n"
      "  static boo() {\n"
      "    return new A();\n"
      "  }\n"
      "}\n"
      "class C {\n"
      "  @NeverInline bacon() {\n"
      "    return this + this;\n"
      "  }\n"
      "  @AlwaysInline operator+(C other) {\n"
      "    return fox();\n"
      "  }\n"
      "  @AlwaysInline fox() {\n"
      "    return B.oats();\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  new C()..bacon();\n"
      "}\n";

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  const Class& class_a = Class::Handle(GetClass(root_library, "A"));
  EXPECT(!class_a.IsNull());

  const Function& main = Function::Handle(GetFunction(root_library, "main"));
  EXPECT(!main.IsNull());

  // Warm up function.
  while (true) {
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
    EXPECT_VALID(result);
    const Code& code = Code::Handle(main.CurrentCode());
    if (code.is_optimized()) {
      // Warmed up.
      break;
    }
  }

  // Turn on allocation tracing for A.
  class_a.SetTraceAllocation(true);

  // Allocate one time.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Still optimized.
  const Code& code = Code::Handle(main.CurrentCode());
  EXPECT(code.is_optimized());

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate->main_port(), class_a.id());
    profile.Build(thread, &filter, Profile::kNoTags);
    // We should have one allocation samples.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("DRT_AllocateObject", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("[Stub] Allocate A", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentExclusiveTicks());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_STREQ("A", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("B.oats", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("boo", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.fox", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("oats", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.+", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("fox", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("C.bacon", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("+", walker.CurrentToken());
    EXPECT(walker.Down());
    EXPECT_STREQ("main", walker.CurrentName());
    EXPECT_EQ(1, walker.CurrentNodeTickCount());
    EXPECT_EQ(1, walker.CurrentInclusiveTicks());
    EXPECT_EQ(0, walker.CurrentExclusiveTicks());
    EXPECT_STREQ("bacon", walker.CurrentToken());
    EXPECT(!walker.Down());
  }
}


static void InsertFakeSample(SampleBuffer* sample_buffer, uword* pc_offsets) {
  ASSERT(sample_buffer != NULL);
  Isolate* isolate = Isolate::Current();
  Sample* sample = sample_buffer->ReserveSample();
  ASSERT(sample != NULL);
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


static uword FindPCForTokenPosition(const Code& code,
                                    TokenPosition tp) {
  GrowableArray<const Function*> functions;
  GrowableArray<TokenPosition> token_positions;
  for (intptr_t pc_offset = 0; pc_offset < code.Size(); pc_offset++) {
    code.GetInlinedFunctionsAtInstruction(pc_offset, &functions,
                                          &token_positions);
    if (token_positions[0] == tp) {
      return code.PayloadStart() + pc_offset;
    }
  }

  return 0;
}


TEST_CASE(Profiler_GetSourceReport) {
  const char* kScript =
      "doWork(i) => i * i;\n"
      "main() {\n"
      "  var sum = 0;\n"
      "  for (var i = 0; i < 100; i++) {\n"
      "     sum += doWork(i);\n"
      "  }\n"
      "  return sum;\n"
      "}\n";

  // Token position of * in `i * i`.
  const TokenPosition squarePosition = TokenPosition(6);

  // Token position of the call to `doWork`.
  const TokenPosition callPosition = TokenPosition(39);

  DisableNativeProfileScope dnps;
  // Disable profiling for this thread.
  DisableThreadInterruptsScope dtis(Thread::Current());

  DisableBackgroundCompilationScope dbcs;

  SampleBuffer* sample_buffer = Profiler::sample_buffer();
  EXPECT(sample_buffer != NULL);

  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);

  // Invoke main so that it gets compiled.
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  {
    // Clear the profile for this isolate.
    ClearProfileVisitor cpv(Isolate::Current());
    sample_buffer->VisitSamples(&cpv);
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

  uword tempMovePc =
      FindPCForTokenPosition(main_code, TokenPosition::kTempMove);
  EXPECT(tempMovePc != 0);

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

  // Sample 4:
  // tempMovePc exclusive.
  uword sample4[] = {tempMovePc,  // main.
                     0};

  InsertFakeSample(sample_buffer, &sample1[0]);
  InsertFakeSample(sample_buffer, &sample2[0]);
  InsertFakeSample(sample_buffer, &sample3[0]);
  InsertFakeSample(sample_buffer, &sample4[0]);

  // Generate source report for main.
  SourceReport sourceReport(SourceReport::kProfile);
  JSONStream js;
  sourceReport.PrintJSON(&js, script, do_work.token_pos(),
                         main.end_token_pos());

  // Verify positions in do_work.
  EXPECT_SUBSTRING("\"positions\":[\"ControlFlow\",6]", js.ToCString());
  // Verify exclusive ticks in do_work.
  EXPECT_SUBSTRING("\"exclusiveTicks\":[1,2]", js.ToCString());
  // Verify inclusive ticks in do_work.
  EXPECT_SUBSTRING("\"inclusiveTicks\":[1,2]", js.ToCString());

  // Verify positions in main.
  EXPECT_SUBSTRING("\"positions\":[\"TempMove\",39]", js.ToCString());
  // Verify exclusive ticks in main.
  EXPECT_SUBSTRING("\"exclusiveTicks\":[1,0]", js.ToCString());
  // Verify inclusive ticks in main.
  EXPECT_SUBSTRING("\"inclusiveTicks\":[1,2]", js.ToCString());
}

#endif  // !PRODUCT

}  // namespace dart
