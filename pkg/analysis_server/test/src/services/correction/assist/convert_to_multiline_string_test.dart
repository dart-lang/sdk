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
  AssistKind get kind => DartAssistKind.convertToMultilineString;

  Future<void> test_doubleQuoted() async {
    await resolveTestCode('''
void f() {
  print("^abc");
}
''');
    await assertHasAssist('''
void f() {
  print("""
abc""");
}
''');
  }

  Future<void> test_doubleQuoted_alreadyMultiline() async {
    await resolveTestCode('''
void f() {
  print("""^abc""");
}
''');
    await assertNoAssist();
  }

  Future<void> test_doubleQuoted_interpolation_expressionElement() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print("a $b - ${^c} d");
}
""");
    await assertNoAssist();
  }

  Future<void> test_doubleQuoted_interpolation_stringElement_begin() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print(^"a $b - ${c} d");
}
""");
    await assertHasAssist(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print("""
a $b - ${c} d""");
}
''');
  }

  Future<void> test_doubleQuoted_interpolation_stringElement_middle() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print("a $b ^- ${c} d");
}
""");
    await assertHasAssist(r'''
void f() {
  var b = 'b';
  var c = 'c';
  print("""
a $b - ${c} d""");
}
''');
  }

  Future<void> test_doubleQuoted_raw() async {
    await resolveTestCode('''
void f() {
  print(r"^abc");
}
''');
    await assertHasAssist('''
void f() {
  print(r"""
abc""");
}
''');
  }

  Future<void> test_doubleQuoted_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  ^"abc
}
''');
    await assertNoAssist();
  }

  Future<void> test_doubleQuoted_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  ^"
}
''');
    await assertNoAssist();
  }

  Future<void> test_singleQuoted() async {
    await resolveTestCode('''
void f() {
  print('^abc');
}
''');
    await assertHasAssist("""
void f() {
  print('''
abc''');
}
""");
  }

  Future<void> test_singleQuoted_interpolation_expressionElement() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('a $b - ${^c} d');
}
""");
    await assertNoAssist();
  }

  Future<void> test_singleQuoted_interpolation_stringElement_begin() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print(^'a $b - ${c} d');
}
""");
    await assertHasAssist(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('''
a $b - ${c} d''');
}
""");
  }

  Future<void> test_singleQuoted_interpolation_stringElement_middle() async {
    await resolveTestCode(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('a $b ^- ${c} d');
}
""");
    await assertHasAssist(r"""
void f() {
  var b = 'b';
  var c = 'c';
  print('''
a $b - ${c} d''');
}
""");
  }

  Future<void> test_singleQuoted_raw() async {
    await resolveTestCode('''
void f() {
  print(r'^abc');
}
''');
    await assertHasAssist("""
void f() {
  print(r'''
abc''');
}
""");
  }

  Future<void> test_singleQuoted_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  ^'abc
}
''');
    await assertNoAssist();
  }

  Future<void> test_singleQuoted_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  ^'
}
''');
    await assertNoAssist();
  }
}
