// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceNullCheckWithCastBulkTest);
    defineReflectiveTests(ReplaceNullCheckWithCastTest);
  });
}

@reflectiveTest
class ReplaceNullCheckWithCastBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.null_check_on_nullable_type_parameter;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
T f<T>(T? result) {
  if (1==1) {
    return result!;
  } else {
    return result!;
  }
}
''');
    await assertHasFix('''
T f<T>(T? result) {
  if (1==1) {
    return result as T;
  } else {
    return result as T;
  }
}
''');
  }
}

@reflectiveTest
class ReplaceNullCheckWithCastTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_NULL_CHECK_WITH_CAST;

  @override
  String get lintCode => LintNames.null_check_on_nullable_type_parameter;

  Future<void> test_simpleIdentifier() async {
    await resolveTestCode('''
T run<T>(T? result) {
  return result!;
}
''');
    await assertHasFix('''
T run<T>(T? result) {
  return result as T;
}
''');
  }
}
