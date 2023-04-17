// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingEnumCaseClausesTest);
  });
}

@reflectiveTest
class AddMissingEnumCaseClausesTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  bool Function(AnalysisError) get _filter {
    var hasError = false;
    return (error) {
      if (!hasError &&
          error.errorCode ==
              StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH) {
        hasError = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixWithFilter(String expected) async {
    await assertHasFix(expected, errorFilter: _filter);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_empty() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_empty_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_empty_singleLine() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {}
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_empty_singleLine_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {}
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_final() async {
    await resolveTestCode('''
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_final_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_import_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_import_prefix_hideDefault() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_import_prefix_hideDefault_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
// @dart=2.19
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_import_prefix_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
// @dart=2.19
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_import_prefix_multiple() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_import_prefix_multiple_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
// @dart=2.19
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      break;
    case my.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_import_prefix_twice() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_import_prefix_twice_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
// @dart=2.19
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_incomplete_switchStatement() async {
    await resolveTestCode(r'''
enum E {a, b, c}
void f(E e) {
  switch(e
}
''');
    await assertNoFix(errorFilter: _filter);
  }

  Future<void> test_incomplete_switchStatement_language219() async {
    await resolveTestCode(r'''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch(e
}
''');
    await assertNoFix(errorFilter: _filter);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_notBrackets() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e)
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_notBrackets_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e)
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_notEmpty() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_notEmpty_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_nullable_handledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case null:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case null:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_nullable_handledNull_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case null:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case null:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_nullable_unhandledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
    case E.c:
      // TODO: Handle this case.
      break;
    case null:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_nullable_unhandledNull_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
    case E.c:
      // TODO: Handle this case.
      break;
    case null:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_static() async {
    await resolveTestCode('''
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_static_const() async {
    await resolveTestCode('''
enum E {
  a,
  b;

  static const int s = 1;
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
enum E {
  a,
  b;

  static const int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_static_const_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {
  a,
  b;

  static const int s = 1;
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {
  a,
  b;

  static const int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_static_language219() async {
    await resolveTestCode('''
// @dart=2.19
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixWithFilter('''
// @dart=2.19
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }
}
