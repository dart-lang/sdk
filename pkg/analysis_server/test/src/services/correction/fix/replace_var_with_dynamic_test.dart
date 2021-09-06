// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceVarWithDynamicTest);
  });
}

@reflectiveTest
class ReplaceVarWithDynamicTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_VAR_WITH_DYNAMIC;

  Future<void> test_simple() async {
    await resolveTestCode('''
class A {
  Map<String, var> m;
}
''');
    await assertHasFix('''
class A {
  Map<String, dynamic> m;
}
''', errorFilter: (error) {
      return error.errorCode == ParserErrorCode.VAR_AS_TYPE_NAME;
    });
  }
}
