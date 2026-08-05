// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsafeTextDirectionCodepointTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnsafeTextDirectionCodepointTest extends PubPackageResolutionTest {
  test_comments() async {
    await resolveTestCodeWithDiagnostics('''
// \u2066
// ^
// [diag.textDirectionCodePointInComment] The Unicode code point 'U+2066' changes the appearance of text from how it's interpreted by the compiler.
/// \u2066
//  ^
// [diag.textDirectionCodePointInComment] The Unicode code point 'U+2066' changes the appearance of text from how it's interpreted by the compiler.
void f() { // \u2066
//            ^
// [diag.textDirectionCodePointInComment] The Unicode code point 'U+2066' changes the appearance of text from how it's interpreted by the compiler.
  // \u2066
//   ^
// [diag.textDirectionCodePointInComment] The Unicode code point 'U+2066' changes the appearance of text from how it's interpreted by the compiler.
}
''');
  }

  /// https://github.com/flutter/flutter/pull/93029
  test_file_ok() async {
    // Raw strings preserve the escapes.
    await resolveTestCodeWithDiagnostics(r'''
var u202a = '\u202AInteractive text\u202C';
''');
  }

  test_message_escape() async {
    await resolveTestCodeWithDiagnostics('''
var u202a = '\u202A';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202A' changes the appearance of text from how it's interpreted by the compiler.
''');
  }

  test_multiLineString() async {
    await resolveTestCodeWithDiagnostics('''
var s = """ \u202a
//          ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202A' changes the appearance of text from how it's interpreted by the compiler.
        Multiline!
""";
''');
  }

  test_simpleStrings() async {
    await resolveTestCodeWithDiagnostics('''
var u202a = '\u202A';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202A' changes the appearance of text from how it's interpreted by the compiler.
var u202b = '\u202B';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202B' changes the appearance of text from how it's interpreted by the compiler.
var u202c = '\u202C';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202C' changes the appearance of text from how it's interpreted by the compiler.
var u202d = '\u202D';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202D' changes the appearance of text from how it's interpreted by the compiler.
var u202e = '\u202E';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202E' changes the appearance of text from how it's interpreted by the compiler.
var u2066 = '\u2066';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+2066' changes the appearance of text from how it's interpreted by the compiler.
var u2067 = '\u2067';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+2067' changes the appearance of text from how it's interpreted by the compiler.
var u2068 = '\u2068';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+2068' changes the appearance of text from how it's interpreted by the compiler.
var u2069 = '\u2069';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+2069' changes the appearance of text from how it's interpreted by the compiler.
''');
  }

  test_stringInterpolation() async {
    await resolveTestCodeWithDiagnostics('''
var x = 'x';
var u202a = '\u202A\$x';
//           ^
// [diag.textDirectionCodePointInLiteral] The Unicode code point 'U+202A' changes the appearance of text from how it's interpreted by the compiler.
''');
  }
}
