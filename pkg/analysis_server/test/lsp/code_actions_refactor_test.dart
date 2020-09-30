// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/utilities/mock_packages.dart';
import '../tool/lsp_spec/matchers.dart';
import 'code_actions_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractMethodRefactorCodeActionsTest);
    defineReflectiveTests(ExtractWidgetRefactorCodeActionsTest);
  });
}

@reflectiveTest
class ExtractMethodRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractMethodTitle = 'Extract Method';
  Future<void> test_appliesCorrectEdits() async {
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
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_cancelsInProgress() async {
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
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNotNull);

    // Respond to any applyEdit requests from the server with successful responses
    // and capturing the last edit.
    WorkspaceEdit edit;
    requestsFromServer.listen((request) async {
      if (request.method == Method.workspace_applyEdit) {
        final params = ApplyWorkspaceEditParams.fromJson(request.params);
        edit = params.edit;
        respondTo(request, ApplyWorkspaceEditResponse(applied: true));
      }
    });

    // Send two requests together.
    final req1 = executeCodeAction(codeAction);
    final req2 = executeCodeAction(codeAction);

    // Expect the first will have cancelled the second.
    await expectLater(
        req1, throwsA(isResponseError(ErrorCodes.RequestCancelled)));
    await req2;

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, edit.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
main() {}
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNull);
  }
}

@reflectiveTest
class ExtractWidgetRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractWidgetTitle = 'Extract Widget';

  @override
  void setUp() {
    super.setUp();

    final flutterLibFolder = MockPackages.instance.addFlutter(resourceProvider);
    final metaLibFolder = MockPackages.instance.addMeta(resourceProvider);
    // Create .packages in the project.
    newFile(join(projectFolderPath, '.packages'), content: '''
flutter:${flutterLibFolder.toUri()}
meta:${metaLibFolder.toUri()}
''');
  }

  Future<void> test_appliesCorrectEdits() async {
    const content = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new [[Column]](
          children: <Widget>[
            new Text('AAA'),
            new Text('BBB'),
          ],
        ),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}
    ''';
    const expectedContent = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        NewWidget(),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Text('AAA'),
        new Text('BBB'),
      ],
    );
  }
}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractWidgetTitle);
    expect(codeAction, isNotNull);

    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);
  }

  Future<void> test_invalidLocation() async {
    const content = '''
import 'dart:convert';
^
main() {}
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final codeActions = await getCodeActions(mainFileUri.toString());
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractWidgetTitle);
    expect(codeAction, isNull);
  }
}
