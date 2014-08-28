// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coverage.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

static RawObject* ExecuteScript(const char* script) {
  Dart_Handle h_lib = TestCase::LoadTestScript(script, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  return Api::UnwrapHandle(h_lib);
}


class FunctionCoverageFilter : public CoverageFilter {
 public:
  explicit FunctionCoverageFilter(const Function& func) : func_(func) {}
  bool ShouldOutputCoverageFor(const Library& lib,
                               const Script& script,
                               const Class& cls,
                               const Function& func) const {
    return func.raw() == func_.raw();
  }
 private:
  const Function& func_;
};


TEST_CASE(Coverage_Empty) {
  const char* kScript =
      "main() {\n"
      "}";

  Isolate* isolate = Isolate::Current();
  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  JSONStream js;
  CodeCoverage::PrintJSON(isolate, &js, NULL);

  char buf[1024];
  OS::SNPrint(buf, sizeof(buf),
      "{\"source\":\"test-lib\",\"script\":{\"type\":\"@Script\","
      "\"id\":\"libraries\\/%" Pd  "\\/scripts\\/test-lib\","
      "\"name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[]}", lib.index());
  EXPECT_SUBSTRING(buf, js.ToCString());
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
  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  JSONStream js;
  CodeCoverage::PrintJSON(isolate, &js, NULL);

  char buf[1024];
  // Coverage data is printed per class, i.e., there should be two sections
  // for test-lib in the JSON data.

  // Data for the actual class Foo.
  OS::SNPrint(buf, sizeof(buf),
      "{\"source\":\"test-lib\",\"script\":{\"type\":\"@Script\","
      "\"id\":\"libraries\\/%" Pd "\\/scripts\\/test-lib\","
      "\"name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[3,1,5,4,6,3]}", lib.index());
  EXPECT_SUBSTRING(buf, js.ToCString());

  // Data for the fake class containing main().
  OS::SNPrint(buf, sizeof(buf),
      "{\"source\":\"test-lib\",\"script\":{\"type\":\"@Script\","
      "\"id\":\"libraries\\/%" Pd  "\\/scripts\\/test-lib\","
      "\"name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[10,1,11,1]}", lib.index());
  EXPECT_SUBSTRING(buf, js.ToCString());
}


TEST_CASE(Coverage_FilterFunction) {
  const char* kScript =
      "class Foo {\n"
      "  var x;\n"
      "  var y;\n"
      "  Foo(this.x);\n"
      "  Foo.other(this.x, this.y);\n"
      "  Foo.yetAnother();\n"
      "}\n"
      "main() {\n"
      "  var foo = new Foo(7);\n"
      "}\n";

  Isolate* isolate = Isolate::Current();
  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(String::New("Foo"))));
  ASSERT(!cls.IsNull());
  const Function& func = Function::Handle(
      cls.LookupFunction(String::Handle(String::New("Foo.yetAnother"))));
  ASSERT(!func.IsNull());

  JSONStream js;
  FunctionCoverageFilter filter(func);
  CodeCoverage::PrintJSON(isolate, &js, &filter);
  // Only expect coverage data for Foo.yetAnother() on line 6.
  char buf[1024];
  OS::SNPrint(buf, sizeof(buf),
      "{\"source\":\"test-lib\",\"script\":{\"type\":\"@Script\","
      "\"id\":\"libraries\\/%" Pd "\\/scripts\\/test-lib\","
      "\"name\":\"test-lib\","
      "\"kind\":\"script\"},\"hits\":[6,0]}", lib.index());
  EXPECT_SUBSTRING(buf, js.ToCString());
}

}  // namespace dart
