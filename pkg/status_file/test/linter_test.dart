// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/status_file_linter.dart';

void main() {
  testCommentLinesInSection_invalidCommentInSection();
  testCommentLinesInSection_invalidCommentInSectionAfterEntries();
  testCommentLinesInSection_okSectionEntryComment();
  testCommentLinesInSection_okSectionComment();

  testCheckForDisjunctions_notAllowedDisjunction();
  testCheckForDisjunctions_shouldBeAllowedInComments();

  testCheckForAlphabeticalOrderingOfPaths_invalidOrdering();
  testCheckForAlphabeticalOrderingOfPaths_okOrdering();

  testCheckForCorrectOrderingInSections_invalidRuntimeBeforeCompiler();
  testCheckForCorrectOrderingInSections_invalidRuntimeBeforeMode();
  testCheckForCorrectOrderingInSections_invalidSystemBeforeMode();
  testCheckForCorrectOrderingInSections_invalidStrongBeforeKernel();
  testCheckForCorrectOrderingInSections_invalidOrdering();
  testCheckForCorrectOrderingInSections_okOrdering();

  checkLintNormalizedSection_invalidAlphabeticalOrderingVariables();
  checkLintNormalizedSection_invalidAlphabeticalOrderingVariableArguments();
  checkLintNormalizedSection_invalidOrderingWithNotEqual();
  checkLintNormalizedSection_invalidOrderingWithNegation();
}

StatusFile createFromString(String text) {
  return new StatusFile.parse("test", text.split('\n'));
}

expectError(String text, String expectedError, {bool disjunctions = false}) {
  var statusFile = createFromString(text);
  var errors = lint(statusFile, checkForDisjunctions: disjunctions).toList();
  Expect.equals(expectedError, errors.first.toString());
}

expectNoError(String text, {bool disjunctions = true}) {
  var errors =
      lint(createFromString(text), checkForDisjunctions: disjunctions).toList();
  Expect.listEquals([], errors);
}

void testCommentLinesInSection_invalidCommentInSection() {
  expectError(r"""[ $mode == debug ]
# this comment is invalid
""", "Error at line 2: Comment is on a line by itself.");
}

void testCommentLinesInSection_invalidCommentInSectionAfterEntries() {
  expectError(r"""[ $mode == debug ]
vm/tests: Skip
# this comment is invalid
""", "Error at line 3: Comment is on a line by itself.");
}

void testCommentLinesInSection_okSectionEntryComment() {
  expectNoError(r"""[ $mode == debug ]
vm/tests: Skip # this comment is valid
vm/tests2: Timeout # this comment is also valid
""");
}

void testCommentLinesInSection_okSectionComment() {
  expectNoError(r"""
recursive_mixin_test: Crash

# These comment lines belong to the section header. These are alright to have.
# Even having multiple lines of these should not be a problem.
[ $mode == debug ]
vm/tests: Skip 
vm/tests2: Timeout # this comment is also valid
""");
}

void testCheckForDisjunctions_notAllowedDisjunction() {
  expectError(
      r"""[ $mode == debug || $mode == release ]
vm/tests: Skip # this comment is valid
""",
      "Error at line 1: Expression contains '||'. Please split the expression "
      "into multiple separate sections.",
      disjunctions: true);
}

void testCheckForDisjunctions_shouldBeAllowedInComments() {
  expectNoError(r"""# This should allow || in comments
[ $mode == debug ]
vm/tests: Skip # this comment is valid
""", disjunctions: true);
}

void testCheckForAlphabeticalOrderingOfPaths_invalidOrdering() {
  expectError(
      r"""[ $mode == debug ]
vm/tests: Skip # this should come after a_test
a_test: Pass
""",
      "Error at line 1: Test paths are not alphabetically ordered in "
      "section. a_test should come before vm/tests.");
}

void testCheckForAlphabeticalOrderingOfPaths_okOrdering() {
  expectNoError(r"""[ $mode == debug ]
a_test: Pass
b_test: Pass
bc_test: Pass
xyz_test: Skip
""");
}

void testCheckForCorrectOrderingInSections_invalidRuntimeBeforeCompiler() {
  expectError(
      r"""[ $runtime == ff && $compiler == dart2js]
a_test: Pass
""",
      r"Error at line 1: Condition expression should be '$compiler == dart2js "
      r"&& $runtime == ff'.");
}

void testCheckForCorrectOrderingInSections_invalidRuntimeBeforeMode() {
  expectError(
      r"""[ $runtime == ff && $mode == debug ]
a_test: Pass
""",
      r"Error at line 1: Condition expression should be '$mode == debug && "
      r"$runtime == ff'.");
}

void testCheckForCorrectOrderingInSections_invalidSystemBeforeMode() {
  expectError(
      r"""[ $system == win && $mode == debug ]
a_test: Pass
""",
      r"Error at line 1: Condition expression should be '$mode == debug && "
      r"$system == win'.");
}

void testCheckForCorrectOrderingInSections_invalidStrongBeforeKernel() {
  expectError(r"""[ !$strong && !$kernel ]
a_test: Pass
""", r"Error at line 1: Condition expression should be '!$kernel && !$strong'.");
}

void testCheckForCorrectOrderingInSections_invalidOrdering() {
  expectError(
      r"""[ $compiler == dart2js && $builder_tag == strong && !$browser ]
a_test: Pass
""",
      r"Error at line 1: Condition expression should be '$builder_tag == "
      r"strong && $compiler == dart2js && !$browser'.");
}

void testCheckForCorrectOrderingInSections_okOrdering() {
  expectNoError(r"""[ $compiler == dart2js && $runtime != ff && !$browser ]
a_test: Pass
""");
}

void checkLintNormalizedSection_invalidAlphabeticalOrderingVariables() {
  expectError(
      r"""[ $runtime == ff ]
a_test: Pass

[ $compiler == dart2js ]
a_test: Pass
""",
      r"Error at line 1: Section expressions are not correctly ordered in file."
      r" $compiler == dart2js on line 4 should come before $runtime == ff at "
      r"line 1.");
}

void checkLintNormalizedSection_invalidAlphabeticalOrderingVariableArguments() {
  expectError(
      r"""[ $runtime == ff ]
a_test: Pass

[ $runtime == chrome ]
a_test: Pass
""",
      r"Error at line 1: Section expressions are not correctly ordered in file."
      r" $runtime == chrome on line 4 should come before $runtime == ff at "
      r"line 1.");
}

void checkLintNormalizedSection_invalidOrderingWithNotEqual() {
  expectError(
      r"""
[ $ runtime == chrome ]
a_test: Pass

[ $runtime != ff ]
a_test: Pass

[ $runtime == ff ]
a_test: Pass
""",
      r"Error at line 4: Section expressions are not correctly ordered in file."
      r" $runtime == ff on line 7 should come before $runtime != ff at line 4.");
}

void checkLintNormalizedSection_invalidOrderingWithNegation() {
  expectError(
      r"""
[ ! $browser ]
a_test: Pass

[ ! $checked ]
a_test: Pass

[ $checked ]
a_test: Pass

""",
      r"Error at line 4: Section expressions are not correctly ordered in file."
      r" $checked on line 7 should come before !$checked at line 4.");
}

void checkLintNormalizedSection_correctOrdering() {
  expectNoError(r"""
[ ! $browser ]
a_test: Pass

[ $compiler == dart2js ]

[ $compiler == dartk ]

[ $checked ]
a_test: Pass

[ !$checked ]
a_test: Pass

[ $runtime == chrome ]
a_test: Pass

""");
}
