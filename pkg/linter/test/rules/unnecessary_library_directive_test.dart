// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryLibraryDirective);
  });
}

@reflectiveTest
class UnnecessaryLibraryDirective extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_library_directive';

  test_hasAnnotation() async {
    await assertNoDiagnostics(r'''
@C()
library with_annotation;

class C {
  const C();
}
''');
  }

  test_hasDocComment() async {
    await assertNoDiagnostics(r'''
/// This is a nice library.
library with_comment;
''');
  }

  test_hasPart() async {
    newFile2('$testPackageLibPath/part.dart', '''
part of 'test.dart';
''');
    // Parts may still use library names to reference what they are a 'part of'.
    // We don't lint those libraries, even though using library names in
    // 'part of' is discouraged.
    await assertNoDiagnostics(r'''
library lib;

part 'part.dart';
''');
  }

  test_unnecessary() async {
    await assertDiagnostics(r'''
library lib;
''', [
      lint(0, 12),
    ]);
  }
}
