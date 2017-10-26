// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/source_report.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

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

TEST_CASE(SourceReport_Coverage_NoCalls) {
  char buffer[1024];
  const char* kScript =
      "main() {\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("libraries", js.ToCString(), buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":"

      // One compiled range, one hit at function declaration.
      "[{\"scriptIndex\":0,\"startPos\":0,\"endPos\":5,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_SimpleCall) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit at function declaration (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":10,\"compiled\":false},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":12,\"endPos\":39,\"compiled\":true,"
      "\"coverage\":{\"hits\":[12,23],\"misses\":[32]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_ForceCompile) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit at function declaration (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // This range is compiled even though it wasn't called (helper1).
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":10,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[6]}},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":12,\"endPos\":39,\"compiled\":true,"
      "\"coverage\":{\"hits\":[12,23],\"misses\":[32]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_UnusedClass_NoForceCompile) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "class Unused {\n"
      "  helper1() { helper0(); }\n"
      "}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass is not compiled.
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":20,\"compiled\":false},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":22,\"endPos\":32,\"compiled\":true,"
      "\"coverage\":{\"hits\":[22,27],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_UnusedClass_ForceCompile) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "class Unused {\n"
      "  helper1() { helper0(); }\n"
      "}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass.helper1 is compiled.
      "{\"scriptIndex\":0,\"startPos\":10,\"endPos\":18,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[10,14]}},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":22,\"endPos\":32,\"compiled\":true,"
      "\"coverage\":{\"hits\":[22,27],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_UnusedClass_ForceCompileError) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "class Unused {\n"
      "  helper1() { helper0()+ }\n"  // syntax error
      "}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass has a syntax error.
      "{\"scriptIndex\":0,\"startPos\":10,\"endPos\":18,\"compiled\":false,"
      "\"error\":{\"type\":\"@Error\",\"_vmType\":\"LanguageError\","
      "\"kind\":\"LanguageError\",\"id\":\"objects\\/0\","
      "\"message\":\"'test-lib': error: line 3 pos 26: unexpected token '}'\\n"
      "  helper1() { helper0()+ }\\n                         ^\\n\"}},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":22,\"endPos\":32,\"compiled\":true,"
      "\"coverage\":{\"hits\":[22,27],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_NestedFunctions) {
  char buffer[1024];
  const char* kScript =
      "helper0() {\n"
      "  nestedHelper0() {}\n"
      "  nestedHelper1() {}\n"
      "  nestedHelper0();\n"
      "}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":22,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0,18],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":24,\"endPos\":28,\"compiled\":false},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":30,\"endPos\":57,\"compiled\":true,"
      "\"coverage\":{\"hits\":[30,41],\"misses\":[50]}},"

      // Nested range compiled (nestedHelper0).
      "{\"scriptIndex\":0,\"startPos\":5,\"endPos\":9,\"compiled\":true,"
      "\"coverage\":{\"hits\":[5],\"misses\":[]}},"

      // Nested range not compiled (nestedHelper1).
      "{\"scriptIndex\":0,\"startPos\":11,\"endPos\":15,\"compiled\":false}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_RestrictedRange) {
  char buffer[1024];
  const char* kScript =
      "helper0() {\n"
      "  nestedHelper0() {}\n"
      "  nestedHelper1() {}\n"
      "  nestedHelper0();\n"
      "}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));
  const Function& helper = Function::Handle(
      lib.LookupLocalFunction(String::Handle(String::New("helper0"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  // Restrict the report to only helper0 and it's nested functions.
  report.PrintJSON(&js, script, helper.token_pos(), helper.end_token_pos());
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":22,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0,18],\"misses\":[]}},"

      // Nested range compiled (nestedHelper0).
      "{\"scriptIndex\":0,\"startPos\":5,\"endPos\":9,\"compiled\":true,"
      "\"coverage\":{\"hits\":[5],\"misses\":[]}},"

      // Nested range not compiled (nestedHelper1).
      "{\"scriptIndex\":0,\"startPos\":11,\"endPos\":15,\"compiled\":false}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_Coverage_AllFunctions) {
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;

  // We generate a report with all functions in the VM.
  Script& null_script = Script::Handle();
  report.PrintJSON(&js, null_script);
  const char* result = js.ToCString();

  // Sanity check the header.
  EXPECT_SUBSTRING("{\"type\":\"SourceReport\",\"ranges\":[", result);

  // Make sure that the main function was found.
  EXPECT_SUBSTRING(
      "\"startPos\":12,\"endPos\":39,\"compiled\":true,"
      "\"coverage\":{\"hits\":[12,23],\"misses\":[32]}",
      result);

  // More than one script is referenced in the report.
  EXPECT_SUBSTRING("\"scriptIndex\":0", result);
  EXPECT_SUBSTRING("\"scriptIndex\":1", result);
  EXPECT_SUBSTRING("\"scriptIndex\":2", result);
}

TEST_CASE(SourceReport_Coverage_AllFunctions_ForceCompile) {
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;

  // We generate a report with all functions in the VM.
  Script& null_script = Script::Handle();
  {
    TransitionNativeToVM transition(Thread::Current());
    report.PrintJSON(&js, null_script);
  }
  const char* result = js.ToCString();

  // Sanity check the header.
  EXPECT_SUBSTRING("{\"type\":\"SourceReport\",\"ranges\":[", result);

  // Make sure that the main function was found.
  EXPECT_SUBSTRING(
      "\"startPos\":12,\"endPos\":39,\"compiled\":true,"
      "\"coverage\":{\"hits\":[12,23],\"misses\":[32]}",
      result);

  // More than one script is referenced in the report.
  EXPECT_SUBSTRING("\"scriptIndex\":0", result);
  EXPECT_SUBSTRING("\"scriptIndex\":1", result);
  EXPECT_SUBSTRING("\"scriptIndex\":2", result);
}

TEST_CASE(SourceReport_CallSites_SimpleCall) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCallSites);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with no callsites (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"callSites\":[]},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":10,\"compiled\":false},"

      // One range compiled with one callsite (main).
      "{\"scriptIndex\":0,\"startPos\":12,\"endPos\":22,\"compiled\":true,"
      "\"callSites\":["
      "{\"name\":\"helper0\",\"tokenPos\":17,\"cacheEntries\":["
      "{\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"helper0\",\"owner\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"test-lib\"},"
      "\"_kind\":\"RegularFunction\",\"static\":true,\"const\":false,"
      "\"_intrinsic\":false,\"_native\":false},\"count\":1}]}]}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_CallSites_PolymorphicCall) {
  char buffer[1024];
  const char* kScript =
      "class Common {\n"
      "  func() {}\n"
      "}\n"
      "class Uncommon {\n"
      "  func() {}\n"
      "}\n"
      "helper(arg) {\n"
      "  arg.func();\n"
      "}\n"
      "main() {\n"
      "  Common common = new Common();\n"
      "  Uncommon uncommon = new Uncommon();\n"
      "  helper(common);\n"
      "  helper(common);\n"
      "  helper(uncommon);\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));
  const Function& helper = Function::Handle(
      lib.LookupLocalFunction(String::Handle(String::New("helper"))));

  SourceReport report(SourceReport::kCallSites);
  JSONStream js;
  report.PrintJSON(&js, script, helper.token_pos(), helper.end_token_pos());
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range...
      "{\"scriptIndex\":0,\"startPos\":24,\"endPos\":37,\"compiled\":true,"

      // With one call site...
      "\"callSites\":[{\"name\":\"func\",\"tokenPos\":32,\"cacheEntries\":["

      // First receiver: "Common", called twice.
      "{\"receiver\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Common\"},"

      "\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"func\","
      "\"owner\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Common\"},\"_kind\":\"RegularFunction\","
      "\"static\":false,\"const\":false,\"_intrinsic\":false,"
      "\"_native\":false},"

      "\"count\":2},"

      // Second receiver: "Uncommon", called once.
      "{\"receiver\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Uncommon\"},"

      "\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"func\","
      "\"owner\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Uncommon\"},\"_kind\":\"RegularFunction\","
      "\"static\":false,\"const\":false,\"_intrinsic\":false,"
      "\"_native\":false},"

      "\"count\":1}]}]}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_MultipleReports) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCallSites | SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with no callsites (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"callSites\":[],"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":10,\"compiled\":false},"

      // One range compiled with one callsite (main).
      "{\"scriptIndex\":0,\"startPos\":12,\"endPos\":22,\"compiled\":true,"
      "\"callSites\":["
      "{\"name\":\"helper0\",\"tokenPos\":17,\"cacheEntries\":["
      "{\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"helper0\",\"owner\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"test-lib\"},"
      "\"_kind\":\"RegularFunction\",\"static\":true,\"const\":false,"
      "\"_intrinsic\":false,\"_native\":false},\"count\":1}]}],"
      "\"coverage\":{\"hits\":[12,17],\"misses\":[]}}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

TEST_CASE(SourceReport_PossibleBreakpoints_Simple) {
  char buffer[1024];
  const char* kScript =
      "helper0() {}\n"
      "helper1() {}\n"
      "main() {\n"
      "  if (true) {\n"
      "    helper0();\n"
      "  } else {\n"
      "    helper1();\n"
      "  }\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kPossibleBreakpoints);
  JSONStream js;
  report.PrintJSON(&js, script);
  ElideJSONSubstring("classes", js.ToCString(), buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // helper0.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":4,\"compiled\":true,"
      "\"possibleBreakpoints\":[1,4]},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":6,\"endPos\":10,\"compiled\":false},"

      // main.
      "{\"scriptIndex\":0,\"startPos\":12,\"endPos\":39,\"compiled\":true,"
      "\"possibleBreakpoints\":[13,23,32,39]}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"test-lib\",\"_kind\":\"script\"}]}",
      buffer);
}

#endif  // !PRODUCT

}  // namespace dart
