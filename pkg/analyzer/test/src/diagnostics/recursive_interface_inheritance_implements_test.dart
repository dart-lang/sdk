// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceImplementsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceImplementsTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements A {}
//                 ^
// [diag.recursiveInterfaceInheritanceImplements] 'A' can't implement itself.
''');
  }

  test_class_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A implements A {}
//                         ^
// [diag.recursiveInterfaceInheritanceImplements] 'A' can't implement itself.
''');
  }

  test_class_inAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}
''',
      b: r'''
part of 'a.dart';

augment class A implements A {}
//                         ^
// [diag.recursiveInterfaceInheritanceImplements] 'A' can't implement itself.
''',
    });
  }

  test_class_inAugmentation_part_indirect() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.

class B implements A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''',
      b: r'''
part of 'a.dart';

augment class A implements B {}
''',
    });
  }

  test_class_tail() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements A {}
//                          ^
// [diag.recursiveInterfaceInheritanceImplements] 'A' can't implement itself.
class B implements A {}
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M {}
class B = A with M implements B;
//                            ^
// [diag.recursiveInterfaceInheritanceImplements] 'B' can't implement itself.
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A implements B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
mixin B implements A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }
}
