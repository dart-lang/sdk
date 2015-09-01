// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"
#include "vm/unit_test.h"

namespace dart {

DECLARE_FLAG(bool, profile_vm);
DECLARE_FLAG(int, max_profile_depth);

// Some tests are written assuming native stack trace profiling is disabled.
class DisableNativeProfileScope : public ValueObject {
 public:
  DisableNativeProfileScope()
      : FLAG_profile_vm_(FLAG_profile_vm) {
    FLAG_profile_vm = false;
  }

  ~DisableNativeProfileScope() {
    FLAG_profile_vm = FLAG_profile_vm_;
  }

 private:
  const bool FLAG_profile_vm_;
};


// Temporarily adjust the maximum profile depth.
class MaxProfileDepthScope : public ValueObject {
 public:
  explicit MaxProfileDepthScope(intptr_t new_max_depth)
      : FLAG_max_profile_depth_(FLAG_max_profile_depth) {
    Profiler::SetSampleDepth(new_max_depth);
  }

  ~MaxProfileDepthScope() {
    Profiler::SetSampleDepth(FLAG_max_profile_depth_);
  }

 private:
  const intptr_t FLAG_max_profile_depth_;
};


class ProfileSampleBufferTestHelper {
 public:
  static intptr_t IterateCount(const Isolate* isolate,
                               const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (intptr_t i = 0; i < sample_buffer.capacity(); i++) {
      Sample* sample = sample_buffer.At(i);
      if (sample->isolate() != isolate) {
        continue;
      }
      c++;
    }
    return c;
  }


  static intptr_t IterateSumPC(const Isolate* isolate,
                               const SampleBuffer& sample_buffer) {
    intptr_t c = 0;
    for (intptr_t i = 0; i < sample_buffer.capacity(); i++) {
      Sample* sample = sample_buffer.At(i);
      if (sample->isolate() != isolate) {
        continue;
      }
      c += sample->At(0);
    }
    return c;
  }
};


TEST_CASE(Profiler_SampleBufferWrapTest) {
  SampleBuffer* sample_buffer = new SampleBuffer(3);
  Isolate* i = reinterpret_cast<Isolate*>(0x1);
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
  Isolate* i = reinterpret_cast<Isolate*>(0x1);
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
  sample->Init(isolate, 0, 0);
  sample->set_metadata(99);
  sample->set_is_allocation_sample(true);
  EXPECT_EQ(99, sample->allocation_cid());
  delete sample_buffer;
}

static RawClass* GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClassAllowPrivate(String::Handle(Symbols::New(name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.raw();
}


class AllocationFilter : public SampleFilter {
 public:
  explicit AllocationFilter(Isolate* isolate, intptr_t cid)
      : SampleFilter(isolate),
        cid_(cid),
        enable_embedder_ticks_(false) {
  }

  bool FilterSample(Sample* sample) {
    if (!enable_embedder_ticks_ &&
        (sample->vm_tag() == VMTag::kEmbedderTagId)) {
      // We don't want to see embedder ticks in the test.
      return false;
    }
    return sample->is_allocation_sample() &&
           (sample->allocation_cid() == cid_);
  }

  void set_enable_embedder_ticks(bool enable) {
    enable_embedder_ticks_ = enable;
  }

 private:
  intptr_t cid_;
  bool enable_embedder_ticks_;
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
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
    EXPECT(!walker.Down());

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
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
    EXPECT(!walker.Down());
  }
}


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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
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
    EXPECT(!walker.Down());

    // Exclusive function: boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
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

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive code: B.boo -> main.
    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
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
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
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

  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have three allocation samples.
    EXPECT_EQ(3, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    // Exclusive function: B.boo -> main.
    walker.Reset(Profile::kExclusiveFunction);
    // Move down from the root.
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(3, walker.CurrentNodeTickCount());
    EXPECT_EQ(3, walker.CurrentInclusiveTicks());
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
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
    EXPECT_EQ(3, walker.CurrentExclusiveTicks());
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
  Isolate* isolate = Isolate::Current();

  const Class& double_class =
      Class::Handle(isolate->object_store()->double_class());
  EXPECT(!double_class.IsNull());

  Dart_Handle args[2] = { Dart_NewDouble(1.0), Dart_NewDouble(2.0), };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, double_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  double_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, double_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
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
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, double_class.id());
    profile.Build(&filter, Profile::kNoTags);
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
  Isolate* isolate = Isolate::Current();

  const Class& array_class =
      Class::Handle(isolate->object_store()->array_class());
  EXPECT(!array_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, array_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  array_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, array_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("_List._List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("List.List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  array_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, array_class.id());
    profile.Build(&filter, Profile::kNoTags);
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
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, array_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("_List._List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_GrowableList._GrowableList", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("List.List", walker.CurrentName());
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
  Isolate* isolate = Isolate::Current();

  const Class& context_class =
      Class::Handle(Object::context_class());
  EXPECT(!context_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, context_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  context_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, context_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  context_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, context_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}


TEST_CASE(Profiler_ClassAllocation) {
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
  Isolate* isolate = Isolate::Current();

  const Class& class_class =
      Class::Handle(Object::class_class());
  EXPECT(!class_class.IsNull());
  class_class.SetTraceAllocation(true);

  // Invoke "foo" which during compilation, triggers a closure class allocation.
  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_class.id());
    filter.set_enable_embedder_ticks(true);
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
#if defined(TARGET_OS_WINDOWS)
    // TODO(johnmccutchan): Hookup native symbol resolver on Windows.
    EXPECT_SUBSTRING("[Native]", walker.CurrentName());
#else
    EXPECT_SUBSTRING("dart::Profiler::RecordAllocation", walker.CurrentName());
#endif
    EXPECT(!walker.Down());
  }

  // Disable allocation tracing for Class.
  class_class.SetTraceAllocation(false);

  // Invoke "bar" which during compilation, triggers a closure class allocation.
  result = Dart_Invoke(lib, NewString("bar"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_class.id());
    filter.set_enable_embedder_ticks(true);
    profile.Build(&filter, Profile::kNoTags);
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
  Isolate* isolate = Isolate::Current();

  const Library& typed_data_library =
      Library::Handle(isolate->object_store()->typed_data_library());

  const Class& float32_list_class =
      Class::Handle(GetClass(typed_data_library, "_Float32Array"));
  EXPECT(!float32_list_class.IsNull());

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, float32_list_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, float32_list_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("_Float32Array._new", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("_Float32Array._Float32Array", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("Float32List.Float32List", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  float32_list_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, float32_list_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  float32_list_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 0, NULL);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, float32_list_class.id());
    profile.Build(&filter, Profile::kNoTags);
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
  Isolate* isolate = Isolate::Current();

  const Class& one_byte_string_class =
      Class::Handle(isolate->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2] = { NewString("a"), NewString("b"), };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("_StringBase.+", walker.CurrentName());
    EXPECT(walker.Down());
    EXPECT_STREQ("foo", walker.CurrentName());
    EXPECT(!walker.Down());
  }

  one_byte_string_class.SetTraceAllocation(false);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}


TEST_CASE(Profiler_StringInterpolation) {
  DisableNativeProfileScope dnps;
  const char* kScript = "String foo(String a, String b) => '$a | $b';";
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Library& root_library = Library::Handle();
  root_library ^= Api::UnwrapHandle(lib);
  Isolate* isolate = Isolate::Current();

  const Class& one_byte_string_class =
      Class::Handle(isolate->object_store()->one_byte_string_class());
  EXPECT(!one_byte_string_class.IsNull());

  Dart_Handle args[2] = { NewString("a"), NewString("b"), };

  Dart_Handle result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have no allocation samples.
    EXPECT_EQ(0, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
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
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }

  one_byte_string_class.SetTraceAllocation(true);
  result = Dart_Invoke(lib, NewString("foo"), 2, &args[0]);
  EXPECT_VALID(result);

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, one_byte_string_class.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should now have two allocation samples.
    EXPECT_EQ(2, profile.sample_count());
  }
}


TEST_CASE(Profiler_FunctionInline) {
  DisableNativeProfileScope dnps;
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have 50,000 allocation samples.
    EXPECT_EQ(50000, profile.sample_count());
    ProfileTrieWalker walker(&profile);
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
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
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kExclusiveFunction);
    EXPECT(walker.Down());
    EXPECT_STREQ("B.choo", walker.CurrentName());
    EXPECT_EQ(1, walker.SiblingCount());
    EXPECT_EQ(50000, walker.CurrentNodeTickCount());
    EXPECT_EQ(50000, walker.CurrentInclusiveTicks());
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
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
    EXPECT_EQ(50000, walker.CurrentExclusiveTicks());
    EXPECT(!walker.Down());
  }

  // Test code transition tags.
  {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter,
                  Profile::kNoTags,
                  ProfilerService::kCodeTransitionTagsBit);
    // We should have 50,000 allocation samples.
    EXPECT_EQ(50000, profile.sample_count());
    ProfileTrieWalker walker(&profile);
    // We have two code objects: mainA and B.boo.
    walker.Reset(Profile::kExclusiveCode);
    EXPECT(walker.Down());
    EXPECT_STREQ("B.boo", walker.CurrentName());
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
    EXPECT_STREQ("B.boo", walker.CurrentName());
    EXPECT(!walker.Down());

    // Inline expansion should show us the complete call chain:
    // mainA -> B.boo -> B.foo -> B.choo.
    walker.Reset(Profile::kExclusiveFunction);
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
    EXPECT_STREQ("[Unoptimized Code]", walker.CurrentName());
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
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should have 1 allocation sample.
    EXPECT_EQ(1, profile.sample_count());
    ProfileTrieWalker walker(&profile);

    walker.Reset(Profile::kExclusiveCode);
    // Move down from the root.
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

}  // namespace dart

