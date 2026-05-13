// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsRepeatedTest);
  });
}

@reflectiveTest
class ImplementsRepeatedTest extends PubPackageResolutionTest {
  test_class_implements_2times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B implements A, A {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');

    var node = findNode.singleImplementsClause;
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_implements_2times_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
class B implements A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class B implements A {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [error(diag.implementsRepeated, 46, 1)]);
  }

  test_class_implements_2times_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
class C implements A, B {}
//                    ^
// [diag.implementsRepeated] 'A' can only be implemented once.
''');

    var node = findNode.singleImplementsClause;
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
    await resolveTestCodeWithDiagnostics(r'''
class A {}
enum E implements A, A {
//                   ^
// [diag.implementsRepeated] 'A' can only be implemented once.
  v
}
''');

    var node = findNode.singleImplementsClause;
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_implements_2times_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
enum E implements A {v}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment enum E implements A {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [error(diag.implementsRepeated, 45, 1)]);
  }

  test_enum_implements_2times_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
enum E implements A, B {
//                   ^
// [diag.implementsRepeated] 'A' can only be implemented once.
  v
}
''');

    var node = findNode.singleImplementsClause;
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
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements int, int {}
//                                       ^^^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');

    var node = findNode.singleImplementsClause;
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_extensionType_implements_2times_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

extension type A(int it) implements int {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment extension type A(int it) implements int {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [error(diag.implementsRepeated, 63, 3)]);
  }

  test_extensionType_implements_2times_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
extension type B(int it) implements int, A {}
//                                       ^
// [diag.implementsRepeated] 'int' can only be implemented once.
''');

    var node = findNode.singleImplementsClause;
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

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_implements_2times_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {}
mixin M implements A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment mixin M implements A {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [error(diag.implementsRepeated, 46, 1)]);
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
