// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/json_stream.h"
#include "vm/metrics.h"
#include "vm/unit_test.h"
// #include "vm/heap.h"

namespace dart {

#if !defined(PRODUCT)
VM_UNIT_TEST_CASE(Metric_Simple) {
  TestCase::CreateTestIsolate();
  {
    Metric metric;

    // Initialize metric.
    metric.InitInstance(Isolate::Current(), "a.b.c", "foobar",
                        Metric::kCounter);
    EXPECT_EQ(0, metric.value());
    metric.increment();
    EXPECT_EQ(1, metric.value());
    metric.set_value(44);
    EXPECT_EQ(44, metric.value());
  }
  Dart_ShutdownIsolate();
}

class MyMetric : public Metric {
 protected:
  int64_t Value() const {
    // 99 bytes.
    return 99;
  }

 public:
  // Just used for testing.
  int64_t LeakyValue() const { return Value(); }
};

VM_UNIT_TEST_CASE(Metric_OnDemand) {
  TestCase::CreateTestIsolate();
  {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    StackZone zone(thread);
    MyMetric metric;

    metric.InitInstance(Isolate::Current(), "a.b.c", "foobar", Metric::kByte);
    // value is still the default value.
    EXPECT_EQ(0, metric.value());
    // Call LeakyValue to confirm that Value returns constant 99.
    EXPECT_EQ(99, metric.LeakyValue());

    // Serialize to JSON.
    JSONStream js;
    metric.PrintJSON(&js);
    const char* json = js.ToCString();
    EXPECT_STREQ(
        "{\"type\":\"Counter\",\"name\":\"a.b.c\",\"description\":"
        "\"foobar\",\"unit\":\"byte\","
        "\"fixedId\":true,\"id\":\"metrics\\/native\\/a.b.c\""
        ",\"value\":99.0}",
        json);
  }
  Dart_ShutdownIsolate();
}
#endif  // !defined(PRODUCT)

ISOLATE_UNIT_TEST_CASE(Metric_EmbedderAPI) {
  {
    TransitionVMToNative transition(thread);

    const char* kScript = "void main() {}";
    Dart_Handle api_lib = TestCase::LoadTestScript(
        kScript, /*resolver=*/nullptr, RESOLVED_USER_TEST_URI);
    EXPECT_VALID(api_lib);
  }

  // Ensure we've done new/old GCs to ensure max metrics are initialized.
  String::New("<land-in-new-space>", Heap::kNew);
  thread->heap()->CollectGarbage(thread, GCType::kScavenge,
                                 GCReason::kDebugging);
  thread->heap()->CollectGarbage(thread, GCType::kMarkCompact,
                                 GCReason::kDebugging);

  // Ensure we've something live in new space.
  String::New("<land-in-new-space2>", Heap::kNew);

  EXPECT(thread->isolate_group()->GetHeapOldUsedMaxMetric()->Value() > 0);
  EXPECT(thread->isolate_group()->GetHeapOldCapacityMaxMetric()->Value() > 0);
  EXPECT(thread->isolate_group()->GetHeapNewUsedMaxMetric()->Value() > 0);
  EXPECT(thread->isolate_group()->GetHeapNewCapacityMaxMetric()->Value() > 0);
  EXPECT(thread->isolate_group()->GetHeapGlobalUsedMetric()->Value() > 0);
  EXPECT(thread->isolate_group()->GetHeapGlobalUsedMaxMetric()->Value() > 0);

  {
    TransitionVMToNative transition(thread);

    Dart_IsolateGroup isolate_group = Dart_CurrentIsolateGroup();
    EXPECT(Dart_IsolateGroupHeapOldUsedMetric(isolate_group) > 0);
    EXPECT(Dart_IsolateGroupHeapOldCapacityMetric(isolate_group) > 0);
    EXPECT(Dart_IsolateGroupHeapNewUsedMetric(isolate_group) > 0);
    EXPECT(Dart_IsolateGroupHeapNewCapacityMetric(isolate_group) > 0);
  }
}

}  // namespace dart
