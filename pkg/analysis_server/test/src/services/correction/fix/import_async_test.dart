// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAsyncTest);
  });
}

@reflectiveTest
class ImportAsyncTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_ASYNC;

  Future<void> test_future() async {
    updateTestPubspecFile('''
environment:
  sdk: ^2.0.0
''');
    await resolveTestCode('''
Future<int> zero() async => 0;
''');
    await assertHasFix('''
import 'dart:async';

Future<int> zero() async => 0;
''');
  }

  Future<void> test_stream() async {
    updateTestPubspecFile('''
environment:
  sdk: ^2.0.0
''');
    await resolveTestCode('''
Stream<int> zero() => null;
''');
    await assertHasFix('''
import 'dart:async';

Stream<int> zero() => null;
''');
  }
}
