// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAddShowTest);
  });
}

@reflectiveTest
class ImportAddShowTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.IMPORT_ADD_SHOW;

  test_hasShow() async {
    await resolveTestUnit('''
import 'dart:math' show PI;
main() {
  PI;
}
''');
    await assertNoAssistAt('import ');
  }

  test_hasUnresolvedIdentifier() async {
    await resolveTestUnit('''
import 'dart:math';
main(x) {
  PI;
  return x.foo();
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show PI;
main(x) {
  PI;
  return x.foo();
}
''');
  }

  test_onDirective() async {
    await resolveTestUnit('''
import 'dart:math';
main() {
  PI;
  E;
  max(1, 2);
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show E, PI, max;
main() {
  PI;
  E;
  max(1, 2);
}
''');
  }

  test_onUri() async {
    await resolveTestUnit('''
import 'dart:math';
main() {
  PI;
  E;
  max(1, 2);
}
''');
    await assertHasAssistAt('art:math', '''
import 'dart:math' show E, PI, max;
main() {
  PI;
  E;
  max(1, 2);
}
''');
  }

  test_unresolvedUri() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
import '/no/such/lib.dart';
''');
    await assertNoAssistAt('import ');
  }

  test_unused() async {
    await resolveTestUnit('''
import 'dart:math';
''');
    await assertNoAssistAt('import ');
  }
}
