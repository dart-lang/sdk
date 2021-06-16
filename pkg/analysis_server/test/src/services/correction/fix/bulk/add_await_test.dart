// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAwaitTest);
  });
}

@reflectiveTest
class AddAwaitTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unawaited_futures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
Future doSomething() => new Future.value('');
Future doSomethingElse() => new Future.value('');

void main() async {
  doSomething();
  doSomethingElse();
}
''');
    await assertHasFix('''
Future doSomething() => new Future.value('');
Future doSomethingElse() => new Future.value('');

void main() async {
  await doSomething();
  await doSomethingElse();
}
''');
  }
}
