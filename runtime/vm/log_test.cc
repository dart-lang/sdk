// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "include/dart_tools_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/unit_test.h"

namespace dart {

static const char* test_output_ = NULL;
static void TestPrinter(const char* format, ...) {
  // Measure.
  va_list args;
  va_start(args, format);
  intptr_t len = OS::VSNPrint(NULL, 0, format, args);
  va_end(args);

  // Print string to buffer.
  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  va_list args2;
  va_start(args2, format);
  OS::VSNPrint(buffer, (len + 1), format, args2);
  va_end(args2);

  if (test_output_ != NULL) {
    free(const_cast<char*>(test_output_));
    test_output_ = NULL;
  }
  test_output_ = buffer;
}

class LogTestHelper : public AllStatic {
 public:
  static void SetPrinter(Log* log, LogPrinter printer) {
    ASSERT(log != NULL);
    ASSERT(printer != NULL);
    log->printer_ = printer;
  }

  static void FreeTestOutput() {
    if (test_output_ != NULL) {
      free(const_cast<char*>(test_output_));
      test_output_ = NULL;
    }
  }
};

TEST_CASE(Log_Macro) {
  test_output_ = NULL;
  Log* log = Log::Current();
  LogTestHelper::SetPrinter(log, TestPrinter);

  THR_Print("Hello %s", "World");
  EXPECT_STREQ("Hello World", test_output_);
  THR_Print("SingleArgument");
  EXPECT_STREQ("SingleArgument", test_output_);
  LogTestHelper::FreeTestOutput();
}

TEST_CASE(Log_Basic) {
  test_output_ = NULL;
  Log* log = new Log(TestPrinter);

  EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
  log->Print("Hello %s", "World");
  EXPECT_STREQ("Hello World", test_output_);

  delete log;
  LogTestHelper::FreeTestOutput();
}

TEST_CASE(Log_Block) {
  test_output_ = NULL;
  Log* log = new Log(TestPrinter);

  EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
  {
    LogBlock ba(thread, log);
    log->Print("APPLE");
    EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    {
      LogBlock ba(thread, log);
      log->Print("BANANA");
      EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    }
    EXPECT_STREQ("BANANA", test_output_);
  }
  EXPECT_STREQ("APPLE", test_output_);
  delete log;
  LogTestHelper::FreeTestOutput();
}

}  // namespace dart
