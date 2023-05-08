// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(DART_HOST_OS_MACOS) && defined(SUPPORT_TIMELINE)

#include "vm/log.h"
#include "vm/timeline.h"

namespace dart {

// Only available on iOS 12.0, macOS 10.14 or above
TimelineEventMacosRecorder::TimelineEventMacosRecorder()
    : TimelineEventPlatformRecorder() {
  Timeline::set_recorder_discards_clock_values(true);
}

TimelineEventMacosRecorder::~TimelineEventMacosRecorder() {}

void TimelineEventMacosRecorder::OnEvent(TimelineEvent* event) {
  if (event == nullptr) {
    return;
  }

#if defined(DART_HOST_OS_SUPPORTS_SIGNPOST)
  os_log_t log = event->stream_->macos_log();
  if (!os_signpost_enabled(log)) {
    return;
  }

  const char* label = event->label();
  bool is_static_label = event->stream_->has_static_labels();
  uint8_t _Alignas(16) buffer[64];
  buffer[0] = 0;

  switch (event->event_type()) {
    case TimelineEvent::kInstant:
      if (is_static_label) {
        _os_signpost_emit_with_name_impl(&__dso_handle, log, OS_SIGNPOST_EVENT,
                                         OS_SIGNPOST_ID_EXCLUSIVE, label, "",
                                         buffer, sizeof(buffer));
      } else {
        os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "Event", "%s",
                               label);
      }
      break;
    case TimelineEvent::kBegin:
    case TimelineEvent::kAsyncBegin:
      if (is_static_label) {
        _os_signpost_emit_with_name_impl(
            &__dso_handle, log, OS_SIGNPOST_INTERVAL_BEGIN, event->Id(), label,
            "", buffer, sizeof(buffer));
      } else {
        os_signpost_interval_begin(log, event->Id(), "Event", "%s", label);
      }
      break;
    case TimelineEvent::kEnd:
    case TimelineEvent::kAsyncEnd:
      if (is_static_label) {
        _os_signpost_emit_with_name_impl(&__dso_handle, log,
                                         OS_SIGNPOST_INTERVAL_END, event->Id(),
                                         label, "", buffer, sizeof(buffer));
      } else {
        os_signpost_interval_end(log, event->Id(), "Event");
      }
      break;
    case TimelineEvent::kCounter:
      os_signpost_event_emit(log, OS_SIGNPOST_ID_EXCLUSIVE, "Counter", "%s=%s",
                             label, event->arguments()[0].value);
      break;
    default:
      break;
  }
#endif  // defined(DART_HOST_OS_SUPPORTS_SIGNPOST)
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS) && defined(SUPPORT_TIMELINE)
