// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSpreadTest);
  });
}

@reflectiveTest
class ConvertToSpreadTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SPREAD;

  void setUp() {
    createAnalysisOptionsFile(experiments: [EnableString.spread_collections]);
    super.setUp();
  }

  test_addAll_expression() async {
    await resolveTestUnit('''
f() {
  var ints = [1, 2, 3];
  print(['a']..addAl/*caret*/l(ints.map((i) => i.toString()))..addAll(['c']));
}
''');
    await assertHasAssist('''
f() {
  var ints = [1, 2, 3];
  print(['a', ...ints.map((i) => i.toString())]..addAll(['c']));
}
''');
  }

  test_addAll_literal() async {
    await resolveTestUnit('''
var l = ['a']..add/*caret*/All(['b'])..addAll(['c']);
''');
    await assertHasAssist('''
var l = ['a', ...['b']]..addAll(['c']);
''');
  }

  test_addAll_notFirst() async {
    await resolveTestUnit('''
var l = ['a']..addAll(['b'])../*caret*/addAll(['c']);
''');
    await assertNoAssist();
  }
}
