// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToMultilineStringTest);
  });
}

@reflectiveTest
class ConvertToMultilineStringTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_MULTILINE_STRING;

  Future<void> test_doubleQuoted() async {
    await resolveTestCode('''
main() {
  print("abc");
}
''');
    await assertHasAssistAt('abc', '''
main() {
  print("""
abc""");
}
''');
  }

  Future<void> test_doubleQuoted_alreadyMultiline() async {
    await resolveTestCode('''
main() {
  print("""abc""");
}
''');
    await assertNoAssistAt('abc');
  }

  Future<void> test_doubleQuoted_interpolation_expressionElement() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print("a $b - ${c} d");
}
""");
    await assertNoAssistAt(r'c}');
  }

  Future<void> test_doubleQuoted_interpolation_stringElement_begin() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print("a $b - ${c} d");
}
""");
    await assertHasAssistAt('"a ', r'''
main() {
  var b = 'b';
  var c = 'c';
  print("""
a $b - ${c} d""");
}
''');
  }

  Future<void> test_doubleQuoted_interpolation_stringElement_middle() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print("a $b - ${c} d");
}
""");
    await assertHasAssistAt('- ', r'''
main() {
  var b = 'b';
  var c = 'c';
  print("""
a $b - ${c} d""");
}
''');
  }

  Future<void> test_doubleQuoted_raw() async {
    await resolveTestCode('''
main() {
  print(r"abc");
}
''');
    await assertHasAssistAt('abc', '''
main() {
  print(r"""
abc""");
}
''');
  }

  Future<void> test_doubleQuoted_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  "abc
}
''');
    await assertNoAssistAt('"');
  }

  Future<void> test_doubleQuoted_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  "
}
''');
    await assertNoAssistAt('"');
  }

  Future<void> test_singleQuoted() async {
    await resolveTestCode('''
main() {
  print('abc');
}
''');
    await assertHasAssistAt('abc', """
main() {
  print('''
abc''');
}
""");
  }

  Future<void> test_singleQuoted_interpolation_expressionElement() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print('a $b - ${c} d');
}
""");
    await assertNoAssistAt(r'c}');
  }

  Future<void> test_singleQuoted_interpolation_stringElement_begin() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print('a $b - ${c} d');
}
""");
    await assertHasAssistAt("'a ", r"""
main() {
  var b = 'b';
  var c = 'c';
  print('''
a $b - ${c} d''');
}
""");
  }

  Future<void> test_singleQuoted_interpolation_stringElement_middle() async {
    await resolveTestCode(r"""
main() {
  var b = 'b';
  var c = 'c';
  print('a $b - ${c} d');
}
""");
    await assertHasAssistAt('- ', r"""
main() {
  var b = 'b';
  var c = 'c';
  print('''
a $b - ${c} d''');
}
""");
  }

  Future<void> test_singleQuoted_raw() async {
    await resolveTestCode('''
main() {
  print(r'abc');
}
''');
    await assertHasAssistAt('abc', """
main() {
  print(r'''
abc''');
}
""");
  }

  Future<void> test_singleQuoted_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  'abc
}
''');
    await assertNoAssistAt("'");
  }

  Future<void> test_singleQuoted_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  '
}
''');
    await assertNoAssistAt("'");
  }
}
