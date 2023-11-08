// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
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
    if (!AnalysisServer.supportsPlugins) return;
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      TextDocumentContentChangeEvent.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 9)),
        text: 'Bar',
      )),
      TextDocumentContentChangeEvent.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 1, character: 21),
            end: Position(line: 1, character: 24)),
        text: 'updated',
      )),
    ]);

    final notifiedChanges = pluginManager.analysisUpdateContentParams!
        .files[mainFilePath] as ChangeContentOverlay;

    expect(
      applySequenceOfEdits(content, notifiedChanges.edits),
      contentAfterUpdate,
    );
  }

  Future<void> test_documentChange_updatesOverlay() async {
    await _initializeAndOpen();
    await changeFile(2, mainFileUri, [
      TextDocumentContentChangeEvent.t1(TextDocumentContentChangeEvent1(
        range: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 9)),
        text: 'Bar',
      )),
      TextDocumentContentChangeEvent.t1(TextDocumentContentChangeEvent1(
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
    if (!AnalysisServer.supportsPlugins) return;
    await _initializeAndOpen();
    await closeFile(mainFileUri);

    expect(pluginManager.analysisUpdateContentParams!.files,
        equals({mainFilePath: RemoveContentOverlay()}));
  }

  Future<void>
      test_documentOpen_addsOverlayOnlyToDriver_onlyIfInsideRoots() async {
    // Ensures that opening a file doesn't add it to the driver if it's outside
    // of the drivers root.
    final fileInsideRootPath = mainFilePath;
    final fileOutsideRootPath = convertPath('/home/unrelated/main.dart');
    await initialize();
    await openFile(pathContext.toUri(fileInsideRootPath), content);
    await openFile(pathContext.toUri(fileOutsideRootPath), content);

    // Expect both files return the same driver
    final driverForInside = server.getAnalysisDriver(fileInsideRootPath)!;
    final driverForOutside = server.getAnalysisDriver(fileOutsideRootPath)!;
    expect(driverForInside, equals(driverForOutside));
    // But that only the file inside the root was added.
    expect(driverForInside.addedFiles, contains(fileInsideRootPath));
    expect(driverForInside.addedFiles, isNot(contains(fileOutsideRootPath)));
  }

  Future<void> test_documentOpen_contentChanged_analysis() async {
    const content = '// original content';
    const newContent = '// new content';
    newFile(mainFilePath, content);

    // Wait for initial analysis to provide diagnostics for the file.
    await Future.wait([
      waitForDiagnostics(mainFileUri),
      initialize(),
    ]);

    // Capture any further diagnostics sent after we open the file.
    List<Diagnostic>? diagnostics;
    unawaited(waitForDiagnostics(mainFileUri).then((d) => diagnostics = d));
    await openFile(mainFileUri, newContent);
    await pumpEventQueue(times: 5000);

    // Expect diagnostics, because changing the content will have triggered
    // analysis.
    expect(diagnostics, isNotNull);
  }

  Future<void> test_documentOpen_contentUnchanged_noAnalysis() async {
    const content = '// original content';
    newFile(mainFilePath, content);

    // Wait for initial analysis to provide diagnostics for the file.
    await Future.wait([
      waitForDiagnostics(mainFileUri),
      initialize(),
    ]);

    // Capture any further diagnostics sent after we open the file.
    List<Diagnostic>? diagnostics;
    unawaited(waitForDiagnostics(mainFileUri).then((d) => diagnostics = d));
    await openFile(mainFileUri, content);
    await pumpEventQueue(times: 5000);

    // Expect no diagnostics because the file didn't actually change content
    // when the overlay was created, so it should not have triggered analysis.
    expect(diagnostics, isNull);
  }

  Future<void> test_documentOpen_createsOverlay() async {
    await _initializeAndOpen();

    expect(server.resourceProvider.hasOverlay(mainFilePath), isTrue);
    expect(server.resourceProvider.getFile(mainFilePath).readAsStringSync(),
        equals(content));
  }

  /// Tests that deleting a file does not clear diagnostics while there's an
  /// overlay, and that removing the overlay later clears the diagnostics.
  ///
  /// https://github.com/dart-lang/sdk/issues/53475
  Future<void> test_documentOpen_fileDeleted_documentClosed() async {
    const content = 'error';
    newFile(mainFilePath, content);

    // Track the latest diagnostics as the client would.
    Map<String, List<Diagnostic>> latestDiagnostics = {};
    trackDiagnostics(latestDiagnostics);

    // Expect diagnostics after initial analysis because file has invalid
    // content.
    await initialize();
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics after opening the file with the same contents.
    await openFile(mainFileUri, content);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics after deleting the file because the overlay is still
    // active.
    deleteFile(mainFilePath);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics to be removed after we close the file (which removes
    // the overlay).
    await closeFile(mainFileUri);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isEmpty);
  }

  /// Tests that deleting and re-creating a file while an overlay is active
  /// keeps the diagnotics when the overlay is then removed, then removes them
  /// when the file is deleted.
  ///
  /// https://github.com/dart-lang/sdk/issues/53475
  Future<void>
      test_documentOpen_fileDeleted_fileCreated_documentClosed_fileDeleted() async {
    const content = 'error';
    newFile(mainFilePath, content);

    // Track the latest diagnostics as the client would.
    Map<String, List<Diagnostic>> latestDiagnostics = {};
    trackDiagnostics(latestDiagnostics);

    // Expect diagnostics after initial analysis because file has invalid
    // content.
    await initialize();
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics after opening the file with the same contents.
    await openFile(mainFileUri, content);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics after deleting the file because the overlay is still
    // active.
    deleteFile(mainFilePath);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics remain after re-creating the file (the overlay is still
    // active).
    newFile(mainFilePath, content);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Expect diagnostics remain after we close the file because the file still
    //exists on disk.
    await closeFile(mainFileUri);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isNotEmpty);

    // Finally, expect deleteing the file clears the diagnostics.
    deleteFile(mainFilePath);
    await pumpEventQueue(times: 5000);
    expect(latestDiagnostics[mainFilePath], isEmpty);
  }

  Future<void> test_documentOpen_notifiesPlugins() async {
    if (!AnalysisServer.supportsPlugins) return;
    await _initializeAndOpen();

    expect(pluginManager.analysisUpdateContentParams!.files,
        equals({mainFilePath: AddContentOverlay(content)}));
  }

  /// Verifies the fix for a race condition where an overlay would not be
  /// processed if the file was created on disk before the overlay was processed
  /// (but the watch event had also not yet been processed).
  ///
  /// https://github.com/dart-lang/sdk/issues/51159
  Future<void> test_documentOpen_processesOverlay_dartSdk_issue51159() async {
    final binFolder = convertPath(join(projectFolderPath, 'bin'));
    final binMainFilePath = convertPath(join(binFolder, 'main.dart'));
    final fooFilePath = convertPath(join(binFolder, 'foo.dart'));
    final fooUri = pathContext.toUri(fooFilePath);

    const binMainContent = '''
import 'foo.dart';

Foo? f;
''';
    const fooContent = '''
class Foo {}
''';

    newFolder(binFolder);
    newFile(binMainFilePath, binMainContent);

    // Track the latest diagnostics we've had for all files.
    Map<String, List<Diagnostic>> diagnostics = {};
    trackDiagnostics(diagnostics);

    // Initialize the server and wait for initial analysis to complete.
    await Future.wait([
      waitForAnalysisComplete(),
      initialize(),
    ]);

    // Expect diagnostics because 'foo.dart' doesn't exist.
    expect(diagnostics[binMainFilePath], isNotEmpty);

    // Create the file and _immediately_ open it, so the file exists when the
    // overlay is created, even though the watcher event has not been processed.
    newFile(fooFilePath, fooContent);
    await Future.wait([
      openFile(fooUri, fooContent),
      waitForAnalysisComplete(),
    ]);

    // Expect the diagnostics have gone.
    expect(diagnostics[binMainFilePath], isEmpty);
  }

  Future<void> test_documentOpen_setsPriorityFileIfEarly() async {
    setConfigurationSupport();

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
    final initResponse = initialize();

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
    expect(server.getAnalysisDriver(mainFilePath)!.priorityFiles,
        equals([mainFilePath]));
  }

  Future<void> _initializeAndOpen() async {
    await initialize();
    await openFile(mainFileUri, content);
  }
}
