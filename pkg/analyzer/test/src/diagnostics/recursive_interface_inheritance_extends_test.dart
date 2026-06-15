// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceExtendsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceExtendsTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends A {}
//              ^
// [diag.recursiveInterfaceInheritanceExtends] 'A' can't extend itself.
''');
  }

  test_class_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class C extends C {
//              ^
// [diag.recursiveInterfaceInheritanceExtends] 'C' can't extend itself.
  var foo = 0;
  bar();
}
''');
  }

  test_class_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A extends A {}
//                      ^
// [diag.recursiveInterfaceInheritanceExtends] 'A' can't extend itself.
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

augment class A extends A {}
//                      ^
// [diag.recursiveInterfaceInheritanceExtends] 'A' can't extend itself.
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

class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''',
      b: r'''
part of 'a.dart';

augment class A extends B {}
''',
    });
  }
}
