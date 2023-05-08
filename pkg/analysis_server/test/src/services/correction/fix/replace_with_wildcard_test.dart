// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithWildcardBulkTest);
    defineReflectiveTests(ReplaceWithWildcardTest);
  });
}

@reflectiveTest
class ReplaceWithWildcardBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
int f1(Object? x) {
  return switch (x) {
    0 => 0,
    default => 1,
  };
}

int f2(Object? x) {
  return switch (x) {
    0 => 0,
    default => 1,
  };
}
''');
    await assertHasFix('''
int f1(Object? x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}

int f2(Object? x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
  }
}

@reflectiveTest
class ReplaceWithWildcardTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_WILDCARD;

  Future<void> test_it() async {
    await resolveTestCode('''
int f(Object? x) {
  return switch (x) {
    0 => 0,
    default => 1,
  };
}
''');
    await assertHasFix('''
int f(Object? x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
  }
}
