// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules/directives_ordering.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rule_test_support.dart';

// ignore_for_file: non_constant_identifier_names
void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectivesOrderingTest);
  });

  group('compareDirectives', () {
    void checkSection(List<String> correctlyOrderedImports) {
      for (int i = 0; i < correctlyOrderedImports.length; i++) {
        var a = correctlyOrderedImports[i];
        expect(compareDirectives(a, a), 0,
            reason: '"$a" sorts the same as itself');

        for (int j = i + 1; j < correctlyOrderedImports.length; j++) {
          var b = correctlyOrderedImports[j];
          expect(compareDirectives(a, b), lessThan(0),
              reason: '"$a" sorts before "$b"');
          expect(compareDirectives(b, a), greaterThan(0),
              reason: '"$b" sorts after "$a"');
        }
      }
    }

    test('dart: imports', () {
      checkSection(const [
        'dart:aaa',
        'dart:bbb',
      ]);
    });

    test('package: imports', () {
      checkSection(const [
        'package:aa/bb.dart',
        'package:aaa/aaa.dart',
        'package:aaa/ccc.dart',
        'package:bbb/bbb.dart',
      ]);
    });

    test('relative imports', () {
      checkSection(const [
        '/foo5.dart',
        '../../foo4.dart',
        '../foo2/a.dart',
        '../foo3.dart',
        './foo2.dart',
        'a.dart',
        'aaa/aaa.dart',
        'bbb/bbb.dart',
        'foo1.dart',
      ]);
    });
  });
}

@reflectiveTest
class DirectivesOrderingTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.directives_ordering;

  test_partOrder_sorted() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    await assertNoDiagnostics(r'''
part 'a.dart';
part 'b.dart';
''');
  }

  test_partOrder_unsorted() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');
    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    // Because parts can contain augmentations, whose order of
    // application matters, we do *not* want to enforce part sorting.
    // See: https://github.com/dart-lang/linter/issues/4945
    await assertNoDiagnostics(r'''
part 'b.dart';
part 'a.dart';
''');
  }
}
