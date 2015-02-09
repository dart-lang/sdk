// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#include "include/dart_debugger_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/log.h"
#include "vm/message_handler.h"
#include "vm/unit_test.h"

namespace dart {

static const char* test_output_;
static void TestPrinter(const char* print, ...) {
  test_output_ = print;
}

class LogTestHelper : public AllStatic {
 public:
  static void SetPrinter(Log* log, LogPrinter printer) {
    ASSERT(log != NULL);
    ASSERT(printer != NULL);
    log->printer_ = printer;
  }
};


TEST_CASE(Log_Macro) {
  test_output_ = NULL;
  Isolate* isolate = Isolate::Current();
  Log* log = isolate->Log();
  LogTestHelper::SetPrinter(log, TestPrinter);

  ISL_Print("Hello %s", "World");
  EXPECT_STREQ("Hello World", test_output_);
  ISL_Print("SingleArgument");
  EXPECT_STREQ("SingleArgument", test_output_);
}


TEST_CASE(Log_Basic) {
  test_output_ = NULL;
  Log* log = new Log(TestPrinter);

  EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
  log->Print("Hello %s", "World");
  EXPECT_STREQ("Hello World", test_output_);
}


TEST_CASE(Log_Block) {
  test_output_ = NULL;
  Log* log = new Log(TestPrinter);

  Isolate* isolate = Isolate::Current();

  EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
  {
    LogBlock ba(isolate, log);
    log->Print("APPLE");
    EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    {
      LogBlock ba(isolate, log);
      log->Print("BANANA");
      EXPECT_EQ(reinterpret_cast<const char*>(NULL), test_output_);
    }
    EXPECT_STREQ("BANANA", test_output_);
  }
  EXPECT_STREQ("APPLE", test_output_);
}

}  // namespace dart
