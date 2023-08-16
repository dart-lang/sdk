import 'dart:convert';

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/fasta/hybrid_file_system.dart';

import "../tool/dart_doctest_impl.dart" as impl;

Future<void> main() async {
  expectCategory = "comment extraction";
  testCommentExtraction();

  expectCategory = "test extraction";
  testTestExtraction();

  expectCategory = "test runs";
  await testRunningTests();
}

Future<void> testRunningTests() async {
  MemoryFileSystem memoryFileSystem =
      new MemoryFileSystem(new Uri(scheme: "darttest", path: "/"));
  HybridFileSystem hybridFileSystem = new HybridFileSystem(memoryFileSystem);
  impl.DartDocTest dartDocTest = new impl.DartDocTest(
      underlyingFileSystem: hybridFileSystem, silent: true);

  // Good test
  Uri test1 = new Uri(scheme: "darttest", path: "/test1.dart");
  String test = """
  // DartDocTest(1+1, 2)
  main() {
    print("Hello from main");
  }

  // DartDocTest(_internal(), 42)
  int _internal() {
    return 42;
  }
  """;
  List<impl.Test> tests = extractTests(test, test1);
  expect(tests.length, 2);
  List<impl.TestResult> expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.Pass),
    new impl.TestResult(tests[1], impl.TestOutcome.Pass),
  ];
  memoryFileSystem.entityForUri(test1).writeAsStringSync(test);
  expect(await dartDocTest.process(test1), expected);

// Mixed good/bad.
  Uri test2 = new Uri(scheme: "darttest", path: "/test2.dart");
  test = """
// DartDocTest(1+1, 3)
main() {
  print("Hello from main");
}

// DartDocTest(_internal(), 43)
// DartDocTest(_internal(), 42)
int _internal() {
  return 42;
}
""";
  tests = extractTests(test, test2);
  expect(tests.length, 3);
  expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.Failed)
      ..message = "Expected '3'; got '2'.",
    new impl.TestResult(tests[1], impl.TestOutcome.Failed)
      ..message = "Expected '43'; got '42'.",
    new impl.TestResult(tests[2], impl.TestOutcome.Pass),
  ];
  memoryFileSystem.entityForUri(test2).writeAsStringSync(test);
  expect(await dartDocTest.process(test2), expected);

// Good case using await.
  Uri test3 = new Uri(scheme: "darttest", path: "/test3.dart");
  test = """
// DartDocTest(await _internal(), 42)
Future<int> _internal() async {
  await Future.delayed(new Duration(milliseconds: 1));
  return 42;
}
""";
  tests = extractTests(test, test3);
  expect(tests.length, 1);
  expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.Pass),
  ];
  memoryFileSystem.entityForUri(test3).writeAsStringSync(test);
  expect(await dartDocTest.process(test3), expected);

// One test parse error and one good case.
  Uri test4 = new Uri(scheme: "darttest", path: "/test4.dart");
  test = """
// DartDocTest(_internal() 42)
// DartDocTest(_internal(), 42)
int _internal() {
  return 42;
}
""";
  tests = extractTests(test, test4);
  expect(tests.length, 2);
  expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.TestCompilationError)
      ..message = "Parse error @ 27",
    new impl.TestResult(tests[1], impl.TestOutcome.Pass),
  ];
  memoryFileSystem.entityForUri(test4).writeAsStringSync(test);
  expect(await dartDocTest.process(test4), expected);

// Test with compile-time error. Note that this means no tests are compiled at
// all and that while the error messages are passed it spills the internals of
// the dartdocs stuff (e.g. the uri "dartdoctest:tester",
// calls to 'dartDocTest.test' etc).
  Uri test5 = new Uri(scheme: "darttest", path: "/test5.dart");
  test = """
// DartDocTest(_internal() + 2, 42)
// // DartDocTest(2+2, 4)
void _internal() {
  return;
}
""";
  tests = extractTests(test);
  expect(tests.length, 2);
  expected = [
    new impl.TestResult(null, impl.TestOutcome.CompilationError)
      ..message =
          """dartdoctest:tester:3:20: Error: This expression has type 'void' and can't be used.
  dartDocTest.test(_internal() + 2, 42);
                   ^
dartdoctest:tester:3:32: Error: The operator '+' isn't defined for the class 'void'.
Try correcting the operator to an existing operator, or defining a '+' operator.
  dartDocTest.test(_internal() + 2, 42);
                               ^""",
  ];
  memoryFileSystem.entityForUri(test5).writeAsStringSync(test);
  expect(await dartDocTest.process(test5), expected);

  // Test with runtime error.
  Uri test6 = new Uri(scheme: "darttest", path: "/test6.dart");
  test = """
// DartDocTest(_internal() + 2, 42)
// // DartDocTest(2+2, 4)
dynamic _internal() {
  return "hello";
}
""";
  tests = extractTests(test);
  expect(tests.length, 2);
  expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.Crash)
      // this weird message is from the VM!
      ..message = "type 'int' is not a subtype of type 'String' of 'other'",
    new impl.TestResult(tests[1], impl.TestOutcome.Pass),
  ];
  memoryFileSystem.entityForUri(test6).writeAsStringSync(test);
  expect(await dartDocTest.process(test6), expected);

  // Good/bad test with private static class method.
  Uri test7 = new Uri(scheme: "darttest", path: "/test7.dart");
  test = """
  class Foo {
    // DartDocTest(Foo._internal(), 42)
    // DartDocTest(Foo._internal(), 44)
    static int _internal() {
      return 42;
    }
  }
  """;
  tests = extractTests(test, test7);
  expect(tests.length, 2);
  expected = [
    new impl.TestResult(tests[0], impl.TestOutcome.Pass),
    new impl.TestResult(tests[1], impl.TestOutcome.Failed)
      ..message = "Expected '44'; got '42'.",
  ];
  memoryFileSystem.entityForUri(test7).writeAsStringSync(test);
  expect(await dartDocTest.process(test7), expected);
}

void testTestExtraction() {
  // No tests.
  expect(extractTests(""), <impl.Test>[]);

  // One test.
  expect(extractTests("// DartDocTest(1+1, 2)"), <impl.Test>[
    new impl.ExpectTest("1+1", "2"),
  ]);

  // Two tests.
  expect(extractTests("""
// DartDocTest(1+1, 2)
// DartDocTest(2+40, 42)
"""), <impl.Test>[
    new impl.ExpectTest("1+1", "2"),
    new impl.ExpectTest("2+40", "42"),
  ]);

  // Two valid tests. Four invalid ones.
  expect(extractTests("""
// DartDocTest(1+1, 2)
// DartDocTest(2+40; 42]
// DartDocTest(2+40+, 42]
// DartDocTest(2+40, 42]
// DartDocTest(2+40, 42)
// DartDocTest(2+40, 42+)
"""), <impl.Test>[
    new impl.ExpectTest("1+1", "2"),
    new impl.TestParseError(
        """darttest:/foo.dart:2:20: Expected ',' before this.
// DartDocTest(2+40; 42]
                   ^""", 42),
    new impl.TestParseError("""Parse error(s):

darttest:/foo.dart:3:21: Expected an identifier, but got ','.
// DartDocTest(2+40+, 42]
                    ^""", 68),
    new impl.TestParseError(
        """darttest:/foo.dart:4:24: Expected ')' before this.
// DartDocTest(2+40, 42]
                       ^""", 97),
    new impl.ExpectTest("2+40", "42"),
    new impl.TestParseError("""Parse error(s):

darttest:/foo.dart:6:25: Expected an identifier, but got ')'.
// DartDocTest(2+40, 42+)
                        ^""", 148),
  ]);

  // Two tests in block comments with back-ticks around tests.
  expect(extractTests("""
/**
 * This is a test:
 * ```
 * DartDocTest(1+1, 2)
 * ```
 * and so is this:
 * ```
 * DartDocTest(2+40, 42)
 * ```
 */
"""), <impl.Test>[
    new impl.ExpectTest("1+1", "2"),
    new impl.ExpectTest("2+40", "42"),
  ]);

  // Two tests --- include linebreaks.
  expect(extractTests("""
/*
  This is a test:
  DartDocTest(1+1,
    2)
  and so is this:
  DartDocTest(2+
  40,
  42)
 */
"""), <impl.Test>[
    new impl.ExpectTest("1+1", "2"),
    // The linebreak etc here is not stripped (at the moment at least)
    new impl.ExpectTest("2+\n  40", "42"),
  ]);

  // Two tests --- with parens and commas as string...
  expect(extractTests("""
// DartDocTest("(", "(")
// and so is this:
// DartDocTest(",)", ",)")
"""), <impl.Test>[
    new impl.ExpectTest('"("', '"("'),
    new impl.ExpectTest('",)"', '",)"'),
  ]);

  // Await expression.
  expect(extractTests("""
// DartDocTest(await foo(), 42)
"""), <impl.Test>[
    new impl.ExpectTest('await foo()', '42'),
  ]);
}

void testCommentExtraction() {
  // No comment
  expect(extractFirstComment(""), null);

  // Simple line comment at position 0.
  expect(
      extractFirstComment("// Hello"), new impl.CommentString("   Hello", 0));

  // Simple line comment at position 5.
  expect(extractFirstComment("     // Hello"),
      new impl.CommentString("   Hello", 5));

  // Multiline simple comment at position 20.
  expect(extractFirstComment("""
import 'foo.dart';

// This is
// a
// multiline
// comment

import 'bar.dart'"""), new impl.CommentString("""
   This is
   a
   multiline
   comment""", 20));

  // Multiline simple comment (with 3 slashes) at position 20.
  expect(extractFirstComment("""
import 'foo.dart';

/// This is
/// a
/// multiline
/// comment

import 'bar.dart'"""), new impl.CommentString("""
    This is
    a
    multiline
    comment""", 20));

  // Multiline comments with /* at position 20.
  expect(extractFirstComment("""
import 'foo.dart';

/* This is
a
 multiline
comment
*/

import 'bar.dart'"""), new impl.CommentString("""
   This is
a
 multiline
comment
  """, 20));

  // Multiline comments with /* at position 20. Note that the comment has
  // * at the start of the line but that they aren't stripped because the
  // comments starts with /* and NOT with /**.
  expect(extractFirstComment("""
import 'foo.dart';

/* This is
*a
* multiline
*comment
*/

import 'bar.dart'"""), new impl.CommentString("""
   This is
*a
* multiline
*comment
  """, 20));

  // Multiline comments with /** */ at position 20. Note that the comment has
  // * at the start of the line and that they are stripped because the
  // comments starts with /** and NOT with only /*.
  expect(extractFirstComment("""
import 'foo.dart';

/** This is
*a
* multiline
*comment
*/

import 'bar.dart'"""), new impl.CommentString("""
    This is
 a
  multiline
 comment
  """, 20));

  // Multiline comment with block comment inside at position 20.
  // The block comment data is not stripped.
  expect(extractFirstComment("""
import 'foo.dart';

/// This is
/// /*a*/
/// multiline comment"""), new impl.CommentString("""
    This is
    /*a*/
    multiline comment""", 20));
}

int expectCalls = 0;
String? expectCategory;

void expect(dynamic actual, dynamic expected) {
  expectCalls++;
  StringBuffer sb = new StringBuffer();
  if (!_expectImpl(actual, expected, sb)) {
    if (sb.isNotEmpty) {
      throw "Error! Expected '$expected' but got '$actual'"
          "\n\n"
          "Explanation: $sb.";
    } else {
      throw "Error! Expected '$expected' but got '$actual'";
    }
  }
  print("Expect #$expectCalls ($expectCategory) OK.");
}

bool _expectImpl(dynamic actual, dynamic expected, StringBuffer explainer) {
  if (identical(actual, expected)) return true;
  if (actual == expected) return true;
  if (actual == null || expected == null) return false;
  if (actual is List && expected is List) {
    if (actual.runtimeType != expected.runtimeType) {
      explainer.write("List runtimeType difference: "
          "${actual.runtimeType} vs ${expected.runtimeType}");
      return false;
    }
    if (actual.length != expected.length) {
      explainer.write("List length difference: "
          "${actual.length} vs ${expected.length}");
      return false;
    }
    for (int i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        explainer.write("List difference at index $i: "
            "${actual[i]} vs ${expected[i]}");
        return false;
      }
    }
    return true;
  }
  if (actual is List || expected is List) return false;

  if (actual is Map && expected is Map) {
    if (actual.runtimeType != expected.runtimeType) return false;
    if (actual.length != expected.length) return false;
    for (dynamic key in actual.keys) {
      if (!expected.containsKey(key)) return false;
      if (actual[key] != expected[key]) return false;
    }
    return true;
  }
  if (actual is Map || expected is Map) return false;

  if (actual is Set && expected is Set) {
    if (actual.runtimeType != expected.runtimeType) return false;
    if (actual.length != expected.length) return false;
    for (dynamic value in actual) {
      if (!expected.contains(value)) return false;
    }
    return true;
  }
  if (actual is Set || expected is Set) return false;

  // More stuff?
  return false;
}

impl.CommentString? extractFirstComment(String test) {
  Token firstToken = impl.scanRawBytes(utf8.encode(test));
  Token token = firstToken;
  while (true) {
    CommentToken? comment = token.precedingComments;
    if (comment != null) {
      return impl.extractComments(comment, test);
    }
    if (token.isEof) break;
    Token? next = token.next;
    if (next == null) break;
    token = next;
  }
  return null;
}

List<impl.Test> extractTests(String test, [Uri? uri]) {
  return impl.extractTests(
      utf8.encode(test), uri ?? new Uri(scheme: "darttest", path: "/foo.dart"));
}
