// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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

  /// A stream of strings (CREATE, BEGIN, END) corresponding to progress requests
  /// and notifications for convenience in testing.
  Stream<String> get progressUpdates {
    final controller = StreamController<String>();

    requestsFromServer
        .where((r) => r.method == Method.window_workDoneProgress_create)
        .listen((request) async {
      controller.add('CREATE');
    }, onDone: controller.close);
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .listen((notification) {
      final params = ProgressParams.fromJson(notification.params);
      if (WorkDoneProgressBegin.canParse(params.value, nullLspJsonReporter)) {
        controller.add('BEGIN');
      } else if (WorkDoneProgressEnd.canParse(
          params.value, nullLspJsonReporter)) {
        controller.add('END');
      }
    });

    return controller.stream;
  }

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

  Future<void> test_contentModified() async {
    const content = '''
main() {
  print('Test!');
  [[print('Test!');]]
}
    ''';
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    expect(codeAction, isNotNull);

    // Send an edit request immediately after the refactor request.
    final req1 = executeCodeAction(codeAction);
    await replaceFile(100, mainFileUri, 'new test content');

    // Expect the first to fail because of the modified content.
    await expectLater(
        req1, throwsA(isResponseError(ErrorCodes.ContentModified)));
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

  Future<void> test_progress_clientProvided() async {
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
    await initialize(
        windowCapabilities:
            withWorkDoneProgressSupport(emptyWindowClientCapabilities));

    // Expect begin/end progress updates without a create, since the
    // token was supplied by us (the client).
    expect(progressUpdates, emitsInOrder(['BEGIN', 'END']));

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent,
        workDoneToken: clientProvidedTestWorkDoneToken);
  }

  Future<void> test_progress_notSupported() async {
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

    var didGetProgressNotifications = false;
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .listen((_) => didGetProgressNotifications = true);

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);

    expect(didGetProgressNotifications, isFalse);
  }

  Future<void> test_progress_serverGenerated() async {
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
    await initialize(
        windowCapabilities:
            withWorkDoneProgressSupport(emptyWindowClientCapabilities));

    // Capture progress-related messages in a list in the order they arrive.
    final progressRequests = <String>[];
    requestsFromServer
        .where((r) => r.method == Method.window_workDoneProgress_create)
        .listen((request) async {
      progressRequests.add('CREATE');
    });
    notificationsFromServer
        .where((n) => n.method == Method.progress)
        .listen((notification) {
      final params = ProgressParams.fromJson(notification.params);
      if (WorkDoneProgressBegin.canParse(params.value, nullLspJsonReporter)) {
        progressRequests.add('BEGIN');
      } else if (WorkDoneProgressEnd.canParse(
          params.value, nullLspJsonReporter)) {
        progressRequests.add('END');
      }
    });

    final codeActions = await getCodeActions(mainFileUri.toString(),
        range: rangeFromMarkers(content));
    final codeAction =
        findCommand(codeActions, Commands.performRefactor, extractMethodTitle);
    await verifyCodeActionEdits(
        codeAction, withoutMarkers(content), expectedContent);

    // Ensure the progress messages came through and in the correct order.
    expect(progressRequests, equals(['CREATE', 'BEGIN', 'END']));
  }
}

@reflectiveTest
class ExtractWidgetRefactorCodeActionsTest extends AbstractCodeActionsTest {
  final extractWidgetTitle = 'Extract Widget';

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(
      projectFolderPath,
      flutter: true,
    );
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
