// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/timeline.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(TimelineEventIsValid) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

  TimelineEvent event;

  // Starts invalid.
  EXPECT(!event.IsValid());

  // Becomes valid.
  event.Instant(&stream, "hello");
  EXPECT(event.IsValid());

  // Becomes invalid.
  event.Reset();
  EXPECT(!event.IsValid());
}


TEST_CASE(TimelineEventDuration) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

  // Create a test event.
  TimelineEvent event;
  event.DurationBegin(&stream, "apple");
  // Measure the duration.
  int64_t current_duration = event.TimeDuration();
  event.DurationEnd();
  // Verify that duration is larger.
  EXPECT_GE(event.TimeDuration(), current_duration);
}


TEST_CASE(TimelineEventDurationPrintJSON) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

  // Create a test event.
  TimelineEvent event;
  event.DurationBegin(&stream, "apple");
  {
    // Test printing to JSON.
    JSONStream js;
    event.PrintJSON(&js);
    // Check category
    EXPECT_SUBSTRING("\"cat\":\"testStream\"", js.ToCString());
    // Check name.
    EXPECT_SUBSTRING("\"name\":\"apple\"", js.ToCString());
    // Check phase.
    EXPECT_SUBSTRING("\"ph\":\"X\"", js.ToCString());
    // Check that ts key is present.
    EXPECT_SUBSTRING("\"ts\":", js.ToCString());
    // Check that dur key is present.
    EXPECT_SUBSTRING("\"dur\":", js.ToCString());
  }
  event.DurationEnd();
}


TEST_CASE(TimelineEventArguments) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

  // Create a test event.
  TimelineEvent event;

  // Allocate room for four arguments.
  event.SetNumArguments(4);
  // Reset.
  event.Reset();

  event.DurationBegin(&stream, "apple");
  event.SetNumArguments(2);
  event.CopyArgument(0, "arg1", "value1");
  event.CopyArgument(1, "arg2", "value2");
  event.DurationEnd();
}


TEST_CASE(TimelineEventArgumentsPrintJSON) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

  // Create a test event.
  TimelineEvent event;

  event.DurationBegin(&stream, "apple");
  event.SetNumArguments(2);
  event.CopyArgument(0, "arg1", "value1");
  event.CopyArgument(1, "arg2", "value2");
  event.DurationEnd();

  {
    // Test printing to JSON.
    JSONStream js;
    event.PrintJSON(&js);

    // Check both arguments.
    EXPECT_SUBSTRING("\"arg1\":\"value1\"", js.ToCString());
    EXPECT_SUBSTRING("\"arg2\":\"value2\"", js.ToCString());
  }
}


TEST_CASE(TimelineEventBufferPrintJSON) {
  Isolate* isolate = Isolate::Current();
  TimelineEventBuffer* buffer = isolate->timeline_event_buffer();
  JSONStream js;
  buffer->PrintJSON(&js);
  // Check the type. This test will fail if we ever make Timeline public.
  EXPECT_SUBSTRING("\"type\":\"_Timeline\"", js.ToCString());
  // Check that there is a traceEvents array.
  EXPECT_SUBSTRING("\"traceEvents\":[", js.ToCString());
}

}  // namespace dart
