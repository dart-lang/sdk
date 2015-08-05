// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/log.h"

#include "vm/flags.h"
#include "vm/thread.h"

namespace dart {

DEFINE_FLAG(bool, force_log_flush, false, "Always flush log messages.");

Log::Log(LogPrinter printer)
    : printer_(printer),
      manual_flush_(0),
      buffer_(0) {
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


Log Log::noop_log_;
Log* Log::NoOpLog() {
  return &noop_log_;
}


void Log::TerminateString() {
  buffer_.Add('\0');
}


void Log::EnableManualFlush() {
  manual_flush_++;
}


void Log::DisableManualFlush() {
  manual_flush_--;
  ASSERT(manual_flush_ >= 0);
  if (manual_flush_ == 0) {
    Flush();
  }
}


LogBlock::LogBlock(Thread* thread, Log* log)
    : StackResource(thread),
      log_(log), cursor_(log->cursor()) {
  CommonConstructor();
}


LogBlock::LogBlock(Isolate* isolate)
    : StackResource(isolate),
      log_(isolate->Log()), cursor_(isolate->Log()->cursor()) {
  CommonConstructor();
}


LogBlock::LogBlock(Thread* thread)
    : StackResource(thread),
      log_(thread->isolate()->Log()),
      cursor_(thread->isolate()->Log()->cursor()) {
  CommonConstructor();
}

}  // namespace dart
