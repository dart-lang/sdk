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


// Only ia32 and x64 can run dart execution tests.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
// Unit test case to verify error during isolate spawning (application classes
// not loaded into the isolate).
TEST_CASE(IsolateSpawn) {
  const char* kScriptChars =
      "#import('dart:isolate');\n"
      "class SpawnNewIsolate extends Isolate {\n"
      "  SpawnNewIsolate() : super() { }\n"
      "  void main() {\n"
      "  }\n"
      "}\n"
      "int testMain() {\n"
      "  try {\n"
      "    new SpawnNewIsolate().spawn().then(function(SendPort port) {\n"
      "    });\n"
      "  } catch (var e) {\n"
      "    throw;\n"
      "  }\n"
      "  return 0;\n"
      "}\n";
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle result = Dart_Invoke(lib, Dart_NewString("testMain"), 0, NULL);
  EXPECT(Dart_IsError(result));
  EXPECT(Dart_ErrorHasException(result));
  Dart_Handle exception_result = Dart_ErrorGetException(result);
  EXPECT_VALID(exception_result);
}
#endif  // defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64).

}  // namespace dart
