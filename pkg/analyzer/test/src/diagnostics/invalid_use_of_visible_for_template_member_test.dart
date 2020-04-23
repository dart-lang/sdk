// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTemplateMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTemplateMemberTest extends DriverResolutionTest
    with PackageMixin {
  void addAngularMetaPackage() {
    Folder lib = addPubPackage('angular_meta');
    newFile(join(lib.path, 'angular_meta.dart'), content: r'''
library angular.meta;

const _VisibleForTemplate visibleForTemplate = const _VisibleForTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}
''');
  }

  test_export() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    newFile('/lib2.dart', content: r'''
export 'lib1.dart' show fn0;
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart');
  }

  test_functionInExtension() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
extension E on List {
  @visibleForTemplate
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
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 42, 1),
    ]);
  }

  test_functionInExtension_fromTemplate() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
extension E on List {
  @visibleForTemplate
  int m() => 1;
}
''');
    newFile('/lib1.template.dart', content: r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib1.template.dart');
  }

  test_method() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
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
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 53, 1),
    ]);
  }

  test_method_fromTemplate() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    addAngularMetaPackage();
    newFile('/lib1.template.dart', content: r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib1.template.dart');
  }

  test_namedConstructor() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';

void main() {
  new A.forTemplate(0);
}
''');

    await _resolveFile('/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 65, 2),
    ]);
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 41, 13),
    ]);
  }

  test_propertyAccess() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  int get a => 7;

  @visibleForTemplate
  set b(_) => 7;
}
''');
    newFile('/lib2.dart', content: r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 45, 1),
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 58, 1),
    ]);
  }

  test_protectedAndForTemplate_usedAsProtected() async {
    addAngularMetaPackage();
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
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

  test_protectedAndForTemplate_usedAsTemplate() async {
    addAngularMetaPackage();
    addMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    addAngularMetaPackage();
    addMetaPackage();
    newFile('/lib1.template.dart', content: r'''
import 'lib1.dart';
void main() {
  new A().a();
}
''');

    await _resolveFile('/lib1.dart');
    await _resolveFile('/lib1.template.dart');
  }

  test_topLevelFunction() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
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
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 37, 3),
    ]);
  }

  test_unnamedConstructor() async {
    addAngularMetaPackage();
    newFile('/lib1.dart', content: r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
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
      error(HintCode.UNUSED_FIELD, 65, 2),
    ]);
    await _resolveFile('/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 41, 1),
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
