// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/json_stream.h"
#include "vm/metrics.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

UNIT_TEST_CASE(Metric_Simple) {
  Dart_CreateIsolate(NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL,
                     NULL);
  {
    Metric metric;

    // Initialize metric.
    metric.Init(Isolate::Current(), "a.b.c", "foobar", Metric::kCounter);
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

UNIT_TEST_CASE(Metric_OnDemand) {
  Dart_CreateIsolate(NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL,
                     NULL);
  {
    Thread* thread = Thread::Current();
    StackZone zone(thread);
    HANDLESCOPE(thread);
    MyMetric metric;

    metric.Init(Isolate::Current(), "a.b.c", "foobar", Metric::kByte);
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
        ",\"value\":99.000000}",
        json);
  }
  Dart_ShutdownIsolate();
}

#endif  // !PRODUCT

}  // namespace dart
