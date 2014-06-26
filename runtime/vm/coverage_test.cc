// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

static void ExecuteScript(const char* script) {
  Dart_Handle h_lib = TestCase::LoadTestScript(script, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
}


TEST_CASE(Coverage_Empty) {
  const char* kScript =
      "main() {\n"
      "}";

  Isolate* isolate = Isolate::Current();
  ExecuteScript(kScript);

  JSONStream js;
  CodeCoverage::PrintJSON(isolate, &js);

  EXPECT_SUBSTRING(
      "{\"source\":\"test-lib\",\"script\":{"
      "\"type\":\"@Script\",\"id\":\"scripts\\/test-lib\","
      "\"name\":\"test-lib\",\"user_name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[]}", js.ToCString());
}


TEST_CASE(Coverage_MainWithClass) {
  const char* kScript =
      "class Foo {\n"
      "  var x;\n"
      "  Foo(this.x);\n"
      "  bar() {\n"
      "    x = x * x;\n"
      "    x = x / 13;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var foo = new Foo(7);\n"
      "  foo.bar();\n"
      "}\n";

  Isolate* isolate = Isolate::Current();
  ExecuteScript(kScript);

  JSONStream js;
  CodeCoverage::PrintJSON(isolate, &js);

  // Coverage data is printed per class, i.e., there should be two sections
  // for test-lib in the JSON data.

  // Data for the actual class Foo.
  EXPECT_SUBSTRING(
      "{\"source\":\"test-lib\",\"script\":{"
      "\"type\":\"@Script\",\"id\":\"scripts\\/test-lib\","
      "\"name\":\"test-lib\",\"user_name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[3,1,5,4,6,3]}", js.ToCString());

  // Data for the fake class containing main().
  EXPECT_SUBSTRING(
      "{\"source\":\"test-lib\",\"script\":{"
      "\"type\":\"@Script\",\"id\":\"scripts\\/test-lib\","
      "\"name\":\"test-lib\",\"user_name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[10,1,11,1]}", js.ToCString());
}

}  // namespace dart
