// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(HOST_OS_MACOS) && defined(SUPPORT_TIMELINE)


#include "vm/log.h"
#include "vm/timeline.h"

namespace dart {

// Only available on iOS 12.0, macOS 10.14 or above
TimelineEventMacosRecorder::TimelineEventMacosRecorder()
    : TimelineEventPlatformRecorder() {}

TimelineEventMacosRecorder::~TimelineEventMacosRecorder() {}

void TimelineEventMacosRecorder::OnEvent(TimelineEvent* event) {
  if (event == NULL) {
    return;
  }

#if defined(HOST_OS_SUPPORTS_SIGNPOST)
  os_log_t log = event->stream_->macos_log();
  if (!os_signpost_enabled(log)) {
    return;
  }

  const char* label = event->label();
  uint8_t _Alignas(16) buffer[64];
  buffer[0] = 0;

  switch (event->event_type()) {
    case TimelineEvent::kInstant: {
      _os_signpost_emit_with_name_impl(&__dso_handle, log, OS_SIGNPOST_EVENT,
                                       OS_SIGNPOST_ID_EXCLUSIVE, label, "",
                                       buffer, sizeof(buffer));
      break;
    }
    case TimelineEvent::kBegin: {
      _os_signpost_emit_with_name_impl(
          &__dso_handle, log, OS_SIGNPOST_INTERVAL_BEGIN,
          OS_SIGNPOST_ID_EXCLUSIVE, label, "", buffer, sizeof(buffer));
      break;
    }
    case TimelineEvent::kEnd: {
      _os_signpost_emit_with_name_impl(
          &__dso_handle, log, OS_SIGNPOST_INTERVAL_END,
          OS_SIGNPOST_ID_EXCLUSIVE, label, "", buffer, sizeof(buffer));
      break;
    }
    case TimelineEvent::kAsyncBegin: {
      _os_signpost_emit_with_name_impl(
          &__dso_handle, log, OS_SIGNPOST_INTERVAL_BEGIN, event->AsyncId(),
          label, "", buffer, sizeof(buffer));
      break;
    }
    case TimelineEvent::kAsyncEnd: {
      _os_signpost_emit_with_name_impl(
          &__dso_handle, log, OS_SIGNPOST_INTERVAL_END, event->AsyncId(), label,
          "", buffer, sizeof(buffer));
      break;
    }
    case TimelineEvent::kCounter: {
      const char* fmt = "%s";
      Utils::SNPrint(reinterpret_cast<char*>(buffer), sizeof(buffer), fmt,
                     event->arguments()[0].value);
      _os_signpost_emit_with_name_impl(&__dso_handle, log, OS_SIGNPOST_EVENT,
                                       event->AsyncId(), label, fmt, buffer,
                                       sizeof(buffer));
      break;
    }
    default:
      break;
  }
#endif  // defined(HOST_OS_SUPPORTS_SIGNPOST)
}

}  // namespace dart

#endif  // defined(HOST_OS_MACOS) && defined(SUPPORT_TIMELINE)
