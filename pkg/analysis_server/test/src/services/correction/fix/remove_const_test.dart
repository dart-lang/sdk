// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstTest);
  });
}

@reflectiveTest
class RemoveConstTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_constClass_firstClass() async {
    await resolveTestCode('''
const class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_constClass_secondClass() async {
    await resolveTestCode('''
class A {}
const class B {}
''');
    await assertHasFix('''
class A {}
class B {}
''');
  }

  Future<void> test_constClass_withComment() async {
    await resolveTestCode('''
/// Comment.
const class C {}
''');
    await assertHasFix('''
/// Comment.
class C {}
''');
  }

  Future<void> test_constFactoryConstructor() async {
    await resolveTestCode('''
class C {
  C._();
  const factory C() => C._();
}
''');
    await assertHasFix('''
class C {
  C._();
  factory C() => C._();
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49818')
  Future<void> test_constInitializedWithNonConstantValue() async {
    await resolveTestCode('''
var x = 0;
const y = x;
''');
    await assertHasFix('''
var x = 0;
final y = x;
''');
  }

  Future<void> test_explicitConst() async {
    await resolveTestCode('''
class A {
  A(_);
}
var x = const A([0]);
''');

    await assertHasFix('''
class A {
  A(_);
}
var x = A([0]);
''');
  }

  Future<void> test_implicitConst_instanceCreation_argument() async {
    await resolveTestCode('''
class A {}

class B {
  const B(a, b);
}

var x = const B(A(), [0]);
''');

    await assertHasFix('''
class A {}

class B {
  const B(a, b);
}

var x = B(A(), const [0]);
''');
  }

  Future<void> test_implicitConst_instanceCreation_argument_named() async {
    await resolveTestCode('''
class A {}

class B {
  const B({a, b});
}

var x = const B(a: A(), b: [0]);
''');

    await assertHasFix('''
class A {}

class B {
  const B({a, b});
}

var x = B(a: A(), b: const [0]);
''');
  }

  Future<void> test_implicitConst_invalidConstant() async {
    await resolveTestCode('''
class A {
  const A(_, _);
}

void f(bool b) {
  const A(b ? 0 : 1, [2]);
}
''');

    await assertHasFix('''
class A {
  const A(_, _);
}

void f(bool b) {
  A(b ? 0 : 1, const [2]);
}
''');
  }

  Future<void> test_implicitConst_listLiteral_sibling_ifElement() async {
    await resolveTestCode('''
class A {}

var x = const [A(), if (true) [0] else [1]];
''');

    await assertHasFix(
      '''
class A {}

var x = [A(), if (true) const [0] else const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_listLiteral_sibling_instanceCreation() async {
    await resolveTestCode('''
class A {}

class B {
  const B();
}

var x = const [A(), const B(), B()];
''');

    await assertHasFix(
      '''
class A {}

class B {
  const B();
}

var x = [A(), const B(), const B()];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_listLiteral_sibling_listLiteral() async {
    await resolveTestCode('''
class A {}

var x = const [A(), const [0], [1]];
''');

    await assertHasFix(
      '''
class A {}

var x = [A(), const [0], const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void>
  test_implicitConst_listLiteral_sibling_spreadElement_list() async {
    await resolveTestCode('''
class A {}

var x = const [A(), ...const [0], ...[1]];
''');

    await assertHasFix(
      '''
class A {}

var x = [A(), ...const [0], ...const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_mapLiteral() async {
    await resolveTestCode('''
class A {}

var x = const {0: A(), ...const {1: 2}, ...{3: 4}};
''');

    await assertHasFix(
      '''
class A {}

var x = {0: A(), ...const {1: 2}, ...const {3: 4}};
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_setLiteral() async {
    await resolveTestCode('''
class A {}

var x = const {A(), ...const {0}, ...{1}};
''');

    await assertHasFix(
      '''
class A {}

var x = {A(), ...const {0}, ...const {1}};
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_variableDeclarationList() async {
    await resolveTestCode('''
class A {}

const x = A(), y = [0];
''');

    await assertHasFix(
      '''
class A {}

var x = A(), y = const [0];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_variableDeclarationList_typed() async {
    await resolveTestCode('''
class A {}

const Object x = A(), y = [0];
''');

    await assertHasFix(
      '''
class A {}

Object x = A(), y = const [0];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }
}
