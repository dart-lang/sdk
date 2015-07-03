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
      lib.LookupClass(String::Handle(Symbols::New(name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.raw();
}


class AllocationFilter : public SampleFilter {
 public:
  explicit AllocationFilter(Isolate* isolate, intptr_t cid)
      : SampleFilter(isolate),
        cid_(cid) {
  }

  bool FilterSample(Sample* sample) {
    return sample->is_allocation_sample() && (sample->allocation_cid() == cid_);
  }

 private:
  intptr_t cid_;
};


TEST_CASE(Profiler_TrivialRecordAllocation) {
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
    Isolate* isolate = Isolate::Current();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
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
    Isolate* isolate = Isolate::Current();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
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
    Isolate* isolate = Isolate::Current();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
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
    Isolate* isolate = Isolate::Current();
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    Profile profile(isolate);
    AllocationFilter filter(isolate, class_a.id());
    profile.Build(&filter, Profile::kNoTags);
    // We should still only have one allocation sample.
    EXPECT_EQ(1, profile.sample_count());
  }
}

}  // namespace dart
