// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:test_runner/src/static_error.dart';

import 'utils.dart';

void main() {
  testProperties();
  testIsWarning();
  testCompareTo();
  testValidate();
}

void testProperties() {
  var analyzer = StaticError(ErrorSource.analyzer, "E.CODE",
      line: 1, column: 2, length: 3, sourceLines: {1, 3, 5});
  Expect.equals(analyzer.source, ErrorSource.analyzer);
  Expect.equals(analyzer.message, "E.CODE");
  Expect.equals(analyzer.line, 1);
  Expect.equals(analyzer.column, 2);
  Expect.equals(analyzer.length, 3);
  Expect.isTrue(analyzer.isSpecified);
  Expect.setEquals({1, 3, 5}, analyzer.sourceLines);

  var cfe = StaticError(ErrorSource.cfe, "Error.", line: 4, column: 5);
  Expect.equals(cfe.source, ErrorSource.cfe);
  Expect.equals(cfe.message, "Error.");
  Expect.equals(cfe.line, 4);
  Expect.equals(cfe.column, 5);
  Expect.isNull(cfe.length);
  Expect.isTrue(cfe.isSpecified);
  Expect.isTrue(cfe.sourceLines.isEmpty);

  var unspecified =
      StaticError(ErrorSource.web, "unspecified", line: 1, column: 2);
  Expect.isFalse(unspecified.isSpecified);
}

void testIsWarning() {
  // Analyzer only.
  Expect.isTrue(
      makeError(analyzerError: "STATIC_WARNING.INVALID_OPTION").isWarning);
  Expect.isFalse(
      makeError(analyzerError: "SYNTACTIC_ERROR.MISSING_FUNCTION_BODY")
          .isWarning);
  Expect.isFalse(makeError(
          analyzerError: "COMPILE_TIME_ERROR.NOT_ENOUGH_POSITIONAL_ARGUMENTS")
      .isWarning);

  // CFE only.
  Expect.isFalse(makeError(cfeError: "Any error message.").isWarning);

  // Web only.
  Expect.isFalse(makeError(webError: "Any error message.").isWarning);
}

void testCompareTo() {
  var errors = [
    // Order by line.
    makeError(line: 1, column: 2, length: 2, cfeError: "E."),
    makeError(line: 2, column: 1, length: 1, cfeError: "E."),

    // Then column.
    makeError(line: 3, column: 1, length: 2, cfeError: "E."),
    makeError(line: 3, column: 2, length: 1, cfeError: "E."),

    // Then length.
    makeError(line: 4, column: 1, length: 1, cfeError: "Z."),
    makeError(line: 4, column: 1, length: 2, cfeError: "A."),

    // Then source.
    makeError(line: 5, column: 1, length: 1, analyzerError: "Z.CODE"),
    makeError(line: 5, column: 1, length: 1, cfeError: "A."),

    // Then message.
    makeError(line: 6, column: 1, length: 1, cfeError: "A."),
    makeError(line: 6, column: 1, length: 1, cfeError: "Z."),
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

void testValidate() {
  // No errors.
  expectValidate([], [], null);

  // Same errors.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.C"),
  ], [
    // Order doesn't matter.
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.C"),
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
  ], null);

  // Catches differences in any field.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.C"),
  ], [
    makeError(line: 1, column: 9, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 9, analyzerError: "ERR.B"),
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.Z"),
  ], """
- Wrong error location line 1, column 2, length 3: ERR.A
  Expected column 2 but was column 9.

- Wrong error location line 2, column 2, length 3: ERR.B
  Expected length 3 but was length 9.

- Wrong message at line 3, column 2, length 3: ERR.Z
  Expected: ERR.C""");

  expectValidate([
    makeError(line: 4, column: 2, length: 3, cfeError: "Four."),
  ], [
    makeError(line: 4, column: 2, length: 3, cfeError: "Zzz."),
  ], """
- Wrong message at line 4, column 2, length 3: Zzz.
  Expected: Four.""");

  expectValidate([
    makeError(line: 5, column: 2, length: 3, webError: "Web 5."),
  ], [
    makeError(line: 5, column: 2, length: 3, webError: "Web Z."),
  ], """
- Wrong message at line 5, column 2, length 3: Web Z.
  Expected: Web 5.""");

  // Unexpected errors.
  expectValidate([
    makeError(line: 2, column: 2, length: 3, cfeError: "One."),
    makeError(line: 4, column: 2, length: 3, cfeError: "Two."),
    makeError(line: 6, column: 2, length: 3, cfeError: "Tres."),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "1."),
    makeError(line: 2, column: 2, length: 3, cfeError: "One."),
    makeError(line: 3, column: 2, length: 3, cfeError: "3."),
    makeError(line: 4, column: 2, length: 3, cfeError: "Two."),
    makeError(line: 5, column: 2, length: 3, cfeError: "5."),
    makeError(line: 6, column: 2, length: 3, cfeError: "Tres."),
    makeError(line: 7, column: 2, length: 3, cfeError: "7."),
  ], """
- Unexpected error at line 1, column 2, length 3: 1.

- Unexpected error at line 3, column 2, length 3: 3.

- Unexpected error at line 5, column 2, length 3: 5.

- Unexpected error at line 7, column 2, length 3: 7.""");

  // Missing errors.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.C"),
    makeError(line: 4, column: 2, length: 3, analyzerError: "ERR.D"),
    makeError(line: 5, column: 2, length: 3, analyzerError: "ERR.E"),
  ], [
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
    makeError(line: 4, column: 2, length: 3, analyzerError: "ERR.D"),
  ], """
- Missing expected error at line 1, column 2, length 3: ERR.A

- Missing expected error at line 3, column 2, length 3: ERR.C

- Missing expected error at line 5, column 2, length 3: ERR.E""");

  // Unspecified errors.
  expectValidate([
    // Missing.
    makeError(line: 2, column: 2, length: 3, cfeError: "unspecified"),

    // Right.
    makeError(line: 6, column: 2, length: 3, cfeError: "unspecified"),
  ], [
    makeError(line: 6, column: 2, length: 3, cfeError: "Actual 1."),

    // Unexpected.
    makeError(line: 9, column: 9, length: 3, cfeError: "Actual 2."),
  ], """
- Missing expected unspecified error at line 2, column 2, length 3.

- Unexpected error at line 9, column 9, length 3: Actual 2.""");

  // Unspecified errors can match multiple errors on the same line.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, analyzerError: "unspecified"),
  ], [
    makeError(line: 1, column: 1, length: 3, analyzerError: "ERROR.CODE1"),
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERROR.CODE2"),
    makeError(line: 1, column: 3, length: 3, analyzerError: "ERROR.CODE3"),
  ], null);

  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "unspecified"),
  ], [
    makeError(line: 1, column: 1, length: 3, cfeError: "Actual 1."),
    makeError(line: 1, column: 2, length: 3, cfeError: "Actual 2."),
    makeError(line: 1, column: 3, length: 3, cfeError: "Actual 3."),
  ], null);

  expectValidate([
    makeError(line: 1, column: 2, length: 3, webError: "unspecified"),
  ], [
    makeError(line: 1, column: 1, length: 3, webError: "Web 1."),
    makeError(line: 1, column: 2, length: 3, webError: "Web 2."),
    makeError(line: 1, column: 3, length: 3, webError: "Web 3."),
  ], null);

  // If expectation has context, actual must match it.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], null);

  // Actual context is different.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context Z."),
    ]),
  ], """
- Wrong context message at line 4, column 5, length 6: Context Z.
  Expected: Context A.""");

  // Missing some actual context.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], """
- Missing expected context message at line 4, column 5, length 6: Context A.""");

  // Missing all actual context.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error."),
  ], """
- Missing expected context message at line 4, column 5, length 6: Context A.

- Missing expected context message at line 7, column 8, length 9: Context B.""");

  // Unexpected extra actual context.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], """
- Unexpected context message at line 7, column 8, length 9: Context B.""");

  // Actual context owned by wrong error.
  // TODO(rnystrom): This error is pretty confusing. Ideally we would detect
  // this case specifically and give better guidance.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error A.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 33, column: 5, length: 6, contextError: "Context."),
    ]),
    makeError(line: 10, column: 2, length: 3, cfeError: "Error B.", context: [
      makeError(line: 11, column: 5, length: 6, contextError: "Context B."),
    ]),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error A.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
    ]),
    makeError(line: 10, column: 2, length: 3, cfeError: "Error B.", context: [
      makeError(line: 11, column: 5, length: 6, contextError: "Context B."),
      makeError(line: 33, column: 5, length: 6, contextError: "Context."),
    ]),
  ], """
- Missing expected context message at line 33, column 5, length 6: Context.

- Unexpected context message at line 33, column 5, length 6: Context.""");

  // If expectation has no context at all, then ignore actual context.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "Error."),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "Error.", context: [
      makeError(line: 4, column: 5, length: 6, contextError: "Context A."),
      makeError(line: 7, column: 8, length: 9, contextError: "Context B."),
    ]),
  ], null);
}

void expectValidate(List<StaticError> expected, List<StaticError> actual,
    String expectedValidation) {
  var actualValidation = StaticError.validateExpectations(expected, actual);
  Expect.stringEquals(expectedValidation, actualValidation);
}
