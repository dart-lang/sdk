// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToWhereTypeTest);
  });
}

@reflectiveTest
class ConvertToWhereTypeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_WHERE_TYPE;

  @override
  String get lintCode => LintNames.prefer_iterable_whereType;

  Future<void> test_default_declaredType() async {
    await resolveTestCode('''
Iterable<C> f(List<Object> list) {
  return list.where((e) => e is C);
}
class C {}
''');
    await assertHasFix('''
Iterable<C> f(List<Object> list) {
  return list.whereType<C>();
}
class C {}
''');
  }
}
