// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "vm/unit_test.h"

namespace dart {

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

TEST_CASE(Mixin_PrivateSuperResolution) {
  // clang-format off
  Dart_SourceFile sourcefiles[] = {
    {
      "file:///test-app.dart",
      "class A {\n"
      "  _bar() => 42;\n"
      "}\n"
      "class M extends A {\n"
      "  bar() => -1;\n"
      "}\n"
      "class B extends A {\n"
      "  foo() => 6;\n"
      "}\n"
      "class C extends B with M {\n"
      "  bar() => super._bar();\n"
      "}\n"
      "main() {\n"
      "  return new C().bar();\n"
      "}\n",
    },
    {
      "file:///.packages", "untitled:/"
    }};
  // clang-format on

  Dart_Handle lib = TestCase::LoadTestScriptWithDFE(
      sizeof(sourcefiles) / sizeof(Dart_SourceFile), sourcefiles,
      /* resolver= */ NULL, /* finalize= */ true, /* incrementally= */ true);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  int64_t value = 0;
  result = Dart_IntegerToInt64(result, &value);
  EXPECT_VALID(result);
  EXPECT_EQ(42, value);
}

TEST_CASE(Mixin_PrivateSuperResolutionCrossLibraryShouldFail) {
  // clang-format off
  Dart_SourceFile sourcefiles[] = {
    {
      "file:///test-app.dart",
      "import 'test-lib.dart';\n"
      "class D extends B with M {\n"
      "  bar() => super._bar();\n"
      "}\n"
      "main() {\n"
      "  try {\n"
      "    return new D().bar();\n"
      "  } catch (e) {\n"
      "    return e.toString().split('\\n').first;\n"
      "  }\n"
      "}"
      "}\n",
    },
    {
      "file:///test-lib.dart",
      "class A {\n"
      "  foo() => 4;\n"
      "  _bar() => 42;\n"
      "}\n"
      "class M extends A {\n"
      "  bar() => -1;\n"
      "}\n"
      "class B extends A {\n"
      "  foo() => 6;\n"
      "}\n"
      "class C extends B with M {\n"
      "  bar() => super._bar();\n"
      "}\n"
    },
    {
      "file:///.packages", "untitled:/"
    }};
  // clang-format on

  Dart_Handle lib = TestCase::LoadTestScriptWithDFE(
      sizeof(sourcefiles) / sizeof(Dart_SourceFile), sourcefiles,
      /* resolver= */ NULL, /* finalize= */ true, /* incrementally= */ true);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  const char* result_str = NULL;
  EXPECT(Dart_IsString(result));
  EXPECT_VALID(Dart_StringToCString(result, &result_str));
  EXPECT_STREQ(
      "NoSuchMethodError: Super class of class 'D' has no instance method "
      "'_bar'.",
      result_str);
}
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
