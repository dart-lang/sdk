// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(IsolateCurrent) {
  Isolate* isolate = Isolate::Init(NULL);
  EXPECT_EQ(isolate, Isolate::Current());
  isolate->Shutdown();
  EXPECT_EQ(reinterpret_cast<Isolate*>(NULL), Isolate::Current());
  delete isolate;
}


// Test to ensure that an exception is thrown if no isolate creation
// callback has been set by the embedder when an isolate is spawned.
TEST_CASE(IsolateSpawn) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      // Ignores printed lines.
      "var _nullPrintClosure = (String line) {};\n"
      "void entry(message) {}\n"
      "int testMain() {\n"
      "  Isolate.spawn(entry, null);\n"
      // TODO(floitsch): the following code is only to bump the event loop
      // so it executes asynchronous microtasks.
      "  var rp = new RawReceivePort();\n"
      "  rp.sendPort.send(null);\n"
      "  rp.handler = (_) { rp.close(); };\n"
      "}\n";

  Dart_Handle test_lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Setup the internal library's 'internalPrint' function.
  // Necessary because asynchronous errors use "print" to print their
  // stack trace.
  Dart_Handle url = NewString("dart:_internal");
  DART_CHECK_VALID(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(internal_lib);
  Dart_Handle print = Dart_GetField(test_lib, NewString("_nullPrintClosure"));
  Dart_Handle result = Dart_SetField(internal_lib,
                                     NewString("_printClosure"),
                                     print);

  DART_CHECK_VALID(result);

  // Setup the 'scheduleImmediate' closure.
  url = NewString("dart:isolate");
  DART_CHECK_VALID(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(isolate_lib);
  Dart_Handle schedule_immediate_closure =
      Dart_Invoke(isolate_lib, NewString("_getIsolateScheduleImmediateClosure"),
                  0, NULL);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  url = NewString("dart:async");
  DART_CHECK_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(async_lib);
  DART_CHECK_VALID(Dart_Invoke(
      async_lib, NewString("_setScheduleImmediateClosure"), 1, args));


  result = Dart_Invoke(test_lib, NewString("testMain"), 0, NULL);
  EXPECT(!Dart_IsError(result));
  // Run until all ports to isolate are closed.
  result = Dart_RunLoop();
  EXPECT_ERROR(result,
               "Isolate spawn is not supported by this Dart implementation");
  EXPECT(Dart_ErrorHasException(result));
  Dart_Handle exception_result = Dart_ErrorGetException(result);
  EXPECT_VALID(exception_result);
}

}  // namespace dart
