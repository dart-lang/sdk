// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_actions_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractMethodRefactorCodeActionsTest);
  });
}

@reflectiveTest
class ExtractMethodRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractMethodTitle = 'Extract Method';
  test_appliesCorrectEdits() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    const expectedContent = '''
main() {
  print('Test!');
  newMethod();
}

void newMethod() {
  print('Test!');
}
    ''';
    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
main() {}
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNull);
  }
}
