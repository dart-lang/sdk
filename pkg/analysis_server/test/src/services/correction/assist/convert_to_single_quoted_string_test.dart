// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSingleQuotedStringTest);
  });
}

@reflectiveTest
class ConvertToSingleQuotedStringTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSingleQuotedString;

  Future<void> test_interpolation_surroundedByEscapedQuote() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^"a \'$b\'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print('a \'$b\'');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote2() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^"a \"$b\"");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print('a "$b"');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote2_left() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^"a \'$b'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print('a \'$b\'');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote2_right() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^"a '$b\'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print('a \'$b\'');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote3() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^" \\'$b\\'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print(' \\\'$b\\\'');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote4() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^" \\\"$b\\\"");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print(' \\"$b\\"');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote5() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^" \\\\'$b\\\\'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print(' \\\\\'$b\\\\\'');
}
''');
  }

  Future<void> test_interpolation_surroundedByEscapedQuote6() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^" \\\\\"$b\\\\\"");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print(' \\\\"$b\\\\"');
}
''');
  }

  Future<void> test_interpolation_surroundedByQuotes() async {
    await resolveTestCode(r'''
void f(int b) {
  print(^"a '$b'");
}
''');
    await assertHasAssist(r'''
void f(int b) {
  print('a \'$b\'');
}
''');
  }

  Future<void> test_one_backslash() async {
    await resolveTestCode(r'''
void f() {
  print(^"a\"b\"c");
}
''');
    await assertHasAssist(r"""
void f() {
  print('a"b"c');
}
""");
  }

  Future<void> test_one_embeddedTarget() async {
    await resolveTestCode('''
void f() {
  print(^"a'b'c");
}
''');
    await assertHasAssist(r'''
void f() {
  print('a\'b\'c');
}
''');
  }

  Future<void> test_one_enclosingTarget() async {
    await resolveTestCode('''
void f() {
  print(^'abc');
}
''');
    await assertNoAssist();
  }

  Future<void> test_one_interpolation() async {
    await resolveTestCode(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print(^"a $b-${c} d");
}
''');
    await assertHasAssist(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print('a $b-${c} d');
}
''');
  }

  Future<void> test_one_interpolation_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode(r'''
void f(int a) {
  ^"$a
}
''');
    await assertNoAssist();
  }

  Future<void> test_one_raw() async {
    await resolveTestCode('''
void f() {
  print(^r"abc");
}
''');
    await assertHasAssist('''
void f() {
  print(r'abc');
}
''');
  }

  Future<void> test_one_simple() async {
    await resolveTestCode('''
void f() {
  print(^"abc");
}
''');
    await assertHasAssist('''
void f() {
  print('abc');
}
''');
  }

  Future<void> test_one_simple_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_single_quotes]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  print(^"abc");
}
''');
    await assertNoAssist();
  }

  Future<void> test_one_simple_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  ^"
}
''');
    await assertNoAssist();
  }

  Future<void> test_raw_multiLine_manyQuotes() async {
    await resolveTestCode('''
void f() {
  print(^r"""
''\'''\'''\'''
""");
}
''');
    await assertHasAssist(r"""
void f() {
  print('''
''\'''\'''\'''
''');
}
""");
  }

  Future<void> test_raw_multiLine_threeQuotes() async {
    await resolveTestCode('''
void f() {
  print(^r"""
''\'""");
}
''');
    await assertHasAssist(r"""
void f() {
  print('''
''\'''');
}
""");
  }

  Future<void> test_raw_multiLine_twoQuotes() async {
    await resolveTestCode(r'''
void f() {
  print(^r"""
""\""\"
''
""");
}
''');
    await assertHasAssist("""
void f() {
  print(r'''
""\""\"
''
''');
}
""");
  }

  Future<void> test_raw_multiLine_twoQuotesAtEnd() async {
    await resolveTestCode('''
void f() {
  print(^r"""
''""");
}
''');
    await assertHasAssist(r"""
void f() {
  print('''
'\'''');
}
""");
  }

  Future<void> test_raw_nonEscapedChars() async {
    await resolveTestCode(r"""
void f() {
  print(^r"\$'");
}
""");
    await assertHasAssist(r"""
void f() {
  print('\\\$\'');
}
""");
  }

  Future<void> test_three_embeddedTarget() async {
    await resolveTestCode('''
void f() {
  print(^"""a''\'bc""");
}
''');
    await assertHasAssist(r"""
void f() {
  print('''a''\'bc''');
}
""");
  }

  Future<void> test_three_enclosingTarget() async {
    await resolveTestCode("""
void f() {
  print(^'''abc''');
}
""");
    await assertNoAssist();
  }

  Future<void> test_three_interpolation() async {
    await resolveTestCode(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print(^"""a $b-${c} d""");
}
''');
    await assertHasAssist(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('''a $b-${c} d''');
}
""");
  }

  Future<void> test_three_raw() async {
    await resolveTestCode('''
void f() {
  print(^r"""abc""");
}
''');
    await assertHasAssist("""
void f() {
  print(r'''abc''');
}
""");
  }

  Future<void> test_three_simple() async {
    await resolveTestCode('''
void f() {
  print(^"""abc""");
}
''');
    await assertHasAssist("""
void f() {
  print('''abc''');
}
""");
  }
}
