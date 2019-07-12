// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:test_runner/src/test_file.dart';

void main() {
  testFlags();
  testCompareTo();
  testDescribeDifferences();
}

void testFlags() {
  var unspecified = StaticError.unspecified(1);
  var noLength = StaticError(line: 1, column: 2, code: "E.CODE");
  var analyzer = StaticError(line: 1, column: 2, length: 3, code: "E.CODE");
  var cfe = StaticError(line: 1, column: 2, length: 3, message: "E.");
  var both =
      StaticError(line: 1, column: 2, length: 3, code: "E.CODE", message: "E.");

  // isUnspecified.
  Expect.isTrue(unspecified.isUnspecified);
  Expect.isFalse(noLength.isUnspecified);
  Expect.isFalse(analyzer.isUnspecified);
  Expect.isFalse(cfe.isUnspecified);
  Expect.isFalse(both.isUnspecified);

  // isAnalyzer.
  Expect.isTrue(unspecified.isAnalyzer);
  Expect.isTrue(noLength.isAnalyzer);
  Expect.isTrue(analyzer.isAnalyzer);
  Expect.isFalse(cfe.isAnalyzer);
  Expect.isTrue(both.isAnalyzer);

  // isCfe.
  Expect.isTrue(unspecified.isCfe);
  Expect.isFalse(noLength.isCfe);
  Expect.isFalse(analyzer.isCfe);
  Expect.isTrue(cfe.isCfe);
  Expect.isTrue(both.isCfe);
}

void testCompareTo() {
  var errors = [
    // Order by line.
    StaticError(line: 1, column: 2, length: 2, code: "E.CODE", message: "E."),
    StaticError(line: 2, column: 1, length: 1, code: "E.CODE", message: "E."),

    // Then column.
    StaticError(line: 3, column: 1, length: 2, code: "E.CODE", message: "E."),
    StaticError(
        line: 3, column: 2, length: 1, code: "Error.CODE", message: "E."),

    // Then length.
    StaticError(line: 4, column: 1, length: 1, code: "Z.CODE", message: "Z."),
    StaticError(line: 4, column: 1, length: 2, code: "A.CODE", message: "A."),

    // Then code.
    StaticError(line: 5, column: 1, length: 1, message: "Z."),
    StaticError(line: 5, column: 1, length: 1, code: "A.CODE", message: "Z."),
    StaticError(line: 5, column: 1, length: 1, code: "Z.CODE", message: "Z."),

    // Then message.
    StaticError(line: 6, column: 1, length: 1, code: "E.CODE"),
    StaticError(line: 6, column: 1, length: 1, code: "E.CODE", message: "A."),
    StaticError(line: 6, column: 1, length: 1, code: "E.CODE", message: "Z."),

    // Unspecified before specified.
    StaticError.unspecified(7),
    StaticError(line: 7, column: 1, length: 1, code: "E.CODE", message: "E."),
  ];

  // Every pair of errors in the array should be ordered correctly.
  for (var i = 0; i < errors.length; i++) {
    for (var j = 0; j < errors.length; j++) {
      var expected = (i - j).sign;
      Expect.equals(expected, errors[i].compareTo(errors[j]),
          "Expected $expected comparison for:\n${errors[i]}\n${errors[j]}");
    }
  }
}

void testDescribeDifferences() {
  var precise = StaticError(
      line: 2,
      column: 3,
      length: 4,
      code: "Error.CODE",
      message: "Error message.");

  // Perfect match.
  expectNoDifferences(
      precise,
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."));

  // Ignore null code.
  expectNoDifferences(
      StaticError(line: 2, column: 3, length: 4, message: "Error message."),
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."));
  expectNoDifferences(
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."),
      StaticError(line: 2, column: 3, length: 4, message: "Error message."));

  // Ignore null message.
  expectNoDifferences(
      StaticError(line: 2, column: 3, length: 4, code: "Error.CODE"),
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."));
  expectNoDifferences(
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."),
      StaticError(line: 2, column: 3, length: 4, code: "Error.CODE"));

  // Different line.
  expectDifferences(
      precise,
      StaticError(
          line: 4,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."),
      """
  Expected on line 2 but was on 4.
  """);

  // Different column.
  expectDifferences(
      precise,
      StaticError(
          line: 2,
          column: 5,
          length: 4,
          code: "Error.CODE",
          message: "Error message."),
      """
  Expected on column 3 but was on 5.
  """);

  // Different length.
  expectDifferences(
      precise,
      StaticError(
          line: 2,
          column: 3,
          length: 6,
          code: "Error.CODE",
          message: "Error message."),
      """
  Expected length 4 but was 6.
  """);

  // Different code.
  expectDifferences(
      precise,
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Weird.ERROR",
          message: "Error message."),
      """
  Expected error code Error.CODE but was Weird.ERROR.
  """);

  // Different message.
  expectDifferences(
      precise,
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Funny story."),
      """
  Expected error message 'Error message.' but was 'Funny story.'.
  """);

  // Multiple differences.
  expectDifferences(
      precise,
      StaticError(
          line: 4,
          column: 3,
          length: 6,
          code: "Weird.ERROR",
          message: "Error message."),
      """
  Expected on line 2 but was on 4.
  Expected length 4 but was 6.
  Expected error code Error.CODE but was Weird.ERROR.
  """);

  var unspecified = StaticError.unspecified(2);

  // Matches if line is right.
  expectNoDifferences(
      unspecified,
      StaticError(
          line: 2,
          column: 3,
          length: 4,
          code: "Error.CODE",
          message: "Error message."));

  // Does not match if lines differ.
  expectDifferences(
      unspecified,
      StaticError(
          line: 3,
          column: 3,
          length: 6,
          code: "Weird.ERROR",
          message: "Error message."),
      """
  Expected unspecified error on line 2 but was on 3.
  """);
}

void expectNoDifferences(StaticError expectedError, StaticError actualError) {
  var actualLines = expectedError.describeDifferences(actualError);
  if (actualLines != null) {
    Expect.fail("Expected no differences, but got:\n${actualLines.join('\n')}");
  }
}

void expectDifferences(StaticError expectedError, StaticError actualError,
    String expectedDifferences) {
  var expectedLines = expectedDifferences
      .split("\n")
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  var actualLines = expectedError.describeDifferences(actualError);
  if (actualLines == null) {
    Expect.fail("Got no differences, but expected:\n$expectedDifferences");
  }
  Expect.listEquals(expectedLines, actualLines);
}
