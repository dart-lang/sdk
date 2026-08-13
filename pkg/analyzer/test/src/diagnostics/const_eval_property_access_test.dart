// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalPropertyAccessTest);
  });
}

@reflectiveTest
class ConstEvalPropertyAccessTest extends PubPackageResolutionTest {
  test_constructorArgument_rhsOfLogicalOperation() async {
    // Note: prior to the fix for https://github.com/dart-lang/sdk/issues/61761,
    // this caused an exception to be thrown during constant evaluation.
    // TODO(paulberry): this error range covers the whole subexpression
    // `false || a.x`. Probably it's better to just cover `a.x`.
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final bool x;
  const C(this.x);
}
const C a = C(true);
const C b = C(false || a.x);
//            ^^^^^^^^^^^^
// [diag.constEvalPropertyAccess] The property 'x' can't be accessed on the type 'C' in a constant expression.
''');
  }

  test_constructorFieldInitializer_fromSeparateLibrary() async {
    var lib = getFile('$testPackageLibPath/lib.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
//                ^^^^^
// [context 1] The error is in the field initializer of 'A', and occurs here.
// [diag.invalidConstant] Invalid constant value.
//                  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'Type'.
}
''',
      testFile: r'''
import 'lib.dart';
const a = const A();
//        ^^^^^^^^^
// [diag.constEvalPropertyAccess][context 1] The property 'foo' can't be accessed on the type 'Type' in a constant expression.
''',
    });
  }

  test_length_dynamic_notNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic d = 'foo';
const int? c = d.length;
''');
  }

  test_length_dynamic_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic d = null;
const int? c = d.length;
//             ^^^^^^^^
// [diag.constEvalPropertyAccess] The property 'length' can't be accessed on the type 'Null' in a constant expression.
''');
  }

  test_length_invalidTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
void main() {
  const RequiresNonEmptyList([1]);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.constEvalPropertyAccess][context 1] The property 'length' can't be accessed on the type 'List<int>' in a constant expression.
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
//                                                       ^^^^^^^^^^^^^^
// [context 1] The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here.
}
''');
  }

  test_nonStaticField_inGenericClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C();
  T? get t => null;
}

const x = const C().t;
//        ^^^^^^^^^^^
// [diag.constEvalPropertyAccess] The property 't' can't be accessed on the type 'C<dynamic>' in a constant expression.
''');
  }

  test_nullAware_isEven_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const int? s = null;
const bool? c = s?.isEven;
//              ^^^^^^^^^
// [diag.constEvalPropertyAccess] The property 'isEven' can't be accessed on the type 'Null' in a constant expression.
''');
  }

  test_nullAware_length_dynamic_null() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic d = 'foo';
const int? c = d?.length;
''');
  }

  test_nullAware_length_list_notNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const List? l = [];
const int? c = l?.length;
//             ^^^^^^^^^
// [diag.constEvalPropertyAccess] The property 'length' can't be accessed on the type 'List<dynamic>' in a constant expression.
''');
  }

  test_nullAware_length_string_notNull() async {
    await resolveTestCodeWithDiagnostics(r'''
const String? s = '';
const int? c = s?.length;
''');
  }
}
