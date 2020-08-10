// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:expect/expect.dart';

import 'package:test_runner/src/feature.dart';
import 'package:test_runner/src/path.dart';
import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/test_file.dart';

import 'utils.dart';

// Note: This test file validates how some of the special markers used by the
// test runner are parsed. But this test is also run *by* that same test
// runner, and we don't want it to see the markers inside the string literals
// here as significant, so we obfuscate them using seemingly-pointless string
// escapes here like `\/`.

void main() {
  testParseDill();
  testParseVMOptions();
  testParseOtherOptions();
  testParseEnvironment();
  testParsePackages();
  testParseExperiments();
  testParseMultitest();
  testParseErrorFlags();
  testParseErrorExpectations();
  testIsRuntimeTest();
  testName();
  testMultitest();
  testShardHash();
}

void testParseDill() {
  // Handles ".dill" files.
  var file = parseTestFile("", path: "test.dill");
  Expect.isNotNull(file.vmOptions);
  Expect.equals(1, file.vmOptions.length);
  Expect.listEquals(<String>[], file.vmOptions.first);

  Expect.listEquals(<String>[], file.dartOptions);
  Expect.listEquals(<String>[], file.sharedOptions);
  Expect.listEquals(<String>[], file.dart2jsOptions);
  Expect.listEquals(<String>[], file.ddcOptions);
  Expect.listEquals(<String>[], file.otherResources);
  Expect.listEquals(<String>[], file.sharedObjects);

  Expect.isNull(file.environment);
  Expect.isNull(file.packages);

  Expect.isFalse(file.isMultitest);

  Expect.isFalse(file.hasSyntaxError);
  Expect.isFalse(file.hasCompileError);
  Expect.isFalse(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);
}

void testParseVMOptions() {
  expectVMOptions(String source, List<List<String>> expected) {
    var file = parseTestFile(source);
    Expect.isNotNull(file.vmOptions);
    Expect.equals(expected.length, file.vmOptions.length);
    for (var i = 0; i < expected.length; i++) {
      Expect.listEquals(expected[i], file.vmOptions[i]);
    }
  }

  // No options.
  expectVMOptions("", [[]]);

  // Splits words.
  expectVMOptions("/\/ VMOptions=--verbose --async", [
    ["--verbose", "--async"]
  ]);

  // Allows multiple.
  expectVMOptions("""
  /\/ VMOptions=--first one
  /\/ VMOptions=--second two
  """, [
    ["--first", "one"],
    ["--second", "two"]
  ]);
}

void testParseOtherOptions() {
  // No options.
  var file = parseTestFile("");
  Expect.listEquals(<String>[], file.dartOptions);
  Expect.listEquals(<String>[], file.sharedOptions);
  Expect.listEquals(<String>[], file.dart2jsOptions);
  Expect.listEquals(<String>[], file.ddcOptions);
  Expect.listEquals(<String>[], file.otherResources);
  Expect.listEquals(<String>[], file.sharedObjects);
  Expect.listEquals(<String>[], file.requirements);

  // Single options split into words.
  file = parseTestFile("""
  /\/ DartOptions=dart options
  /\/ SharedOptions=shared options
  /\/ dart2jsOptions=dart2js options
  /\/ dartdevcOptions=ddc options
  /\/ OtherResources=other resources
  /\/ SharedObjects=shared objects
  /\/ Requirements=nnbd nnbd-strong
  """);
  Expect.listEquals(["dart", "options"], file.dartOptions);
  Expect.listEquals(["shared", "options"], file.sharedOptions);
  Expect.listEquals(["dart2js", "options"], file.dart2jsOptions);
  Expect.listEquals(["ddc", "options"], file.ddcOptions);
  Expect.listEquals(["other", "resources"], file.otherResources);
  Expect.listEquals([Feature.nnbd, Feature.nnbdStrong], file.requirements);

  // Disallows multiple lines for some options.
  expectParseThrows("""
  /\/ DartOptions=first
  /\/ DartOptions=second
  """);
  expectParseThrows("""
  /\/ SharedOptions=first
  /\/ SharedOptions=second
  """);
  expectParseThrows("""
  /\/ dart2jsOptions=first
  /\/ dart2jsOptions=second
  """);
  expectParseThrows("""
  /\/ dartdevcOptions=first
  /\/ dartdevcOptions=second
  """);
  expectParseThrows("""
  /\/ Requirements=nnbd
  /\/ Requirements=nnbd-strong
  """);

  // Merges multiple lines for others.
  file = parseTestFile("""
  /\/ OtherResources=other resources
  /\/ OtherResources=even more
  /\/ SharedObjects=shared objects
  /\/ SharedObjects=many more
  """);
  Expect.listEquals(
      ["other", "resources", "even", "more"], file.otherResources);
  Expect.listEquals(["shared", "objects", "many", "more"], file.sharedObjects);

  // Disallows unrecognized features in requirements.
  expectParseThrows("""
  /\/ Requirements=unknown-feature
  """);
}

void testParseEnvironment() {
  // No environment.
  var file = parseTestFile("");
  Expect.isNull(file.environment);

  // Without values.
  file = parseTestFile("""
  /\/ Environment=some value
  /\/ Environment=another one
  """);
  Expect.mapEquals({"some value": "", "another one": ""}, file.environment);

  // With values.
  file = parseTestFile("""
  /\/ Environment=some value=its value
  /\/ Environment=another one   =   also value
  """);
  Expect.mapEquals(
      {"some value": "its value", "another one   ": "   also value"},
      file.environment);
}

void testParsePackages() {
  // No option.
  var file = parseTestFile("");
  Expect.isNull(file.packages);

  // Single option is converted to a path.
  file = parseTestFile("""
  /\/ Packages=packages thing
  """);
  Expect.isTrue(
      file.packages.endsWith("${Platform.pathSeparator}packages thing"));

  // "none" is left alone.
  file = parseTestFile("""
  /\/ Packages=none
  """);
  Expect.equals("none", file.packages);

  // Cannot appear more than once.
  expectParseThrows("""
  /\/ Packages=first
  /\/ Packages=second
  """);
}

void testParseExperiments() {
  // No option.
  var file = parseTestFile("");
  Expect.isTrue(file.experiments.isEmpty);

  // Single non-experiment option.
  file = parseTestFile("""
  /\/ SharedOptions=not-experiment
  """);
  Expect.isTrue(file.experiments.isEmpty);
  Expect.listEquals(["not-experiment"], file.sharedOptions);

  // Experiments.
  file = parseTestFile("""
  /\/ SharedOptions=--enable-experiment=flubber,gloop
  """);
  Expect.listEquals(["flubber", "gloop"], file.experiments);
  Expect.isTrue(file.sharedOptions.isEmpty);

  // Experiment option mixed with other options.
  file = parseTestFile("""
  /\/ SharedOptions=-a --enable-experiment=flubber --other
  """);
  Expect.listEquals(["flubber"], file.experiments);
  Expect.listEquals(["-a", "--other"], file.sharedOptions);

  // Poorly-formatted experiment option.
  expectParseThrows("""
  /\/ SharedOptions=stuff--enable-experiment=flubber,gloop
  """);
}

void testParseMultitest() {
  // Not present.
  var file = parseTestFile("");
  Expect.isFalse(file.isMultitest);

  // Present.
  file = parseTestFile("""
  main() {} /\/# 01: compile-time error
  """);
  Expect.isTrue(file.isMultitest);
}

void testParseErrorFlags() {
  // Not present.
  var file = parseTestFile("");
  Expect.isFalse(file.hasSyntaxError);
  Expect.isFalse(file.hasCompileError);
  Expect.isFalse(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);

  file = parseTestFile("@syntax\-error");
  Expect.isTrue(file.hasSyntaxError);
  Expect.isTrue(file.hasCompileError); // Note: true.
  Expect.isFalse(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);

  file = parseTestFile("@compile\-error");
  Expect.isFalse(file.hasSyntaxError);
  Expect.isTrue(file.hasCompileError);
  Expect.isFalse(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);

  file = parseTestFile("@runtime\-error");
  Expect.isFalse(file.hasSyntaxError);
  Expect.isFalse(file.hasCompileError);
  Expect.isTrue(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);

  file = parseTestFile("@static\-warning");
  Expect.isFalse(file.hasSyntaxError);
  Expect.isFalse(file.hasCompileError);
  Expect.isFalse(file.hasRuntimeError);
  Expect.isTrue(file.hasStaticWarning);
  Expect.isFalse(file.hasCrash);
}

void testParseErrorExpectations() {
  // No errors.
  expectParseErrorExpectations("""
main() {}
""", []);

  // Empty file
  expectParseErrorExpectations("", []);

  // Multiple errors.
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^
/\/ [analyzer] CompileTimeErrorCode.WRONG_TYPE
/\/ [cfe] Error: Can't assign a string to an int.
/\/ [web] Web-specific error.

num j = "str";
  /\/    ^^^^^
/\/ [analyzer] CompileTimeErrorCode.ALSO_WRONG_TYPE
    /\/ [cfe] Error: Can't assign a string to a num.
/\/ [web] Another web error.
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        analyzerError: "CompileTimeErrorCode.WRONG_TYPE",
        cfeError: "Error: Can't assign a string to an int.",
        webError: "Web-specific error."),
    makeError(
        line: 7,
        column: 9,
        length: 5,
        analyzerError: "CompileTimeErrorCode.ALSO_WRONG_TYPE",
        cfeError: "Error: Can't assign a string to a num.",
        webError: "Another web error.")
  ]);

  // Explicit error location.
  expectParseErrorExpectations("""
/\/ [error line 123, column 45, length 678]
/\/ [analyzer] CompileTimeErrorCode.FIRST
/\/ [cfe] First error.
  /\/   [ error line   23  ,  column   5  ,  length   78  ]
/\/ [analyzer] CompileTimeErrorCode.SECOND
/\/ [cfe] Second error.
/\/ [web] Second web error.
/\/[error line 9,column 8,length 7]
/\/ [cfe] Third.
/\/[error line 10,column 9]
/\/ [cfe] No length.
""", [
    makeError(
        line: 123,
        column: 45,
        length: 678,
        analyzerError: "CompileTimeErrorCode.FIRST",
        cfeError: "First error."),
    makeError(
        line: 23,
        column: 5,
        length: 78,
        analyzerError: "CompileTimeErrorCode.SECOND",
        cfeError: "Second error.",
        webError: "Second web error."),
    makeError(line: 9, column: 8, length: 7, cfeError: "Third."),
    makeError(line: 10, column: 9, cfeError: "No length.")
  ]);

  // Multi-line error message.
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^
/\/ [analyzer] CompileTimeErrorCode.WRONG_TYPE
/\/ [cfe] First line.
/\/Second line.
    /\/     Third line.
/\/ [web] Web first line.
/\/Web second line.
    /\/     Web third line.

/\/ The preceding blank line ends the message.
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        analyzerError: "CompileTimeErrorCode.WRONG_TYPE",
        cfeError: "First line.\nSecond line.\nThird line.",
        webError: "Web first line.\nWeb second line.\nWeb third line.")
  ]);

  // Multiple errors attached to same line.
  expectParseErrorExpectations("""
main() {}
int i = "s";
/\/      ^^^
/\/ [cfe] First error.
/\/    ^
/\/ [analyzer] ErrorCode.second
/\/  ^^^^^^^
/\/ [cfe] Third error.
""", [
    makeError(line: 2, column: 9, length: 3, cfeError: "First error."),
    makeError(line: 2, column: 7, length: 1, analyzerError: "ErrorCode.second"),
    makeError(line: 2, column: 5, length: 7, cfeError: "Third error."),
  ]);

  // Unspecified errors.
  expectParseErrorExpectations("""
int i = "s";
/\/     ^^^
// [analyzer] unspecified
// [cfe] unspecified
// [web] unspecified
int j = "s";
/\/     ^^^
// [analyzer] unspecified
// [cfe] Message.
int k = "s";
/\/     ^^^
// [analyzer] Error.CODE
// [cfe] unspecified
int l = "s";
/\/     ^^^
// [analyzer] unspecified
int m = "s";
/\/     ^^^
// [cfe] unspecified
int n = "s";
/\/     ^^^
// [web] unspecified
""", [
    makeError(
        line: 1,
        column: 8,
        length: 3,
        analyzerError: "unspecified",
        cfeError: "unspecified",
        webError: "unspecified"),
    makeError(
        line: 6,
        column: 8,
        length: 3,
        analyzerError: "unspecified",
        cfeError: "Message."),
    makeError(
        line: 10,
        column: 8,
        length: 3,
        analyzerError: "Error.CODE",
        cfeError: "unspecified"),
    makeError(line: 14, column: 8, length: 3, analyzerError: "unspecified"),
    makeError(line: 17, column: 8, length: 3, cfeError: "unspecified"),
    makeError(line: 20, column: 8, length: 3, webError: "unspecified"),
  ]);

  // Ignore multitest markers.
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^ /\/# 0: ok
/\/ [analyzer] ErrorCode.BAD_THING /\/# 123: continued
/\/ [cfe] Message.  /\/# named: compile-time error
/\/ More message.  /\/#   another: ok
/\/ [error line 12, column 34, length 56]  /\/# 3: continued
/\/ [cfe] Message.
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        analyzerError: "ErrorCode.BAD_THING",
        cfeError: "Message.\nMore message."),
    makeError(line: 12, column: 34, length: 56, cfeError: "Message."),
  ]);

  // Allow front ends in any order.
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^
/\/ [cfe] Error message.
/\/ [analyzer] ErrorCode.BAD_THING
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        analyzerError: "ErrorCode.BAD_THING",
        cfeError: "Error message."),
  ]);
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^
/\/ [web] Web message.
/\/ [analyzer] ErrorCode.BAD_THING
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        analyzerError: "ErrorCode.BAD_THING",
        webError: "Web message."),
  ]);
  expectParseErrorExpectations("""
int i = "s";
/\/      ^^^
/\/ [web] Web message.
/\/ [cfe] Error message.
""", [
    makeError(
        line: 1,
        column: 9,
        length: 3,
        cfeError: "Error message.",
        webError: "Web message."),
  ]);

  // Must have at least one error message.
  expectFormatError("""
int i = "s";
/\/      ^^^

var wrong;
""");

  // Location must follow some real code.
  expectFormatError("""
/\/ [error line 123, column 45, length 678]
/\/ [analyzer] CompileTimeErrorCode.FIRST
/\/ ^^^
/\/ [cfe] This doesn't make sense.
""");

  // Location at end without message.
  expectFormatError("""
int i = "s";
/\/ ^^^
""");

  // Must recognize the front end.
  expectFormatError("""
int i = "s";
/\/ ^^^
/\/ [wat] Error message.
""");

  // Analyzer error must look like an error code.
  expectFormatError("""
int i = "s";
/\/      ^^^
/\/ [analyzer] Not error code.
""");

  // A CFE-only error with length one is treated as having no length.
  expectParseErrorExpectations("""
int i = "s";
/\/      ^
/\/ [cfe] Message.

int j = "s";
/\/      ^
/\/ [analyzer] Error.BAD
/\/ [cfe] Message.

int j = "s";
/\/      ^
/\/ [cfe] Message.
/\/ [web] Web message.
""", [
    makeError(line: 1, column: 9, length: null, cfeError: "Message."),
    makeError(
        line: 5,
        column: 9,
        length: 1,
        analyzerError: "Error.BAD",
        cfeError: "Message."),
    makeError(
      line: 10,
      column: 9,
      length: 1,
      cfeError: "Message.",
      webError: "Web message.",
    ),
  ]);

  // Cannot have the same front end more than once.
  expectFormatError("""
int i = "s";
/\/      ^^^
/\/ [analyzer] ErrorCode.BAD_THING
/\/ [analyzer] ErrorCode.ANOTHER_THING
""");
  expectFormatError("""
int i = "s";
/\/      ^^^
/\/ [cfe] Message 1.
/\/ [cfe] Message 2.
""");
  expectFormatError("""
int i = "s";
/\/      ^^^
/\/ [web] Web 1.
/\/ [web] Web 2.
""");
}

void testIsRuntimeTest() {
  // No static errors at all.
  var file = parseTestFile("");
  Expect.isTrue(file.isRuntimeTest);

  // Only warnings.
  file = parseTestFile("""
  int i = "s";
  /\/ ^^^
  /\/ [analyzer] STATIC_WARNING.INVALID_OPTION
  /\/ ^^^
  /\/ [analyzer] STATIC_WARNING.INVALID_OPTION
  """);
  Expect.isTrue(file.isRuntimeTest);

  // Errors.
  file = parseTestFile("""
  int i = "s";
  /\/ ^^^
  /\/ [analyzer] COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS
  """);
  Expect.isFalse(file.isRuntimeTest);

  file = parseTestFile("""
  int i = "s";
  /\/ ^^^
  /\/ [cfe] Error message.
  """);
  Expect.isFalse(file.isRuntimeTest);

  file = parseTestFile("""
  int i = "s";
  /\/ ^^^
  /\/ [web] Error message.
  """);
  Expect.isFalse(file.isRuntimeTest);

  // Mixed errors and warnings.
  file = parseTestFile("""
  int i = "s";
  /\/ ^^^
  /\/ [analyzer] STATIC_WARNING.INVALID_OPTION
  /\/ [cfe] Error message.
  """);
  Expect.isFalse(file.isRuntimeTest);
}

void testName() {
  // Immediately inside suite.
  var file = TestFile.parse(Path("suite").absolute,
      Path("suite/a_test.dart").absolute.toNativePath(), "");
  Expect.equals("a_test", file.name);

  // Inside subdirectory.
  file = TestFile.parse(Path("suite").absolute,
      Path("suite/a/b/c_test.dart").absolute.toNativePath(), "");
  Expect.equals("a/b/c_test", file.name);

  // Multitest.
  file = file.split(Path("suite/a/b/c_test_00.dart").absolute, "00", "");
  Expect.equals("a/b/c_test/00", file.name);
}

void testMultitest() {
  var file = parseTestFile("", path: "origin.dart");
  Expect.isFalse(file.hasSyntaxError);
  Expect.isFalse(file.hasCompileError);
  Expect.isFalse(file.hasRuntimeError);
  Expect.isFalse(file.hasStaticWarning);

  var a = file.split(Path("a.dart").absolute, "a", "", hasSyntaxError: true);
  Expect.isTrue(a.originPath.toNativePath().endsWith("origin.dart"));
  Expect.isTrue(a.path.toNativePath().endsWith("a.dart"));
  Expect.isTrue(a.hasSyntaxError);
  Expect.isFalse(a.hasCompileError);
  Expect.isFalse(a.hasRuntimeError);
  Expect.isFalse(a.hasStaticWarning);

  var b = file.split(
    Path("b.dart").absolute,
    "b",
    "",
    hasCompileError: true,
  );
  Expect.isTrue(b.originPath.toNativePath().endsWith("origin.dart"));
  Expect.isTrue(b.path.toNativePath().endsWith("b.dart"));
  Expect.isFalse(b.hasSyntaxError);
  Expect.isTrue(b.hasCompileError);
  Expect.isFalse(b.hasRuntimeError);
  Expect.isFalse(b.hasStaticWarning);

  var c = file.split(Path("c.dart").absolute, "c", "", hasRuntimeError: true);
  Expect.isTrue(c.originPath.toNativePath().endsWith("origin.dart"));
  Expect.isTrue(c.path.toNativePath().endsWith("c.dart"));
  Expect.isFalse(c.hasSyntaxError);
  Expect.isFalse(c.hasCompileError);
  Expect.isTrue(c.hasRuntimeError);
  Expect.isFalse(c.hasStaticWarning);

  var d = file.split(Path("d.dart").absolute, "d", "", hasStaticWarning: true);
  Expect.isTrue(d.originPath.toNativePath().endsWith("origin.dart"));
  Expect.isTrue(d.path.toNativePath().endsWith("d.dart"));
  Expect.isFalse(d.hasSyntaxError);
  Expect.isFalse(d.hasCompileError);
  Expect.isFalse(d.hasRuntimeError);
  Expect.isTrue(d.hasStaticWarning);
}

void testShardHash() {
  // Test files with paths should successfully return some kind of integer. We
  // don't want to depend on the hash algorithm, so we can't really be more
  // specific than that.
  var testFile = parseTestFile("", path: "a_test.dart");
  Expect.isTrue(testFile.shardHash is int);

  // VM test files are hard-coded to return hash zero because they don't have a
  // path to base the hash on.
  Expect.equals(0, TestFile.vmUnitTest().shardHash);
}

void expectParseErrorExpectations(String source, List<StaticError> errors) {
  var file = parseTestFile(source);
  Expect.listEquals(errors.map((error) => error.toString()).toList(),
      file.expectedErrors.map((error) => error.toString()).toList());
}

void expectFormatError(String source) {
  Expect.throwsFormatException(() => parseTestFile(source));
}

void expectParseThrows(String source) {
  Expect.throws(() => parseTestFile(source));
}
