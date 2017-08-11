// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/log.h"

#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/thread.h"

namespace dart {

DEFINE_FLAG(bool, force_log_flush, false, "Always flush log messages.");

DEFINE_FLAG(charp,
            isolate_log_filter,
            NULL,
            "Log isolates whose name include the filter. "
            "Default: service isolate log messages are suppressed "
            "(specify 'vm-service' to log them).");

Log::Log(LogPrinter printer)
    : printer_(printer), manual_flush_(0), buffer_(0) {}

Log::~Log() {
  // Did someone enable manual flushing and then forgot to Flush?
  ASSERT(cursor() == 0);
}

Log* Log::Current() {
  Thread* thread = Thread::Current();
  if (thread == NULL) {
    OSThread* os_thread = OSThread::Current();
    ASSERT(os_thread != NULL);
    return os_thread->log();
  }
  Isolate* isolate = thread->isolate();
  if (isolate != NULL && Log::ShouldLogForIsolate(isolate)) {
    OSThread* os_thread = thread->os_thread();
    ASSERT(os_thread != NULL);
    return os_thread->log();
  } else {
    return Log::NoOpLog();
  }
}

void Log::Print(const char* format, ...) {
  if (this == NoOpLog()) {
    return;
  }

  va_list args;
  va_start(args, format);
  VPrint(format, args);
  va_end(args);
}

void Log::VPrint(const char* format, va_list args) {
  if (this == NoOpLog()) {
    return;
  }

  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = OS::VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  // Print.
  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  va_list print_args;
  va_copy(print_args, args);
  OS::VSNPrint(buffer, (len + 1), format, print_args);
  va_end(print_args);

  // Append.
  // NOTE: does not append the '\0' character.
  for (intptr_t i = 0; i < len; i++) {
    buffer_.Add(buffer[i]);
  }
  free(buffer);

  if ((manual_flush_ == 0) || FLAG_force_log_flush) {
    Flush();
  }
}

void Log::Flush(const intptr_t cursor) {
  if (this == NoOpLog()) {
    return;
  }
  if (buffer_.is_empty()) {
    return;
  }
  if (buffer_.length() <= cursor) {
    return;
  }
  TerminateString();
  const char* str = &buffer_[cursor];
  ASSERT(str != NULL);
  printer_("%s", str);
  buffer_.TruncateTo(cursor);
}

void Log::Clear() {
  if (this == NoOpLog()) {
    return;
  }
  buffer_.TruncateTo(0);
}

intptr_t Log::cursor() const {
  return buffer_.length();
}

bool Log::ShouldLogForIsolate(const Isolate* isolate) {
  if (FLAG_isolate_log_filter == NULL) {
    if (isolate->is_service_isolate()) {
      // By default, do not log for the service isolate.
      return false;
    }
    return true;
  }
  const char* name = isolate->name();
  ASSERT(name != NULL);
  if (strstr(name, FLAG_isolate_log_filter) == NULL) {
    // Filter does not match, do not log for this isolate.
    return false;
  }
  return true;
}

Log Log::noop_log_;
Log* Log::NoOpLog() {
  return &noop_log_;
}

void Log::TerminateString() {
  if (this == NoOpLog()) {
    return;
  }
  buffer_.Add('\0');
}

void Log::EnableManualFlush() {
  if (this == NoOpLog()) {
    return;
  }
  manual_flush_++;
}

void Log::DisableManualFlush(const intptr_t cursor) {
  if (this == NoOpLog()) {
    return;
  }

  manual_flush_--;
  ASSERT(manual_flush_ >= 0);
  if (manual_flush_ == 0) {
    Flush(cursor);
  }
}

void LogBlock::Initialize() {
  log_->EnableManualFlush();
}

LogBlock::~LogBlock() {
  log_->DisableManualFlush(cursor_);
}

}  // namespace dart
