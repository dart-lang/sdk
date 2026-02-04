// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddFieldFormalNamedParametersTest);
    defineReflectiveTests(AddFieldFormalParametersTest);
  });
}

@reflectiveTest
class AddFieldFormalNamedParametersTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addInitializingFormalNamedParameters;

  Future<void> test_enum() async {
    await resolveTestCode('''
enum MyEnum {
  a;

  const MyEnum();

  final int value;
}
''');
    await assertHasFix('''
enum MyEnum {
  a;

  const MyEnum({required this.value});

  final int value;
}
''');
  }

  Future<void> test_flutter_nullable() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a, required this.b, this.c, required this.d}) : super(key: key);
}
''');
  }

  Future<void> test_flutter_nullable_lint() async {
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(
      lints: [LintNames.always_put_required_named_parameters_first],
    );
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required this.b, required this.d, required Key key, required this.a, this.c}) : super(key: key);
}
''');
  }

  Future<void> test_flutter_potentiallyNullable() async {
    writeTestPackageConfig(flutter: true);

    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget<T> extends StatelessWidget {
  final int a;
  final int b;
  final T c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget<T> extends StatelessWidget {
  final int a;
  final int b;
  final T c;
  final int d;

  MyWidget({required Key key, required this.a, required this.b, required this.c, required this.d}) : super(key: key);
}
''');
  }

  Future<void> test_hasNamedParameter() async {
    await resolveTestCode('''
class Test {
  final int? a;
  final int b;
  final int c;
  Test({this.a});
}
''');
    await assertHasFix('''
class Test {
  final int? a;
  final int b;
  final int c;
  Test({this.a, required this.b, required this.c});
}
''');
  }

  Future<void> test_hasNamedParameter_lint() async {
    createAnalysisOptionsFile(
      lints: [LintNames.always_put_required_named_parameters_first],
    );
    await resolveTestCode('''
class Test {
  final int? a;
  final int b;
  final int c;
  Test({this.a});
}
''');
    await assertHasFix('''
class Test {
  final int? a;
  final int b;
  final int c;
  Test({required this.b, required this.c, this.a});
}
''');
  }

  Future<void> test_hasOptionalPositionalParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test([this.a = 0]);
}
''');
    await assertNoFix();
  }

  Future<void> test_hasRequiredNamedParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test({required this.a});
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test({required this.a, required this.b, required this.c});
}
''');
  }

  Future<void> test_hasRequiredParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a);
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, {required this.b, required this.c});
}
''');
  }

  Future<void> test_privateField() async {
    await resolveTestCode('''
class A {
  A({int? other});

  final int _foo;
}
''');
    await assertHasFix(
      '''
class A {
  A({int? other, required this._foo});

  final int _foo;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_alphaNumeric() async {
    await resolveTestCode('''
class C {
  C();

  final int _1to1;
}
''');
    await assertHasFix(
      '''
class C {
  C({required int p1to1}) : _1to1 = p1to1;

  final int _1to1;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_initializer() async {
    await resolveTestCode('''
class A {
  A({int? other}) : assert(true);

  final int _foo;
}
''');
    await assertHasFix(
      '''
class A {
  A({int? other, required this._foo}) : assert(true);

  final int _foo;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_numeric() async {
    await resolveTestCode('''
class C {
  C();

  final int _3;
}
''');
    await assertHasFix(
      '''
class C {
  C({required int p3}) : _3 = p3;

  final int _3;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_reserved() async {
    await resolveTestCode('''
class C {
  C();

  final int _for;
}
''');
    await assertHasFix(
      '''
class C {
  C({required int pfor}) : _for = pfor;

  final int _for;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_withoutPrivateNamedParams() async {
    await resolveTestCode('''
// @dart=3.10
class A {
  A({int? other});

  final int _foo;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class A {
  A({int? other, required int foo}) : _foo = foo;

  final int _foo;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void>
  test_privateField_withoutPrivateNamedParams_alphaNumeric() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  C();

  final int _1to1;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class C {
  C({required int p1to1}) : _1to1 = p1to1;

  final int _1to1;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_withoutPrivateNamedParams_initializer() async {
    await resolveTestCode('''
// @dart=3.10
class A {
  A({int? other}) : assert(true);

  final int _foo;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class A {
  A({int? other, required int foo}) : _foo = foo, assert(true);

  final int _foo;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_withoutPrivateNamedParams_numeric() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  C();

  final int _3;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class C {
  C({required int p3}) : _3 = p3;

  final int _3;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateField_withoutPrivateNamedParams_reserved() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  C();

  final int _for;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class C {
  C({required int pfor}) : _for = pfor;

  final int _for;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }

  Future<void> test_privateFields() async {
    await resolveTestCode('''
class A {
  A({int? other});

  final int _foo;
  final String _bar;
}
''');
    await assertHasFix(
      '''
class A {
  A({int? other, required this._foo, required this._bar});

  final int _foo;
  final String _bar;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor2,
    );
  }

  Future<void> test_privateFields_withoutPrivateNamedParams() async {
    await resolveTestCode('''
// @dart=3.10
class A {
  A({int? other});

  final int _foo;
  final String _bar;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class A {
  A({int? other, required int foo, required String bar}) : _foo = foo, _bar = bar;

  final int _foo;
  final String _bar;
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor2,
    );
  }
}

@reflectiveTest
class AddFieldFormalParametersTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addInitializingFormalParameters;

  Future<void> test_enum() async {
    await resolveTestCode('''
enum MyEnum {
  a;

  const MyEnum();

  final int value;
}
''');
    await assertHasFix('''
enum MyEnum {
  a;

  const MyEnum(this.value);

  final int value;
}
''');
  }

  Future<void> test_flutter() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget(this.b, this.c, this.d, {required Key key, required this.a}) : super(key: key);
}
''');
  }

  Future<void> test_hasRequiredNamedParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test({required this.a});
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.b, this.c, {required this.a});
}
''');
  }

  Future<void> test_hasRequiredParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a);
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  Future<void> test_noParameters() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test();
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  Future<void> test_noRequiredParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test([this.c = 0]);
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, [this.c = 0]);
}
''');
  }

  Future<void> test_notAllFinal() async {
    await resolveTestCode('''
class Test {
  final int a;
  int b = 0;
  final int c;
  Test();
}
''');
    await assertHasFix('''
class Test {
  final int a;
  int b = 0;
  final int c;
  Test(this.a, this.c);
}
''');
  }

  Future<void> test_privateFields() async {
    await resolveTestCode('''
class Test {
  final int _a;
  final int _1alpha;
  final int _123;
  final int _for;

  Test();
}
''');
    await assertHasFix('''
class Test {
  final int _a;
  final int _1alpha;
  final int _123;
  final int _for;

  Test(this._a, this._1alpha, this._123, this._for);
}
''', filter: (diagnostic) => diagnostic.diagnosticCode != diag.unusedField);
  }

  Future<void> test_synthetic_field() async {
    await resolveTestCode('''
class Test {
  final int foo,;
  Test();
}
''');
    await assertHasFix(
      '''
class Test {
  final int foo,;
  Test(this.foo);
}
''',
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.finalNotInitializedConstructor1,
    );
  }
}
