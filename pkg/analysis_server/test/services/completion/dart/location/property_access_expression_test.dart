// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessTest);
  });
}

@reflectiveTest
class PropertyAccessTest extends AbstractCompletionDriverTest
    with PropertyAccessTestCases {
  @failingTest
  Future<void> test_afterIdentifier_partial_if() async {
    allowedIdentifiers = {'always', 'ifPresent'};
    await computeSuggestions('''
enum E {
  always, ifPresent
}
void f() {
  E.if^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  ifPresent
    kind: enumConstant
''');
  }
}

mixin PropertyAccessTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterGetter() async {
    await computeSuggestions('''
class A { int x; foo() {x.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterIdentifier() async {
    await computeSuggestions('''
class A { foo() {bar.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterIdentifier_beforeAwait() async {
    await computeSuggestions('''
void f(A a) async {
  a.^
  await a.foo();
}

class A {
  void m01() {}
}
''');
    assertResponse(r'''
suggestions
  m01
    kind: methodInvocation
''');
  }

  Future<void> test_afterIdentifier_beforeAwait_partial() async {
    await computeSuggestions('''
void f(A a) async {
  a.m0^ 
  await 0;
}

class A {
  void m01() {}
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  m01
    kind: methodInvocation
''');
  }

  Future<void> test_afterIdentifier_beforeIdentifier_partial() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
void f(String x) {
  x.len^
  foo();
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  length
    kind: getter
''');
  }

  Future<void>
      test_afterIdentifier_beforeIdentifier_partial_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
void v01() {}
void g01() {}
''');

    // There should be no `void`, we use `v` to verify this.
    await computeSuggestions('''
import 'a.dart' as prefix;

void f() {
  prefix.v^
  print(0);
}
''');

    assertResponse(r'''
replacement
  left: 1
suggestions
  v01
    kind: functionInvocation
''');
  }

  Future<void> test_afterIdentifier_partial() async {
    await computeSuggestions('''
class A { foo() {bar.as^}}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
''');
  }

  Future<void> test_afterInstanceCreation() async {
    await computeSuggestions('''
class A { get x => 7; foo() {new A().^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLibraryPrefix() async {
    await computeSuggestions('''
import "b" as b; class A { foo() {b.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_afterLocalVariable() async {
    await computeSuggestions('''
class A { foo() {int x; x.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_isInternal_method_otherPackage() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('${otherRoot.path}/lib/src/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @internal
  void f02() {}
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'other',
          rootPath: otherRoot.path,
        ),
      meta: true,
    );

    await computeSuggestions('''
import 'package:other/src/a.dart''

void f() {
  A().^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void> test_isInternal_method_samePackage() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/src/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @internal
  void f02() {}
}
''');

    await computeSuggestions('''
import 'src/a.dart''

void f() {
  A().^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
  f02
    kind: methodInvocation
''');
  }

  Future<void> test_isProtected_field_otherLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  int f01 = 0;

  @protected
  int f02 = 0;
}
''');

    await computeSuggestions('''
import 'a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: field
''');
  }

  Future<void> test_isProtected_field_sameLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  int f01 = 0;

  @protected
  int f02 = 0;
}

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: field
  f02
    kind: field
''');
  }

  Future<void> test_isProtected_getter_otherLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  int get f01 => 0;

  @protected
  int get f02 => 0;
}
''');

    await computeSuggestions('''
import 'a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: getter
''');
  }

  Future<void> test_isProtected_getter_sameLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  int get f01 => 0;

  @protected
  int get f02 => 0;
}

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: getter
  f02
    kind: getter
''');
  }

  Future<void> test_isProtected_method_otherLibrary_class_notSubtype() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @protected
  void f02() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

class B {
  void foo(A a) {
    a.^
  }
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void> test_isProtected_method_otherLibrary_class_subtype() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @protected
  void f02() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

class B extends A {
  void foo() {
    this.^
  }
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
  f02
    kind: methodInvocation
''');
  }

  Future<void> test_isProtected_method_otherLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @protected
  void f02() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void> test_isProtected_method_sameLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @protected
  void f02() {}
}

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
  f02
    kind: methodInvocation
''');
  }

  Future<void> test_isProtected_setter_otherLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  set f01(int _) {}

  @protected
  set f02(int _) {}
}
''');

    await computeSuggestions('''
import 'a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: setter
''');
  }

  Future<void> test_isProtected_setter_sameLibrary_function() async {
    writeTestPackageConfig(
      meta: true,
    );

    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  set f01(int _) {}

  @protected
  set f02(int _) {}
}

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: setter
  f02
    kind: setter
''');
  }

  Future<void> test_isVisibleForTesting_method_otherPackage() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('${otherRoot.path}/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @visibleForTesting
  void f02() {}
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'other',
          rootPath: otherRoot.path,
        ),
      meta: true,
    );

    await computeSuggestions('''
import 'package:other/a.dart''

void f() {
  A().^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void> test_isVisibleForTesting_method_otherPackage_test() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('${otherRoot.path}/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @visibleForTesting
  void f02() {}
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'other',
          rootPath: otherRoot.path,
        ),
      meta: true,
    );

    testFilePath = '$testPackageTestPath/test.dart';
    await computeSuggestions('''
import 'package:other/a.dart''

void f() {
  A().^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void> test_isVisibleForTesting_method_sameLibrary() async {
    writeTestPackageConfig(
      meta: true,
    );

    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @visibleForTesting
  void f02() {}
}

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
  f02
    kind: methodInvocation
''');
  }

  Future<void>
      test_isVisibleForTesting_method_samePackage_otherLibrary() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @visibleForTesting
  void f02() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
''');
  }

  Future<void>
      test_isVisibleForTesting_method_samePackage_otherLibrary_test() async {
    writeTestPackageConfig(
      meta: true,
    );

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  void f01() {}

  @visibleForTesting
  void f02() {}
}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await computeSuggestions('''
import 'package:test/a.dart';

void f(A a) {
  a.^
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: methodInvocation
  f02
    kind: methodInvocation
''');
  }

  Future<void> test_property_assignmentLeft_newLine() async {
    await computeSuggestions('''
class A {
  int? f01;
  void m01() {}
}

void f(A? a, Object? v01) {
  a.^
  v01 = null;
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: field
  m01
    kind: methodInvocation
''');
  }

  Future<void> test_property_assignmentLeft_newLine2() async {
    await computeSuggestions('''
class A {
  int? f01;
  void m01() {}
}

void f(A? a, Object? v01) {
  (a).^
  v01 = null;
}
''');

    assertResponse(r'''
suggestions
  f01
    kind: field
  m01
    kind: methodInvocation
''');
  }

  Future<void> test_target_assignmentLeft() async {
    await computeSuggestions('''
void f(Object v01) {
  v0^.foo = 0;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
''');
  }
}
