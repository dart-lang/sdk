// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "include/dart_tools_api.h"
#include "platform/utils.h"
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

static void TestPrinter(const char* buffer) {
  if (test_output_ != NULL) {
    free(const_cast<char*>(test_output_));
    test_output_ = NULL;
  }
  test_output_ = Utils::StrDup(buffer);

  // Also print to stdout to see the overall result.
  OS::PrintErr("%s", test_output_);
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
    EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    {
      LogBlock ba(thread, log);
      log->Print("PEAR");
      EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    }
    EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
  }
  EXPECT_STREQ("APPLEBANANAPEAR", test_output_);
  delete log;
  LogTestHelper::FreeTestOutput();
}

}  // namespace dart
