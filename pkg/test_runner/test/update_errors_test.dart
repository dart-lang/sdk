// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'package:test_runner/src/static_error.dart';
import 'package:test_runner/src/update_errors.dart';

// Note: This test file validates how some of the special markers used by the
// test runner are parsed. But this test is also run *by* that same test
// runner, and we don't want it to see the markers inside the string literals
// here as significant, so we obfuscate them using seemingly-pointless string
// escapes here like `\/`.

Future<void> main() async {
  // Inserts analyzer, CFE, and both errors.
  expectUpdate("""
int i = "bad";

int another = "wrong";

int third = "boo";
""", errors: [
    StaticError(line: 1, column: 9, length: 5, code: "some.error"),
    StaticError(line: 3, column: 15, length: 7, message: "Bad."),
    StaticError(
        line: 5,
        column: 13,
        length: 5,
        code: "an.error",
        message: "Wrong.\nLine.\nAnother."),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
/\/ [cfe] Wrong.
/\/ Line.
/\/ Another.
""");

  // Removes only analyzer errors.
  expectUpdate(
      """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
/\/ [cfe] Wrong.
""",
      removeCfe: false,
      expected: """
int i = "bad";

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [cfe] Wrong.
""");

  // Removes only CFE errors.
  expectUpdate(
      """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";
/\/            ^^^^^^^
/\/ [cfe] Bad.

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
/\/ [cfe] Wrong.
""",
      removeAnalyzer: false,
      expected: """
int i = "bad";
/\/      ^^^^^
/\/ [analyzer] some.error

int another = "wrong";

int third = "boo";
/\/          ^^^^^
/\/ [analyzer] an.error
""");

  // Preserves previous error's indentation if possible.
  expectUpdate("""
int i = "bad";
    /\/    ^^
    /\/ [analyzer] previous.error
""", errors: [
    StaticError(
        line: 1,
        column: 9,
        length: 5,
        code: "updated.error",
        message: "Long.\nError.\nMessage."),
  ], expected: """
int i = "bad";
    /\/  ^^^^^
    /\/ [analyzer] updated.error
    /\/ [cfe] Long.
    /\/ Error.
    /\/ Message.
""");

  // Uses previous line's indentation if there was no existing error
  // expectation.
  expectUpdate("""
main() {
  int i = "bad";
}
""", errors: [
    StaticError(line: 2, column: 11, length: 5, code: "updated.error"),
  ], expected: """
main() {
  int i = "bad";
  /\/      ^^^^^
  /\/ [analyzer] updated.error
}
""");

  // Discards indentation if it would collide with carets.
  expectUpdate("""
int i = "bad";
        /\/    ^^
        /\/ [analyzer] previous.error

main() {
  int i =
  "bad";
}
""", errors: [
    StaticError(line: 1, column: 9, length: 5, message: "Error."),
    StaticError(line: 7, column: 3, length: 5, code: "new.error"),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [cfe] Error.

main() {
  int i =
  "bad";
/\/^^^^^
/\/ [analyzer] new.error
}
""");

  // Uses an explicit error location if there's no room for the carets.
  expectUpdate("""
int i =
"bad";
    /\/    ^^
    /\/ [analyzer] previous.error

int j =
"bad";
""", errors: [
    StaticError(line: 2, column: 1, length: 5, code: "updated.error"),
    StaticError(line: 7, column: 1, length: 5, message: "Error."),
  ], expected: """
int i =
"bad";
/\/ [error line 2, column 1, length 5]
/\/ [analyzer] updated.error

int j =
"bad";
/\/ [error line 7, column 1, length 5]
/\/ [cfe] Error.
""");

  // Uses length one if there's no length.
  expectUpdate("""
int i = "bad";
""", errors: [StaticError(line: 1, column: 9, message: "Error.")], expected: """
int i = "bad";
/\/      ^
/\/ [cfe] Error.
""");

  // Explicit error location handles null length.
  expectUpdate("""
int i =
"bad";
""", errors: [StaticError(line: 2, column: 1, message: "Error.")], expected: """
int i =
"bad";
/\/ [error line 2, column 1]
/\/ [cfe] Error.
""");

  // Handles shifted line numbers in explicit error locations.
  // Note that the reported line is line 6, but the output is line 3 to take
  // into account the three removed lines.
  expectUpdate("""
main() {
/\/ ^^
/\/ [analyzer] ERROR.CODE
/\/ [cfe] Error.
}
Error here;
""", errors: [
    StaticError(line: 6, column: 1, length: 5, code: "NEW.ERROR"),
    StaticError(line: 6, column: 2, length: 3, message: "Error."),
  ], expected: """
main() {
}
Error here;
/\/ [error line 3, column 1, length 5]
/\/ [analyzer] NEW.ERROR
/\/ [error line 3, column 2, length 3]
/\/ [cfe] Error.
""");

  // Inserts a blank line if a subsequent line comment would become part of the
  // error message.
  expectUpdate("""
int i = "bad";
// Line comment.
""", errors: [
    StaticError(line: 1, column: 9, length: 5, message: "Wrong."),
  ], expected: """
int i = "bad";
/\/      ^^^^^
/\/ [cfe] Wrong.

// Line comment.
""");

  // Multiple errors on the same line are ordered by column then length.
  expectUpdate("""
someBadCode();
""", errors: [
    StaticError(line: 1, column: 9, length: 5, message: "Wrong 1."),
    StaticError(line: 1, column: 9, length: 4, message: "Wrong 2."),
    StaticError(line: 1, column: 6, length: 3, message: "Wrong 3."),
    StaticError(line: 1, column: 5, length: 5, message: "Wrong 4."),
  ], expected: """
someBadCode();
/\/  ^^^^^
/\/ [cfe] Wrong 4.
/\/   ^^^
/\/ [cfe] Wrong 3.
/\/      ^^^^
/\/ [cfe] Wrong 2.
/\/      ^^^^^
/\/ [cfe] Wrong 1.
""");

  regression();
}

void regression() {
  // https://github.com/dart-lang/sdk/issues/37990.
  expectUpdate(
      """
int get xx => 3;
int get yy => 3;

class A {
  void test() {
    xx = 1;
/\/  ^^^^^^^^^^^^^^
/\/ [cfe] unspecified
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified


    yy(4);
/\/  ^^^^^^^^^^^^^^
/\/ [cfe] unspecified
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified

  }
}
""",
      removeAnalyzer: false,
      errors: [
        StaticError(
            line: 6, column: 5, length: 14, message: "Setter not found: 'xx'."),
        StaticError(
            line: 16,
            column: 7,
            message: "The method 'call' isn't defined for the class 'int'.")
      ],
      expected: """
int get xx => 3;
int get yy => 3;

class A {
  void test() {
    xx = 1;
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified
/\/ [cfe] Setter not found: 'xx'.


    yy(4);
/\/  ^^^^^^^^^^^^^^
/\/ [analyzer] unspecified
/\/    ^
/\/ [cfe] The method 'call' isn't defined for the class 'int'.

  }
}
""");
}

void expectUpdate(String original,
    {List<StaticError> errors,
    bool removeAnalyzer = true,
    bool removeCfe = true,
    String expected}) {
  errors ??= const [];

  var actual = updateErrorExpectations(original, errors,
      removeAnalyzer: removeAnalyzer, removeCfe: removeCfe);
  if (actual != expected) {
    // Not using Expect.equals() because the diffs it shows aren't helpful for
    // strings this large.
    Expect.fail("Output did not match expectation. Expected:\n$expected"
        "\n\nWas:\n$actual");
  }
}
