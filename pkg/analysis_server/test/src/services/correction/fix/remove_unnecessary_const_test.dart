// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryConstBulkTest);
    defineReflectiveTests(RemoveUnnecessaryConstTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryConstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_const;

  Future<void> test_singleFile() async {
    await parseTestCode('''
class C { const C(); }
class D { const D(C c); }
const c = const C();
const list = const [];
var d = const D(const C());
''');
    await assertHasFix('''
class C { const C(); }
class D { const D(C c); }
const c = C();
const list = [];
var d = const D(C());
''', isParse: true);
  }
}

@reflectiveTest
class RemoveUnnecessaryConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_CONST;

  @override
  String get lintCode => LintNames.unnecessary_const;

  Future<void> test_instanceCreation() async {
    await resolveTestCode('''
class C { const C(); }
const c = const C();
''');
    await assertHasFix('''
class C { const C(); }
const c = C();
''');
  }

  Future<void> test_typedLiteral() async {
    await resolveTestCode('''
const list = const [];
''');
    await assertHasFix('''
const list = [];
''');
  }
}
