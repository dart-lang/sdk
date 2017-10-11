// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if defined(DART_USE_TCMALLOC) && !defined(PRODUCT) && !defined(TARGET_ARCH_DBC)

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/malloc_hooks.h"
#include "vm/os.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"
#include "vm/unit_test.h"

namespace dart {

static void MallocHookTestBufferInitializer(volatile char* buffer,
                                            uintptr_t size) {
  // Run through the buffer and do something. If we don't do this and the memory
  // in buffer isn't touched, the tcmalloc hooks won't be called.
  for (uintptr_t i = 0; i < size; ++i) {
    buffer[i] = i;
  }
}

class EnableMallocHooksScope : public ValueObject {
 public:
  EnableMallocHooksScope() {
    OSThread::Current();  // Ensure not allocated during test.
    saved_enable_malloc_hooks_ = FLAG_profiler_native_memory;
    FLAG_profiler_native_memory = true;
    MallocHooks::InitOnce();
    MallocHooks::ResetStats();
  }

  ~EnableMallocHooksScope() {
    MallocHooks::TearDown();
    FLAG_profiler_native_memory = saved_enable_malloc_hooks_;
  }

 private:
  bool saved_enable_malloc_hooks_;
};

class EnableMallocHooksAndStacksScope : public EnableMallocHooksScope {
 public:
  EnableMallocHooksAndStacksScope() {
    OSThread::Current();  // Ensure not allocated during test.
    saved_enable_stack_traces_ = MallocHooks::stack_trace_collection_enabled();
    MallocHooks::set_stack_trace_collection_enabled(true);
    if (!FLAG_profiler) {
      FLAG_profiler = true;
      Profiler::InitOnce();
    }
    MallocHooks::ResetStats();
  }

  ~EnableMallocHooksAndStacksScope() {
    MallocHooks::set_stack_trace_collection_enabled(saved_enable_stack_traces_);
  }

 private:
  bool saved_enable_stack_traces_;
};

UNIT_TEST_CASE(BasicMallocHookTest) {
  EnableMallocHooksScope scope;

  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
  const intptr_t buffer_size = 10;
  char* buffer = new char[buffer_size];
  MallocHookTestBufferInitializer(buffer, buffer_size);

  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());

  delete[] buffer;
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
}

UNIT_TEST_CASE(FreeUnseenMemoryMallocHookTest) {
  EnableMallocHooksScope scope;

  const intptr_t pre_hook_buffer_size = 3;
  char* pre_hook_buffer = new char[pre_hook_buffer_size];
  MallocHookTestBufferInitializer(pre_hook_buffer, pre_hook_buffer_size);

  MallocHooks::ResetStats();
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());

  const intptr_t buffer_size = 10;
  char* buffer = new char[buffer_size];
  MallocHookTestBufferInitializer(buffer, buffer_size);

  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());

  delete[] pre_hook_buffer;
  EXPECT_EQ(1L, MallocHooks::allocation_count());
  EXPECT_EQ(static_cast<intptr_t>(sizeof(char) * buffer_size),
            MallocHooks::heap_allocated_memory_in_bytes());

  delete[] buffer;
  EXPECT_EQ(0L, MallocHooks::allocation_count());
  EXPECT_EQ(0L, MallocHooks::heap_allocated_memory_in_bytes());
}

VM_UNIT_TEST_CASE(StackTraceMallocHookSimpleTest) {
  EnableMallocHooksAndStacksScope scope;

  char* var = static_cast<char*>(malloc(16 * sizeof(char)));
  Sample* sample = MallocHooks::GetSample(var);
  EXPECT(sample != NULL);

  free(var);
  sample = MallocHooks::GetSample(var);
  EXPECT(sample == NULL);
}

static char* DART_NOINLINE StackTraceLengthHelper(uintptr_t* end_address) {
  char* var = static_cast<char*>(malloc(16 * sizeof(char)));
  *end_address = OS::GetProgramCounter();
  return var;
}

VM_UNIT_TEST_CASE(StackTraceMallocHookLengthTest) {
  EnableMallocHooksAndStacksScope scope;

  uintptr_t test_start_address =
      reinterpret_cast<uintptr_t>(Dart_TestStackTraceMallocHookLengthTest);
  uintptr_t helper_start_address =
      reinterpret_cast<uintptr_t>(StackTraceLengthHelper);
  uintptr_t helper_end_address = 0;

  char* var = StackTraceLengthHelper(&helper_end_address);
  Sample* sample = MallocHooks::GetSample(var);
  EXPECT(sample != NULL);
  uintptr_t test_end_address = OS::GetProgramCounter();

  // Ensure that all stack frames are where we expect them to be in the sample.
  // If they aren't, the kSkipCount constant in malloc_hooks.cc is likely
  // incorrect.
  uword address = sample->At(0);
  bool first_result =
      (helper_start_address <= address) && (helper_end_address >= address);
  EXPECT(first_result);
  address = sample->At(1);
  bool second_result =
      (test_start_address <= address) && (test_end_address >= address);
  EXPECT(second_result);

  if (!(first_result && second_result)) {
    OS::PrintErr(
        "If this test is failing, it's likely that the value set for"
        " the number of frames to skip in malloc_hooks.cc is "
        "incorrect for this configuration/platform. This value can be"
        " found in malloc_hooks.cc in the AllocationInfo class, and "
        "is stored in the kSkipCount constant.\n");
    OS::PrintErr("First result: %d Second Result: %d\n", first_result,
                 second_result);
    OS::PrintErr("Dumping sample stack trace:\n");
    sample->DumpStackTrace();
  }

  free(var);
}

ISOLATE_UNIT_TEST_CASE(StackTraceMallocHookSimpleJSONTest) {
  EnableMallocHooksAndStacksScope scope;

  ClearProfileVisitor cpv(Isolate::Current());
  Profiler::sample_buffer()->VisitSamples(&cpv);

  char* var = static_cast<char*>(malloc(16 * sizeof(char)));
  JSONStream js;
  ProfilerService::PrintNativeAllocationJSON(&js, Profile::kNoTags, -1, -1);
  const char* json = js.ToCString();

  // Check that all the stack frames from the current down to main are actually
  // present in the profile. This is just a simple sanity check to make sure
  // that the ProfileTrie has a representation of the stack trace collected when
  // var is allocated. More intense testing is already done in profiler_test.cc.
  EXPECT_SUBSTRING("\"dart::Dart_TestStackTraceMallocHookSimpleJSONTest()\"",
                   json);
  EXPECT_SUBSTRING("\"dart::TestCase::Run()\"", json);
  EXPECT_SUBSTRING("\"dart::TestCaseBase::RunTest()\"", json);
  EXPECT_SUBSTRING("\"main\"", json);

  free(var);
}

};  // namespace dart

#endif  // defined(DART_USE_TCMALLOC) && !defined(PRODUCT)
