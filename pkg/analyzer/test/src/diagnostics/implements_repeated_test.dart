// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsRepeatedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImplementsRepeatedTest extends PubPackageResolutionTest {
  test_class_implements_2times() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B implements A, A {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
''');
  }

  test_class_implements_2times_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B implements A {}
augment class B implements A {}
//                         ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }

  test_class_implements_2times_augmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}
class B implements A {}
''',
      b: r'''
part of 'a.dart';

augment class B implements A {}
//                         ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''',
    });
  }

  test_class_implements_2times_viaTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
class C implements A, B {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A
        alias: <testLibrary>::@typeAlias::B
''');
  }

  test_class_implements_4times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {} class C{}
class B implements A, A, A, A {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                       ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                          ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }

  test_enum_implements_2times() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
enum E implements A, A {
//                   ^
// [diag.implementsRepeated] 'A' can only be implemented once.
  v
}
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
''');
  }

  test_enum_implements_2times_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
enum E implements A {v}
augment enum E implements A {}
//                        ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }

  test_enum_implements_2times_augmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}
enum E implements A {v}
''',
      b: r'''
part of 'a.dart';

augment enum E implements A {}
//                        ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''',
    });
  }

  test_enum_implements_2times_viaTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
enum E implements A, B {
//                   ^
// [diag.implementsRepeated] 'A' can only be implemented once.
  v
}
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A
        alias: <testLibrary>::@typeAlias::B
''');
  }

  test_enum_implements_4times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {} class C{}
enum E implements A, A, A, A {
//                   ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                      ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                         ^
// [diag.implementsRepeated] 'A' can only be implemented once.
  v
}
''');
  }

  test_extensionType_implements_2times() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements int, int {}
//                                       ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
''');
  }

  test_extensionType_implements_2times_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements int {}
augment extension type A implements int {}
//                                  ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');
  }

  test_extensionType_implements_2times_augmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

extension type A(int it) implements int {}
''',
      b: r'''
part of 'a.dart';

augment extension type A implements int {}
//                                  ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
''',
    });
  }

  test_extensionType_implements_2times_viaTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
extension type B(int it) implements int, A {}
//                                       ^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');

    var node = result.findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
    NamedType
      name: A
      element: <testLibrary>::@typeAlias::A
      type: int
        alias: <testLibrary>::@typeAlias::A
''');
  }

  test_extensionType_implements_4times() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements int, int, int, int {}
//                                       ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
//                                            ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
//                                                 ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');
  }

  test_mixin_implements_2times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M implements A, A {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }

  test_mixin_implements_2times_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M implements A {}
augment mixin M implements A {}
//                         ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }

  test_mixin_implements_2times_augmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}
mixin M implements A {}
''',
      b: r'''
part of 'a.dart';

augment mixin M implements A {}
//                         ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''',
    });
  }

  test_mixin_implements_4times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M implements A, A, A, A {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                       ^
// [diag.implementsRepeated] 'A' can only be implemented once.
//                          ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');
  }
}
