// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingSwitchCasesTest_SwitchExpression);
    defineReflectiveTests(AddMissingSwitchCasesTest_SwitchStatement);
  });
}

@reflectiveTest
class AddMissingSwitchCasesTest_SwitchExpression extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_SWITCH_CASES;

  Future<void> test_bool_hasFalse() async {
    await resolveTestCode('''
int f(bool x) {
  return switch (x) {
    false => 0,
  };
}
''');
    await assertHasFix('''
int f(bool x) {
  return switch (x) {
    false => 0,
    // TODO: Handle this case.
    true => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_bool_hasTrue() async {
    await resolveTestCode('''
int f(bool x) {
  return switch (x) {
    true => 0,
  };
}
''');
    await assertHasFix('''
int f(bool x) {
  return switch (x) {
    true => 0,
    // TODO: Handle this case.
    false => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_hasFirst() async {
    await resolveTestCode('''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFix('''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E.third => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_importedWithPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, third
}
''');

    await resolveTestCode('''
import 'a.dart' as prefix;

int f(prefix.E x) {
  return switch (x) {
  };
}
''');
    await assertHasFix('''
import 'a.dart' as prefix;

int f(prefix.E x) {
  return switch (x) {
    // TODO: Handle this case.
    prefix.E.first => throw UnimplementedError(),
    // TODO: Handle this case.
    prefix.E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    prefix.E.third => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, third
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

var value = E.first;
''');

    createAnalysisOptionsFile(
      lints: [
        LintNames.prefer_relative_imports,
      ],
    );

    await resolveTestCode('''
import 'b.dart';

int f() {
  return switch (value) {
  };
}
''');
    await assertHasFix('''
import 'a.dart';
import 'b.dart';

int f() {
  return switch (value) {
    // TODO: Handle this case.
    E.first => throw UnimplementedError(),
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E.third => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_privateEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _E {
  first, second
}

var e = _E.first;
''');

    await resolveTestCode('''
import 'a.dart';

int f() {
  return switch (e) {
  };
}
''');
    await assertHasFix('''
import 'a.dart';

int f() {
  return switch (e) {
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_privateMemberInOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, _unknown
}
''');

    await resolveTestCode('''
import 'a.dart';

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFix('''
import 'a.dart';

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_enum_privateMemberInSameLibrary() async {
    await resolveTestCode('''
enum E {
  first, second, _unknown
}

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFix(
      '''
enum E {
  first, second, _unknown
}

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E._unknown => throw UnimplementedError(),
  };
}
''',
      errorFilter: (e) =>
          e.errorCode == CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION,
    );
  }

  Future<void> test_num_anyDouble_intProperty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_num_doubleAny() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_num_doubleAny_coreWithPrefix() async {
    await resolveTestCode('''
import 'dart:core' as core;

core.int f(core.num x) {
  return switch (x) {
    core.double() => 0,
  };
}
''');
    await assertHasFix('''
import 'dart:core' as core;

core.int f(core.num x) {
  return switch (x) {
    core.double() => 0,
    // TODO: Handle this case.
    core.int() => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_num_doubleAny_intWhen() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
  };
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''');
  }

  Future<void> test_num_empty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {};
}
''');
    await assertHasFix('''
int f(num x) {
  return switch (x) {
    // TODO: Handle this case.
    double() => throw UnimplementedError(),
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''');
  }
}

@reflectiveTest
class AddMissingSwitchCasesTest_SwitchStatement extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_SWITCH_CASES;

  bool Function(AnalysisError) get _filter {
    var hasError = false;
    return (error) {
      if (!hasError &&
          error.errorCode ==
              CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT) {
        hasError = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixWithFilter(String expected) async {
    await assertHasFix(expected, errorFilter: _filter);
  }

  Future<void> test_empty() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFix('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_empty_singleLine() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {}
}
''');
    await assertHasFix('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_enum_privateEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _E {
  first, second
}

var e = _E.first;
''');

    await resolveTestCode('''
import 'a.dart';

void f() {
  switch (e) {
  }
}
''');
    await assertHasFix('''
import 'a.dart';

void f() {
  switch (e) {
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_enum_privateMemberInOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b, _c}
''');

    await resolveTestCode('''
import 'a.dart';

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFix('''
import 'a.dart';

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_enum_privateMemberInSameLibrary() async {
    await resolveTestCode('''
enum E {a, b, _c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFix(
      '''
enum E {a, b, _c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E._c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
      errorFilter: (e) =>
          e.errorCode == CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT,
    );
  }

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
    await assertHasFix('''
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
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

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
    await assertHasFix('''
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

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
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/49759',
    reason: 'Fails because we use the wrong import (dream) in the cases',
  )
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
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

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
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/49759',
    reason: 'Expects no fix but produces a fix that adds the cases '
        '(but does not fix the incomplete code)',
  )
  Future<void> test_incomplete_switchStatement() async {
    await resolveTestCode(r'''
enum E {a, b, c}
void f(E e) {
  switch(e
}
''');
    await assertNoFix(errorFilter: _filter);
  }

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
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_nullable_handledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case null:
  }
}
''');
    await assertHasFix('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case null:
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/49759',
    reason: 'Puts the null case second-to-last instead of last',
  )
  Future<void> test_nullable_unhandledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case E.b:
  }
}
''');
    await assertHasFix('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case E.b:
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
    case null:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_num_doubleAny() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
  }
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_num_doubleAny_intProperty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
    case int(hashCode: 5):
  }
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
    case int(hashCode: 5):
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_num_empty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {}
}
''');
    await assertHasFix('''
void f(num x) {
  switch (x) {
    case double():
      // TODO: Handle this case.
      throw UnimplementedError();
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }

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
    await assertHasFix('''
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''');
  }
}
