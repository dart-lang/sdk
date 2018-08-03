// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstring>

#include "platform/assert.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/globals.h"
#include "vm/timeline.h"
#include "vm/timeline_analysis.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

class TimelineRecorderOverride : public ValueObject {
 public:
  explicit TimelineRecorderOverride(TimelineEventRecorder* new_recorder)
      : recorder_(Timeline::recorder()) {
    Timeline::recorder_ = new_recorder;
  }

  ~TimelineRecorderOverride() { Timeline::recorder_ = recorder_; }

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

  static void Clear(TimelineEventRecorder* recorder) {
    ASSERT(recorder != NULL);
    recorder->Clear();
  }

  static void FinishBlock(TimelineEventBlock* block) { block->Finish(); }
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

#if defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX)
TEST_CASE(TimelineEventPrintSystrace) {
  const intptr_t kBufferLength = 1024;
  char buffer[kBufferLength];

  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

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
#endif  // defined(HOST_OS_ANDROID) || defined(HOST_OS_LINUX)

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
  TimelineEventRecorder* recorder = Timeline::recorder();
  JSONStream js;
  TimelineEventFilter filter;
  recorder->PrintJSON(&js, &filter);
  // Check the type. This test will fail if we ever make Timeline public.
  EXPECT_SUBSTRING("\"type\":\"_Timeline\"", js.ToCString());
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

 private:
  intptr_t counts_[TimelineEvent::kNumEventTypes];
};

TEST_CASE(TimelineEventCallbackRecorderBasic) {
  EventCounterRecorder* recorder = new EventCounterRecorder();
  TimelineRecorderOverride override(recorder);

  // Initial counts are all zero.
  for (intptr_t i = TimelineEvent::kNone + 1; i < TimelineEvent::kNumEventTypes;
       i++) {
    EXPECT_EQ(0, recorder->CountFor(static_cast<TimelineEvent::EventType>(i)));
  }

  // Create a test stream.
  TimelineStream stream;
  stream.Init("testStream", true);

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
  int64_t async_id = recorder->GetNextAsyncId();
  EXPECT(async_id >= 0);
  event->AsyncBegin("asyncBeginCabbage", async_id);
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

  delete recorder;
}

static bool LabelMatch(TimelineEvent* event, const char* label) {
  ASSERT(event != NULL);
  return strcmp(event->label(), label) == 0;
}

TEST_CASE(TimelineAnalysis_ThreadBlockCount) {
  TimelineEventEndlessRecorder* recorder = new TimelineEventEndlessRecorder();
  ASSERT(recorder != NULL);
  // Blocks owned by thread "1".
  TimelineEventBlock* block_1_0 = recorder->GetNewBlock();
  TimelineTestHelper::SetBlockThread(block_1_0, 1);
  TimelineEventBlock* block_1_1 = recorder->GetNewBlock();
  TimelineTestHelper::SetBlockThread(block_1_1, 1);
  TimelineEventBlock* block_1_2 = recorder->GetNewBlock();
  TimelineTestHelper::SetBlockThread(block_1_2, 1);
  // Blocks owned by thread "2".
  TimelineEventBlock* block_2_0 = recorder->GetNewBlock();
  TimelineTestHelper::SetBlockThread(block_2_0, 2);
  // Blocks owned by thread "3".
  TimelineEventBlock* block_3_0 = recorder->GetNewBlock();
  TimelineTestHelper::SetBlockThread(block_3_0, 3);
  USE(block_3_0);

  // Add events to each block for thread 1.
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1, "B1");
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1, "B2");
  TimelineTestHelper::FakeThreadEvent(block_1_2, 1, "B3");
  // Sleep to ensure timestamps differ.
  OS::Sleep(32);
  TimelineTestHelper::FakeThreadEvent(block_1_0, 1, "A1");
  OS::Sleep(32);
  TimelineTestHelper::FakeThreadEvent(block_1_1, 1, "C1");
  TimelineTestHelper::FakeThreadEvent(block_1_1, 1, "C2");
  OS::Sleep(32);

  // Add events to each block for thread 2.
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "A");
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "B");
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "C");
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "D");
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "E");
  TimelineTestHelper::FakeThreadEvent(block_2_0, 2, "F");

  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();

  // Discover threads in recorder.
  TimelineAnalysis ta(zone, isolate, recorder);
  ta.BuildThreads();
  EXPECT(!ta.has_error());
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

  {
    TimelineAnalysisThreadEventIterator it(thread_1);
    // Six events spread across three blocks.
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "B1"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "B2"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "B3"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "A1"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "C1"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "C2"));
    EXPECT(!it.HasNext());
  }

  {
    TimelineAnalysisThreadEventIterator it(thread_2);
    // Six events spread across three blocks.
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "A"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "B"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "C"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "D"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "E"));
    EXPECT(it.HasNext());
    EXPECT(LabelMatch(it.Next(), "F"));
    EXPECT(!it.HasNext());
  }

  TimelineTestHelper::Clear(recorder);
  delete recorder;
}

TEST_CASE(TimelineRingRecorderJSONOrder) {
  TimelineStream stream;
  stream.Init("testStream", true);

  TimelineEventRingRecorder* recorder =
      new TimelineEventRingRecorder(TimelineEventBlock::kBlockSize * 2);

  TimelineEventBlock* block_0 = recorder->GetNewBlock();
  EXPECT(block_0 != NULL);
  TimelineEventBlock* block_1 = recorder->GetNewBlock();
  EXPECT(block_1 != NULL);
  // Test that we wrapped.
  EXPECT(block_0 == recorder->GetNewBlock());

  // Emit the earlier event into block_1.
  TimelineTestHelper::FakeThreadEvent(block_1, 2, "Alpha", &stream);
  OS::Sleep(32);
  // Emit the later event into block_0.
  TimelineTestHelper::FakeThreadEvent(block_0, 2, "Beta", &stream);

  TimelineTestHelper::FinishBlock(block_0);
  TimelineTestHelper::FinishBlock(block_1);

  JSONStream js;
  TimelineEventFilter filter;
  recorder->PrintJSON(&js, &filter);
  // trace-event has a requirement that events for a thread must have
  // monotonically increasing timestamps.
  // Verify that "Alpha" comes before "Beta" even though "Beta" is in the first
  // block.
  const char* alpha = strstr(js.ToCString(), "Alpha");
  const char* beta = strstr(js.ToCString(), "Beta");
  EXPECT(alpha < beta);

  TimelineTestHelper::Clear(recorder);
  delete recorder;
}

TEST_CASE(TimelinePauses_Basic) {
  TimelineEventEndlessRecorder* recorder = new TimelineEventEndlessRecorder();
  ASSERT(recorder != NULL);
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  ThreadId tid = os_thread->trace_id();

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(10, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxExclusiveTime("a"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "b", 0, 10);
  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(10, pauses.InclusiveTime("b"));
    EXPECT_EQ(10, pauses.ExclusiveTime("b"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(10, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "b", 1, 8);
  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(3, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(3, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(7, pauses.InclusiveTime("b"));
    EXPECT_EQ(7, pauses.ExclusiveTime("b"));
    EXPECT_EQ(7, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(7, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "b", 0, 1);
  TimelineTestHelper::FakeDuration(recorder, "b", 1, 2);
  TimelineTestHelper::FakeDuration(recorder, "b", 2, 3);
  TimelineTestHelper::FakeDuration(recorder, "b", 3, 4);
  TimelineTestHelper::FakeDuration(recorder, "b", 4, 5);
  TimelineTestHelper::FakeDuration(recorder, "b", 5, 6);
  TimelineTestHelper::FakeDuration(recorder, "b", 6, 7);
  TimelineTestHelper::FakeDuration(recorder, "b", 7, 8);
  TimelineTestHelper::FakeDuration(recorder, "b", 8, 9);
  TimelineTestHelper::FakeDuration(recorder, "b", 9, 10);
  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(10, pauses.InclusiveTime("b"));
    EXPECT_EQ(10, pauses.ExclusiveTime("b"));
    EXPECT_EQ(1, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(1, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "b", 0, 5);
  TimelineTestHelper::FakeDuration(recorder, "c", 1, 4);
  TimelineTestHelper::FakeDuration(recorder, "d", 5, 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(5, pauses.InclusiveTime("b"));
    EXPECT_EQ(2, pauses.ExclusiveTime("b"));
    EXPECT_EQ(5, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("b"));
    EXPECT_EQ(3, pauses.InclusiveTime("c"));
    EXPECT_EQ(3, pauses.ExclusiveTime("c"));
    EXPECT_EQ(3, pauses.MaxInclusiveTime("c"));
    EXPECT_EQ(3, pauses.MaxExclusiveTime("c"));
    EXPECT_EQ(5, pauses.InclusiveTime("d"));
    EXPECT_EQ(5, pauses.ExclusiveTime("d"));
    EXPECT_EQ(5, pauses.MaxInclusiveTime("d"));
    EXPECT_EQ(5, pauses.MaxExclusiveTime("d"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "b", 1, 9);
  TimelineTestHelper::FakeDuration(recorder, "c", 2, 8);
  TimelineTestHelper::FakeDuration(recorder, "d", 3, 7);
  TimelineTestHelper::FakeDuration(recorder, "e", 4, 6);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(2, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(8, pauses.InclusiveTime("b"));
    EXPECT_EQ(2, pauses.ExclusiveTime("b"));
    EXPECT_EQ(8, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("b"));
    EXPECT_EQ(6, pauses.InclusiveTime("c"));
    EXPECT_EQ(2, pauses.ExclusiveTime("c"));
    EXPECT_EQ(6, pauses.MaxInclusiveTime("c"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("c"));
    EXPECT_EQ(4, pauses.InclusiveTime("d"));
    EXPECT_EQ(2, pauses.ExclusiveTime("d"));
    EXPECT_EQ(4, pauses.MaxInclusiveTime("d"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("d"));
    EXPECT_EQ(2, pauses.InclusiveTime("e"));
    EXPECT_EQ(2, pauses.ExclusiveTime("e"));
    EXPECT_EQ(2, pauses.MaxInclusiveTime("e"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("e"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeDuration(recorder, "a", 0, 10);
  TimelineTestHelper::FakeDuration(recorder, "a", 1, 9);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(10, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(8, pauses.MaxExclusiveTime("a"));
  }
  TimelineTestHelper::Clear(recorder);

  delete recorder;
}

TEST_CASE(TimelinePauses_BeginEnd) {
  TimelineEventEndlessRecorder* recorder = new TimelineEventEndlessRecorder();
  ASSERT(recorder != NULL);
  Zone* zone = thread->zone();
  Isolate* isolate = thread->isolate();
  OSThread* os_thread = thread->os_thread();
  ASSERT(os_thread != NULL);
  ThreadId tid = os_thread->trace_id();

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(10, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxExclusiveTime("a"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "b", 0);
  TimelineTestHelper::FakeEnd(recorder, "b", 10);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(10, pauses.InclusiveTime("b"));
    EXPECT_EQ(10, pauses.ExclusiveTime("b"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(10, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "b", 1);
  TimelineTestHelper::FakeEnd(recorder, "b", 8);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(3, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(3, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(7, pauses.InclusiveTime("b"));
    EXPECT_EQ(7, pauses.ExclusiveTime("b"));
    EXPECT_EQ(7, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(7, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeDuration(recorder, "b", 0, 1);
  TimelineTestHelper::FakeDuration(recorder, "b", 1, 2);
  TimelineTestHelper::FakeDuration(recorder, "b", 2, 3);
  TimelineTestHelper::FakeBegin(recorder, "b", 3);
  TimelineTestHelper::FakeEnd(recorder, "b", 4);
  TimelineTestHelper::FakeDuration(recorder, "b", 4, 5);
  TimelineTestHelper::FakeDuration(recorder, "b", 5, 6);
  TimelineTestHelper::FakeDuration(recorder, "b", 6, 7);
  TimelineTestHelper::FakeBegin(recorder, "b", 7);
  TimelineTestHelper::FakeEnd(recorder, "b", 8);
  TimelineTestHelper::FakeBegin(recorder, "b", 8);
  TimelineTestHelper::FakeEnd(recorder, "b", 9);
  TimelineTestHelper::FakeDuration(recorder, "b", 9, 10);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(10, pauses.InclusiveTime("b"));
    EXPECT_EQ(10, pauses.ExclusiveTime("b"));
    EXPECT_EQ(1, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(1, pauses.MaxExclusiveTime("b"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "b", 0);
  TimelineTestHelper::FakeBegin(recorder, "c", 1);
  TimelineTestHelper::FakeEnd(recorder, "c", 4);
  TimelineTestHelper::FakeEnd(recorder, "b", 5);
  TimelineTestHelper::FakeBegin(recorder, "d", 5);
  TimelineTestHelper::FakeEnd(recorder, "d", 10);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(0, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(0, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(5, pauses.InclusiveTime("b"));
    EXPECT_EQ(2, pauses.ExclusiveTime("b"));
    EXPECT_EQ(5, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("b"));
    EXPECT_EQ(3, pauses.InclusiveTime("c"));
    EXPECT_EQ(3, pauses.ExclusiveTime("c"));
    EXPECT_EQ(3, pauses.MaxInclusiveTime("c"));
    EXPECT_EQ(3, pauses.MaxExclusiveTime("c"));
    EXPECT_EQ(5, pauses.InclusiveTime("d"));
    EXPECT_EQ(5, pauses.ExclusiveTime("d"));
    EXPECT_EQ(5, pauses.MaxInclusiveTime("d"));
    EXPECT_EQ(5, pauses.MaxExclusiveTime("d"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "b", 1);
  TimelineTestHelper::FakeBegin(recorder, "c", 2);
  TimelineTestHelper::FakeBegin(recorder, "d", 3);
  TimelineTestHelper::FakeBegin(recorder, "e", 4);
  TimelineTestHelper::FakeEnd(recorder, "e", 6);
  TimelineTestHelper::FakeEnd(recorder, "d", 7);
  TimelineTestHelper::FakeEnd(recorder, "c", 8);
  TimelineTestHelper::FakeEnd(recorder, "b", 9);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(2, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("a"));
    EXPECT_EQ(8, pauses.InclusiveTime("b"));
    EXPECT_EQ(2, pauses.ExclusiveTime("b"));
    EXPECT_EQ(8, pauses.MaxInclusiveTime("b"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("b"));
    EXPECT_EQ(6, pauses.InclusiveTime("c"));
    EXPECT_EQ(2, pauses.ExclusiveTime("c"));
    EXPECT_EQ(6, pauses.MaxInclusiveTime("c"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("c"));
    EXPECT_EQ(4, pauses.InclusiveTime("d"));
    EXPECT_EQ(2, pauses.ExclusiveTime("d"));
    EXPECT_EQ(4, pauses.MaxInclusiveTime("d"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("d"));
    EXPECT_EQ(2, pauses.InclusiveTime("e"));
    EXPECT_EQ(2, pauses.ExclusiveTime("e"));
    EXPECT_EQ(2, pauses.MaxInclusiveTime("e"));
    EXPECT_EQ(2, pauses.MaxExclusiveTime("e"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "a", 1);
  TimelineTestHelper::FakeEnd(recorder, "a", 9);
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(!pauses.has_error());
    EXPECT_EQ(10, pauses.InclusiveTime("a"));
    EXPECT_EQ(10, pauses.ExclusiveTime("a"));
    EXPECT_EQ(10, pauses.MaxInclusiveTime("a"));
    EXPECT_EQ(8, pauses.MaxExclusiveTime("a"));
  }
  TimelineTestHelper::Clear(recorder);

  // Test case.
  TimelineTestHelper::FakeBegin(recorder, "a", 0);
  TimelineTestHelper::FakeBegin(recorder, "b", 1);
  // Pop "a" without popping "b" first.
  TimelineTestHelper::FakeEnd(recorder, "a", 10);

  {
    TimelinePauses pauses(zone, isolate, recorder);
    pauses.Setup();
    pauses.CalculatePauseTimesForThread(tid);
    EXPECT(pauses.has_error());
  }
  TimelineTestHelper::Clear(recorder);

  delete recorder;
}

#endif  // !PRODUCT

}  // namespace dart
