// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(r'''
class A extends dynamic {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 7),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: dynamic
    element: dynamic@-1
    element2: dynamic@-1
    type: dynamic
''');
  }

  test_class_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends E {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 31, 1),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: E
    element: <testLibraryFragment>::@enum::E
    element2: <testLibraryFragment>::@enum::E#element
    type: E
''');
  }

  test_class_extensionType() async {
    await assertErrorsInCode(r'''
extension type A(int it) {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 44, 1),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: A
    element: <testLibraryFragment>::@extensionType::A
    element2: <testLibraryFragment>::@extensionType::A#element
    type: A
''');
  }

  test_class_mixin() async {
    await assertErrorsInCode(r'''
mixin M {}
class A extends M {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: M
    element: <testLibraryFragment>::@mixin::M
    element2: <testLibraryFragment>::@mixin::M#element
    type: M
''');
  }

  test_class_variable() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: v
    element: <testLibraryFragment>::@getter::v
    element2: <testLibraryFragment>::@getter::v#element
    type: InvalidType
''');
  }

  test_class_variable_generic() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v<int> {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var node = findNode.singleExtendsClause;
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@getter::v
    element2: <testLibraryFragment>::@getter::v#element
    type: InvalidType
''');
  }

  test_Never() async {
    await assertErrorsInCode('''
class A extends Never {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 5),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: Never
    element: Never@-1
    element2: Never@-1
    type: Never
''');
  }

  test_undefined() async {
    await assertErrorsInCode(r'''
class C extends A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 1),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    name: A
    element: <null>
    element2: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix() async {
    await assertErrorsInCode(r'''
import 'a.dart' as p;

class C extends p.A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: A
    element: <null>
    element2: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'x.dart' as p;
part 'test.dart';
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';
class C extends p.A {}
''');

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: package:test/a.dart::<fragment>::@prefix::p
      element2: package:test/a.dart::<fragment>::@prefix2::p
    name: A
    element: <null>
    element2: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_prefix_part2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertErrorsInCode(r'''
part of 'a.dart';
import 'x.dart' as p;
class C extends p.A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 25, 8),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: package:test/a.dart::@fragment::package:test/test.dart::@prefix::p
      element2: package:test/a.dart::@fragment::package:test/test.dart::@prefix2::p
    name: A
    element: <null>
    element2: <null>
    type: InvalidType
''');
  }

  test_undefined_ignore_import_show_it() async {
    await assertErrorsInCode(r'''
import 'a.dart' show A;

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_undefined_ignore_import_show_it_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
import 'x.dart' show A;
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';
class C extends A {}
''');
  }

  test_undefined_ignore_import_show_it_part2() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertErrorsInCode(r'''
part of 'a.dart';
import 'x.dart' show A;
class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 25, 8),
    ]);
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
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
part of 'a.dart';
class C extends A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 34, 1),
    ]);
  }

  test_undefined_ignore_import_show_other() async {
    await assertErrorsInCode(r'''
import 'a.dart' show B;

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 41, 1),
    ]);
  }

  test_undefined_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 34, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 34, 1),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 32, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 32, 1),
    ]);
  }

  test_undefined_import_exists_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

class C extends p.A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 42, 3),
    ]);

    var node = findNode.singleExtendsClause;
    assertResolvedNodeText(node, r'''
ExtendsClause
  extendsKeyword: extends
  superclass: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
      element: <testLibraryFragment>::@prefix::p
      element2: <testLibraryFragment>::@prefix2::p
    name: A
    element: <null>
    element2: <null>
    type: InvalidType
''');
  }
}
