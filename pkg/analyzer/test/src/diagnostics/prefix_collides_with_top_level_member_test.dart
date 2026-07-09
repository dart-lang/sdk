// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixCollidesWithTopLevelMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrefixCollidesWithTopLevelMemberTest extends PubPackageResolutionTest {
  test_library_functionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
typedef foo = void Function();
//      ^^^
// [context 1] The first definition of this name.
''');
  }

  test_library_no_collision() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
void bar() {}
''');
  }

  test_library_topLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
void foo() {}
//   ^^^
// [context 1] The first definition of this name.
''');
  }

  test_library_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
int get foo => 0;
//      ^^^
// [context 1] The first definition of this name.
''');
  }

  test_library_topLevelSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
set foo(int _) {}
//  ^^^
// [context 1] The first definition of this name.
''');
  }

  test_library_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
var foo = 0;
//  ^^^
// [context 1] The first definition of this name.
''');
  }

  test_library_type() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
class foo {}
//    ^^^
// [context 1] The first definition of this name.
''');
  }

  test_part_topLevelFunction_inLibrary() async {
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'test.dart';
void foo() {}
//   ^^^
// [context 1] The first definition of this name.
''',
      testFile: r'''
part of 'a.dart';
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
''',
    });
  }

  test_part_topLevelFunction_inPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
part of 'a.dart';
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
void foo() {}
//   ^^^
// [context 1] The first definition of this name.
''');
  }

  test_part_topLevelFunction_inPart2() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'test.dart';
part 'b.dart';
''',
      b: r'''
part of 'a.dart';
void foo() {}
//   ^^^
// [context 1] The first definition of this name.
''',
      testFile: r'''
part of 'a.dart';
import 'dart:math' as foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.
//                    ^^^
// [diag.prefixCollidesWithTopLevelMember][context 1] The name 'foo' is already used as an import prefix and can't be used to name a top-level element.
''',
    });
  }
}
