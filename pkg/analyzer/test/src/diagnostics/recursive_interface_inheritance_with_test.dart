// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceWithTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceWithTest extends PubPackageResolutionTest {
  test_class_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Object {}
augment class A with A {}
//                   ^
// [diag.recursiveInterfaceInheritanceWith] 'A' can't use itself as a mixin.
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_class_inAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class A extends Object {}
''',
      b: r'''
part of 'a.dart';

augment class A with A {}
//                   ^
// [diag.recursiveInterfaceInheritanceWith] 'A' can't use itself as a mixin.
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
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

mixin class B implements A {}
//          ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''',
      b: r'''
part of 'a.dart';

augment class A with B {}
''',
    });
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class M = Object with M;
//                          ^
// [diag.recursiveInterfaceInheritanceWith] 'M' can't use itself as a mixin.
''');
  }
}
