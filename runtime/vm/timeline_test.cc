// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstring>

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/timeline.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

template <class T>
class TimelineRecorderOverride : public ValueObject {
 public:
  TimelineRecorderOverride() : recorder_(Timeline::recorder()) {
    Timeline::recorder_ = new T();
  }

  explicit TimelineRecorderOverride(T* recorder)
      : recorder_(Timeline::recorder()) {
    Timeline::recorder_ = recorder;
  }

  ~TimelineRecorderOverride() {
    Timeline::Clear();
    delete Timeline::recorder_;
    Timeline::recorder_ = recorder_;
  }

  T* recorder() { return static_cast<T*>(Timeline::recorder()); }

 private:
  TimelineEventRecorder* recorder_;
};

class TimelineTestHelper : public AllStatic {
 public:
  static void SetStream(TimelineEvent* event, TimelineStream* stream) {
    event->StreamInit(stream);
  }

  static void FakeThreadEvent(TimelineEventBlock* block,
                              intptr_t ftid,
                              const char* label = "fake",
                              TimelineStream* stream = NULL) {
    TimelineEvent* event = block->StartEvent();
    ASSERT(event != NULL);
    event->DurationBegin(label);
    event->thread_ = OSThread::ThreadIdFromIntPtr(ftid);
    if (stream != NULL) {
      event->StreamInit(stream);
    }
  }

  static void SetBlockThread(TimelineEventBlock* block, intptr_t ftid) {
    block->thread_id_ = OSThread::ThreadIdFromIntPtr(ftid);
  }

  static void FakeDuration(TimelineEventRecorder* recorder,
                           const char* label,
                           int64_t start,
                           int64_t end) {
    ASSERT(recorder != NULL);
    ASSERT(start < end);
    ASSERT(label != NULL);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != NULL);
    event->Duration(label, start, end);
    event->Complete();
  }

  static void FakeBegin(TimelineEventRecorder* recorder,
                        const char* label,
                        int64_t start) {
    ASSERT(recorder != NULL);
    ASSERT(label != NULL);
    ASSERT(start >= 0);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != NULL);
    event->Begin(label, start);
    event->Complete();
  }

  static void FakeEnd(TimelineEventRecorder* recorder,
                      const char* label,
                      int64_t end) {
    ASSERT(recorder != NULL);
    ASSERT(label != NULL);
    ASSERT(end >= 0);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != NULL);
    event->End(label, end);
    event->Complete();
  }

  static void FinishBlock(TimelineEventBlock* block) { block->Finish(); }
};

TEST_CASE(TimelineEventIsValid) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);

  // Starts invalid.
  EXPECT(!event.IsValid());

  // Becomes valid.
  event.Instant("hello");
  EXPECT(event.IsValid());

  // Becomes invalid.
  event.Reset();
  EXPECT(!event.IsValid());
}

TEST_CASE(TimelineEventDuration) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);
  event.DurationBegin("apple");
  // Measure the duration.
  int64_t current_duration = event.TimeDuration();
  event.DurationEnd();
  // Verify that duration is larger.
  EXPECT_GE(event.TimeDuration(), current_duration);
}

TEST_CASE(TimelineEventDurationPrintJSON) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);
  event.DurationBegin("apple");
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

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
TEST_CASE(TimelineEventPrintSystrace) {
  const intptr_t kBufferLength = 1024;
  char buffer[kBufferLength];

  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);

  // Test a Begin event.
  event.Begin("apple", 1, 2);
  TimelineEventSystraceRecorder::PrintSystrace(&event, &buffer[0],
                                               kBufferLength);
  EXPECT_SUBSTRING("|apple", buffer);
  EXPECT_SUBSTRING("B|", buffer);

  // Test an End event.
  event.End("apple", 2, 3);
  TimelineEventSystraceRecorder::PrintSystrace(&event, &buffer[0],
                                               kBufferLength);
  EXPECT_STREQ("E", buffer);

  // Test a Counter event. We only report the first counter value (in this case
  // "4").
  event.Counter("CTR", 1);
  // We have two counters.
  event.SetNumArguments(2);
  // Set the first counter value.
  event.CopyArgument(0, "cats", "4");
  // Set the second counter value.
  event.CopyArgument(1, "dogs", "1");
  TimelineEventSystraceRecorder::PrintSystrace(&event, &buffer[0],
                                               kBufferLength);
  EXPECT_SUBSTRING("C|", buffer);
  EXPECT_SUBSTRING("|CTR|4", buffer);

  // Test a duration event. This event kind is not supported so we should
  // serialize it to an empty string.
  event.Duration("DUR", 0, 1, 2, 3);
  TimelineEventSystraceRecorder::PrintSystrace(&event, &buffer[0],
                                               kBufferLength);
  EXPECT_STREQ("", buffer);
}
#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)

TEST_CASE(TimelineEventArguments) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);

  // Allocate room for four arguments.
  event.SetNumArguments(4);
  // Reset.
  event.Reset();

  event.DurationBegin("apple");
  event.SetNumArguments(2);
  event.CopyArgument(0, "arg1", "value1");
  event.CopyArgument(1, "arg2", "value2");
  event.DurationEnd();
}

TEST_CASE(TimelineEventArgumentsPrintJSON) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);

  event.DurationBegin("apple");
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
  JSONStream js;
  TimelineEventFilter filter;
  Timeline::recorder()->PrintJSON(&js, &filter);
  // Check the type.
  EXPECT_SUBSTRING("\"type\":\"Timeline\"", js.ToCString());
  // Check that there is a traceEvents array.
  EXPECT_SUBSTRING("\"traceEvents\":[", js.ToCString());
}

// Count the number of each event type seen.
class EventCounterRecorder : public TimelineEventCallbackRecorder {
 public:
  EventCounterRecorder() {
    for (intptr_t i = 0; i < TimelineEvent::kNumEventTypes; i++) {
      counts_[i] = 0;
    }
  }

  void OnEvent(TimelineEvent* event) { counts_[event->event_type()]++; }

  intptr_t CountFor(TimelineEvent::EventType type) { return counts_[type]; }

  intptr_t Size() { return -1; }

 private:
  intptr_t counts_[TimelineEvent::kNumEventTypes];
};

TEST_CASE(TimelineEventCallbackRecorderBasic) {
  TimelineRecorderOverride<EventCounterRecorder> override;

  // Initial counts are all zero.
  for (intptr_t i = TimelineEvent::kNone + 1; i < TimelineEvent::kNumEventTypes;
       i++) {
    EXPECT_EQ(0, override.recorder()->CountFor(
                     static_cast<TimelineEvent::EventType>(i)));
  }

  // Create a test stream.
  TimelineStream stream("testStream", "testStream", true);

  TimelineEvent* event = NULL;

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kDuration));
  event->DurationBegin("cabbage");
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kDuration));
  event->DurationEnd();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kDuration));
  event->Complete();
  EXPECT_EQ(1, override.recorder()->CountFor(TimelineEvent::kDuration));

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kInstant));
  event->Instant("instantCabbage");
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kInstant));
  event->Complete();
  EXPECT_EQ(1, override.recorder()->CountFor(TimelineEvent::kInstant));

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncBegin));
  int64_t async_id = override.recorder()->GetNextAsyncId();
  EXPECT(async_id >= 0);
  event->AsyncBegin("asyncBeginCabbage", async_id);
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncBegin));
  event->Complete();
  EXPECT_EQ(1, override.recorder()->CountFor(TimelineEvent::kAsyncBegin));

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncInstant));
  event->AsyncInstant("asyncInstantCabbage", async_id);
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncInstant));
  event->Complete();
  EXPECT_EQ(1, override.recorder()->CountFor(TimelineEvent::kAsyncInstant));

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncEnd));
  event->AsyncEnd("asyncEndCabbage", async_id);
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kAsyncEnd));
  event->Complete();
  EXPECT_EQ(1, override.recorder()->CountFor(TimelineEvent::kAsyncEnd));
}

TEST_CASE(TimelineRingRecorderJSONOrder) {
  TimelineStream stream("testStream", "testStream", true);

  TimelineEventRingRecorder* recorder =
      new TimelineEventRingRecorder(TimelineEventBlock::kBlockSize * 2);
  TimelineRecorderOverride<TimelineEventRingRecorder> override(recorder);

  TimelineEventBlock* block_0 = Timeline::recorder()->GetNewBlock();
  EXPECT(block_0 != NULL);
  TimelineEventBlock* block_1 = Timeline::recorder()->GetNewBlock();
  EXPECT(block_1 != NULL);
  // Test that we wrapped.
  EXPECT(block_0 == Timeline::recorder()->GetNewBlock());

  // Emit the earlier event into block_1.
  TimelineTestHelper::FakeThreadEvent(block_1, 2, "Alpha", &stream);
  OS::Sleep(32);
  // Emit the later event into block_0.
  TimelineTestHelper::FakeThreadEvent(block_0, 2, "Beta", &stream);

  TimelineTestHelper::FinishBlock(block_0);
  TimelineTestHelper::FinishBlock(block_1);

  JSONStream js;
  TimelineEventFilter filter;
  Timeline::recorder()->PrintJSON(&js, &filter);
  // trace-event has a requirement that events for a thread must have
  // monotonically increasing timestamps.
  // Verify that "Alpha" comes before "Beta" even though "Beta" is in the first
  // block.
  const char* alpha = strstr(js.ToCString(), "Alpha");
  const char* beta = strstr(js.ToCString(), "Beta");
  EXPECT(alpha < beta);
}

#endif  // !PRODUCT

}  // namespace dart
