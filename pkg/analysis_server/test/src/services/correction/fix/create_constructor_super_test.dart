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
    defineReflectiveTests(CreateConstructorSuperTest);
  });
}

@reflectiveTest
class CreateConstructorSuperTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_SUPER;

  Future<void> test_fieldInitializer() async {
    await resolveTestCode('''
class A {
  int _field;
  A(this._field);
  int get field => _field;
}
class B extends A {
  int existingField = 0;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  int _field;
  A(this._field);
  int get field => _field;
}
class B extends A {
  int existingField = 0;

  B(int field) : super(field);

  void existingMethod() {}
}
''');
  }

  Future<void> test_importType() async {
    addSource('$testPackageLibPath/a.dart', r'''
class A {}
''');
    addSource('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

class B {
  B(A a);
}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

class C extends B {
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

class C extends B {
  C(A a) : super(a);
}
''');
  }

  Future<void> test_lint_sortConstructorsFirst() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await resolveTestCode('''
class A {
  A(this.field);

  int field;
}
class B extends A {
  int existingField = 0;
  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A(this.field);

  int field;
}
class B extends A {
  B(int field) : super(field);

  int existingField = 0;
  void existingMethod() {}
}
''');
  }

  Future<void> test_namedConstructor() async {
    await resolveTestCode('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField = 0;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField = 0;

  B.named(p1, int p2) : super.named(p1, p2);

  void existingMethod() {}
}
''');
  }

  Future<void> test_namedOptionalParams() async {
    await resolveTestCode('''
class A {
  A(p1, int p2, List<String> p3, {int? p4});
}
class B extends A {
  int existingField = 0;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A(p1, int p2, List<String> p3, {int? p4});
}
class B extends A {
  int existingField = 0;

  B(p1, int p2, List<String> p3) : super(p1, p2, p3);

  void existingMethod() {}
}
''');
  }

  Future<void> test_namedRequiredParams() async {
    await resolveTestCode('''
class A {
  A(p1, int p2, List<String> p3, {required int p4, required int p5});
}
class B extends A {
  int existingField = 0;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A(p1, int p2, List<String> p3, {required int p4, required int p5});
}
class B extends A {
  int existingField = 0;

  B(p1, int p2, List<String> p3, {required int p4, required int p5}) : super(p1, p2, p3, p4: p4, p5: p5);

  void existingMethod() {}
}
''');
  }

  Future<void> test_optional() async {
    await resolveTestCode('''
class A {
  A(p1, int p2, List<String> p3, [int p4 = 0]);
}
class B extends A {
  int existingField = 0;

  void existingMethod() {}
}
''');
    await assertHasFix('''
class A {
  A(p1, int p2, List<String> p3, [int p4 = 0]);
}
class B extends A {
  int existingField = 0;

  B(p1, int p2, List<String> p3) : super(p1, p2, p3);

  void existingMethod() {}
}
''');
  }

  Future<void> test_private() async {
    await resolveTestCode('''
class A {
  A._named(p);
}
class B extends A {
}
''');
    await assertNoFix();
  }

  Future<void> test_typeArgument() async {
    await resolveTestCode('''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
}''');
    await assertHasFix('''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
  D(int x) : super(x);
}''');
  }
}
