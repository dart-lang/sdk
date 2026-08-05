// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends PubPackageResolutionTest {
  test_class_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A extends dynamic {}
//              ^^^^^^^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: dynamic
    element: dynamic
    type: dynamic
''');
  }

  test_class_enum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { ONE }
class A extends E {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: E
    element: <testLibrary>::@enum::E
    type: E
''');
  }

  test_class_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
class B extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: A
    element: <testLibrary>::@extensionType::A
    type: A
''');
  }

  test_class_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
class A extends M {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: M
    element: <testLibrary>::@mixin::M
    type: M
''');
  }

  test_class_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int v = 0;
class A extends v {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: v
    element: <testLibrary>::@getter::v
    type: InvalidType
''');
  }

  test_class_variable_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int v = 0;
class A extends v<int> {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: v
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@getter::v
    type: InvalidType
''');
  }

  test_Never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A extends Never {}
//              ^^^^^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: Never
    element: Never
    type: Never
''');
  }

  test_undefined() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: A
    element: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C extends p.A {}
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: A
    element: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'x.dart' as p;
part 'test.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
class C extends p.A {}
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: package:test/a.dart::<fragment>::@prefix::p
    name: A
    element: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix_part2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
import 'x.dart' as p;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'x.dart'.
class C extends p.A {}
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: package:test/a.dart::@fragment::package:test/test.dart::@prefix::p
    name: A
    element: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_show_it() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show A;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C extends A {}
''');
  }

  test_undefined_ignore_import_show_it_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
import 'x.dart' show A;
''');

    await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
class C extends A {}
''');
  }

  test_undefined_ignore_import_show_it_part2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
import 'x.dart' show A;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'x.dart'.
class C extends A {}
''');
  }

  test_undefined_ignore_import_show_it_part3() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart' show A;
part 'test.dart';
''');

    // This file is on the path with `b.dart`, so no error.
    await resolveTestCodeWithDiagnostics(r'''
part of 'b.dart';
class C extends A {}
''');
  }

  test_undefined_ignore_import_show_it_part4() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
part 'test.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart' show A;
''');

    // This file is not on the path with `b.dart`, so the error.
    await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
class C extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_ignore_import_show_other() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show B;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class C extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';

class C extends _$A {}
//              ^^^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

class C extends _$A {}
''');
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.g.dart';
//   ^^^^^^^^^^
// [diag.uriHasNotBeenGenerated] Target of URI hasn't been generated: 'package:test/a.g.dart'.

class C extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

class C extends _$A {}
//              ^^^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.

class C extends A {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
''');
  }

  test_undefined_import_exists_prefixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

class C extends p.A {}
//              ^^^
// [diag.extendsNonClass] Classes can only extend other classes.
''');

    var node = result.findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
    name: A
    element: <null>
    type: InvalidType
''');
  }
}
