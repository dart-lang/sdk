// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTestingMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMemberTest extends DriverResolutionTest
    with PackageMixin {
  test_export() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
@visibleForTesting
int fn0() => 1;
''');
    newFile('/lib2.dart', content: r'''
export 'lib1.dart' show fn0;
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart');
  }

  test_fromTestDirectory() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('/test/test.dart', content: r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/test/test.dart');
  }

  test_fromTestingDirectory() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('/testing/lib1.dart', content: r'''
import '../lib1.dart';
class C {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/testing/lib1.dart');
  }

  test_functionInExtension() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 42, 1),
    ]);
  }

  test_functionInExtension_fromTestDirectory() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    newFile('/test/test.dart', content: r'''
import '../lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/test/test.dart');
  }

  test_getter() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  new A().a;
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_method() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 52, 1),
    ]);
  }

  test_mixin() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
mixin M {
  @visibleForTesting
  int m() => 1;
}
class C with M {}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  C().m();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
    ]);
  }

  test_namedConstructor() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A.forTesting(this._x);
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  new A.forTesting(0);
}
''');

    await _resolveFile('/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 49, 2),
    ]);
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 12,
          messageContains: 'A.forTesting'),
    ]);
  }

  test_protectedAndForTesting_usedAsProtected() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
class B extends A {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart');
  }

  test_protectedAndForTesting_usedAsTesting() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    addMetaPackage();
    newFile('/test/test1.dart', content: r'''
import '../lib1.dart';
void main() {
  new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/test/test1.dart');
  }

  test_setter() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  set b(_) => 7;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  new A().b = 6;
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_topLevelFunction() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
@visibleForTesting
int fn0() => 1;
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  fn0();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 36, 3),
    ]);
  }

  test_unnamedConstructor() async {
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A(this._x);
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';
void main() {
  new A(0);
}
''');

    await _resolveFile('/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 49, 2),
    ]);
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
    ]);
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}
