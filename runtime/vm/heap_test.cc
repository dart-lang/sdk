// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/assert.h"
#include "vm/globals.h"
#include "vm/heap.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(TARGET_ARCH_IA32)
TEST_CASE(OldGC) {
  const char* kScriptChars =
  "class HeapTester {\n"
  "  static void main() {\n"
  "    return [1, 2, 3];\n"
  "  }\n"
  "}\n";
  FLAG_verbose_gc = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_Handle result = Dart_InvokeStatic(lib,
                                         Dart_NewString("HeapTester"),
                                         Dart_NewString("main"),
                                         0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
}


TEST_CASE(LargeSweep) {
  const char* kScriptChars =
  "class HeapTester {\n"
  "  static void main() {\n"
  "    return new List(8 * 1024 * 1024);\n"
  "  }\n"
  "}\n";
  FLAG_verbose_gc = true;
  Dart_Handle lib = TestCase::LoadTestScript(kScriptChars, NULL);
  Dart_EnterScope();
  Dart_Handle result = Dart_InvokeStatic(lib,
                                         Dart_NewString("HeapTester"),
                                         Dart_NewString("main"),
                                         0, NULL);

  EXPECT_VALID(result);
  EXPECT(!Dart_IsNull(result));
  EXPECT(Dart_IsList(result));
  Isolate* isolate = Isolate::Current();
  Heap* heap = isolate->heap();
  heap->CollectGarbage(Heap::kOld);
  Dart_ExitScope();
  heap->CollectGarbage(Heap::kOld);
}

#endif  // TARGET_ARCH_IA32
}
