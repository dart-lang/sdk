// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentOfDoNotStoreTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentOfDoNotStoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_cascadeExpression_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String get v => '';
}

String f = A().v;
//         ^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
''');
  }

  test_class_containingInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@doNotStore
class A {
  String v() => '';
}

String f = A().v();
//         ^^^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
''');
  }

  test_class_containingStaticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String get v => '';
}

String f = A.v;
//         ^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
''');
  }

  test_class_containingStaticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@doNotStore
class A {
  static String v() => '';
}

String f = A.v();
//         ^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
''');
  }

  test_classMemberGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String get v => '';
}

class B {
  String f = A().v;
//           ^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_classStaticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  static String get v => '';
}

class B {
  String f = A.v;
//           ^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_functionAssignment() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String g(int i) => '';

class C {
  String Function(int) f = g;
}
''');
  }

  test_functionReturnValue() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV();
//          ^^^^^^
// [diag.assignmentOfDoNotStore] 'getV' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_localVariable_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String getV() => '';
}

class B {
  final f = A().getV();
//          ^^^^^^^^^^
// [diag.assignmentOfDoNotStore] 'getV' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_mixin_containingInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@doNotStore
mixin M {
  String v() => '';
}

abstract class A {
  M get m;
  late String f = m.v();
//                ^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_noHintsInTestDir() async {
    // Code that is in a test dir should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    var file = getFile('$testPackageRootPath/test/test.dart');

    await resolveFileWithDiagnostics(file, r'''
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

  test_tearOff() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String getV() => '';

class A {
  final f = getV;
}
''');
  }

  test_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get v => '';

class A {
  final f = v;
//          ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_topLevelGetter_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String? get v => '';

class A {
  final f = v ?? v;
//          ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
//               ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  @FailingTest() // TODO(scheglov): Not yet implemented.
  test_topLevelVariable_asExpression() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

final f = v as Object;
//        ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_assignment_field() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

String top = A().f;
//           ^^^^^
// [diag.assignmentOfDoNotStore] 'f' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

class A{
  @doNotStore
  String get f => '';
}
''');
  }

  test_topLevelVariable_assignment_functionExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

@doNotStore
String get _v => '';

var c = () => _v;
//            ^^
// [diag.assignmentOfDoNotStore] '_v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

String v = c();
''');
  }

  test_topLevelVariable_assignment_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

String top = v;
//           ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_assignment_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

String top = A().v();
//           ^^^^^^^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

class A{
  @doNotStore
  String v() => '';
}
''');
  }

  test_topLevelVariable_cascadeExpression_propertyAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = A()..v;

class A {
  @doNotStore
  String get v => '';
}
''');
  }

  @FailingTest() // TODO(scheglov): Not yet implemented.
  test_topLevelVariable_cascadeExpression_target() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

final f = v..runtimeType;
//        ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_conditionalExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  final f = 1 == 2 ? v : v;
//                   ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
//                       ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}

@doNotStore
String get v => '';
''');
  }

  @FailingTest() // TODO(scheglov): Not yet implemented.
  test_topLevelVariable_dotShorthandPropertyAccess() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

final A f = .v;
//            ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

class A {
  @doNotStore
  static A get v => A();
}
''');
  }

  test_topLevelVariable_forElement() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = [for (var _ in [1]) v];

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_ifElement() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = [if (true) v];

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_instanceCreationExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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

    await resolveTestCodeWithDiagnostics(r'''
import 'library.dart';

class A {
  final f = v;
//          ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
}
''');
  }

  test_topLevelVariable_listLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = [v];

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_mapLiteral_key() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = {v: 1};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_mapLiteral_value() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = {1: v};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_nonAssignment_argToFunctionCall() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

var top = print(v);

@doNotStore
String get v => '';
''');
  }

  @FailingTest() // TODO(scheglov): Not yet implemented.
  test_topLevelVariable_nullAssert() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

final f = v!;
//        ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_nullAwareElement() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = [?v];

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = -v;

@doNotStore
int get v => 1;
''');
  }

  test_topLevelVariable_recordLiteral_namedField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = (a: v, );

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_recordLiteral_positionalField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = (v, );

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_setLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = {v};

@doNotStore
String get v => '';
''');
  }

  test_topLevelVariable_spreadElement() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = [...v];

@doNotStore
List<String> get v => [];
''');
  }

  @FailingTest() // TODO(scheglov): Not yet implemented.
  test_topLevelVariable_switchExpression_caseBody() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';

final f = switch (1 == 2) {
  true => v,
//        ^
// [diag.assignmentOfDoNotStore] 'v' is marked 'doNotStore' and shouldn't be assigned to a field or top-level variable.
  false => '',
};

@doNotStore
String? get v => '';
''');
  }

  test_topLevelVariable_switchExpression_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

final f = throw v;

@doNotStore
String get v => '';
''');
  }
}
