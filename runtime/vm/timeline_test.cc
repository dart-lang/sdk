// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstring>
#include <memory>

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

  static Mutex& GetRecorderLock(TimelineEventRecorder& recorder) {
    return recorder.lock_;
  }

  static void FakeThreadEvent(TimelineEventBlock* block,
                              intptr_t ftid,
                              const char* label = "fake",
                              TimelineStream* stream = nullptr) {
    OSThread& current_thread = *OSThread::Current();
    MutexLocker ml(current_thread.timeline_block_lock());
    TimelineEvent* event = block->StartEventLocked();
    ASSERT(event != nullptr);
    event->DurationBegin(label);
    event->thread_ = OSThread::ThreadIdFromIntPtr(ftid);
    if (stream != nullptr) {
      event->StreamInit(stream);
    }
  }

  static void FakeDuration(TimelineEventRecorder* recorder,
                           const char* label,
                           int64_t start,
                           int64_t end) {
    ASSERT(recorder != nullptr);
    ASSERT(start < end);
    ASSERT(label != nullptr);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != nullptr);
    event->Duration(label, start, end);
    recorder->CompleteEvent(event);
  }

  static void FakeBegin(TimelineEventRecorder* recorder,
                        const char* label,
                        int64_t start) {
    ASSERT(recorder != nullptr);
    ASSERT(label != nullptr);
    ASSERT(start >= 0);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != nullptr);
    event->Begin(label, /*id=*/-1, start);
    recorder->CompleteEvent(event);
  }

  static void FakeEnd(TimelineEventRecorder* recorder,
                      const char* label,
                      int64_t end) {
    ASSERT(recorder != nullptr);
    ASSERT(label != nullptr);
    ASSERT(end >= 0);
    TimelineEvent* event = recorder->StartEvent();
    ASSERT(event != nullptr);
    event->End(label, end);
    recorder->CompleteEvent(event);
  }

  static void FinishBlock(TimelineEventBlock* block) { block->Finish(); }
};

TEST_CASE(TimelineEventIsValid) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", false, true);

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
  TimelineStream stream("testStream", "testStream", false, true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);
  event.DurationBegin("apple");
  // Measure the duration.
  int64_t current_duration = event.TimeDuration();
  event.SetTimeEnd();
  // Verify that duration is larger.
  EXPECT_GE(event.TimeDuration(), current_duration);
}

TEST_CASE(TimelineEventDurationPrintJSON) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", false, true);

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
  event.SetTimeEnd();
}

#if defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)
TEST_CASE(TimelineEventPrintSystrace) {
  const intptr_t kBufferLength = 1024;
  char buffer[kBufferLength];

  // Create a test stream.
  TimelineStream stream("testStream", "testStream", false, true);

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
  event.Duration("DUR", 0, 1);
  TimelineEventSystraceRecorder::PrintSystrace(&event, &buffer[0],
                                               kBufferLength);
  EXPECT_STREQ("", buffer);
}
#endif  // defined(DART_HOST_OS_ANDROID) || defined(DART_HOST_OS_LINUX)

TEST_CASE(TimelineEventArguments) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", false, true);

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
  event.SetTimeEnd();
}

TEST_CASE(TimelineEventArgumentsPrintJSON) {
  // Create a test stream.
  TimelineStream stream("testStream", "testStream", false, true);

  // Create a test event.
  TimelineEvent event;
  TimelineTestHelper::SetStream(&event, &stream);

  event.DurationBegin("apple");
  event.SetNumArguments(2);
  event.CopyArgument(0, "arg1", "value1");
  event.CopyArgument(1, "arg2", "value2");
  event.SetTimeEnd();

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
  TimelineStream stream("testStream", "testStream", false, true);

  TimelineEvent* event = nullptr;

  event = stream.StartEvent();
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kDuration));
  event->DurationBegin("cabbage");
  EXPECT_EQ(0, override.recorder()->CountFor(TimelineEvent::kDuration));
  event->SetTimeEnd();
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
  int64_t async_id = thread->GetNextTaskId();
  EXPECT(async_id != 0);
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
  TimelineStream stream("testStream", "testStream", false, true);

  TimelineEventRingRecorder* recorder =
      new TimelineEventRingRecorder(TimelineEventBlock::kBlockSize * 2);
  TimelineRecorderOverride<TimelineEventRingRecorder> override(recorder);

  {
    Mutex& recorder_lock = TimelineTestHelper::GetRecorderLock(*recorder);
    MutexLocker ml(&recorder_lock);
    TimelineEventBlock* block_0 = Timeline::recorder()->GetNewBlockLocked();
    EXPECT(block_0 != nullptr);
    TimelineEventBlock* block_1 = Timeline::recorder()->GetNewBlockLocked();
    EXPECT(block_1 != nullptr);
    // Test that we wrapped.
    EXPECT(block_0 == Timeline::recorder()->GetNewBlockLocked());

    // Emit the earlier event into block_1.
    TimelineTestHelper::FakeThreadEvent(block_1, 2, "Alpha", &stream);
    OS::Sleep(32);
    // Emit the later event into block_0.
    TimelineTestHelper::FakeThreadEvent(block_0, 2, "Beta", &stream);

    TimelineTestHelper::FinishBlock(block_0);
    TimelineTestHelper::FinishBlock(block_1);
  }

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

TEST_CASE(TimelineRingRecorderRace) {
  struct ReportEventsArguments {
    Monitor& synchronization_monitor;
    TimelineEventRecorder& recorder;
    ThreadJoinId join_id = OSThread::kInvalidThreadJoinId;
  };

  // Note that |recorder| will be freed by |TimelineRecorderOverride|'s
  // destructor.
  TimelineEventRingRecorder& recorder =
      *(new TimelineEventRingRecorder(2 * TimelineEventBlock::kBlockSize));
  TimelineRecorderOverride<TimelineEventRingRecorder> override(&recorder);
  Monitor synchronization_monitor;
  JSONStream js;
  TimelineEventFilter filter;
  ReportEventsArguments report_events_1_arguments{synchronization_monitor,
                                                  recorder};
  ReportEventsArguments report_events_2_arguments{synchronization_monitor,
                                                  recorder};

  // Try concurrently writing events, serializing them, and clearing the
  // timeline. It is not possible to assert anything about the outcome, because
  // of scheduling uncertainty. This test is just used to ensure that TSAN
  // checks the ring recorder code.
  OSThread::Start(
      "ReportEvents1",
      [](uword arguments_ptr) {
        ReportEventsArguments& arguments =
            *reinterpret_cast<ReportEventsArguments*>(arguments_ptr);
        for (intptr_t i = 0; i < 2 * TimelineEventBlock::kBlockSize; ++i) {
          TimelineTestHelper::FakeDuration(&arguments.recorder, "testEvent",
                                           /*start=*/0, /*end=*/1);
        }
        MonitorLocker ml(&arguments.synchronization_monitor);
        arguments.join_id =
            OSThread::GetCurrentThreadJoinId(OSThread::Current());
        ml.Notify();
      },
      reinterpret_cast<uword>(&report_events_1_arguments));
  OSThread::Start(
      "ReportEvents2",
      [](uword arguments_ptr) {
        ReportEventsArguments& arguments =
            *reinterpret_cast<ReportEventsArguments*>(arguments_ptr);
        for (intptr_t i = 0; i < 2 * TimelineEventBlock::kBlockSize; ++i) {
          TimelineTestHelper::FakeDuration(&arguments.recorder, "testEvent",
                                           /*start=*/0, /*end=*/1);
        }
        MonitorLocker ml(&arguments.synchronization_monitor);
        arguments.join_id =
            OSThread::GetCurrentThreadJoinId(OSThread::Current());
        ml.Notify();
      },
      reinterpret_cast<uword>(&report_events_2_arguments));
  Timeline::Clear();
  recorder.PrintJSON(&js, &filter);

  MonitorLocker ml(&synchronization_monitor);
  while (report_events_1_arguments.join_id == OSThread::kInvalidThreadJoinId ||
         report_events_2_arguments.join_id == OSThread::kInvalidThreadJoinId) {
    ml.Wait();
  }
  OSThread::Join(report_events_1_arguments.join_id);
  OSThread::Join(report_events_2_arguments.join_id);
}

// |OSThread::Start()| takes in a function pointer, and only lambdas that don't
// capture can be converted to function pointers. So, we use these macros to
// avoid needing to capture.
#define FAKE_PROCESS_ID 1
#define FAKE_TRACE_ID 1

TEST_CASE(TimelineTrackMetadataRace) {
  struct ReportMetadataArguments {
    Monitor& synchronization_monitor;
    TimelineEventRecorder& recorder;
    ThreadJoinId join_id = OSThread::kInvalidThreadJoinId;
  };

  Monitor synchronization_monitor;
  TimelineEventRecorder& recorder = *Timeline::recorder();

  // Try concurrently reading from / writing to the metadata map. It is not
  // possible to assert anything about the outcome, because of scheduling
  // uncertainty. This test is just used to ensure that TSAN checks the metadata
  // map code.
  JSONStream js;
  TimelineEventFilter filter;
  ReportMetadataArguments report_metadata_1_arguments{synchronization_monitor,
                                                      recorder};
  ReportMetadataArguments report_metadata_2_arguments{synchronization_monitor,
                                                      recorder};
  OSThread::Start(
      "ReportMetadata1",
      [](uword arguments_ptr) {
        ReportMetadataArguments& arguments =
            *reinterpret_cast<ReportMetadataArguments*>(arguments_ptr);
        arguments.recorder.AddTrackMetadataBasedOnThread(
            FAKE_PROCESS_ID, FAKE_TRACE_ID, "Thread 1");
        MonitorLocker ml(&arguments.synchronization_monitor);
        arguments.join_id =
            OSThread::GetCurrentThreadJoinId(OSThread::Current());
        ml.Notify();
      },
      reinterpret_cast<uword>(&report_metadata_1_arguments));
  OSThread::Start(
      "ReportMetadata2",
      [](uword arguments_ptr) {
        ReportMetadataArguments& arguments =
            *reinterpret_cast<ReportMetadataArguments*>(arguments_ptr);
        arguments.recorder.AddTrackMetadataBasedOnThread(
            FAKE_PROCESS_ID, FAKE_TRACE_ID, "Incorrect Name");
        MonitorLocker ml(&arguments.synchronization_monitor);
        arguments.join_id =
            OSThread::GetCurrentThreadJoinId(OSThread::Current());
        ml.Notify();
      },
      reinterpret_cast<uword>(&report_metadata_2_arguments));
  recorder.PrintJSON(&js, &filter);
  MonitorLocker ml(&synchronization_monitor);
  while (
      report_metadata_1_arguments.join_id == OSThread::kInvalidThreadJoinId ||
      report_metadata_2_arguments.join_id == OSThread::kInvalidThreadJoinId) {
    ml.Wait();
  }
  OSThread::Join(report_metadata_1_arguments.join_id);
  OSThread::Join(report_metadata_2_arguments.join_id);
}

#undef FAKE_PROCESS_ID
#undef FAKE_TRACE_ID

#endif  // !PRODUCT

#if defined(SUPPORT_TIMELINE)

static Dart_Port expected_isolate;
static Dart_IsolateGroupId expected_isolate_group;
static bool saw_begin;
static bool saw_end;
static void* expected_isolate_data;
static void* expected_isolate_group_data;

static void TestTimelineRecorderCallback(Dart_TimelineRecorderEvent* event) {
  EXPECT_EQ(DART_TIMELINE_RECORDER_CURRENT_VERSION, event->version);

  if ((event->type == Dart_Timeline_Event_Begin) &&
      (strcmp(event->label, "TestEvent") == 0)) {
    saw_begin = true;
    EXPECT_NE(0, event->timestamp0);
    EXPECT_EQ(expected_isolate, event->isolate);
    EXPECT_EQ(expected_isolate_group, event->isolate_group);
    EXPECT_EQ(expected_isolate_data, event->isolate_data);
    EXPECT_EQ(expected_isolate_group_data, event->isolate_group_data);
    EXPECT_STREQ("Dart", event->stream);
    EXPECT_EQ(1, event->argument_count);
    EXPECT_STREQ("Dart Arguments", event->arguments[0].name);
    EXPECT_STREQ("{\"key\":\"value\"}", event->arguments[0].value);
  }

  if ((event->type == Dart_Timeline_Event_End) &&
      (strcmp(event->label, "TestEvent") == 0)) {
    saw_end = true;
    EXPECT_NE(0, event->timestamp0);
    EXPECT_EQ(expected_isolate, event->isolate);
    EXPECT_EQ(expected_isolate_group, event->isolate_group);
    EXPECT_EQ(expected_isolate_data, event->isolate_data);
    EXPECT_EQ(expected_isolate_group_data, event->isolate_group_data);
    EXPECT_STREQ("Dart", event->stream);
    EXPECT_EQ(1, event->argument_count);
    EXPECT_STREQ("Dart Arguments", event->arguments[0].name);
    EXPECT_STREQ("{\"key\":\"value\"}", event->arguments[0].value);
  }
}

UNIT_TEST_CASE(DartAPI_SetTimelineRecorderCallback) {
  int argc = TesterState::argc + 2;
  const char** argv = new const char*[argc];
  for (intptr_t i = 0; i < argc - 2; i++) {
    argv[i] = TesterState::argv[i];
  }
  argv[argc - 2] = "--timeline_recorder=callback";
  argv[argc - 1] = "--timeline_streams=Dart";

  Dart_SetTimelineRecorderCallback(TestTimelineRecorderCallback);

  EXPECT(Dart_SetVMFlags(argc, argv) == nullptr);
  Dart_InitializeParams params;
  memset(&params, 0, sizeof(Dart_InitializeParams));
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  params.vm_snapshot_data = TesterState::vm_snapshot_data;
  params.create_group = TesterState::create_callback;
  params.shutdown_isolate = TesterState::shutdown_callback;
  params.cleanup_group = TesterState::group_cleanup_callback;
  params.start_kernel_isolate = true;

  int64_t isolate_data = 0;

  EXPECT(Dart_Initialize(&params) == nullptr);
  {
    // Note: run_vm_tests will create and attach an instance of
    // bin::IsolateGroupData to the newly created isolate group.
    TestIsolateScope scope(/*isolate_group_data=*/nullptr, &isolate_data);
    const char* kScriptChars =
        "import 'dart:developer';\n"
        "main() {\n"
        "  Timeline.startSync('TestEvent', arguments: {'key':'value'});\n"
        "  Timeline.finishSync();\n"
        "}\n";
    Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, nullptr);
    EXPECT_VALID(lib);

    expected_isolate = Dart_GetMainPortId();
    EXPECT_NE(ILLEGAL_PORT, expected_isolate);
    expected_isolate_group = Dart_CurrentIsolateGroupId();
    EXPECT_NE(ILLEGAL_PORT, expected_isolate_group);
    expected_isolate_data = &isolate_data;
    EXPECT_EQ(expected_isolate_data, Dart_CurrentIsolateData());
    expected_isolate_group_data = Dart_CurrentIsolateGroupData();
    saw_begin = false;
    saw_end = false;

    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);

    EXPECT(saw_begin);
    EXPECT(saw_end);
  }
  EXPECT(Dart_Cleanup() == nullptr);

  Dart_SetTimelineRecorderCallback(nullptr);

  delete[] argv;
}

#endif  // defined(SUPPORT_TIMELINE)

}  // namespace dart
