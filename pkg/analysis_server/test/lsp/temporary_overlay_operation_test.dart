// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TemporaryOverlayOperationTest);
  });
}

@reflectiveTest
class TemporaryOverlayOperationTest extends AbstractLspAnalysisServerTest {
  void expectFsStateContent(String path, String expected) {
    var driver = server.getAnalysisDriver(path)!;
    var actual = driver.fsState.getFileForPath(path).content;
    expect(actual, expected);
  }

  void expectOverlayContent(String path, String expected) {
    expect(server.resourceProvider.hasOverlay(path), isTrue);
    var actual = server.resourceProvider.getFile(path).readAsStringSync();
    expect(actual, expected);
  }

  Future<void> test_noIntermediateAnalysisResults() async {
    newFile(mainFilePath, '');
    await initialize();
    await initialAnalysis;

    // Modify the overlays to have invalid code, which will then be reverted.
    // At no point should diagnostics or closing labels be transmitted for the
    // intermediate invalid code.
    await _TestTemporaryOverlayOperation(server, () async {
      server.onOverlayCreated(mainFilePath, 'INVALID1');
      server.onOverlayUpdated(mainFilePath, [], newContent: 'INVALID2');
    }).doWork();

    await pumpEventQueue(times: 5000);
    expect(diagnostics[mainFileUri], isNull);
  }

  Future<void> test_pausesRequestQueue() async {
    await initialize();
    await initialAnalysis;
    await openFile(mainFileUri, '// ORIGINAL');

    await _TestTemporaryOverlayOperation(server, () async {
      // Simulate changes from the client.
      await replaceFile(2, mainFileUri, '// CHANGED');

      // Ensure we still have the original content.
      await pumpEventQueue(times: 5000);
      expectFsStateContent(mainFilePath, '// ORIGINAL');
      expectOverlayContent(mainFilePath, '// ORIGINAL');
    }).doWork();

    // Ensure we processed the update afterwards.
    await pumpEventQueue(times: 5000);
    expectFsStateContent(mainFilePath, '// CHANGED');
    expectOverlayContent(mainFilePath, '// CHANGED');
  }

  Future<void> test_pausesWatcherEvents() async {
    newFile(mainFilePath, '// ORIGINAL');
    await initialize();
    await initialAnalysis;

    await _TestTemporaryOverlayOperation(server, () async {
      // Modify the file to trigger watcher events
      modifyFile(mainFilePath, '// CHANGED');

      // Ensure we still have the original content.
      await pumpEventQueue(times: 5000);
      expectFsStateContent(mainFilePath, '// ORIGINAL');
    }).doWork();

    // Ensure we processed the update afterwards.
    await pumpEventQueue(times: 5000);
    expectFsStateContent(mainFilePath, '// CHANGED');
  }

  Future<void> test_restoresOverlays() async {
    newFile(mainFilePath, '// DISK');
    await initialize();
    await initialAnalysis;
    await openFile(mainFileUri, '// ORIGINAL OVERLAY');

    late _TestTemporaryOverlayOperation operation;
    operation = _TestTemporaryOverlayOperation(server, () async {
      operation.applyTemporaryOverlayEdits(
        SourceFileEdit(mainFilePath, -1, edits: [SourceEdit(3, 8, 'CHANGED')]),
      );
      expectOverlayContent(mainFilePath, '// CHANGED OVERLAY');
    });
    await operation.doWork();

    await pumpEventQueue(times: 5000);
    expectOverlayContent(mainFilePath, '// ORIGINAL OVERLAY');
  }

  Future<void> test_temporarilyRemovesAddedFiles() async {
    newFile(mainFilePath, '');
    await initialize();
    await initialAnalysis;

    expect(server.driverMap.values.single.addedFiles, isNotEmpty);

    await _TestTemporaryOverlayOperation(server, () async {
      expect(server.driverMap.values.single.addedFiles, isEmpty);
    }).doWork();

    expect(server.driverMap.values.single.addedFiles, isNotEmpty);
  }
}

/// A [TemporaryOverlayOperation] that accepts an implementation in its
/// constructor.
class _TestTemporaryOverlayOperation extends TemporaryOverlayOperation {
  final Future<void> Function() operation;

  _TestTemporaryOverlayOperation(super.server, this.operation);

  Future<void> doWork() => lockRequestsWithTemporaryOverlays(operation);
}
