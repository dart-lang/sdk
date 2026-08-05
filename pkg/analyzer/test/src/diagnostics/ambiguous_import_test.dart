// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousImportTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

@foo
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
// [diag.ambiguousImport][column 2][length 3] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
class A {}
''');
  }

  test_as() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p as N;}
//         ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_extends() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
class A extends N {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_implements() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
class A implements N {}
//                 ^
// [diag.implementsNonClass] Classes and mixins can only implement other classes and mixins.
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_inPart() async {
    newFile("$testPackageLibPath/lib1.dart", '''
class N {}
''');
    newFile("$testPackageLibPath/lib2.dart", '''
class N {}
''');
    var partFile = getFile('$testPackageLibPath/part.dart');
    var libFile = getFile('$testPackageLibPath/lib.dart');

    await resolveFilesWithDiagnostics({
      libFile: r'''
import 'lib1.dart';
import 'lib2.dart';
part 'part.dart';
''',
      partFile: r'''
part of 'lib.dart';
class A extends N {}
//              ^
// [diag.extendsNonClass] Classes can only extend other classes.
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
''',
    });
  }

  test_instanceCreation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {new N();}
//       ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_instanceCreation_dotShorthand() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(r'''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {
  N n = .new();
//^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
//       ^^^
// [diag.dotShorthandUndefinedInvocation] The static method or constructor 'new' isn't defined for the context type 'InvalidType'.
  print(n);
}''');
  }

  test_is() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p is N;}
//         ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_qualifier() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
g() { N.FOO; }
//    ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_systemLibrary_nonSystemLibrary() async {
    // From the spec, "a declaration from a non-system library shadows
    // declarations from system libraries."
    newFile('$testPackageLibPath/a.dart', '''
class StreamController {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async'; // ignore: unused_import
import 'a.dart';

StreamController s = StreamController();
''');
  }

  test_systemLibrary_systemLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:html';
import 'dart:io';
g(File f) {}
//^^^^
// [diag.ambiguousImport] The name 'File' is defined in the libraries 'dart:html' and 'dart:io'.
''');
  }

  test_typeAnnotation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
typedef N FT(N p);
//      ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
//           ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
N f(N p) {
// [diag.ambiguousImport][column 1][length 1] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
//  ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
  N v;
//^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  return null;
}
class A {
  N m() { return null; }
//^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.
}
class B<T extends N> {}
//                ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_typeArgument_annotation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
A<N>? f() { return null; }
//^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_typeArgument_instanceCreation() async {
    newFile("$testPackageLibPath/lib1.dart", '''
library lib1;
class N {}''');
    newFile("$testPackageLibPath/lib2.dart", '''
library lib2;
class N {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
f() {new A<N>();}
//         ^
// [diag.ambiguousImport] The name 'N' is defined in the libraries 'package:test/lib1.dart' and 'package:test/lib2.dart'.''',
    );
  }

  test_variable_read() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  x;
//^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');
  }

  test_variable_read_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.x;
//  ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');
  }

  test_variable_write() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
import 'b.dart';

void f() {
  x = 0;
//^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  x += 1;
//^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  ++x;
//  ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  x++;
//^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');
  }

  test_variable_write_prefixed() async {
    newFile('$testPackageLibPath/a.dart', '''
var x;
''');

    newFile('$testPackageLibPath/b.dart', '''
var x;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;
import 'b.dart' as p;

void f() {
  p.x = 0;
//  ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  p.x += 1;
//  ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  ++p.x;
//    ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
  p.x++;
//  ^
// [diag.ambiguousImport] The name 'x' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');
  }
}
