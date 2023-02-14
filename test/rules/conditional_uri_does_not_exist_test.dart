// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalUriDoesNotExistTest);
  });
}

@reflectiveTest
class ConditionalUriDoesNotExistTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'conditional_uri_does_not_exist';

  test_missingDartLibraries() async {
    await assertDiagnostics(
      r'''
import ''
    if (dart.library.io) 'dart:missing_1'
    if (dart.library.html) 'dart:async'
    if (dart.library.async) 'dart:missing_2';
''',
      [
        error(WarningCode.UNUSED_IMPORT, 7, 2),
        lint(35, 16, messageContains: 'dart:missing_1'),
        lint(120, 16, messageContains: 'dart:missing_2'),
      ],
    );
  }

  test_missingFiles() async {
    newFile2('$testPackageRootPath/lib/exists.dart', '');

    await assertDiagnostics(
      r'''
import ''
    if (dart.library.io) 'missing_1.dart'
    if (dart.library.html) 'exists.dart'
    if (dart.library.async) 'missing_2.dart';
''',
      [
        error(WarningCode.UNUSED_IMPORT, 7, 2),
        lint(35, 16, messageContains: 'missing_1.dart'),
        lint(121, 16, messageContains: 'missing_2.dart'),
      ],
    );
  }

  test_missingPackages() async {
    await assertDiagnostics(
      r'''
import ''
    if (dart.library.io) 'package:meta/missing_1.dart'
    if (dart.library.html) 'package:meta/meta.dart'
    if (dart.library.io) 'package:foo/missing_2.dart';
''',
      [
        error(WarningCode.UNUSED_IMPORT, 7, 2),
        lint(35, 29, messageContains: 'missing_1.dart'),
        lint(142, 28, messageContains: 'missing_2.dart'),
      ],
    );
  }
}
