// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAnnotationsTest);
  });
}

@reflectiveTest
class LibraryAnnotationsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'library_annotations';

  test_classDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
class C {}
''',
      [lint(0, 29)],
    );
  }

  test_classTypeAliasDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
abstract class C = Object with M;

mixin M {}
''',
      [lint(0, 29)],
    );
  }

  test_enumDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
enum E { one, two }
''',
      [lint(0, 29)],
    );
  }

  test_exportDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
export 'dart:math';
''',
      [lint(0, 29)],
    );
  }

  test_extensionDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
extension E on int {}
''',
      [lint(0, 29)],
    );
  }

  test_functionDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
void f() {}
''',
      [lint(0, 29)],
    );
  }

  test_functionDeclaration_annotationWithTargetKindLibrary() async {
    // In this library, `invalid_annotation_target` is reported (and
    // suppressed), so we do not also report `library_annotations`.
    await assertNoDiagnostics(
      r'''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class TestOn {
  const TestOn(String name);
}

// ignore: invalid_annotation_target
@TestOn('browser')
class C {}
''',
    );
  }

  test_genericTypedefDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
typedef Fn = void Function();
''',
      [lint(0, 29)],
    );
  }

  test_importDirective_annotationWithTargetKindLibrary() async {
    await assertDiagnostics(
      r'''
@TestOn('browser')
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class TestOn {
  const TestOn(String name);
}

class C {}
''',
      [lint(0, 18)],
    );
  }

  test_mixinDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
mixin M {}
''',
      [lint(0, 29)],
    );
  }

  test_topLevelVariableDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
var i = 1;
''',
      [lint(0, 29)],
    );
  }

  test_typedefDeclaration() async {
    await assertDiagnostics(
      r'''
@pragma('dart2js:late:trust')
typedef void Fn();
''',
      [lint(0, 29)],
    );
  }
}
