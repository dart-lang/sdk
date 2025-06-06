// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingGenericInterfacesTest);
  });
}

@reflectiveTest
class ConflictingGenericInterfacesTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_extends_augmentation_implements() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class B implements I<String> {}
''');

    newFile(testFile.path, '''
part 'a.dart';

class I<T> {}
class A implements I<int> {}
class B extends A {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(testFile, [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 65, 1),
    ]);
  }

  test_class_extends_implements() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1)],
    );
  }

  test_class_extends_implements_never() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<Never> {}
class B implements I<Never> {}
class C extends A implements B {}
''');
  }

  test_class_extends_implements_nullability() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
class C extends A implements B {}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 79, 1)],
    );
  }

  test_class_extends_implements_object_objectQuestion() async {
    await assertErrorsInCode(
      '''
class A<T> {}
class B implements A<Object> {}
class C implements A<Object?> {}
class D extends B implements C {}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 85, 1)],
    );
  }

  test_class_extends_with() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
mixin B implements I<String> {}
class C extends A with B {}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1)],
    );
  }

  test_class_topMerge() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A<T> {}

class B extends A<FutureOr<Object>> {}

class C extends B implements A<Object> {}
''');
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with() async {
    await assertErrorsInCode(
      '''
class I<T> {}
typedef A = I<int>;
mixin M implements I<String> {}
class C = A with M;
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 72, 1)],
    );
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with_ok() async {
    await assertNoErrorsInCode('''
class I<T> {}
typedef A = I<String>;
mixin M implements I<String> {}
class C = A with M;
''');
  }

  test_classTypeAlias_extends_with() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
mixin M implements I<String> {}
class C = A with M;
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1)],
    );
  }

  test_enum_implements() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
enum E implements A, B {
  v
}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 80, 1)],
    );
  }

  test_enum_with() async {
    await assertErrorsInCode(
      '''
class I<T> {}
mixin M1 implements I<int> {}
mixin M2 implements I<String> {}
enum E with M1, M2 {
  v
}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 82, 1)],
    );
  }

  test_extensionType() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
class B implements I<num> {}
extension type C(Never it) implements A, B {}
''',
      [
        error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 87, 1),
        error(
          CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM,
          89,
          5,
        ),
      ],
    );
  }

  test_mixin_on_implements() async {
    await assertErrorsInCode(
      '''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
mixin M on A implements B {}
''',
      [error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1)],
    );
  }

  test_noConflict() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<int> {}
class C extends A implements B {}
''');
  }
}
