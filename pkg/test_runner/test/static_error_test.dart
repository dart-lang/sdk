// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:test_runner/src/static_error.dart';

void main() {
  testFlags();
  testIsSpecifiedFor();
  testCompareTo();
  testDescribeDifferences();
  testSimplify();
  testValidate();
}

void testFlags() {
  var unspecified = StaticError(
      line: 1,
      column: 2,
      length: 3,
      code: "unspecified",
      message: "unspecified");
  var unspecifiedAnalyzer =
      StaticError(line: 1, column: 2, length: 3, code: "unspecified");
  var unspecifiedCfe =
      StaticError(line: 1, column: 2, length: 3, message: "unspecified");
  var noLength = StaticError(line: 1, column: 2, code: "E.CODE");
  var analyzer = StaticError(line: 1, column: 2, length: 3, code: "E.CODE");
  var cfe = StaticError(line: 1, column: 2, length: 3, message: "E.");
  var both =
      StaticError(line: 1, column: 2, length: 3, code: "E.CODE", message: "E.");

  // isAnalyzer.
  Expect.isTrue(unspecified.isAnalyzer);
  Expect.isTrue(unspecifiedAnalyzer.isAnalyzer);
  Expect.isFalse(unspecifiedCfe.isAnalyzer);
  Expect.isTrue(noLength.isAnalyzer);
  Expect.isTrue(analyzer.isAnalyzer);
  Expect.isFalse(cfe.isAnalyzer);
  Expect.isTrue(both.isAnalyzer);

  // isCfe.
  Expect.isTrue(unspecified.isCfe);
  Expect.isFalse(unspecifiedAnalyzer.isCfe);
  Expect.isTrue(unspecifiedCfe.isCfe);
  Expect.isFalse(noLength.isCfe);
  Expect.isFalse(analyzer.isCfe);
  Expect.isTrue(cfe.isCfe);
  Expect.isTrue(both.isCfe);
}

void testIsSpecifiedFor() {
  var specifiedBoth = StaticError(
      line: 1, column: 2, length: 3, code: "ERR.CODE", message: "Message.");
  var unspecifiedBoth = StaticError(
      line: 1,
      column: 2,
      length: 3,
      code: "unspecified",
      message: "unspecified");
  var specifiedAnalyzer = StaticError(
      line: 1, column: 2, length: 3, code: "ERR.CODE", message: "unspecified");
  var specifiedCfe = StaticError(
      line: 1, column: 2, length: 3, code: "unspecified", message: "Message.");

  var specifiedAnalyzerOnly =
      StaticError(line: 1, column: 2, length: 3, code: "ERR.CODE");
  var specifiedCfeOnly =
      StaticError(line: 1, column: 2, length: 3, message: "Message.");

  var unspecifiedAnalyzerOnly =
      StaticError(line: 1, column: 2, length: 3, code: "unspecified");
  var unspecifiedCfeOnly =
      StaticError(line: 1, column: 2, length: 3, message: "unspecified");

  var analyzer = StaticError(line: 1, column: 2, length: 3, code: "E.CODE");
  var cfe = StaticError(line: 1, column: 2, length: 3, message: "E.");

  // isSpecifiedFor().
  Expect.isTrue(specifiedBoth.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedBoth.isSpecifiedFor(cfe));

  Expect.isFalse(unspecifiedBoth.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedBoth.isSpecifiedFor(cfe));

  Expect.isTrue(specifiedAnalyzer.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedAnalyzer.isSpecifiedFor(cfe));

  Expect.isFalse(specifiedCfe.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedCfe.isSpecifiedFor(cfe));

  Expect.isTrue(specifiedAnalyzerOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedAnalyzerOnly.isSpecifiedFor(cfe));

  Expect.isFalse(specifiedCfeOnly.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedCfeOnly.isSpecifiedFor(cfe));

  Expect.isFalse(unspecifiedAnalyzerOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedAnalyzerOnly.isSpecifiedFor(cfe));

  Expect.isFalse(unspecifiedCfeOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedCfeOnly.isSpecifiedFor(cfe));
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

  // Unspecified errors.
  var unspecified = StaticError(
      line: 2,
      column: 3,
      length: 4,
      code: "unspecified",
      message: "unspecified");
  var specifiedAnalyzer = StaticError(
      line: 2,
      column: 3,
      length: 4,
      code: "Error.CODE",
      message: "unspecified");
  var specifiedCfe = StaticError(
      line: 2,
      column: 3,
      length: 4,
      code: "unspecified",
      message: "Error message.");

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
          length: 4,
          code: "Weird.ERROR",
          message: "Error message."),
      """
  Expected on line 2 but was on 3.
  """);

  // Ignores differences in other fields.
  expectNoDifferences(
      unspecified,
      StaticError(
          line: 2,
          column: 333,
          length: 4444,
          code: "Different.CODE",
          message: "Different message."));

  // If error is specified on analyzer, must match fields when actual is
  // analyzer error.
  expectDifferences(specifiedAnalyzer,
      StaticError(line: 2, column: 5, length: 6, code: "Weird.ERROR"), """
  Expected on column 3 but was on 5.
  Expected length 4 but was 6.
  Expected error code Error.CODE but was Weird.ERROR.
  """);
  expectNoDifferences(specifiedAnalyzer,
      StaticError(line: 2, column: 333, length: 444, message: "Message."));
  expectNoDifferences(specifiedAnalyzer,
      StaticError(line: 2, column: 3, length: 4, code: "Error.CODE"));

  // If error is specified on CFE, must match fields when actual is
  // CFE error.
  expectDifferences(
      specifiedCfe,
      StaticError(line: 2, column: 5, length: 6, message: "Different message."),
      """
  Expected on column 3 but was on 5.
  Expected length 4 but was 6.
  Expected error message 'Error message.' but was 'Different message.'.
  """);
  expectNoDifferences(specifiedCfe,
      StaticError(line: 2, column: 333, length: 444, code: "Error.CODE."));
  expectNoDifferences(specifiedCfe,
      StaticError(line: 2, column: 3, length: 4, message: "Error message."));
}

void testSimplify() {
  // Merges errors if one has only a code and the only a message.
  expectSimplify([
    StaticError(line: 1, column: 2, length: 3, code: "Weird.ERROR"),
    StaticError(line: 1, column: 2, length: 3, message: "Message.")
  ], [
    StaticError(
        line: 1, column: 2, length: 3, code: "Weird.ERROR", message: "Message.")
  ]);

  // Merges if length is null.
  expectSimplify([
    StaticError(line: 1, column: 1, code: "A.ERR"),
    StaticError(line: 1, column: 1, length: 3, message: "A."),
    StaticError(line: 2, column: 1, length: 4, code: "B.ERR"),
    StaticError(line: 2, column: 1, message: "B."),
    StaticError(line: 3, column: 1, code: "C.ERR"),
    StaticError(line: 3, column: 1, message: "C."),
  ], [
    StaticError(line: 1, column: 1, length: 3, code: "A.ERR", message: "A."),
    StaticError(line: 2, column: 1, length: 4, code: "B.ERR", message: "B."),
    StaticError(line: 3, column: 1, code: "C.ERR", message: "C."),
  ]);

  // Merges multiple errors with no length with errors that have length.
  expectSimplify([
    StaticError(line: 1, column: 2, length: 3, code: "ERROR.A"),
    StaticError(line: 1, column: 4, length: 3, code: "ERROR.C"),
    StaticError(line: 1, column: 2, length: 5, code: "ERROR.B"),
    StaticError(line: 1, column: 2, message: "One."),
    StaticError(line: 1, column: 4, message: "Three."),
    StaticError(line: 1, column: 2, message: "Two."),
  ], [
    StaticError(
        line: 1, column: 2, length: 3, code: "ERROR.A", message: "One."),
    StaticError(
        line: 1, column: 2, length: 5, code: "ERROR.B", message: "Two."),
    StaticError(
        line: 1, column: 4, length: 3, code: "ERROR.C", message: "Three."),
  ]);

  // Merges even if not adjacent in input array.
  expectSimplify([
    StaticError(line: 1, column: 2, length: 3, code: "Some.ERROR"),
    StaticError(line: 10, column: 2, length: 3, code: "Other.ERROR"),
    StaticError(line: 1, column: 2, length: 3, message: "Message.")
  ], [
    StaticError(
        line: 1, column: 2, length: 3, code: "Some.ERROR", message: "Message."),
    StaticError(line: 10, column: 2, length: 3, code: "Other.ERROR")
  ]);

  // Does not merge if positions differ.
  expectSimplify([
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 2, column: 1, length: 1, message: "A."),
  ], [
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 2, column: 1, length: 1, message: "A."),
  ]);
  expectSimplify([
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 1, column: 2, length: 1, message: "A."),
  ], [
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 1, column: 2, length: 1, message: "A."),
  ]);
  expectSimplify([
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 1, column: 1, length: 2, message: "A."),
  ], [
    StaticError(line: 1, column: 1, length: 1, code: "A.ERR"),
    StaticError(line: 1, column: 1, length: 2, message: "A."),
  ]);

  // Does not merge if it would lose code or message.
  expectSimplify([
    StaticError(line: 1, column: 1, length: 1, code: "ERR.ONE"),
    StaticError(line: 1, column: 1, length: 1, code: "ERR.TWO"),
    StaticError(line: 2, column: 1, length: 1, message: "One."),
    StaticError(line: 2, column: 1, length: 1, message: "Two."),
  ], [
    StaticError(line: 1, column: 1, length: 1, code: "ERR.ONE"),
    StaticError(line: 1, column: 1, length: 1, code: "ERR.TWO"),
    StaticError(line: 2, column: 1, length: 1, message: "One."),
    StaticError(line: 2, column: 1, length: 1, message: "Two."),
  ]);

  // Orders output.
  expectSimplify([
    StaticError(line: 2, column: 1, length: 1, message: "Two."),
    StaticError(line: 3, column: 1, length: 1, message: "Three."),
    StaticError(line: 1, column: 1, length: 1, message: "One."),
  ], [
    StaticError(line: 1, column: 1, length: 1, message: "One."),
    StaticError(line: 2, column: 1, length: 1, message: "Two."),
    StaticError(line: 3, column: 1, length: 1, message: "Three."),
  ]);
}

void testValidate() {
  // No errors.
  expectValidate([], [], null);

  // Same errors.
  expectValidate([
    StaticError(line: 1, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "Two."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C", message: "Tres."),
  ], [
    // Order doesn't matter.
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C", message: "Tres."),
    StaticError(line: 1, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "Two."),
  ], null);

  // Ignore fields that aren't in actual errors.
  expectValidate([
    StaticError(line: 1, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "Two."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C", message: "Tres."),
  ], [
    StaticError(line: 1, column: 2, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 3, message: "Two."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C"),
  ], null);

  // Catches differences in any field.
  expectValidate([
    StaticError(line: 1, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "Two."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C", message: "Tres."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.D", message: "Four."),
  ], [
    StaticError(line: 1, column: 9, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 2, column: 2, length: 9, code: "ERR.B", message: "Two."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.Z", message: "Tres."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.D", message: "Zzz."),
  ], """
Wrong static error at line 1, column 2, length 3:
- Expected on column 2 but was on 9.

Wrong static error at line 2, column 2, length 3:
- Expected length 3 but was 9.

Wrong static error at line 3, column 2, length 3:
- Expected error code ERR.C but was ERR.Z.

Wrong static error at line 4, column 2, length 3:
- Expected error message 'Four.' but was 'Zzz.'.""");

  // Unexpected errors.
  expectValidate([
    StaticError(line: 2, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.B", message: "Two."),
    StaticError(line: 6, column: 2, length: 3, code: "ERR.C", message: "Tres."),
  ], [
    StaticError(line: 1, column: 2, length: 3, code: "ERR.W", message: "1."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.A", message: "One."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.X", message: "3."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.B", message: "Two."),
    StaticError(line: 5, column: 2, length: 3, code: "ERR.Y", message: "5."),
    StaticError(line: 6, column: 2, length: 3, code: "ERR.C", message: "Tres."),
    StaticError(line: 7, column: 2, length: 3, code: "ERR.Z", message: "7."),
  ], """
Unexpected static error at line 1, column 2, length 3:
- Had error code ERR.W.
- Had error message '1.'.

Unexpected static error at line 3, column 2, length 3:
- Had error code ERR.X.
- Had error message '3.'.

Unexpected static error at line 5, column 2, length 3:
- Had error code ERR.Y.
- Had error message '5.'.

Unexpected static error at line 7, column 2, length 3:
- Had error code ERR.Z.
- Had error message '7.'.""");

  // Missing errors.
  expectValidate([
    StaticError(line: 1, column: 2, length: 3, code: "ERR.A", message: "1."),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "2."),
    StaticError(line: 3, column: 2, length: 3, code: "ERR.C", message: "3."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.D", message: "4."),
    StaticError(line: 5, column: 2, length: 3, code: "ERR.E", message: "5."),
    StaticError(line: 6, column: 2, length: 3, code: "ERR.F", message: "6."),
    StaticError(line: 7, column: 2, length: 3, code: "ERR.G", message: "7."),
  ], [
    StaticError(line: 2, column: 2, length: 3, code: "ERR.B", message: "2."),
    StaticError(line: 4, column: 2, length: 3, code: "ERR.D", message: "4."),
    StaticError(line: 6, column: 2, length: 3, code: "ERR.F", message: "6."),
  ], """
Missing static error at line 1, column 2, length 3:
- Expected error code ERR.A.
- Expected error message '1.'.

Missing static error at line 3, column 2, length 3:
- Expected error code ERR.C.
- Expected error message '3.'.

Missing static error at line 5, column 2, length 3:
- Expected error code ERR.E.
- Expected error message '5.'.

Missing static error at line 7, column 2, length 3:
- Expected error code ERR.G.
- Expected error message '7.'.""");

  // Unspecified errors.
  expectValidate([
    // Missing.
    StaticError(line: 1, column: 2, length: 3, code: "unspecified"),
    StaticError(line: 2, column: 2, length: 3, message: "unspecified"),
    StaticError(
        line: 3,
        column: 2,
        length: 3,
        code: "unspecified",
        message: "unspecified"),

    // Right.
    StaticError(line: 4, column: 2, length: 3, code: "unspecified"),
    StaticError(line: 5, column: 2, length: 3, message: "unspecified"),
    StaticError(
        line: 6,
        column: 2,
        length: 3,
        code: "unspecified",
        message: "unspecified"),
  ], [
    StaticError(line: 4, column: 2, length: 3, code: "ACT.UAL"),
    StaticError(line: 5, column: 2, length: 3, message: "Actual."),
    StaticError(
        line: 6, column: 2, length: 3, code: "ACT.UAL", message: "Actual."),

    // Unexpected.
    StaticError(line: 7, column: 9, length: 3, code: "ACT.UAL"),
  ], """
Missing static error at line 1, column 2, length 3:
- Expected unspecified error code.

Missing static error at line 2, column 2, length 3:
- Expected unspecified error message.

Missing static error at line 3, column 2, length 3:
- Expected unspecified error code.
- Expected unspecified error message.

Unexpected static error at line 7, column 9, length 3:
- Had error code ACT.UAL.""");

  // Unspecified errors can match multiple errors on the same line.

  // Unspecified CFE-only error.
  expectValidate([
    StaticError(line: 2, column: 2, length: 3, message: "unspecified"),
  ], [
    StaticError(line: 2, column: 1, length: 3, message: "Actual 1."),
    StaticError(line: 2, column: 2, length: 3, message: "Actual 2."),
    StaticError(line: 2, column: 3, length: 3, message: "Actual 3."),
  ], null);

  // Unspecified on both.
  expectValidate([
    StaticError(
        line: 2,
        column: 2,
        length: 3,
        code: "unspecified",
        message: "unspecified"),
  ], [
    StaticError(line: 2, column: 1, length: 3, message: "Actual 1."),
    StaticError(line: 2, column: 2, length: 3, message: "Actual 2."),
    StaticError(line: 2, column: 3, length: 3, message: "Actual 3."),
  ], null);

  // Unspecified on CFE, specified on analyzer.
  expectValidate([
    StaticError(
        line: 2,
        column: 2,
        length: 3,
        code: "ERR.CODE",
        message: "unspecified"),
  ], [
    StaticError(line: 2, column: 1, length: 3, message: "Actual 1."),
    StaticError(line: 2, column: 2, length: 3, message: "Actual 2."),
    StaticError(line: 2, column: 3, length: 3, message: "Actual 3."),
  ], null);

  // Specified on CFE, unspecified on analyzer.
  expectValidate([
    StaticError(
        line: 2,
        column: 1,
        length: 3,
        code: "unspecified",
        message: "Actual 1."),
  ], [
    // These are not matched.
    StaticError(line: 2, column: 1, length: 3, message: "Actual 1."),
    StaticError(line: 2, column: 2, length: 3, message: "Actual 2."),
    StaticError(line: 2, column: 3, length: 3, message: "Actual 3."),
  ], """
Unexpected static error at line 2, column 2, length 3:
- Had error message 'Actual 2.'.

Unexpected static error at line 2, column 3, length 3:
- Had error message 'Actual 3.'.""");

  // Unspecified analyzer-only error.
  expectValidate([
    StaticError(line: 2, column: 1, length: 3, code: "unspecified"),
  ], [
    StaticError(line: 2, column: 1, length: 3, code: "ERR.CODE1"),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.CODE2"),
    StaticError(line: 2, column: 3, length: 3, code: "ERR.CODE3"),
  ], null);

  // Unspecified on both.
  expectValidate([
    StaticError(
        line: 2,
        column: 1,
        length: 3,
        code: "unspecified",
        message: "unspecified"),
  ], [
    StaticError(line: 2, column: 1, length: 3, code: "ERR.CODE1"),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.CODE2"),
    StaticError(line: 2, column: 3, length: 3, code: "ERR.CODE3"),
  ], null);

  // Unspecified on analyzer, specified on CFE.
  expectValidate([
    StaticError(
        line: 2,
        column: 1,
        length: 3,
        code: "unspecified",
        message: "Message."),
  ], [
    StaticError(line: 2, column: 1, length: 3, code: "ERR.CODE1"),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.CODE2"),
    StaticError(line: 2, column: 3, length: 3, code: "ERR.CODE3"),
  ], null);

  // Specified on analyzer, unspecified on CFE.
  expectValidate([
    StaticError(
        line: 2,
        column: 1,
        length: 3,
        code: "ERR.CODE1",
        message: "unspecified"),
  ], [
    // These are not matched.
    StaticError(line: 2, column: 1, length: 3, code: "ERR.CODE1"),
    StaticError(line: 2, column: 2, length: 3, code: "ERR.CODE2"),
    StaticError(line: 2, column: 3, length: 3, code: "ERR.CODE3"),
  ], """
Unexpected static error at line 2, column 2, length 3:
- Had error code ERR.CODE2.

Unexpected static error at line 2, column 3, length 3:
- Had error code ERR.CODE3.""");
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

void expectSimplify(List<StaticError> input, List<StaticError> expected) {
  var actual = StaticError.simplify(input);
  Expect.listEquals(expected.map((error) => error.toString()).toList(),
      actual.map((error) => error.toString()).toList());
}

void expectValidate(List<StaticError> expected, List<StaticError> actual,
    String expectedValidation) {
  var actualValidation = StaticError.validateExpectations(expected, actual);
  Expect.stringEquals(expectedValidation, actualValidation);
}
