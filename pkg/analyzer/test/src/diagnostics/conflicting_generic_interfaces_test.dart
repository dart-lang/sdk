// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingGenericInterfacesTest);
    defineReflectiveTests(ConflictingGenericInterfacesWithNullSafetyTest);
  });
}

@reflectiveTest
class ConflictingGenericInterfacesTest extends PubPackageResolutionTest {
  test_class_extends_implements() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 75, 33),
    ]);
  }

  test_class_extends_with() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 75, 27),
    ]);
  }

  test_classTypeAlias_extends_with() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
mixin M implements I<String> {}
class C = A with M;
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 75, 19),
    ]);
  }

  test_mixin_on_implements() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
mixin M on A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 75, 28),
    ]);
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

@reflectiveTest
class ConflictingGenericInterfacesWithNullSafetyTest
    extends ConflictingGenericInterfacesTest with WithNullSafetyMixin {
  test_class_extends_implements_never() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<Never> {}
class B implements I<Never> {}
class C extends A implements B {}
''');
  }

  test_class_extends_implements_nullability() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 73, 33),
    ]);
  }

  test_class_extends_implements_optOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
''');
    await assertNoErrorsInCode('''
// @dart = 2.5
import 'a.dart';

class C extends A implements B {}
''');
  }

  test_class_extends_optIn_implements_optOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {}

class B extends A<int> {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class C extends B implements A<int> {}
''');
  }

  test_class_mixed_viaLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {}

class Bi implements A<int> {}

class Biq implements A<int?> {}
''');

    // Both `Bi` and `Biq` implement `A<int*>` in legacy, so identical.
    newFile('$testPackageLibPath/b.dart', content: r'''
// @dart = 2.7
import 'a.dart';

class C extends Bi implements Biq {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

abstract class D implements C {}
''');
  }

  test_class_topMerge() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A<T> {}

class B extends A<FutureOr<Object>> {}

class C extends B implements A<Object> {}
''');
  }

  test_class_topMerge_optIn_optOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
// @dart = 2.5
import 'a.dart';

class B extends A<int> {}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart';

class C extends B implements A<int> {}
''');
  }
}
