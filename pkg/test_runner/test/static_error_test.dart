// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:test_runner/src/static_error.dart';

import 'utils.dart';

void main() {
  testHasError();
  testErrorFor();
  testIsWarning();
  testIsSpecifiedFor();
  testCompareTo();
  testDescribeDifferences();
  testSimplify();
  testValidate();
}

void testHasError() {
  var analyzer =
      makeError(line: 1, column: 2, length: 3, analyzerError: "E.CODE");
  var cfe = makeError(line: 1, column: 2, length: 3, cfeError: "Error.");
  var web = makeError(line: 1, column: 2, length: 3, webError: "Web.");
  var all = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "E.CODE",
      cfeError: "Error.",
      webError: "Web.");

  Expect.isTrue(analyzer.hasError(ErrorSource.analyzer));
  Expect.isFalse(analyzer.hasError(ErrorSource.cfe));
  Expect.isFalse(analyzer.hasError(ErrorSource.web));

  Expect.isFalse(cfe.hasError(ErrorSource.analyzer));
  Expect.isTrue(cfe.hasError(ErrorSource.cfe));
  Expect.isFalse(cfe.hasError(ErrorSource.web));

  Expect.isFalse(web.hasError(ErrorSource.analyzer));
  Expect.isFalse(web.hasError(ErrorSource.cfe));
  Expect.isTrue(web.hasError(ErrorSource.web));

  Expect.isTrue(all.hasError(ErrorSource.analyzer));
  Expect.isTrue(all.hasError(ErrorSource.cfe));
  Expect.isTrue(all.hasError(ErrorSource.web));
}

void testErrorFor() {
  var analyzer =
      makeError(line: 1, column: 2, length: 3, analyzerError: "E.CODE");
  var cfe = makeError(line: 1, column: 2, length: 3, cfeError: "Error.");
  var web = makeError(line: 1, column: 2, length: 3, webError: "Web.");
  var all = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "E.CODE",
      cfeError: "Error.",
      webError: "Web.");

  Expect.equals("E.CODE", analyzer.errorFor(ErrorSource.analyzer));
  Expect.isNull(analyzer.errorFor(ErrorSource.cfe));
  Expect.isNull(analyzer.errorFor(ErrorSource.web));

  Expect.isNull(cfe.errorFor(ErrorSource.analyzer));
  Expect.equals("Error.", cfe.errorFor(ErrorSource.cfe));
  Expect.isNull(cfe.errorFor(ErrorSource.web));

  Expect.isNull(web.errorFor(ErrorSource.analyzer));
  Expect.isNull(web.errorFor(ErrorSource.cfe));
  Expect.equals("Web.", web.errorFor(ErrorSource.web));

  Expect.equals("E.CODE", all.errorFor(ErrorSource.analyzer));
  Expect.equals("Error.", all.errorFor(ErrorSource.cfe));
  Expect.equals("Web.", all.errorFor(ErrorSource.web));
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

  // Multiple front ends.
  Expect.isFalse(makeError(
          analyzerError: "STATIC_WARNING.INVALID_OPTION",
          cfeError: "Any error message.")
      .isWarning);
  Expect.isFalse(
      makeError(cfeError: "Any error message.", webError: "Any error message.")
          .isWarning);
  Expect.isFalse(makeError(
          analyzerError: "STATIC_WARNING.INVALID_OPTION",
          webError: "Any error message.")
      .isWarning);
  Expect.isFalse(makeError(
          analyzerError: "STATIC_WARNING.INVALID_OPTION",
          cfeError: "Any error message.",
          webError: "Any error message.")
      .isWarning);
}

void testIsSpecifiedFor() {
  var specifiedAll = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "ERR.CODE",
      cfeError: "Message.",
      webError: "Web.");
  var unspecifiedAll = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "unspecified",
      cfeError: "unspecified",
      webError: "unspecified");
  var specifiedAnalyzer = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "ERR.CODE",
      cfeError: "unspecified",
      webError: "unspecified");
  var specifiedCfe = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "unspecified",
      cfeError: "Message.",
      webError: "unspecified");
  var specifiedWeb = makeError(
      line: 1,
      column: 2,
      length: 3,
      analyzerError: "unspecified",
      cfeError: "unspecified",
      webError: "Web.");

  var specifiedAnalyzerOnly =
      makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.CODE");
  var specifiedCfeOnly =
      makeError(line: 1, column: 2, length: 3, cfeError: "Message.");
  var specifiedWebOnly =
      makeError(line: 1, column: 2, length: 3, webError: "Web.");

  var unspecifiedAnalyzerOnly =
      makeError(line: 1, column: 2, length: 3, analyzerError: "unspecified");
  var unspecifiedCfeOnly =
      makeError(line: 1, column: 2, length: 3, cfeError: "unspecified");
  var unspecifiedWebOnly =
      makeError(line: 1, column: 2, length: 3, webError: "unspecified");

  var analyzer =
      makeError(line: 1, column: 2, length: 3, analyzerError: "E.CODE");
  var cfe = makeError(line: 1, column: 2, length: 3, cfeError: "E.");
  var web = makeError(line: 1, column: 2, length: 3, webError: "E.");

  // isSpecifiedFor().
  Expect.isTrue(specifiedAll.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedAll.isSpecifiedFor(cfe));
  Expect.isTrue(specifiedAll.isSpecifiedFor(web));

  Expect.isFalse(unspecifiedAll.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedAll.isSpecifiedFor(cfe));
  Expect.isFalse(unspecifiedAll.isSpecifiedFor(web));

  Expect.isTrue(specifiedAnalyzer.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedAnalyzer.isSpecifiedFor(cfe));
  Expect.isFalse(specifiedAnalyzer.isSpecifiedFor(web));

  Expect.isFalse(specifiedCfe.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedCfe.isSpecifiedFor(cfe));
  Expect.isFalse(specifiedCfe.isSpecifiedFor(web));

  Expect.isFalse(specifiedWeb.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedWeb.isSpecifiedFor(cfe));
  Expect.isTrue(specifiedWeb.isSpecifiedFor(web));

  Expect.isTrue(specifiedAnalyzerOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedAnalyzerOnly.isSpecifiedFor(cfe));
  Expect.isFalse(specifiedAnalyzerOnly.isSpecifiedFor(web));

  Expect.isFalse(specifiedCfeOnly.isSpecifiedFor(analyzer));
  Expect.isTrue(specifiedCfeOnly.isSpecifiedFor(cfe));
  Expect.isFalse(specifiedCfeOnly.isSpecifiedFor(web));

  Expect.isFalse(specifiedWebOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(specifiedWebOnly.isSpecifiedFor(cfe));
  Expect.isTrue(specifiedWebOnly.isSpecifiedFor(web));

  Expect.isFalse(unspecifiedAnalyzerOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedAnalyzerOnly.isSpecifiedFor(cfe));
  Expect.isFalse(unspecifiedAnalyzerOnly.isSpecifiedFor(web));

  Expect.isFalse(unspecifiedCfeOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedCfeOnly.isSpecifiedFor(cfe));
  Expect.isFalse(unspecifiedCfeOnly.isSpecifiedFor(web));

  Expect.isFalse(unspecifiedWebOnly.isSpecifiedFor(analyzer));
  Expect.isFalse(unspecifiedWebOnly.isSpecifiedFor(cfe));
  Expect.isFalse(unspecifiedWebOnly.isSpecifiedFor(web));
}

void testCompareTo() {
  var errors = [
    // Order by line.
    makeError(
        line: 1, column: 2, length: 2, analyzerError: "E.CODE", cfeError: "E."),
    makeError(
        line: 2, column: 1, length: 1, analyzerError: "E.CODE", cfeError: "E."),

    // Then column.
    makeError(
        line: 3, column: 1, length: 2, analyzerError: "E.CODE", cfeError: "E."),
    makeError(
        line: 3,
        column: 2,
        length: 1,
        analyzerError: "Error.CODE",
        cfeError: "E."),

    // Then length.
    makeError(
        line: 4, column: 1, length: 1, analyzerError: "Z.CODE", cfeError: "Z."),
    makeError(
        line: 4, column: 1, length: 2, analyzerError: "A.CODE", cfeError: "A."),

    // Then analyzer error.
    makeError(line: 5, column: 1, length: 1, cfeError: "Z."),
    makeError(
        line: 5, column: 1, length: 1, analyzerError: "A.CODE", cfeError: "Z."),
    makeError(
        line: 5, column: 1, length: 1, analyzerError: "Z.CODE", cfeError: "Z."),

    // Then CFE error.
    makeError(line: 6, column: 1, length: 1, analyzerError: "E.CODE"),
    makeError(
        line: 6,
        column: 1,
        length: 1,
        analyzerError: "E.CODE",
        cfeError: "A.",
        webError: "Z."),
    makeError(
        line: 6,
        column: 1,
        length: 1,
        analyzerError: "E.CODE",
        cfeError: "Z.",
        webError: "A."),

    // Then web error.
    makeError(line: 7, column: 1, length: 1, cfeError: "E."),
    makeError(line: 7, column: 1, length: 1, cfeError: "E.", webError: "A."),
    makeError(line: 7, column: 1, length: 1, cfeError: "E.", webError: "Z."),
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
  var precise = makeError(
      line: 2,
      column: 3,
      length: 4,
      analyzerError: "Error.CODE",
      cfeError: "Error message.",
      webError: "Web error.");

  // Perfect match.
  expectNoDifferences(precise,
      makeError(line: 2, column: 3, length: 4, analyzerError: "Error.CODE"));
  expectNoDifferences(precise,
      makeError(line: 2, column: 3, length: 4, cfeError: "Error message."));
  expectNoDifferences(precise,
      makeError(line: 2, column: 3, length: 4, webError: "Web error."));

  // Ignore null analyzer error.
  expectNoDifferences(
      makeError(
          line: 2,
          column: 3,
          length: 4,
          cfeError: "Error message.",
          webError: "Web error."),
      makeError(line: 2, column: 3, length: 4, cfeError: "Error message."));

  // Ignore null CFE error.
  expectNoDifferences(
      makeError(
          line: 2,
          column: 3,
          length: 4,
          analyzerError: "Error.CODE",
          webError: "Web error."),
      makeError(line: 2, column: 3, length: 4, analyzerError: "Error.CODE"));

  // Ignore null web error.
  expectNoDifferences(
      makeError(
          line: 2,
          column: 3,
          length: 4,
          analyzerError: "Error.CODE",
          cfeError: "Error message."),
      makeError(line: 2, column: 3, length: 4, cfeError: "Error message."));

  // Different line.
  expectDifferences(precise,
      makeError(line: 4, column: 3, length: 4, analyzerError: "Error.CODE"), """
  Expected on line 2 but was on 4.
  """);

  // Different column.
  expectDifferences(precise,
      makeError(line: 2, column: 5, length: 4, cfeError: "Error message."), """
  Expected on column 3 but was on 5.
  """);

  // Different length.
  expectDifferences(precise,
      makeError(line: 2, column: 3, length: 6, webError: "Web error."), """
  Expected length 4 but was 6.
  """);

  // Different analyzer error.
  expectDifferences(
      precise,
      makeError(line: 2, column: 3, length: 4, analyzerError: "Weird.ERROR"),
      """
  Expected analyzer error 'Error.CODE' but was 'Weird.ERROR'.
  """);

  // Different CFE error.
  expectDifferences(precise,
      makeError(line: 2, column: 3, length: 4, cfeError: "Funny story."), """
  Expected CFE error 'Error message.' but was 'Funny story.'.
  """);

  // Different web error.
  expectDifferences(precise,
      makeError(line: 2, column: 3, length: 4, webError: "Funny story."), """
  Expected web error 'Web error.' but was 'Funny story.'.
  """);

  // Multiple differences.
  expectDifferences(
      precise,
      makeError(line: 4, column: 3, length: 6, analyzerError: "Weird.ERROR"),
      """
  Expected on line 2 but was on 4.
  Expected length 4 but was 6.
  Expected analyzer error 'Error.CODE' but was 'Weird.ERROR'.
  """);

  // Unspecified errors.
  var unspecified = makeError(
      line: 2,
      column: 3,
      length: 4,
      analyzerError: "unspecified",
      cfeError: "unspecified",
      webError: "unspecified");
  var specifiedAnalyzer = makeError(
      line: 2,
      column: 3,
      length: 4,
      analyzerError: "Error.CODE",
      cfeError: "unspecified",
      webError: "unspecified");
  var specifiedCfe = makeError(
      line: 2,
      column: 3,
      length: 4,
      analyzerError: "unspecified",
      cfeError: "Error message.",
      webError: "unspecified");
  var specifiedWeb = makeError(
      line: 2,
      column: 3,
      length: 4,
      analyzerError: "unspecified",
      cfeError: "unspecified",
      webError: "Web error.");

  // Matches if line is right.
  expectNoDifferences(unspecified,
      makeError(line: 2, column: 3, length: 4, analyzerError: "Error.CODE"));

  // Does not match if lines differ.
  expectDifferences(unspecified,
      makeError(line: 3, column: 3, length: 4, cfeError: "Error message."), """
  Expected on line 2 but was on 3.
  """);

  // If error is specified on analyzer, must match fields when actual is
  // analyzer error.
  expectDifferences(
      specifiedAnalyzer,
      makeError(line: 2, column: 5, length: 6, analyzerError: "Weird.ERROR"),
      """
  Expected on column 3 but was on 5.
  Expected length 4 but was 6.
  Expected analyzer error 'Error.CODE' but was 'Weird.ERROR'.
  """);
  expectNoDifferences(specifiedAnalyzer,
      makeError(line: 2, column: 3, length: 4, analyzerError: "Error.CODE"));

  // If error is specified on CFE, must match fields when actual is
  // CFE error.
  expectDifferences(
      specifiedCfe,
      makeError(line: 2, column: 5, length: 6, cfeError: "Different message."),
      """
  Expected on column 3 but was on 5.
  Expected length 4 but was 6.
  Expected CFE error 'Error message.' but was 'Different message.'.
  """);
  expectNoDifferences(specifiedCfe,
      makeError(line: 2, column: 3, length: 4, cfeError: "Error message."));

  // If error is specified on web, must match fields when actual is web error.
  expectDifferences(
      specifiedWeb,
      makeError(line: 2, column: 5, length: 6, webError: "Different message."),
      """
  Expected on column 3 but was on 5.
  Expected length 4 but was 6.
  Expected web error 'Web error.' but was 'Different message.'.
  """);
  expectNoDifferences(specifiedWeb,
      makeError(line: 2, column: 3, length: 4, webError: "Web error."));
}

void testSimplify() {
  // Merges errors if each has only one error.
  expectSimplify([
    makeError(line: 1, column: 2, length: 3, analyzerError: "Weird.ERROR"),
    makeError(line: 1, column: 2, length: 3, cfeError: "Message."),
    makeError(line: 1, column: 2, length: 3, webError: "Web.")
  ], [
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "Weird.ERROR",
        cfeError: "Message.",
        webError: "Web.")
  ]);

  // Merges if length is null.
  expectSimplify([
    makeError(line: 1, column: 1, analyzerError: "A.ERR"),
    makeError(line: 1, column: 1, length: 3, cfeError: "A."),
    makeError(line: 2, column: 1, length: 4, analyzerError: "B.ERR"),
    makeError(line: 2, column: 1, webError: "B."),
    makeError(line: 3, column: 1, analyzerError: "C.ERR"),
    makeError(line: 3, column: 1, cfeError: "C."),
  ], [
    makeError(
        line: 1, column: 1, length: 3, analyzerError: "A.ERR", cfeError: "A."),
    makeError(
        line: 2, column: 1, length: 4, analyzerError: "B.ERR", webError: "B."),
    makeError(line: 3, column: 1, analyzerError: "C.ERR", cfeError: "C."),
  ]);

  // Merges multiple errors with no length with errors that have length.
  expectSimplify([
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERROR.A"),
    makeError(line: 1, column: 4, length: 3, analyzerError: "ERROR.C"),
    makeError(line: 1, column: 2, length: 5, analyzerError: "ERROR.B"),
    makeError(line: 1, column: 2, cfeError: "One."),
    makeError(line: 1, column: 4, cfeError: "Three."),
    makeError(line: 1, column: 2, cfeError: "Two."),
    makeError(line: 1, column: 2, webError: "Web 1."),
    makeError(line: 1, column: 2, webError: "Web 2."),
  ], [
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "ERROR.A",
        cfeError: "One.",
        webError: "Web 1."),
    makeError(
        line: 1,
        column: 2,
        length: 5,
        analyzerError: "ERROR.B",
        cfeError: "Two.",
        webError: "Web 2."),
    makeError(
        line: 1,
        column: 4,
        length: 3,
        analyzerError: "ERROR.C",
        cfeError: "Three."),
  ]);

  // Merges even if not adjacent in input array.
  expectSimplify([
    makeError(line: 1, column: 2, length: 3, analyzerError: "Some.ERROR"),
    makeError(line: 10, column: 2, length: 3, analyzerError: "Other.ERROR"),
    makeError(line: 1, column: 2, length: 3, cfeError: "Message."),
    makeError(line: 10, column: 2, length: 3, webError: "Web two."),
    makeError(line: 1, column: 2, length: 3, webError: "Web."),
  ], [
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "Some.ERROR",
        cfeError: "Message.",
        webError: "Web."),
    makeError(
        line: 10,
        column: 2,
        length: 3,
        analyzerError: "Other.ERROR",
        webError: "Web two.")
  ]);

  // Does not merge if positions differ.
  expectSimplify([
    makeError(line: 1, column: 1, length: 1, analyzerError: "A.ERR"),
    makeError(line: 2, column: 1, length: 1, cfeError: "A."),
  ], [
    makeError(line: 1, column: 1, length: 1, analyzerError: "A.ERR"),
    makeError(line: 2, column: 1, length: 1, cfeError: "A."),
  ]);
  expectSimplify([
    makeError(line: 1, column: 1, length: 1, analyzerError: "A.ERR"),
    makeError(line: 1, column: 2, length: 1, webError: "A."),
  ], [
    makeError(line: 1, column: 1, length: 1, analyzerError: "A.ERR"),
    makeError(line: 1, column: 2, length: 1, webError: "A."),
  ]);
  expectSimplify([
    makeError(line: 1, column: 1, length: 1, cfeError: "A."),
    makeError(line: 1, column: 1, length: 2, webError: "W."),
  ], [
    makeError(line: 1, column: 1, length: 1, cfeError: "A."),
    makeError(line: 1, column: 1, length: 2, webError: "W."),
  ]);

  // Does not merge if it would lose a message.
  expectSimplify([
    makeError(line: 1, column: 1, length: 1, analyzerError: "ERR.ONE"),
    makeError(line: 1, column: 1, length: 1, analyzerError: "ERR.TWO"),
    makeError(line: 2, column: 1, length: 1, cfeError: "One."),
    makeError(line: 2, column: 1, length: 1, cfeError: "Two."),
    makeError(line: 3, column: 1, length: 1, webError: "One."),
    makeError(line: 3, column: 1, length: 1, webError: "Two."),
  ], [
    makeError(line: 1, column: 1, length: 1, analyzerError: "ERR.ONE"),
    makeError(line: 1, column: 1, length: 1, analyzerError: "ERR.TWO"),
    makeError(line: 2, column: 1, length: 1, cfeError: "One."),
    makeError(line: 2, column: 1, length: 1, cfeError: "Two."),
    makeError(line: 3, column: 1, length: 1, webError: "One."),
    makeError(line: 3, column: 1, length: 1, webError: "Two."),
  ]);

  // Orders output.
  expectSimplify([
    makeError(line: 2, column: 1, length: 1, cfeError: "Two."),
    makeError(line: 3, column: 1, length: 1, cfeError: "Three."),
    makeError(line: 1, column: 1, length: 1, cfeError: "One."),
  ], [
    makeError(line: 1, column: 1, length: 1, cfeError: "One."),
    makeError(line: 2, column: 1, length: 1, cfeError: "Two."),
    makeError(line: 3, column: 1, length: 1, cfeError: "Three."),
  ]);
}

void testValidate() {
  // No errors.
  expectValidate([], [], null);

  // Same errors.
  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "ERR.A",
        cfeError: "One.",
        webError: "Web 1."),
    makeError(
        line: 2,
        column: 2,
        length: 3,
        analyzerError: "ERR.B",
        cfeError: "Two.",
        webError: "Web 2."),
    makeError(
        line: 3,
        column: 2,
        length: 3,
        analyzerError: "ERR.C",
        cfeError: "Tres.",
        webError: "Web 3."),
  ], [
    // Order doesn't matter.
    makeError(line: 3, column: 2, length: 3, analyzerError: "ERR.C"),
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERR.A"),
    makeError(line: 2, column: 2, length: 3, analyzerError: "ERR.B"),
  ], null);

  // Ignore fields that aren't in actual errors.
  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "ERR.A",
        cfeError: "One.",
        webError: "Web 1."),
    makeError(
        line: 2,
        column: 2,
        length: 3,
        analyzerError: "ERR.B",
        cfeError: "Two.",
        webError: "Web 2."),
    makeError(
        line: 3,
        column: 2,
        length: 3,
        analyzerError: "ERR.C",
        cfeError: "Tres.",
        webError: "Web 3."),
  ], [
    makeError(line: 1, column: 2, cfeError: "One."),
    makeError(line: 2, column: 2, length: 3, cfeError: "Two."),
    makeError(line: 3, column: 2, length: 3, cfeError: "Tres."),
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
Wrong static error at line 1, column 2, length 3:
- Expected on column 2 but was on 9.

Wrong static error at line 2, column 2, length 3:
- Expected length 3 but was 9.

Wrong static error at line 3, column 2, length 3:
- Expected analyzer error 'ERR.C' but was 'ERR.Z'.""");

  expectValidate([
    makeError(line: 4, column: 2, length: 3, cfeError: "Four."),
  ], [
    makeError(line: 4, column: 2, length: 3, cfeError: "Zzz."),
  ], """
Wrong static error at line 4, column 2, length 3:
- Expected CFE error 'Four.' but was 'Zzz.'.""");

  expectValidate([
    makeError(line: 5, column: 2, length: 3, webError: "Web 5."),
  ], [
    makeError(line: 5, column: 2, length: 3, webError: "Web Z."),
  ], """
Wrong static error at line 5, column 2, length 3:
- Expected web error 'Web 5.' but was 'Web Z.'.""");

  // Unexpected errors.
  expectValidate([
    makeError(
        line: 2,
        column: 2,
        length: 3,
        analyzerError: "ERR.A",
        cfeError: "One."),
    makeError(
        line: 4,
        column: 2,
        length: 3,
        analyzerError: "ERR.B",
        cfeError: "Two.",
        webError: "Web 2."),
    makeError(
        line: 6,
        column: 2,
        length: 3,
        analyzerError: "ERR.C",
        cfeError: "Tres."),
  ], [
    makeError(line: 1, column: 2, length: 3, cfeError: "1."),
    makeError(line: 2, column: 2, length: 3, cfeError: "One."),
    makeError(line: 3, column: 2, length: 3, cfeError: "3."),
    makeError(line: 4, column: 2, length: 3, cfeError: "Two."),
    makeError(line: 5, column: 2, length: 3, cfeError: "5."),
    makeError(line: 6, column: 2, length: 3, cfeError: "Tres."),
    makeError(line: 7, column: 2, length: 3, cfeError: "7."),
  ], """
Unexpected static error at line 1, column 2, length 3:
- Had CFE error '1.'.

Unexpected static error at line 3, column 2, length 3:
- Had CFE error '3.'.

Unexpected static error at line 5, column 2, length 3:
- Had CFE error '5.'.

Unexpected static error at line 7, column 2, length 3:
- Had CFE error '7.'.""");

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
Missing static error at line 1, column 2, length 3:
- Expected analyzer error 'ERR.A'.

Missing static error at line 3, column 2, length 3:
- Expected analyzer error 'ERR.C'.

Missing static error at line 5, column 2, length 3:
- Expected analyzer error 'ERR.E'.""");

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
Missing static error at line 2, column 2, length 3:
- Expected unspecified CFE error.

Unexpected static error at line 9, column 9, length 3:
- Had CFE error 'Actual 2.'.""");

  // Unspecified errors can match multiple errors on the same line.
  var actualAnalyzer = [
    makeError(line: 1, column: 1, length: 3, analyzerError: "ERROR.CODE1"),
    makeError(line: 1, column: 2, length: 3, analyzerError: "ERROR.CODE2"),
    makeError(line: 1, column: 3, length: 3, analyzerError: "ERROR.CODE3"),
  ];

  var actualCfe = [
    makeError(line: 1, column: 1, length: 3, cfeError: "Actual 1."),
    makeError(line: 1, column: 2, length: 3, cfeError: "Actual 2."),
    makeError(line: 1, column: 3, length: 3, cfeError: "Actual 3."),
  ];

  var actualWeb = [
    makeError(line: 1, column: 1, length: 3, webError: "Web 1."),
    makeError(line: 1, column: 2, length: 3, webError: "Web 2."),
    makeError(line: 1, column: 3, length: 3, webError: "Web 3."),
  ];

  // Unspecified error specific to one front end.
  expectValidate([
    makeError(line: 1, column: 2, length: 3, analyzerError: "unspecified"),
  ], actualAnalyzer, null);

  expectValidate([
    makeError(line: 1, column: 2, length: 3, cfeError: "unspecified"),
  ], actualCfe, null);

  expectValidate([
    makeError(line: 1, column: 2, length: 3, webError: "unspecified"),
  ], actualWeb, null);

  // Unspecified error on multiple front ends.
  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "unspecified",
        cfeError: "unspecified"),
  ], actualAnalyzer, null);

  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        cfeError: "unspecified",
        webError: "unspecified"),
  ], actualCfe, null);

  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "unspecified",
        webError: "unspecified"),
  ], actualWeb, null);

  expectValidate([
    makeError(
        line: 1,
        column: 2,
        length: 3,
        analyzerError: "unspecified",
        cfeError: "unspecified",
        webError: "unspecified"),
  ], actualAnalyzer, null);

  // Specified on one, unspecified on another, no error at all on the third.
  var specifiedAnalyzer = [
    makeError(
        line: 1,
        column: 1,
        length: 3,
        analyzerError: "ERROR.CODE1",
        cfeError: "unspecified")
  ];

  var specifiedCfe = [
    makeError(
        line: 1,
        column: 1,
        length: 3,
        cfeError: "Actual 1.",
        webError: "unspecified")
  ];

  var specifiedWeb = [
    makeError(
        line: 1,
        column: 1,
        length: 3,
        analyzerError: "unspecified",
        webError: "Web 1.")
  ];

  expectValidate(specifiedAnalyzer, actualCfe, null);
  expectValidate(specifiedCfe, actualWeb, null);
  expectValidate(specifiedWeb, actualAnalyzer, null);

  expectValidate(specifiedAnalyzer, actualAnalyzer, """
Unexpected static error at line 1, column 2, length 3:
- Had analyzer error 'ERROR.CODE2'.

Unexpected static error at line 1, column 3, length 3:
- Had analyzer error 'ERROR.CODE3'.""");

  expectValidate(specifiedCfe, actualCfe, """
Unexpected static error at line 1, column 2, length 3:
- Had CFE error 'Actual 2.'.

Unexpected static error at line 1, column 3, length 3:
- Had CFE error 'Actual 3.'.""");

  expectValidate(specifiedWeb, actualWeb, """
Unexpected static error at line 1, column 2, length 3:
- Had web error 'Web 2.'.

Unexpected static error at line 1, column 3, length 3:
- Had web error 'Web 3.'.""");
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
