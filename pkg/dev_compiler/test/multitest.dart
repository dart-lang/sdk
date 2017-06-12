// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this was factored out of
// dart-lang/sdk/tools/testing/dart/multitest.dart
library dev_compiler.test.tools.multitest;

final validMultitestOutcomes = new Set<String>.from([
  'ok',
  'compile-time error',
  'runtime error',
  'static type warning',
  'dynamic type error',
  'checked mode compile-time error'
]);

final runtimeErrorOutcomes = [
  'runtime error',
  'dynamic type error',
];

// Require at least one non-space character before '//#'
// Handle both //# and the legacy /// multitest regexp patterns.
final _multiTestRegExp = new RegExp(r"\S *//[#/] \w+:(.*)");

final _multiTestRegExpSeperator = new RegExp(r"//[#/]");

bool isMultiTest(String contents) => _multiTestRegExp.hasMatch(contents);

// Multitests are Dart test scripts containing lines of the form
// " [some dart code] /// [key]: [error type]"
//
// For each key in the file, a new test file is made containing all
// the normal lines of the file, and all of the multitest lines containing
// that key, in the same order as in the source file.  The new test is expected
// to pass if the error type listed is 'ok', or to fail if there is an error
// type of type 'compile-time error', 'runtime error', 'static type warning', or
// 'dynamic type error'.  The type error tests fail only in checked mode.
// There is also a test created from only the untagged lines of the file,
// with key "none", which is expected to pass.  This library extracts these
// tests, writes them into a temporary directory, and passes them to the test
// runner.  These tests may be referred to in the status files with the
// pattern [test name]/[key].
//
// For example: file I_am_a_multitest.dart
//   aaa
//   bbb //# 02: runtime error
//   ccc //# 02: continued
//   ddd //# 07: static type warning
//   eee //# 10: ok
//   fff
//
// should create four tests:
// I_am_a_multitest_none.dart
//   aaa
//   fff
//
// I_am_a_multitest_02.dart
//   aaa
//   bbb //# 02: runtime error
//   ccc //# 02: continued
//   fff
//
// I_am_a_multitest_07.dart
//   aaa
//   ddd //# 07: static type warning
//   fff
//
// and I_am_a_multitest_10.dart
//   aaa
//   eee //# 10: ok
//   fff
//
// Note that it is possible to indicate more than one acceptable outcome
// in the case of dynamic and static type warnings
//   aaa
//   ddd //# 07: static type warning, dynamic type error
//   fff

void extractTestsFromMultitest(String filePath, String contents,
    Map<String, String> tests, Map<String, Set<String>> outcomes) {
  int first_newline = contents.indexOf('\n');
  final String line_separator =
      (first_newline == 0 || contents[first_newline - 1] != '\r')
          ? '\n'
          : '\r\n';
  List<String> lines = contents.split(line_separator);
  if (lines.last == '') lines.removeLast();
  contents = null;

  // Create the set of multitests, which will have a new test added each
  // time we see a multitest line with a new key.
  Map<String, List<String>> testsAsLines = new Map<String, List<String>>();

  // Add the default case with key "none".
  testsAsLines['none'] = new List<String>();
  outcomes['none'] = new Set<String>();

  int lineCount = 0;
  for (String line in lines) {
    lineCount++;
    var annotation = new _Annotation.from(line);
    if (annotation != null) {
      testsAsLines.putIfAbsent(
          annotation.key, () => new List<String>.from(testsAsLines["none"]));
      // Add line to test with annotation.key as key, empty line to the rest.
      for (var key in testsAsLines.keys) {
        testsAsLines[key].add(annotation.key == key ? line : "");
      }
      outcomes.putIfAbsent(annotation.key, () => new Set<String>());
      if (annotation.rest != 'continued') {
        for (String nextOutcome in annotation.outcomesList) {
          if (validMultitestOutcomes.contains(nextOutcome)) {
            outcomes[annotation.key].add(nextOutcome);
          } else {
            print("Warning: Invalid test directive '$nextOutcome' on line "
                "${lineCount}:\n${annotation.rest} ");
          }
        }
      }
    } else {
      for (var test in testsAsLines.values) test.add(line);
    }
  }
  // End marker, has a final line separator so we don't need to add it after
  // joining the lines.
  var marker = '// Test created from multitest named $filePath.'
      '$line_separator';
  testsAsLines.forEach((key, test) {
    if (runtimeErrorOutcomes.any(outcomes[key].contains)) {
      test.add('final _expectRuntimeError = true;');
    }
    test.add(marker);
  });

  var keysToDelete = [];
  // Check that every key (other than the none case) has at least one outcome
  for (var outcomeKey in outcomes.keys) {
    if (outcomeKey != 'none' && outcomes[outcomeKey].isEmpty) {
      print("Warning: Test ${outcomeKey} has no valid annotated outcomes.\n"
          "Expected one of: ${validMultitestOutcomes.toString()}");
      // If this multitest doesn't have an outcome, mark the multitest for
      // deletion.
      keysToDelete.add(outcomeKey);
    }
  }
  // If a key/multitest was marked for deletion, do the necessary cleanup.
  keysToDelete.forEach(outcomes.remove);
  keysToDelete.forEach(testsAsLines.remove);

  // Copy all the tests into the output map tests, as multiline strings.
  for (String key in testsAsLines.keys) {
    tests[key] = testsAsLines[key].join(line_separator);
  }
}

// Represents a mutlitest annotation in the special //# comment.
class _Annotation {
  String key;
  String rest;
  List<String> outcomesList;
  _Annotation() {}
  factory _Annotation.from(String line) {
    // Do an early return with "null" if this is not a valid multitest
    // annotation.
    if (!line.contains(_multiTestRegExpSeperator)) {
      return null;
    }
    var parts = line
        .split(_multiTestRegExpSeperator)[1]
        .split(':')
        .map((s) => s.trim())
        .where((s) => s.length > 0)
        .toList();
    if (parts.length <= 1) {
      return null;
    }

    var annotation = new _Annotation();
    annotation.key = parts[0];
    annotation.rest = parts[1];
    annotation.outcomesList =
        annotation.rest.split(',').map((s) => s.trim()).toList();
    return annotation;
  }
}
