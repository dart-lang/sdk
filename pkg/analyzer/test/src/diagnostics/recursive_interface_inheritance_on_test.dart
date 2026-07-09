// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceOnTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceOnTest extends PubPackageResolutionTest {
  test_1() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A on A {}
//         ^
// [diag.recursiveInterfaceInheritanceOn] 'A' can't use itself as a superclass constraint.
''');
  }

  test_1_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A on A {}
//                 ^
// [diag.recursiveInterfaceInheritanceOn] 'A' can't use itself as a superclass constraint.
''');
  }

  test_1_inAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin A {}
''',
      b: r'''
part of 'a.dart';

augment mixin A on A {}
//                 ^
// [diag.recursiveInterfaceInheritanceOn] 'A' can't use itself as a superclass constraint.
''',
    });
  }

  test_1_inAugmentation_part_indirect() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.

mixin B on A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''',
      b: r'''
part of 'a.dart';

augment mixin A on B {}
''',
    });
  }

  test_2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A on B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
mixin B on A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }
}
