// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/timeline.h"
#include "vm/timeline_analysis.h"
#include "vm/unit_test.h"

namespace dart {

class TimelineTestHelper : public AllStatic {
 public:
  static void SetStream(TimelineEvent* event, TimelineStream* stream) {
    event->StreamInit(stream);
  }

  static TimelineEvent* FakeThreadEvent(
      TimelineEventBlock* block, intptr_t ftid) {
    TimelineEvent* event = block->StartEvent();
    ASSERT(event != NULL);
    event->DurationBegin("fake");
    event->thread_ = OSThread::ThreadIdFromIntPtr(ftid);
    return event;
  }
};


TEST_CASE(TimelineEventIsValid) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

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
  TimelineStream stream;
  stream.Init("testStream", true);

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
  TimelineStream stream;
  stream.Init("testStream", true);

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


TEST_CASE(TimelineEventArguments) {
  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

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
  TimelineStream stream;
  stream.Init("testStream", true);

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
  Isolate* isolate = Isolate::Current();
  TimelineEventRecorder* recorder = isolate->timeline_event_recorder();
  JSONStream js;
  recorder->PrintJSON(&js);
  // Check the type. This test will fail if we ever make Timeline public.
  EXPECT_SUBSTRING("\"type\":\"_Timeline\"", js.ToCString());
  // Check that there is a traceEvents array.
  EXPECT_SUBSTRING("\"traceEvents\":[", js.ToCString());
}


// Count the number of each event type seen.
class EventCounterRecorder : public TimelineEventStreamingRecorder {
 public:
  EventCounterRecorder() {
    for (intptr_t i = 0; i < TimelineEvent::kNumEventTypes; i++) {
      counts_[i] = 0;
    }
  }

  void StreamEvent(TimelineEvent* event) {
    counts_[event->event_type()]++;
  }

  intptr_t CountFor(TimelineEvent::EventType type) {
    return counts_[type];
  }

 private:
  intptr_t counts_[TimelineEvent::kNumEventTypes];
};


TEST_CASE(TimelineEventStreamingRecorderBasic) {
  EventCounterRecorder* recorder = new EventCounterRecorder();

  // Initial counts are all zero.
  for (intptr_t i = TimelineEvent::kNone + 1;
       i < TimelineEvent::kNumEventTypes;
       i++) {
    EXPECT_EQ(0, recorder->CountFor(static_cast<TimelineEvent::EventType>(i)));
  }

  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);
  stream.set_recorder(recorder);

  TimelineEvent* event = NULL;

  event = stream.StartEvent();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kDuration));
  event->DurationBegin("cabbage");
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kDuration));
  event->DurationEnd();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kDuration));
  event->Complete();
  EXPECT_EQ(1, recorder->CountFor(TimelineEvent::kDuration));

  event = stream.StartEvent();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kInstant));
  event->Instant("instantCabbage");
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kInstant));
  event->Complete();
  EXPECT_EQ(1, recorder->CountFor(TimelineEvent::kInstant));

  event = stream.StartEvent();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncBegin));
  int64_t async_id = event->AsyncBegin("asyncBeginCabbage");
  EXPECT(async_id >= 0);
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncBegin));
  event->Complete();
  EXPECT_EQ(1, recorder->CountFor(TimelineEvent::kAsyncBegin));

  event = stream.StartEvent();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncInstant));
  event->AsyncInstant("asyncInstantCabbage", async_id);
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncInstant));
  event->Complete();
  EXPECT_EQ(1, recorder->CountFor(TimelineEvent::kAsyncInstant));

  event = stream.StartEvent();
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncEnd));
  event->AsyncEnd("asyncEndCabbage", async_id);
  EXPECT_EQ(0, recorder->CountFor(TimelineEvent::kAsyncEnd));
  event->Complete();
  EXPECT_EQ(1, recorder->CountFor(TimelineEvent::kAsyncEnd));
}


TEST_CASE(TimelineAnalysis_ThreadBlockCount) {
  TimelineEventEndlessRecorder* recorder = new TimelineEventEndlessRecorder();
  ASSERT(recorder != NULL);
  // Blocks owned by thread "1".
  TimelineEventBlock* block_1_0 = recorder->GetNewBlock();
  TimelineEventBlock* block_1_1 = recorder->GetNewBlock();
  TimelineEventBlock* block_1_2 = recorder->GetNewBlock();
  // Blocks owned by thread "2".
  TimelineEventBlock* block_2_0 = recorder->GetNewBlock();
  // Blocks owned by thread "3".
  TimelineEventBlock* block_3_0 = recorder->GetNewBlock();
  USE(block_3_0);

  // Add events to each block for thread 1.
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1);
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1);
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1);
  // Sleep to ensure timestamps differ.
  OS::Sleep(1);
  TimelineTestHelper::FakeThreadEvent(block_1_0, 1);
  OS::Sleep(1);
  TimelineTestHelper::FakeThreadEvent(block_1_1, 1);
  TimelineTestHelper::FakeThreadEvent(block_1_1, 1);
  OS::Sleep(1);

  // Add events to each block for thread 2.
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2);

  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  // Discover threads in recorder.
  TimelineAnalysis ta(zone, isolate, recorder);
  ta.BuildThreads();
  // block_3_0 is never used by a thread, so we only have two threads.
  EXPECT_EQ(2, ta.NumThreads());

  // Extract both threads.
  TimelineAnalysisThread* thread_1 =
      ta.GetThread(OSThread::ThreadIdFromIntPtr(1));
  TimelineAnalysisThread* thread_2 =
      ta.GetThread(OSThread::ThreadIdFromIntPtr(2));
  EXPECT_EQ(OSThread::ThreadIdFromIntPtr(1), thread_1->id());
  EXPECT_EQ(OSThread::ThreadIdFromIntPtr(2), thread_2->id());

  // Thread "1" should have three blocks.
  EXPECT_EQ(3, thread_1->NumBlocks());

  // Verify that blocks for thread "1" are sorted based on start time.
  EXPECT_EQ(thread_1->At(0), block_1_2);
  EXPECT_EQ(thread_1->At(1), block_1_0);
  EXPECT_EQ(thread_1->At(2), block_1_1);

  // Verify that block_1_2 has three events.
  EXPECT_EQ(3, block_1_2->length());

  // Verify that block_1_0 has one events.
  EXPECT_EQ(1, block_1_0->length());

  // Verify that block_1_1 has two events.
  EXPECT_EQ(2, block_1_1->length());

  // Thread '2" should have one block.'
  EXPECT_EQ(1, thread_2->NumBlocks());
  EXPECT_EQ(thread_2->At(0), block_2_0);
  // Verify that block_2_0 has six events.
  EXPECT_EQ(6, block_2_0->length());
}

}  // namespace dart
