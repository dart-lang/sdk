// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalUriDoesNotExistTest);
  });
}

@reflectiveTest
class ConditionalUriDoesNotExistTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.conditional_uri_does_not_exist;

  test_inPartFile() async {
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnostics(
      r'''
part of 'a.dart';

import ''
    if (dart.library.io) 'dart:missing_1'
    if (dart.library.js_interop) 'dart:async'
    if (dart.library.async) 'dart:missing_2';
''',
      [
        // The imported library '' can't have a part-of directive,
        // but that's OK for the purposes of verifying the lint.
        error(diag.importOfNonLibrary, 26, 2),
        lint(54, 16),
        lint(145, 16),
      ],
    );
  }

  test_missingDartLibraries() async {
    await assertDiagnostics(
      r'''
// ignore: unused_import
import ''
    if (dart.library.io) 'dart:missing_1'
    if (dart.library.js_interop) 'dart:async'
    if (dart.library.async) 'dart:missing_2';
''',
      [
        lint(60, 16, messageContainsAll: ['dart:missing_1']),
        lint(151, 16, messageContainsAll: ['dart:missing_2']),
      ],
    );
  }

  test_missingFiles() async {
    newFile('$testPackageRootPath/lib/exists.dart', '');

    await assertDiagnostics(
      r'''
// ignore: unused_import
import ''
    if (dart.library.io) 'missing_1.dart'
    if (dart.library.js_interop) 'exists.dart'
    if (dart.library.async) 'missing_2.dart';
''',
      [
        lint(60, 16, messageContainsAll: ['missing_1.dart']),
        lint(152, 16, messageContainsAll: ['missing_2.dart']),
      ],
    );
  }

  test_missingPackages() async {
    await assertDiagnostics(
      r'''
// ignore: unused_import
import ''
    if (dart.library.io) 'package:meta/missing_1.dart'
    if (dart.library.js_interop) 'package:meta/meta.dart'
    if (dart.library.io) 'package:foo/missing_2.dart';
''',
      [
        lint(60, 29, messageContainsAll: ['missing_1.dart']),
        lint(173, 28, messageContainsAll: ['missing_2.dart']),
      ],
    );
  }

  test_withPartFile() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertDiagnostics(
      r'''
// ignore: unused_import
import ''
    if (dart.library.io) 'dart:missing_1'
    if (dart.library.js_interop) 'dart:async'
    if (dart.library.async) 'dart:missing_2';

part 'a.dart';
''',
      [lint(60, 16), lint(151, 16)],
    );
  }
}
