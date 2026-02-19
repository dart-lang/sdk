// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentOfDoNotStoreTest);
    defineReflectiveTests(AssignmentOfDoNotStoreInTestsTest);
  });
}

@reflectiveTest
class AssignmentOfDoNotStoreInTestsTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir (the default for PubPackageResolutionTests)
    // should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''');
  }
}

@reflectiveTest
class AssignmentOfDoNotStoreTest extends PubPackageResolutionTest {
  /// Override the default which is in .../test and should not trigger hints.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test_project';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_cascadeExpression_assignment() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = A()..f = v;

class A {
  String f = '';
}

@doNotStore
String get v => '';
''');
  }

  test_class_containingInstanceGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String get v => '';
}

String f = A().v;
''',
      [error(diag.assignmentOfDoNotStore, 95, 1)],
    );
  }

  test_class_containingInstanceMethod() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String v() => '';
}

String f = A().v();
''',
      [error(diag.assignmentOfDoNotStore, 93, 1)],
    );
  }

  test_class_containingStaticGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String get v => '';
}

String f = A.v;
''',
      [error(diag.assignmentOfDoNotStore, 100, 1)],
    );
  }

  test_class_containingStaticMethod() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String v() => '';
}

String f = A.v();
''',
      [error(diag.assignmentOfDoNotStore, 98, 1)],
    );
  }

  test_classMemberGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
}
''',
      [
        error(diag.assignmentOfDoNotStore, 110, 1, messageContains: ["'v'"]),
      ],
    );
  }

  test_classStaticGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  static String get v => '';
}

class B {
  String f = A.v;
}
''',
      [error(diag.assignmentOfDoNotStore, 115, 1)],
    );
  }

  test_functionAssignment() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String g(int i) => '';

class C {
  String Function(int) f = g;
}
''');
  }

  test_functionReturnValue() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV();
}
''',
      [error(diag.assignmentOfDoNotStore, 90, 4)],
    );
  }

  test_localVariable_assignment() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String? get v => '';

void f() {
  // ignore: unused_local_variable
  final String? g;
  g = v ?? v;
}
''');
  }

  test_localVariable_declaration() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String? get v => '';

void f() {
  // ignore: unused_local_variable
  final g = v ?? v;
}
''');
  }

  test_methodReturnValue() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String getV() => '';
}

class B {
  final f = A().getV();
}
''',
      [error(diag.assignmentOfDoNotStore, 110, 4)],
    );
  }

  test_mixin_containingInstanceMethod() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@doNotStore
mixin M {
  String v() => '';
}

abstract class A {
  M get m;
  late String f = m.v();
}
''',
      [error(diag.assignmentOfDoNotStore, 128, 1)],
    );
  }

  test_tearOff() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV;
}
''');
  }

  test_topLevelGetter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

class A {
  final f = v;
}
''',
      [error(diag.assignmentOfDoNotStore, 89, 1)],
    );
  }

  test_topLevelGetter_binaryExpression_ifNull() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String? get v => '';

class A {
  final f = v ?? v;
}
''',
      [
        error(diag.assignmentOfDoNotStore, 90, 1),
        error(diag.assignmentOfDoNotStore, 95, 1),
      ],
    );
  }

  test_topLevelVariable_asExpression() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

final f = v as Object;

@doNotStore
String get v => '';
''',
      [error(diag.assignmentOfDoNotStore, 44, 1)],
    );
  }

  test_topLevelVariable_assignment_field() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

String top = A().f;

class A{
  @doNotStore
  String get f => '';
}
''',
      [
        error(diag.assignmentOfDoNotStore, 51, 1, messageContains: ["'f'"]),
      ],
    );
  }

  test_topLevelVariable_assignment_getter() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

String top = v;

@doNotStore
String get v => '';
''',
      [
        error(diag.assignmentOfDoNotStore, 47, 1, messageContains: ["'v'"]),
      ],
    );
  }

  test_topLevelVariable_assignment_method() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

String top = A().v();

class A{
  @doNotStore
  String v() => '';
}
''',
      [
        error(diag.assignmentOfDoNotStore, 51, 1, messageContains: ["'v'"]),
      ],
    );
  }

  test_topLevelVariable_cascadeExpression_propertyAccess() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = A()..v;

class A {
  @doNotStore
  String get v => '';
}
''');
  }

  test_topLevelVariable_cascadeExpression_target() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

final f = v..runtimeType;

@doNotStore
String get v => '';
''',
      [error(diag.assignmentOfDoNotStore, 44, 1)],
    );
  }

  test_topLevelVariable_conditionalExpression() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

class A {
  final f = 1 == 2 ? v : v;
}

@doNotStore
String get v => '';
''',
      [
        error(diag.assignmentOfDoNotStore, 65, 1),
        error(diag.assignmentOfDoNotStore, 69, 1),
      ],
    );
  }

  test_topLevelVariable_dotShorthandPropertyAccess() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

final A f = .v;

class A {
  @doNotStore
  static A get v => A();
}
''',
      [error(diag.assignmentOfDoNotStore, 47, 1)],
    );
  }

  test_topLevelVariable_forElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = [for (var _ in [1]) v];

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_ifElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = [if (true) v];

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_instanceCreationExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  A(Object? a);
}

final f = A(v);

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_isExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = v is int;

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_libraryAnnotation() async {
    newFile('$testPackageLibPath/library.dart', '''
@doNotStore
library lib;

import 'package:meta/meta.dart';

final v = '';
''');

    await assertErrorsInCode(
      '''
import 'library.dart';

class A {
  final f = v;
}
''',
      [error(diag.assignmentOfDoNotStore, 46, 1)],
    );
  }

  test_topLevelVariable_listLiteral() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = [v];

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_mapLiteral_key() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = {v: 1};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_mapLiteral_value() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = {1: v};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_nonAssignment_argToFunctionCall() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

var top = print(v);

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_nullAssert() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

final f = v!;

@doNotStore
String? get v => '';
''',
      [error(diag.assignmentOfDoNotStore, 44, 1)],
    );
  }

  test_topLevelVariable_nullAwareElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = [?v];

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_prefixExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = -v;

@doNotStore
int get v => 1;
''');
  }

  test_topLevelVariable_recordLiteral_namedField() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = (a: v, );

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_recordLiteral_positionalField() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = (v, );

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_setLiteral() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = {v};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_spreadElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = [...v];

@doNotStore
List<String> get v => [];
''');
  }

  test_topLevelVariable_switchExpression_caseBody() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';

final f = switch (1 == 2) {
  true => v,
  false => '',
};

@doNotStore
String? get v => '';
''',
      [error(diag.assignmentOfDoNotStore, 72, 1)],
    );
  }

  test_topLevelVariable_switchExpression_condition() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = switch (v) {
  '' => 1,
  _ => 2,
};

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_throwExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

final f = throw v;

@doNotStore
String get v => '';
''');
  }
}
