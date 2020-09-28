// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Position;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentChangesTest);
  });
}

@reflectiveTest
class DocumentChangesTest extends AbstractLspAnalysisServerTest {
  String get content => '''
class Foo {
  String get bar => 'baz';
}
''';

  String get contentAfterUpdate => '''
class Bar {
  String get bar => 'updated';
}
''';

  Future<void> test_documentChange_notifiesPlugins() async {
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      Either2<TextDocumentContentChangeEvent1,
          TextDocumentContentChangeEvent2>.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 9)),
        text: 'Bar',
      )),
      Either2<TextDocumentContentChangeEvent1,
          TextDocumentContentChangeEvent2>.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 1, character: 21),
            end: Position(line: 1, character: 24)),
        text: 'updated',
      )),
    ]);

    final notifiedChanges = pluginManager.analysisUpdateContentParams
        .files[mainFilePath] as ChangeContentOverlay;

    expect(
      applySequenceOfEdits(content, notifiedChanges.edits),
      contentAfterUpdate,
    );
  }

  Future<void> test_documentChange_updatesOverlay() async {
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      Either2<TextDocumentContentChangeEvent1,
          TextDocumentContentChangeEvent2>.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 9)),
        text: 'Bar',
      )),
      Either2<TextDocumentContentChangeEvent1,
          TextDocumentContentChangeEvent2>.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 1, character: 21),
            end: Position(line: 1, character: 24)),
        text: 'updated',
      )),
    ]);

    expect(server.resourceProvider.hasOverlay(mainFilePath), isTrue);
    expect(server.resourceProvider.getFile(mainFilePath).readAsStringSync(),
        equals(contentAfterUpdate));
  }

  Future<void> test_documentClose_deletesOverlay() async {
    await _initializeAndOpen();
    await closeFile(mainFileUri);

    expect(server.resourceProvider.hasOverlay(mainFilePath), isFalse);
  }

  Future<void> test_documentClose_notifiesPlugins() async {
    await _initializeAndOpen();
    await closeFile(mainFileUri);

    expect(pluginManager.analysisUpdateContentParams.files,
        equals({mainFilePath: RemoveContentOverlay()}));
  }

  Future<void> test_documentOpen_createsOverlay() async {
    await _initializeAndOpen();

    expect(server.resourceProvider.hasOverlay(mainFilePath), isTrue);
    expect(server.resourceProvider.getFile(mainFilePath).readAsStringSync(),
        equals(content));
  }

  Future<void> test_documentOpen_notifiesPlugins() async {
    await _initializeAndOpen();

    expect(pluginManager.analysisUpdateContentParams.files,
        equals({mainFilePath: AddContentOverlay(content)}));
  }

  Future<void> test_documentOpen_setsPriorityFileIfEarly() async {
    // When initializing with config support, the server will call back to the client
    // which can delay analysis roots being configured. This can result in files
    // being opened before analysis roots are set which has previously caused the
    // files not to be marked as priority on the created drivers.
    // https://github.com/Dart-Code/Dart-Code/issues/2438
    // https://github.com/dart-lang/sdk/issues/42994

    // Initialize the server, but delay providing the configuration until after
    // we've opened the file.
    final completer = Completer<void>();

    // Send the initialize request but do not await it.
    final initResponse = initialize(
        workspaceCapabilities: withDidChangeConfigurationDynamicRegistration(
            withConfigurationSupport(emptyWorkspaceClientCapabilities)));

    // When asked for config, delay the response until we have sent the openFile notification.
    final config = provideConfig(
      () => initResponse,
      completer.future.then((_) => {'dart.foo': false}),
    );

    // Wait for initialization to finish, open the file, then allow config to complete.
    await initResponse;
    await openFile(mainFileUri, content);
    completer.complete();
    await config;
    await pumpEventQueue(times: 5000);

    // Ensure the opened file is in the priority list.
    expect(server.getAnalysisDriver(mainFilePath).priorityFiles,
        equals([mainFilePath]));
  }

  Future<void> _initializeAndOpen() async {
    await initialize();
    await openFile(mainFileUri, content);
  }
}
