// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithNamedConstantTest);
  });
}

@reflectiveTest
class ReplaceWithNamedConstantTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.USE_NAMED_CONSTANTS;

  @override
  String get lintCode => LintNames.use_named_constants;

  Future<void> test_use_named_constant() async {
    await resolveTestCode('''
final value = const C(0);

class C {
  static const C zero = C(0);
  final int f;
  const C(this.f);
}
''');

    await assertHasFix('''
final value = C.zero;

class C {
  static const C zero = C(0);
  final int f;
  const C(this.f);
}
''');
  }
}
