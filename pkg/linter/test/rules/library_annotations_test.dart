// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAnnotationsTest);
  });
}

@reflectiveTest
class LibraryAnnotationsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.library_annotations;

  test_classDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
class C {}
''');
  }

  test_classTypeAliasDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
abstract class C = Object with M;

mixin M {}
''');
  }

  test_enumDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
enum E { one, two }
''');
  }

  test_exportDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
export 'dart:math';
''');
  }

  test_extensionDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
extension E on int {}
''');
  }

  test_functionDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
void f() {}
''');
  }

  test_functionDeclaration_annotationWithTargetKindLibrary() async {
    // In this library, `invalid_annotation_target` is reported (and
    // suppressed), so we do not also report `library_annotations`.
    await assertNoDiagnostics(r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class TestOn {
  const TestOn(String name);
}

// ignore: invalid_annotation_target
@TestOn('browser')
class C {}
''');
  }

  test_genericTypedefDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
typedef Fn = void Function();
''');
  }

  test_importDirective_annotationWithTargetKindLibrary() async {
    await assertDiagnosticsFromMarkup(r'''
[!@TestOn('browser')!]
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class TestOn {
  const TestOn(String name);
}

class C {}
''');
  }

  test_libraryDirective() async {
    await assertNoDiagnostics(r'''
@pragma('dart2js:late:trust')
library;

class C {}
''');
  }

  test_mixinDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
mixin M {}
''');
  }

  test_partFile() async {
    newFile('$testPackageRootPath/lib/part.dart', r'''
part of 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]

part 'part.dart';

class C {}
''');
  }

  test_partOfFile() async {
    newFile('$testPackageRootPath/test/part.dart', r'''
part 'test.dart';
''');

    await assertNoDiagnostics(r'''
@pragma('dart2js:late:trust')

part of 'part.dart';

class C {}
''');
  }

  test_partOfFile_annotatedPartOf() async {
    newFile('$testPackageRootPath/test/part.dart', r'''
part 'test.dart';
''');

    await assertNoDiagnostics(r'''
@pragma('dart2js:late:trust')
part of 'part.dart';

class C {}
''');
  }

  test_topLevelVariableDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
var i = 1;
''');
  }

  test_typedefDeclaration() async {
    await assertDiagnosticsFromMarkup(r'''
[!@pragma('dart2js:late:trust')!]
typedef void Fn();
''');
  }
}
