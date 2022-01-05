// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceReturnTypeStreamTest);
  });
}

@reflectiveTest
class ReplaceReturnTypeStreamTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE_STREAM;

  Future<void> test_complexTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
List<int> f() async* {}
''');
    await assertHasFix('''
import 'dart:async';
Stream<List<int>> f() async* {}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE;
    });
  }

  Future<void> test_complexTypeName_withoutImport() async {
    await resolveTestCode('''
List<int> f() async* {}
''');
    await assertHasFix('''
Stream<List<int>> f() async* {}
''');
  }

  Future<void> test_importedWithPrefix() async {
    await resolveTestCode('''
import 'dart:async' as al;
int f() async* {}
''');
    await assertHasFix('''
import 'dart:async' as al;
al.Stream<int> f() async* {}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE;
    });
  }

  Future<void> test_simpleTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
int f() async* {}
''');
    await assertHasFix('''
import 'dart:async';
Stream<int> f() async* {}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE;
    });
  }

  Future<void> test_simpleTypeName_withoutImport() async {
    await resolveTestCode('''
int f() async* {}
''');
    await assertHasFix('''
Stream<int> f() async* {}
''');
  }
}
