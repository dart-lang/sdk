// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToMapLiteralTest);
  });
}

@reflectiveTest
class ConvertToMapLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToMapLiteral;

  Future<void> test_default_declaredType() async {
    await resolveTestCode('''
Map m = Ma^p();
''');
    await assertHasAssist('''
Map m = {};
''');
  }

  Future<void> test_default_linkedHashMap() async {
    await resolveTestCode('''
import 'dart:collection';
var m = LinkedHashMa^p();
''');
    await assertHasAssist('''
import 'dart:collection';
var m = {};
''');
  }

  Future<void> test_default_minimal() async {
    await resolveTestCode('''
var m = Ma^p();
''');
    await assertHasAssist('''
var m = {};
''');
  }

  Future<void> test_default_newKeyword() async {
    await resolveTestCode('''
var m = new Ma^p();
''');
    await assertHasAssist('''
var m = {};
''');
  }

  Future<void> test_default_typeArg() async {
    await resolveTestCode('''
var m = Ma^p<String, int>();
''');
    await assertHasAssist('''
var m = <String, int>{};
''');
  }
}
