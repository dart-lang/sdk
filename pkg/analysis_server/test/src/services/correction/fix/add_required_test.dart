// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddRequiredBulkTest);
    defineReflectiveTests(AddRequiredTest);
    defineReflectiveTests(AddRequiredWithNullSafetyTest);
  });
}

@reflectiveTest
class AddRequiredBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_require_non_null_named_parameters;

  @override
  // Note that this lint does not fire w/ NNBD.
  String? get testPackageLanguageVersion => '2.9';

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void function({String p1, int p2}) {
  assert(p1 != null);
  assert(p2 != null);
}
''');
    await assertHasFix('''
void function({@required String p1, @required int p2}) {
  assert(p1 != null);
  assert(p2 != null);
}
''');
  }
}

@reflectiveTest
class AddRequiredTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_REQUIRED;

  @override
  String get lintCode => LintNames.always_require_non_null_named_parameters;

  @override
  String? get testPackageLanguageVersion => '2.9';

  Future<void> test_withAssert() async {
    await resolveTestCode('''
void function({String param}) {
  assert(param != null);
}
''');
    await assertHasFix('''
void function({@required String param}) {
  assert(param != null);
}
''');
  }
}

@reflectiveTest
class AddRequiredWithNullSafetyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_REQUIRED2;

  Future<void> test_nonNullable() async {
    await resolveTestCode('''
void function({String param}) {}
''');
    await assertHasFix('''
void function({required String param}) {}
''');
  }

  Future<void> test_nonNullable_superParameter() async {
    await resolveTestCode('''
class C {
  C({required int param});
}
class D extends C {
  D({super.param});
}
''');
    await assertHasFix('''
class C {
  C({required int param});
}
class D extends C {
  D({required super.param});
}
''');
  }

  Future<void> test_withRequiredAnnotation() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

void function({@required String param}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

void function({required String param}) {}
''');
  }

  Future<void> test_withRequiredAnnotation_constructor() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  String foo;
  A({@required this.foo});
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  String foo;
  A({required this.foo});
}
''');
  }

  Future<void> test_withRequiredAnnotation_functionParam() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

void f({@required int g(String)}) { }
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

void f({required int g(String)}) { }
''');
  }

  Future<void> test_withRequiredAnnotationInList_first() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

class Foo {
  const Foo();
}

const foo = Foo();

void function({@required @foo String param}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class Foo {
  const Foo();
}

const foo = Foo();

void function({@foo required String param}) {}
''');
  }

  Future<void> test_withRequiredAnnotationInList_last() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

class Foo {
  const Foo();
}

const foo = Foo();

void function({@foo @required String param}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class Foo {
  const Foo();
}

const foo = Foo();

void function({@foo required String param}) {}
''');
  }

  Future<void> test_withRequiredAnnotationWithReason() async {
    writeTestPackageConfig(meta: true);

    await resolveTestCode('''
import 'package:meta/meta.dart';

void function({@Required('reason') String param}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

void function({required String param}) {}
''');
  }
}
