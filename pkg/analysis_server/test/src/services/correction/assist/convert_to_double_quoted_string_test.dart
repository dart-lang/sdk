// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToDoubleQuotedStringTest);
  });
}

@reflectiveTest
class ConvertToDoubleQuotedStringTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_DOUBLE_QUOTED_STRING;

  Future<void> test_one_backslash() async {
    await resolveTestCode(r'''
void f() {
  print('a\'b\'c');
}
''');
    await assertHasAssistAt("'a", r'''
void f() {
  print("a'b'c");
}
''');
  }

  Future<void> test_one_embeddedTarget() async {
    await resolveTestCode('''
void f() {
  print('a"b"c');
}
''');
    await assertHasAssistAt("'a", r'''
void f() {
  print("a\"b\"c");
}
''');
  }

  Future<void> test_one_enclosingTarget() async {
    await resolveTestCode('''
void f() {
  print("abc");
}
''');
    await assertNoAssistAt('"ab');
  }

  Future<void> test_one_interpolation() async {
    await resolveTestCode(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print('a $b-${c} d');
}
''');
    await assertHasAssistAt(r"'a $b", r'''
void f() {
  var b = 'b';
  var c = 'c';
  print("a $b-${c} d");
}
''');
  }

  Future<void> test_one_interpolation_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode(r'''
void f(int a) {
  '$a
}
''');
    await assertNoAssistAt("'");
  }

  Future<void> test_one_raw() async {
    await resolveTestCode('''
void f() {
  print(r'abc');
}
''');
    await assertHasAssistAt("'ab", '''
void f() {
  print(r"abc");
}
''');
  }

  Future<void> test_one_simple() async {
    await resolveTestCode('''
void f() {
  print('abc');
}
''');
    await assertHasAssistAt("'ab", '''
void f() {
  print("abc");
}
''');
  }

  Future<void> test_one_simple_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  '
}
''');
    await assertNoAssistAt("'");
  }

  Future<void> test_three_embeddedTarget() async {
    await resolveTestCode("""
void f() {
  print('''a""\"c''');
}
""");
    await assertHasAssistAt("'a", r'''
void f() {
  print("""a\"\"\"c""");
}
''');
  }

  Future<void> test_three_enclosingTarget() async {
    await resolveTestCode('''
void f() {
  print("""abc""");
}
''');
    await assertNoAssistAt('"ab');
  }

  Future<void> test_three_interpolation() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('''a $b-${c} d''');
}
""");
    await assertHasAssistAt(r"'a $b", r'''
void f() {
  var b = 'b';
  var c = 'c';
  print("""a $b-${c} d""");
}
''');
  }

  Future<void> test_three_raw() async {
    await resolveTestCode("""
void f() {
  print(r'''abc''');
}
""");
    await assertHasAssistAt("'ab", '''
void f() {
  print(r"""abc""");
}
''');
  }

  Future<void> test_three_simple() async {
    await resolveTestCode("""
void f() {
  print('''abc''');
}
""");
    await assertHasAssistAt("'ab", '''
void f() {
  print("""abc""");
}
''');
  }
}
