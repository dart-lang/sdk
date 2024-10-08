// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/implementation_imports.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  group('uris', () {
    group('isPackage', () {
      for (var uri in [
        Uri.parse('package:foo/src/bar.dart'),
        Uri.parse('package:foo/src/baz/bar.dart')
      ]) {
        test(uri.toString(), () {
          expect(isPackage(uri), isTrue);
        });
      }
      for (var uri in [
        Uri.parse('foo/bar.dart'),
        Uri.parse('src/bar.dart'),
        Uri.parse('dart:async')
      ]) {
        test(uri.toString(), () {
          expect(isPackage(uri), isFalse);
        });
      }
    });

    group('samePackage', () {
      test('identity', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/src/bar.dart')),
            isTrue);
      });
      test('foo/bar.dart', () {
        expect(
            samePackage(Uri.parse('package:foo/src/bar.dart'),
                Uri.parse('package:foo/bar.dart')),
            isTrue);
      });
    });
  });

  group('implementation', () {
    for (var uri in [
      Uri.parse('package:foo/src/bar.dart'),
      Uri.parse('package:foo/src/baz/bar.dart')
    ]) {
      test(uri.toString(), () {
        expect(isImplementation(uri), isTrue);
      });
    }
    for (var uri in [
      Uri.parse('package:foo/bar.dart'),
      Uri.parse('src/bar.dart')
    ]) {
      test(uri.toString(), () {
        expect(isImplementation(uri), isFalse);
      });
    }
  });

  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementationImportsTest);
  });
}

@reflectiveTest
class ImplementationImportsTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => LintNames.implementation_imports;
  test_inPartFile() async {
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnostics(r'''
part of 'a.dart';

import 'package:flutter/src/material/colors.dart';
''', [
      error(WarningCode.UNUSED_IMPORT, 26, 42),
      lint(26, 42),
    ]);
  }
}
