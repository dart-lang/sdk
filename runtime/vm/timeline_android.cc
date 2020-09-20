// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_ANDROID) && defined(SUPPORT_TIMELINE)

#include <errno.h>
#include <fcntl.h>
#include <cstdlib>

#include "platform/atomic.h"
#include "platform/signal_blocker.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/lockers.h"
#include "vm/log.h"
#include "vm/object.h"
#include "vm/service_event.h"
#include "vm/thread.h"
#include "vm/timeline.h"

namespace dart {

DECLARE_FLAG(bool, trace_timeline);

static int OpenTraceFD() {
  const char* kSystraceDebugPath = "/sys/kernel/debug/tracing/trace_marker";
  const char* kSystracePath = "/sys/kernel/tracing/trace_marker";

  int fd = TEMP_FAILURE_RETRY(::open(kSystracePath, O_WRONLY));
  if (fd < 0) {
    fd = TEMP_FAILURE_RETRY(::open(kSystraceDebugPath, O_WRONLY));
  }

  if (fd < 0 && FLAG_trace_timeline) {
    OS::PrintErr("TimelineEventSystraceRecorder: Could not open `%s` or `%s`\n",
                 kSystraceDebugPath, kSystracePath);
  }
  return fd;
}

TimelineEventSystraceRecorder::TimelineEventSystraceRecorder()
    : TimelineEventPlatformRecorder(), systrace_fd_(OpenTraceFD()) {}

TimelineEventSystraceRecorder::~TimelineEventSystraceRecorder() {
  if (systrace_fd_ >= 0) {
    close(systrace_fd_);
  }
}

intptr_t TimelineEventSystraceRecorder::PrintSystrace(TimelineEvent* event,
                                                      char* buffer,
                                                      intptr_t buffer_size) {
  ASSERT(buffer != NULL);
  ASSERT(buffer_size > 0);
  buffer[0] = '\0';
  intptr_t length = 0;
  int64_t pid = OS::ProcessId();
  switch (event->event_type()) {
    case TimelineEvent::kBegin: {
      length = Utils::SNPrint(buffer, buffer_size, "B|%" Pd64 "|%s", pid,
                              event->label());
      break;
    }
    case TimelineEvent::kEnd: {
      length = Utils::SNPrint(buffer, buffer_size, "E");
      break;
    }
    case TimelineEvent::kCounter: {
      if (event->arguments_length() > 0) {
        // We only report the first counter value.
        length = Utils::SNPrint(buffer, buffer_size, "C|%" Pd64 "|%s|%s", pid,
                                event->label(), event->arguments()[0].value);
      }
      break;
    }
    case TimelineEvent::kAsyncBegin: {
      length = Utils::SNPrint(buffer, buffer_size, "S|%" Pd64 "|%s|%" Pd64 "",
                              pid, event->label(), event->AsyncId());
      break;
    }
    case TimelineEvent::kAsyncEnd: {
      length = Utils::SNPrint(buffer, buffer_size, "F|%" Pd64 "|%s|%" Pd64 "",
                              pid, event->label(), event->AsyncId());
      break;
    }
    default:
      // Ignore event types that we cannot serialize to the Systrace format.
      break;
  }
  return length;
}

void TimelineEventSystraceRecorder::OnEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }
  if (systrace_fd_ < 0) {
    return;
  }

  // Serialize to the systrace format.
  const intptr_t kBufferLength = 1024;
  char buffer[kBufferLength];
  const intptr_t event_length = PrintSystrace(event, &buffer[0], kBufferLength);
  if (event_length > 0) {
    ssize_t result;
    // Repeatedly attempt the write while we are being interrupted.
    do {
      result = write(systrace_fd_, buffer, event_length);
    } while ((result == -1L) && (errno == EINTR));
  }
}

}  // namespace dart

#endif  // defined(HOST_OS_ANDROID) && !defined(PRODUCT)
