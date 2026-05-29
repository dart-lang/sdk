// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingGenericInterfacesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConflictingGenericInterfacesTest extends PubPackageResolutionTest {
  test_class_extends_augmentation_implements() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B extends A {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'B' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
augment class B implements I<String> {}
''');
  }

  test_class_extends_augmentation_implements_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class I<T> {}
class A implements I<int> {}
class B extends A {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'B' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''',
      b: r'''
part of 'a.dart';

augment class B implements I<String> {}
''',
    });
  }

  test_class_extends_implements() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'C' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''');
  }

  test_class_extends_implements_never() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<Never> {}
class B implements I<Never> {}
class C extends A implements B {}
''');
  }

  test_class_extends_implements_nullability() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
class C extends A implements B {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'C' can't implement both 'I<int>' and 'I<int?>' because the type arguments are different.
''');
  }

  test_class_extends_implements_object_objectQuestion() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}
class B implements A<Object> {}
class C implements A<Object?> {}
class D extends B implements C {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'D' can't implement both 'A<Object>' and 'A<Object?>' because the type arguments are different.
''');
  }

  test_class_extends_with() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
mixin B implements I<String> {}
class C extends A with B {}
//    ^
// [diag.conflictingGenericInterfaces] The class 'C' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''');
  }

  test_class_topMerge() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

class A<T> {}

class B extends A<FutureOr<Object>> {}

class C extends B implements A<Object> {}
''');
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
typedef A = I<int>;
mixin M implements I<String> {}
class C = A with M;
//    ^
// [diag.conflictingGenericInterfaces] The class 'C' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''');
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with_ok() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
typedef A = I<String>;
mixin M implements I<String> {}
class C = A with M;
''');
  }

  test_classTypeAlias_extends_with() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
mixin M implements I<String> {}
class C = A with M;
//    ^
// [diag.conflictingGenericInterfaces] The class 'C' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''');
  }

  test_enum_implements() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
enum E implements A, B {
//   ^
// [diag.conflictingGenericInterfaces] The enum 'E' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
  v
}
''');
  }

  test_enum_with() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
mixin M1 implements I<int> {}
mixin M2 implements I<String> {}
enum E with M1, M2 {
//   ^
// [diag.conflictingGenericInterfaces] The enum 'E' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
  v
}
''');
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<num> {}
extension type C(Never it) implements A, B {}
//             ^
// [diag.conflictingGenericInterfaces] The extension type 'C' can't implement both 'I<int>' and 'I<num>' because the type arguments are different.
//               ^^^^^
// [diag.extensionTypeRepresentationTypeBottom] The representation type can't be a bottom type.
''');
  }

  test_mixin_on_implements() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
mixin M on A implements B {}
//    ^
// [diag.conflictingGenericInterfaces] The mixin 'M' can't implement both 'I<int>' and 'I<String>' because the type arguments are different.
''');
  }

  test_noConflict() async {
    await resolveTestCodeWithDiagnostics('''
class I<T> {}
class A implements I<int> {}
class B implements I<int> {}
class C extends A implements B {}
''');
  }
}
