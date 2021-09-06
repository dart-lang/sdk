// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SurroundWithTryCatchTest);
  });
}

@reflectiveTest
class SurroundWithTryCatchTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SURROUND_WITH_TRY_CATCH;

  Future<void> test_twoStatements() async {
    await resolveTestCode('''
main() {
// start
  print(0);
  print(1);
// end
}
''');
    await assertHasAssist('''
main() {
  try {
    print(0);
    print(1);
  } on Exception catch (e) {
    // TODO
  }
}
''');
    assertLinkedGroup(0, ['Exception']);
    assertLinkedGroup(1, ['e) {']);
    assertLinkedGroup(2, ['// TODO']);
    assertExitPosition(after: '// TODO');
  }
}
