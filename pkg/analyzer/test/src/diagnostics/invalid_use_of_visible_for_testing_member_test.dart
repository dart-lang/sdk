// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTestingMemberTest);
    defineReflectiveTests(InvalidUseOfVisibleForTestingMember_InExtensionTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMemberTest extends DriverResolutionTest
    with PackageMixin {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_constructor() async {
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
  }

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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertNoTestErrors();
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/test/test.dart');
    assertNoTestErrors();
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/testing/lib1.dart');
    assertNoTestErrors();
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertNoTestErrors();
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/test/test1.dart');
    assertNoTestErrors();
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
  }

  /// Resolve the test file at [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveTestFile(String path) async {
    result = await resolveFile(convertPath(path));
  }
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMember_InExtensionTest
    extends InvalidUseOfVisibleForTestingMemberTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/lib2.dart');
    assertTestErrorsWithCodes(
        [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
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

    await _resolveTestFile('/lib1.dart');
    await _resolveTestFile('/test/test.dart');
    assertNoTestErrors();
  }
}
