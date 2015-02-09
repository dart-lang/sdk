// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LOG_H_
#define VM_LOG_H_

#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/os.h"

namespace dart {

class Isolate;
class LogBlock;
class Thread;

#if defined(_MSC_VER)
#define ISL_Print(format, ...) \
    Isolate::Current()->Log()->Print(format, __VA_ARGS__)
#else
#define ISL_Print(format, ...) \
    Isolate::Current()->Log()->Print(format, ##__VA_ARGS__)
#endif

typedef void (*LogPrinter)(const char* str, ...);

class Log {
 public:
  explicit Log(LogPrinter printer = OS::Print);

  // Append a formatted string to the log.
  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

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
  void DisableManualFlush();

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
  LogBlock(Isolate* isolate, Log* log)
      : StackResource(isolate),
        log_(log), cursor_(log->cursor()) {
    CommonConstructor();
  }

  explicit LogBlock(Isolate* isolate);
  explicit LogBlock(Thread* thread);

  LogBlock(Thread* thread, Log* log);

  ~LogBlock() {
    CommonDestructor();
  }

 private:
  void CommonConstructor() {
    log_->EnableManualFlush();
  }

  void CommonDestructor() {
    log_->Flush(cursor_);
    log_->DisableManualFlush();
  }
  Log* log_;
  const intptr_t cursor_;
};

}  // namespace dart

#endif  // VM_LOG_H_
