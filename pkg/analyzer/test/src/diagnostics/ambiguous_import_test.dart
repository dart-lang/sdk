// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:matcher/src/core_matchers.dart';
import 'package:test/test.dart' show expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousImportTest);
  });
}

@reflectiveTest
class AmbiguousImportTest extends PubPackageResolutionTest {
  test_annotation_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
const foo = 0;
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
import 'b.dart';

@foo
class A {}
''',
      [
        error(CompileTimeErrorCode.invalidAnnotation, 35, 4),
        error(CompileTimeErrorCode.ambiguousImport, 36, 3),
      ],
    );
  }

  test_as() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p as N;}''',
      [error(CompileTimeErrorCode.ambiguousImport, 51, 1)],
    );
  }

  test_extends() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
class A extends N {}''',
      [
        error(CompileTimeErrorCode.ambiguousImport, 56, 1),
        error(CompileTimeErrorCode.extendsNonClass, 56, 1),
      ],
    );
  }

  test_implements() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
class A implements N {}''',
      [
        error(CompileTimeErrorCode.implementsNonClass, 59, 1),
        error(CompileTimeErrorCode.ambiguousImport, 59, 1),
      ],
    );
  }

  test_inPart() async {
    newFile("$testPackageLibPath/lib1.dart", '''
class N {}
''');
    newFile("$testPackageLibPath/lib2.dart", '''
class N {}
''');
    var partFile = newFile('$testPackageLibPath/part.dart', '''
part of 'lib.dart';
class A extends N {}
''');
    var libFile = newFile('$testPackageLibPath/lib.dart', '''
import 'lib1.dart';
import 'lib2.dart';
part 'part.dart';
''');
    ResolvedUnitResult libResult = await resolveFile(libFile);
    ResolvedUnitResult partResult = await resolveFile(partFile);
    expect(libResult.diagnostics, hasLength(0));
    GatheringDiagnosticListener()
      ..addAll(partResult.diagnostics)
      ..assertErrors([
        error(CompileTimeErrorCode.extendsNonClass, 36, 1),
        error(CompileTimeErrorCode.ambiguousImport, 36, 1),
      ]);
  }

  test_instanceCreation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {new N();}''',
      [error(CompileTimeErrorCode.ambiguousImport, 60, 1)],
    );
  }

  test_instanceCreation_dotShorthand() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {
  N n = .new();
  print(n);
}''',
      [
        error(CompileTimeErrorCode.ambiguousImport, 59, 1),
        error(CompileTimeErrorCode.dotShorthandUndefinedInvocation, 66, 3),
      ],
    );
  }

  test_is() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p is N;}''',
      [error(CompileTimeErrorCode.ambiguousImport, 51, 1)],
    );
  }

  test_qualifier() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
g() { N.FOO; }''',
      [error(CompileTimeErrorCode.ambiguousImport, 46, 1)],
    );
  }

  test_systemLibrary_nonSystemLibrary() async {
    // From the spec, "a declaration from a non-system library shadows
    // declarations from system libraries."
    newFile('$testPackageLibPath/a.dart', '''
class StreamController {}
''');
    await assertNoErrorsInCode('''
import 'dart:async'; // ignore: unused_import
import 'a.dart';

StreamController s = StreamController();
''');
  }

  test_systemLibrary_systemLibrary() async {
    await assertErrorsInCode(
      '''
import 'dart:html';
import 'dart:io';
g(File f) {}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 40, 4)],
    );
  }

  test_typeAnnotation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
typedef N FT(N p);
N f(N p) {
  N v;
  return null;
}
class A {
  N m() { return null; }
}
class B<T extends N> {}''',
      [
        error(CompileTimeErrorCode.ambiguousImport, 48, 1),
        error(CompileTimeErrorCode.ambiguousImport, 53, 1),
        error(CompileTimeErrorCode.ambiguousImport, 59, 1),
        error(CompileTimeErrorCode.ambiguousImport, 63, 1),
        error(CompileTimeErrorCode.ambiguousImport, 72, 1),
        error(WarningCode.unusedLocalVariable, 74, 1),
        error(CompileTimeErrorCode.ambiguousImport, 106, 1),
        error(CompileTimeErrorCode.ambiguousImport, 149, 1),
      ],
    );
  }

  test_typeArgument_annotation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
A<N>? f() { return null; }''',
      [error(CompileTimeErrorCode.ambiguousImport, 56, 1)],
    );
  }

  test_typeArgument_instanceCreation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await assertErrorsInCode(
      '''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
f() {new A<N>();}''',
      [error(CompileTimeErrorCode.ambiguousImport, 65, 1)],
    );
  }

  test_variable_read() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await assertErrorsInCode(
      '''
import 'a.dart';
import 'b.dart';

void f() {
  x;
}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 48, 1)],
    );
  }

  test_variable_read_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await assertErrorsInCode(
      '''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.x;
}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 60, 1)],
    );
  }

  test_variable_write() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await assertErrorsInCode(
      '''
import 'a.dart';
import 'b.dart';

void f() {
  x = 0;
  x += 1;
  ++x;
  x++;
}
''',
      [
        error(
          CompileTimeErrorCode.ambiguousImport,
          48,
          1,
          messageContains: ["'x'"],
        ),
        error(CompileTimeErrorCode.ambiguousImport, 57, 1),
        error(CompileTimeErrorCode.ambiguousImport, 69, 1),
        error(CompileTimeErrorCode.ambiguousImport, 74, 1),
      ],
    );
  }

  test_variable_write_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await assertErrorsInCode(
      '''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.x = 0;
  p.x += 1;
  ++p.x;
  p.x++;
}
''',
      [
        error(CompileTimeErrorCode.ambiguousImport, 60, 1),
        error(CompileTimeErrorCode.ambiguousImport, 71, 1),
        error(CompileTimeErrorCode.ambiguousImport, 85, 1),
        error(CompileTimeErrorCode.ambiguousImport, 92, 1),
      ],
    );
  }
}
