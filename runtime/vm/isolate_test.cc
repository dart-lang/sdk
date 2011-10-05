// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(IsolateCurrent) {
  Isolate* isolate = Isolate::Init();
  EXPECT_EQ(isolate, Isolate::Current());
  isolate->Shutdown();
  EXPECT_EQ(reinterpret_cast<Isolate*>(NULL), Isolate::Current());
  delete isolate;
}


#if defined(TARGET_ARCH_IA32)  // only ia32 can run dart execution tests.
// Unit test case to verify error during isolate spawning (application classes
// not loaded into the isolate).
TEST_CASE(IsolateSpawn) {
  const char* kScriptChars =
      "class SpawnNewIsolate extends Isolate {\n"
      "  SpawnNewIsolate() : super() { }\n"
      "  void main() {\n"
      "  }\n"
      "  static int testMain() {\n"
      "    try {\n"
      "      new SpawnNewIsolate().spawn().then(function(SendPort port) {\n"
      "      });\n"
      "    } catch (var e) {\n"
      "      throw;\n"
      "    }\n"
      "    return 0;\n"
      "  }\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Result result = Dart_InvokeStatic(lib,
                                         Dart_NewString("SpawnNewIsolate"),
                                         Dart_NewString("testMain"),
                                         0,
                                         NULL);
  EXPECT(Dart_IsValidResult(result));
  Dart_Handle result_obj = Dart_GetResult(result);
  EXPECT(Dart_ExceptionOccurred(result_obj));
  Dart_Result exception_result = Dart_GetException(result_obj);
  EXPECT(Dart_IsValidResult(exception_result));
}
#endif  // TARGET_ARCH_IA32.

}  // namespace dart
