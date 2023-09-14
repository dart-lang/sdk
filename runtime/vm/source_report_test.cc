// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/source_report.h"
#include "vm/dart_api_impl.h"
#include "vm/unit_test.h"

namespace dart {

#ifndef PRODUCT

static ObjectPtr ExecuteScript(const char* script, bool allow_errors = false) {
  Dart_Handle lib;
  {
    TransitionVMToNative transition(Thread::Current());
    if (allow_errors) {
      lib = TestCase::LoadTestScriptWithErrors(script, nullptr);
    } else {
      lib = TestCase::LoadTestScript(script, nullptr);
    }
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }
  return Api::UnwrapHandle(lib);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_NoCalls) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("libraries", json_str, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":"

      // One compiled range, one hit at function declaration.
      "[{\"scriptIndex\":0,\"startPos\":0,\"endPos\":9,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_Filters_single) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "main() {\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  GrowableObjectArray& filters =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  filters.Add(String::Handle(String::New(RESOLVED_USER_TEST_URI)));
  SourceReport report(SourceReport::kCoverage, filters);
  JSONStream js;
  report.PrintJSON(&js, Script::Handle(Script::null()));
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("libraries", json_str, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":"

      // One compiled range, one hit at function declaration.
      "[{\"scriptIndex\":0,\"startPos\":0,\"endPos\":9,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_Filters_empty) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "main() {\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());

  GrowableObjectArray& filters =
      GrowableObjectArray::Handle(GrowableObjectArray::New());
  filters.Add(String::Handle(String::New("foo:bar/")));
  SourceReport report(SourceReport::kCoverage, filters);
  JSONStream js;
  report.PrintJSON(&js, Script::Handle(Script::null()));
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("libraries", json_str, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":"

      // No compiled range.
      "[],"

      // No script.
      "\"scripts\":[]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_SimpleCall) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit at function declaration (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":24,\"compiled\":false},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":26,\"endPos\":94,\"compiled\":true,"
      "\"coverage\":{\"hits\":[26,53],\"misses\":[79]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_ForceCompile) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);

  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit at function declaration (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // This range is compiled even though it wasn't called (helper1).
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":24,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[13]}},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":26,\"endPos\":94,\"compiled\":true,"
      "\"coverage\":{\"hits\":[26,53],\"misses\":[79]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_UnusedClass_NoForceCompile) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass is not compiled.
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":55,\"compiled\":false},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":57,\"endPos\":79,\"compiled\":true,"
      "\"coverage\":{\"hits\":[57,68],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_UnusedClass_ForceCompile) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass.helper1 is compiled.
      "{\"scriptIndex\":0,\"startPos\":30,\"endPos\":53,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[30,42]}},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":57,\"endPos\":79,\"compiled\":true,"
      "\"coverage\":{\"hits\":[57,68],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_UnusedClass_ForceCompileError) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "helper0() {}\n"
      "class Unused {\n"
      "  helper1() { helper0()+ }\n"  // syntax error
      "}\n"
      "main() {\n"
      "  helper0();\n"
      "}";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript, true);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // UnusedClass has a syntax error.
      "{\"scriptIndex\":0,\"startPos\":30,\"endPos\":53,\"compiled\":false,"
      "\"error\":{\"type\":\"@Error\",\"_vmType\":\"LanguageError\","
      "\"kind\":\"LanguageError\",\"id\":\"objects\\/0\","
      "\"message\":\"'file:\\/\\/\\/test-lib': error: "
      "\\/test-lib:3:26: "
      "Error: This couldn't be parsed.\\n"
      "  helper1() { helper0()+ }\\n                         ^\"}},"

      // helper0 is compiled.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range with two hits (main).
      "{\"scriptIndex\":0,\"startPos\":57,\"endPos\":79,\"compiled\":true,"
      "\"coverage\":{\"hits\":[57,68],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_NestedFunctions) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);

  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":73,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0,56],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":75,\"endPos\":86,\"compiled\":false},"

      // One range with two hits and a miss (main).
      "{\"scriptIndex\":0,\"startPos\":88,\"endPos\":156,\"compiled\":true,"
      "\"coverage\":{\"hits\":[88,115],\"misses\":[141]}},"

      // Nested range compiled (nestedHelper0).
      "{\"scriptIndex\":0,\"startPos\":14,\"endPos\":31,\"compiled\":true,"
      "\"coverage\":{\"hits\":[14],\"misses\":[]}},"

      // Nested range not compiled (nestedHelper1).
      "{\"scriptIndex\":0,\"startPos\":35,\"endPos\":52,\"compiled\":false}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_RestrictedRange) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
      lib.LookupFunctionAllowPrivate(String::Handle(String::New("helper0"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  // Restrict the report to only helper0 and it's nested functions.
  report.PrintJSON(&js, script, helper.token_pos(), helper.end_token_pos());
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);

  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with one hit (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":73,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0,56],\"misses\":[]}},"

      // Nested range compiled (nestedHelper0).
      "{\"scriptIndex\":0,\"startPos\":14,\"endPos\":31,\"compiled\":true,"
      "\"coverage\":{\"hits\":[14],\"misses\":[]}},"

      // Nested range not compiled (nestedHelper1).
      "{\"scriptIndex\":0,\"startPos\":35,\"endPos\":52,\"compiled\":false}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_AllFunctions) {
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
      "\"startPos\":26,\"endPos\":94,\"compiled\":true,"
      "\"coverage\":{\"hits\":[26,53],\"misses\":[79]}",
      result);

  // More than one script is referenced in the report.
  EXPECT_SUBSTRING("\"scriptIndex\":0", result);
  EXPECT_SUBSTRING("\"scriptIndex\":1", result);
  EXPECT_SUBSTRING("\"scriptIndex\":2", result);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_AllFunctions_ForceCompile) {
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
  report.PrintJSON(&js, null_script);
  const char* result = js.ToCString();

  // Sanity check the header.
  EXPECT_SUBSTRING("{\"type\":\"SourceReport\",\"ranges\":[", result);

  // Make sure that the main function was found.
  EXPECT_SUBSTRING(
      "\"startPos\":26,\"endPos\":94,\"compiled\":true,"
      "\"coverage\":{\"hits\":[26,53],\"misses\":[79]}",
      result);

  // More than one script is referenced in the report.
  EXPECT_SUBSTRING("\"scriptIndex\":0", result);
  EXPECT_SUBSTRING("\"scriptIndex\":1", result);
  EXPECT_SUBSTRING("\"scriptIndex\":2", result);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_CallSites_SimpleCall) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 2048;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with no callsites (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"callSites\":[]},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":24,\"compiled\":false},"

      // One range compiled with one callsite (main).
      "{\"scriptIndex\":0,\"startPos\":26,\"endPos\":48,\"compiled\":true,"
      "\"callSites\":["
      "{\"name\":\"helper0\",\"tokenPos\":37,\"cacheEntries\":["
      "{\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"helper0\",\"owner\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"},"
      "\"_kind\":\"RegularFunction\",\"static\":true,\"const\":false,"
      "\"implicit\":false,\"abstract\":false,"
      "\"_intrinsic\":false,\"_native\":false,\"isGetter\":false,"
      "\"isSetter\":false,\"location\":{\"type\":"
      "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
      "\"id\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"},"
      "\"tokenPos\":0,\"endTokenPos\":11,\"line\":1,\"column\":1}},\"count\":1}"
      "]}]}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_CallSites_PolymorphicCall) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 4096;
  char buffer[kBufferSize];
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
      lib.LookupFunctionAllowPrivate(String::Handle(String::New("helper"))));

  SourceReport report(SourceReport::kCallSites);
  JSONStream js;
  report.PrintJSON(&js, script, helper.token_pos(), helper.end_token_pos());
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range...
      "{\"scriptIndex\":0,\"startPos\":60,\"endPos\":88,\"compiled\":true,"

      // With one call site...
      "\"callSites\":[{\"name\":\"dyn:func\",\"tokenPos\":80,\"cacheEntries\":["

      // First receiver: "Common", called twice.
      "{\"receiver\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Common\","
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\","
      "\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":0,\"endTokenPos\":27,\"line\":1,"
      "\"column\":1},"
      "\"library\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"}},"

      "\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"func\","
      "\"owner\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Common\","
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\","
      "\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":0,\"endTokenPos\":27,\"line\":1,"
      "\"column\":1},"
      "\"library\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"}"
      "},\"_kind\":\"RegularFunction\","
      "\"static\":false,\"const\":false,\"implicit\":false,\"abstract\":"
      "false,\"_intrinsic\":false,"
      "\"_native\":false,\"isGetter\":false,\"isSetter\":false,"
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
      "\"id\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":17,\"endTokenPos\":25,\"line\":2,"
      "\"column\":3}},"

      "\"count\":2},"

      // Second receiver: "Uncommon", called once.
      "{\"receiver\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Uncommon\","
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\","
      "\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":29,\"endTokenPos\":58,\"line\":4,"
      "\"column\":1},"
      "\"library\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"}},"

      "\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"func\","
      "\"owner\":{\"type\":\"@Class\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"Uncommon\","
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\","
      "\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":29,\"endTokenPos\":58,\"line\":4,"
      "\"column\":1},"
      "\"library\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"}"
      "},\"_kind\":\"RegularFunction\","
      "\"static\":false,\"const\":false,\"implicit\":false,\"abstract\":"
      "false,\"_intrinsic\":false,"
      "\"_native\":false,\"isGetter\":false,\"isSetter\":false,"
      "\"location\":{\"type\":\"SourceLocation\","
      "\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
      "\"id\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\","
      "\"_kind\":\"kernel\"},\"tokenPos\":48,\"endTokenPos\":56,\"line\":5,"
      "\"column\":3}},"

      "\"count\":1}]}]}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_MultipleReports) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 2048;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // One range compiled with no callsites (helper0).
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"callSites\":[],"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":24,\"compiled\":false},"

      // One range compiled with one callsite (main)m
      "{\"scriptIndex\":0,\"startPos\":26,\"endPos\":48,\"compiled\":true,"
      "\"callSites\":[{\"name\":\"helper0\",\"tokenPos\":37,\"cacheEntries\":[{"
      "\"target\":{\"type\":\"@Function\",\"fixedId\":true,\"id\":\"\","
      "\"name\":\"helper0\",\"owner\":{\"type\":\"@Library\",\"fixedId\":true,"
      "\"id\":\"\",\"name\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\"},\"_"
      "kind\":\"RegularFunction\",\"static\":true,\"const\":false,\"implicit\":"
      "false,\"abstract\":false,\"_"
      "intrinsic\":false,\"_native\":false,\"isGetter\":false,"
      "\"isSetter\":false,\"location\":{\"type\":"
      "\"SourceLocation\",\"script\":{\"type\":\"@Script\",\"fixedId\":true,"
      "\"id\":\"\",\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"},"
      "\"tokenPos\":0,\"endTokenPos\":11,\"line\":1,\"column\":1}},\"count\":1}"
      "]}],\"coverage\":{"
      "\"hits\":[26,37],\"misses\":[]}}],"

      // One script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_PossibleBreakpoints_Simple) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
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
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // helper0.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":11,\"compiled\":true,"
      "\"possibleBreakpoints\":[7,11]},"

      // One range not compiled (helper1).
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":24,\"compiled\":false},"

      // main.
      "{\"scriptIndex\":0,\"startPos\":26,\"endPos\":94,\"compiled\":true,"
      "\"possibleBreakpoints\":[30,53,79,94]}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_Issue35453_NoSuchMethod) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "class Foo {\n"
      "  void bar() {}\n"
      "}\n"
      "class Unused implements Foo {\n"
      "  dynamic noSuchMethod(_) {}\n"
      "}\n"
      "void main() {\n"
      "  Foo().bar();\n"
      "}\n";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // Foo is hit.
      "{\"scriptIndex\":0,\"startPos\":14,\"endPos\":26,\"compiled\":true,"
      "\"coverage\":{\"hits\":[14],\"misses\":[]}},"

      // Unused is missed.
      "{\"scriptIndex\":0,\"startPos\":62,\"endPos\":87,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[62]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":91,\"endPos\":120,\"compiled\":true,"
      "\"coverage\":{\"hits\":[91,107,113],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_Issue47017_Assert) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "void foo(Object? bar) {\n"
      "  assert(bar == null);\n"
      "}\n"
      "void main() {\n"
      "  foo(null);\n"
      "}\n";

  Library& lib = Library::Handle();
  const bool old_asserts = IsolateGroup::Current()->asserts();
  IsolateGroup::Current()->set_asserts(true);
  lib ^= ExecuteScript(kScript);
  IsolateGroup::Current()->set_asserts(old_asserts);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // Foo is hit, and the assert is hit.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":47,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0,33],\"misses\":[]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":49,\"endPos\":76,\"compiled\":true,"
      "\"coverage\":{\"hits\":[49,65],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_Issue47021_StaticOnlyClasses) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 2048;
  char buffer[kBufferSize];
  const char* kScript =
      "abstract class AllStatic {\n"
      "  AllStatic._();\n"
      "  static int test() => 123;\n"
      "  static int foo = 456;\n"
      "}\n"
      "class NotAbstract {\n"
      "  NotAbstract._();\n"
      "  static int test() => 123;\n"
      "  static int foo = 456;\n"
      "}\n"
      "abstract class NotConstructor {\n"
      "  void _() {}\n"
      "  static int test() => 123;\n"
      "}\n"
      "abstract class NotPrivate {\n"
      "  NotPrivate();\n"
      "  static int test() => 123;\n"
      "}\n"
      "abstract class HasParams {\n"
      "  HasParams._(int i);\n"
      "  static int test() => 123;\n"
      "}\n"
      "abstract class HasFields {\n"
      "  HasFields._();\n"
      "  static int test() => 123;\n"
      "  int foo = 0;\n"
      "}\n"
      "abstract class HasNonStaticFunction {\n"
      "  HasNonStaticFunction._();\n"
      "  static int test() => 123;\n"
      "  int foo() => 456;\n"
      "}\n"
      "abstract class HasSubclass {\n"
      "  HasSubclass._();\n"
      "  static int test() => 123;\n"
      "  static int foo = 456;\n"
      "}\n"
      "abstract class Subclass extends HasSubclass {\n"
      "  Subclass() : super._();\n"
      "}\n"
      "void main() {\n"
      "  AllStatic.test();\n"
      "  NotAbstract.test();\n"
      "  NotConstructor.test();\n"
      "  NotPrivate.test();\n"
      "  HasParams.test();\n"
      "  HasFields.test();\n"
      "  HasNonStaticFunction.test();\n"
      "  HasSubclass.test();\n"
      "}\n";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // Subclass() is missed.
      "{\"scriptIndex\":0,\"startPos\":775,\"endPos\":797,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[775,794]}},"

      // AllStatic.test() is hit. AllStatic._() is ignored (would be pos: 29).
      "{\"scriptIndex\":0,\"startPos\":46,\"endPos\":70,\"compiled\":true,"
      "\"coverage\":{\"hits\":[46],\"misses\":[]}},"

      // HasSubclass._() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":656,\"endPos\":671,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[656]}},"

      // HasSubclass.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":675,\"endPos\":699,\"compiled\":true,"
      "\"coverage\":{\"hits\":[675],\"misses\":[]}},"

      // HasParams._(int i) is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":370,\"endPos\":388,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[370]}},"

      // HasParams.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":392,\"endPos\":416,\"compiled\":true,"
      "\"coverage\":{\"hits\":[392],\"misses\":[]}},"

      // NotAbstract._() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":120,\"endPos\":135,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[120]}},"

      // NotAbstract.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":139,\"endPos\":163,\"compiled\":true,"
      "\"coverage\":{\"hits\":[139],\"misses\":[]}},"

      // HasFields._() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":449,\"endPos\":462,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[449]}},"

      // HasFields.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":466,\"endPos\":490,\"compiled\":true,"
      "\"coverage\":{\"hits\":[466],\"misses\":[]}},"

      // NotPrivate() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":297,\"endPos\":309,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[297]}},"

      // NotPrivate.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":313,\"endPos\":337,\"compiled\":true,"
      "\"coverage\":{\"hits\":[313],\"misses\":[]}},"

      // HasNonStaticFunction._() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":549,\"endPos\":573,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[549]}},"

      // HasNonStaticFunction.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":577,\"endPos\":601,\"compiled\":true,"
      "\"coverage\":{\"hits\":[577],\"misses\":[]}},"

      // HasNonStaticFunction.foo() is missed.
      "{\"scriptIndex\":0,\"startPos\":605,\"endPos\":621,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[605]}},"

      // NotConstructor._() is missed, not ignored.
      "{\"scriptIndex\":0,\"startPos\":225,\"endPos\":235,\"compiled\":true,"
      "\"coverage\":{\"hits\":[],\"misses\":[225]}},"

      // NotConstructor.test() is hit.
      "{\"scriptIndex\":0,\"startPos\":239,\"endPos\":263,\"compiled\":true,"
      "\"coverage\":{\"hits\":[239],\"misses\":[]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":801,\"endPos\":996,\"compiled\":true,"
      "\"coverage\":{\"hits\":"
      "[801,827,849,874,895,915,935,966,988],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_IssueCov341_LateFinalVars) {
  // https://github.com/dart-lang/coverage/issues/341
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "int foo(bool bar) {\n"
      "  late final int baz;\n"
      "  if (bar) {\n"
      "    baz = 123;\n"
      "  } else {\n"
      "    baz = 456;\n"
      "  }\n"
      "  return baz;\n"
      "}\n"
      "main() {\n"
      "  foo(true);\n"
      "  foo(false);\n"
      "}\n";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // foo is hit, but the late variable sets and gets are ignored.
      "{\"scriptIndex\":0,\"startPos\":0,\"endPos\":114,\"compiled\":true,"
      "\"coverage\":{\"hits\":[0],\"misses\":[]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":116,\"endPos\":152,\"compiled\":true,\""
      "coverage\":{\"hits\":[116,127,140],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Coverage_IssueCov386_EnhancedEnums) {
  // https://github.com/dart-lang/coverage/issues/386
  // https://github.com/dart-lang/coverage/issues/377
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript =
      "enum FoodType {\n"
      "  candy();\n"
      "  const FoodType();\n"
      "  factory FoodType.candyFactory() => candy;\n"
      "}\n"
      "void main() {\n"
      "  final food = FoodType.candyFactory();\n"
      "}\n";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage, SourceReport::kForceCompile);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":49,\"endPos\":89,\"compiled\":true,"
      "\"coverage\":{\"hits\":[49],\"misses\":[]}},"

      // The enum's constructor, and toString, are not included in the hitmap,
      // but the factory is included.
      "{\"scriptIndex\":0,\"startPos\":93,\"endPos\":147,\"compiled\":true,"
      "\"coverage\":{\"hits\":[93,131],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_Regress95008_RedirectingFactory) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript = R"(
class A {
  A();
  factory A.foo(int i) = B; // LINE_A
}

class B extends A {
  int i;
  B(this.i); // LINE_B
}

main() {
  A.foo(42);
}
)";

  Library& lib = Library::Handle();
  lib ^= ExecuteScript(kScript);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // A()
      "{\"scriptIndex\":0,\"startPos\":13,\"endPos\":16,\"compiled\":true,"
      "\"coverage\":{\"hits\":[13],\"misses\":[]}},"

      // B()
      "{\"scriptIndex\":0,\"startPos\":90,\"endPos\":99,\"compiled\":true,"
      "\"coverage\":{\"hits\":[90],\"misses\":[]}},"

      // main
      "{\"scriptIndex\":0,\"startPos\":114,\"endPos\":136,\"compiled\":true,"
      "\"coverage\":{\"hits\":[114,127],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_BranchCoverage_if) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript = R"(
int ifTest(int x) {
  if (x > 0) {
    if (x > 10) {
      return 10;
    } else {
      return 1;
    }
  } else {
    return 0;
  }
}

main() {
  ifTest(1);
}
)";

  Library& lib = Library::Handle();
  const bool old_branch_coverage = IsolateGroup::Current()->branch_coverage();
  IsolateGroup::Current()->set_branch_coverage(true);
  lib ^= ExecuteScript(kScript);
  IsolateGroup::Current()->set_branch_coverage(old_branch_coverage);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kBranchCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // In ifTest, the outer true case is hit, the inner true case is missed,
      // the inner false case is hit, and the outer false case is missed.
      "{\"scriptIndex\":0,\"startPos\":1,\"endPos\":135,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[1,34,82],\"misses\":[52,115]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":138,\"endPos\":160,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[138],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_BranchCoverage_loops) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript = R"(
int loopTest() {
  var x = 0;

  while (x < 10) {
    ++x;
  }

  do {
    ++x;
  } while (false);

  for (int i = 0; i < 10; ++i) {
    ++x;
  }

  for (final i in [1, 2, 3]) {
    ++x;
  }

  return x;
}

main() {
  loopTest();
}
)";

  Library& lib = Library::Handle();
  const bool old_branch_coverage = IsolateGroup::Current()->branch_coverage();
  IsolateGroup::Current()->set_branch_coverage(true);
  lib ^= ExecuteScript(kScript);
  IsolateGroup::Current()->set_branch_coverage(old_branch_coverage);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kBranchCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // In loopTest, the while loop, do-while loop, for loop, and for-in loop
      // are all hit.
      "{\"scriptIndex\":0,\"startPos\":1,\"endPos\":205,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[1,49,70,132,177],\"misses\":[]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":208,\"endPos\":231,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[208],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_BranchCoverage_switch) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript = R"(
int switchTest(int x) {
  switch (x) {
    case 0:
      return 10;
    case 1:
      return 20;
    default:
      return 30;
  }
}

main() {
  switchTest(1);
}
)";

  Library& lib = Library::Handle();
  const bool old_branch_coverage = IsolateGroup::Current()->branch_coverage();
  IsolateGroup::Current()->set_branch_coverage(true);
  lib ^= ExecuteScript(kScript);
  IsolateGroup::Current()->set_branch_coverage(old_branch_coverage);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kBranchCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // In switchTest, the 1 case is hit and the others are missed.
      "{\"scriptIndex\":0,\"startPos\":1,\"endPos\":132,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[1,73],\"misses\":[44,102]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":135,\"endPos\":161,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[135],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

ISOLATE_UNIT_TEST_CASE(SourceReport_BranchCoverage_try) {
  // WARNING: This MUST be big enough for the serialized JSON string.
  const int kBufferSize = 1024;
  char buffer[kBufferSize];
  const char* kScript = R"(
void tryTestInner() {
  try {
    throw "abc";
  } catch (e) {
  } finally {
  }

  try {
    throw "def";
  } finally {
  }
}

void tryTestOuter() {
  try {
    tryTestInner();
  } catch (e) {
  }
}

main() {
  tryTestOuter();
}
)";

  Library& lib = Library::Handle();
  const bool old_branch_coverage = IsolateGroup::Current()->branch_coverage();
  IsolateGroup::Current()->set_branch_coverage(true);
  lib ^= ExecuteScript(kScript);
  IsolateGroup::Current()->set_branch_coverage(old_branch_coverage);
  ASSERT(!lib.IsNull());
  const Script& script =
      Script::Handle(lib.LookupScript(String::Handle(String::New("test-lib"))));

  SourceReport report(SourceReport::kBranchCoverage);
  JSONStream js;
  report.PrintJSON(&js, script);
  const char* json_str = js.ToCString();
  ASSERT(strlen(json_str) < kBufferSize);
  ElideJSONSubstring("classes", json_str, buffer);
  ElideJSONSubstring("libraries", buffer, buffer);
  EXPECT_STREQ(
      "{\"type\":\"SourceReport\",\"ranges\":["

      // In tryTestInner, the try/catch/finally and the try/finally are all hit,
      // and the try/finally rethrows its exception.
      "{\"scriptIndex\":0,\"startPos\":1,\"endPos\":126,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[1,29,62,76,89,120],\"misses\":[]}},"

      // In tryTestOuter, the exception thrown by tryTestInner causes both the
      // try and the catch to be hit.
      "{\"scriptIndex\":0,\"startPos\":129,\"endPos\":199,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[129,157,193],\"misses\":[]}},"

      // Main is hit.
      "{\"scriptIndex\":0,\"startPos\":202,\"endPos\":229,\"compiled\":true,"
      "\"branchCoverage\":{\"hits\":[202],\"misses\":[]}}],"

      // Only one script in the script table.
      "\"scripts\":[{\"type\":\"@Script\",\"fixedId\":true,\"id\":\"\","
      "\"uri\":\"file:\\/\\/\\/test-lib\",\"_kind\":\"kernel\"}]}",
      buffer);
}

#endif  // !PRODUCT

}  // namespace dart
