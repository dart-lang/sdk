// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LOG_H_
#define RUNTIME_VM_LOG_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/os.h"

namespace dart {

class LogBlock;
class Thread;

#if defined(_MSC_VER)
#define THR_Print(format, ...) Log::Current()->Print(format, __VA_ARGS__)
#else
#define THR_Print(format, ...) Log::Current()->Print(format, ##__VA_ARGS__)
#endif

#define THR_VPrint(format, args) Log::Current()->VPrint(format, args)

typedef void (*LogPrinter)(const char* str, ...);

class Log {
 public:
  explicit Log(LogPrinter printer = OS::Print);
  ~Log();

  static Log* Current();

  // Append a formatted string to the log.
  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  void VPrint(const char* format, va_list args);

  // Flush and truncate the log. The log is flushed starting at cursor
  // and truncated to cursor afterwards.
  void Flush(const intptr_t cursor = 0);

  // Clears the log.
  void Clear();

  // Current cursor.
  intptr_t cursor() const;

  // A logger that does nothing.
  static Log* NoOpLog();

 private:
  void TerminateString();
  void EnableManualFlush();
  void DisableManualFlush(const intptr_t cursor);

  // Returns false if we should drop log messages related to 'isolate'.
  static bool ShouldLogForIsolate(const Isolate* isolate);

  static Log noop_log_;
  LogPrinter printer_;
  intptr_t manual_flush_;
  MallocGrowableArray<char> buffer_;

  friend class LogBlock;
  friend class LogTestHelper;
  DISALLOW_COPY_AND_ASSIGN(Log);
};

// Causes all log messages to be buffered until destructor is called.
// Can be nested.
class LogBlock : public StackResource {
 public:
  LogBlock(Thread* thread, Log* log)
      : StackResource(thread), log_(log), cursor_(log->cursor()) {
    Initialize();
  }

  LogBlock()
      : StackResource(Thread::Current()),
        log_(Log::Current()),
        cursor_(Log::Current()->cursor()) {
    Initialize();
  }

  ~LogBlock();

 private:
  void Initialize();

  Log* const log_;
  const intptr_t cursor_;
};

}  // namespace dart

#endif  // RUNTIME_VM_LOG_H_
