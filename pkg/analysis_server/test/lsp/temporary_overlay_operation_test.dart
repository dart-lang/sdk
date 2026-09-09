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

  Future<void> test_applyTemporaryOverlay_noContext() async {
    await initialize();
    await workspaceAnalysisComplete();

    var unanalyzedPath = join(
      projectFolderPath,
      '.dart_tool',
      'package_config.json',
    );
    newFile(unanalyzedPath, '// DISK');
    expect(server.contextManager.getContextFor(unanalyzedPath), isNull);

    late _TestTemporaryOverlayOperation operation;
    operation = _TestTemporaryOverlayOperation(server, () async {
      operation.applyTemporaryOverlay(
        unanalyzedPath,
        '// TEMPORARY OVERLAY',
        '// DISK',
      );
      expectOverlayContent(unanalyzedPath, '// TEMPORARY OVERLAY');
    });
    await operation.doWork();

    // After reverting, the temporary overlay should be removed.
    expect(server.resourceProvider.hasOverlay(unanalyzedPath), isFalse);
    expect(
      server.resourceProvider.getFile(unanalyzedPath).readAsStringSync(),
      '// DISK',
    );
  }

  Future<void> test_applyTemporaryOverlay_noContext_existingOverlay() async {
    await initialize();
    await workspaceAnalysisComplete();

    var unanalyzedPath = join(
      projectFolderPath,
      '.dart_tool',
      'package_config.json',
    );
    newFile(unanalyzedPath, '// DISK');
    server.resourceProvider.setOverlay(
      unanalyzedPath,
      content: '// ORIGINAL OVERLAY',
      modificationStamp: -1,
    );
    expect(server.contextManager.getContextFor(unanalyzedPath), isNull);

    late _TestTemporaryOverlayOperation operation;
    operation = _TestTemporaryOverlayOperation(server, () async {
      operation.applyTemporaryOverlay(
        unanalyzedPath,
        '// TEMPORARY OVERLAY',
        '// ORIGINAL OVERLAY',
      );
      expectOverlayContent(unanalyzedPath, '// TEMPORARY OVERLAY');
    });
    await operation.doWork();

    // After reverting, the original overlay should be restored.
    expectOverlayContent(unanalyzedPath, '// ORIGINAL OVERLAY');
  }

  Future<void> test_applyTemporaryOverlay_nonExistentFile() async {
    await initialize();
    await workspaceAnalysisComplete();

    var nonExistentPath = join(
      projectFolderPath,
      '.dart_tool',
      'non_existent_file.json',
    );
    expect(server.resourceProvider.getFile(nonExistentPath).exists, isFalse);

    late _TestTemporaryOverlayOperation operation;
    operation = _TestTemporaryOverlayOperation(server, () async {
      operation.applyTemporaryOverlay(
        nonExistentPath,
        '// TEMPORARY OVERLAY',
        '',
      );
      expectOverlayContent(nonExistentPath, '// TEMPORARY OVERLAY');
    });
    await operation.doWork();

    // After reverting, the temporary overlay should be removed and the file
    // remains non-existent on disk.
    expect(server.resourceProvider.hasOverlay(nonExistentPath), isFalse);
    expect(server.resourceProvider.getFile(nonExistentPath).exists, isFalse);
  }

  Future<void> test_noIntermediateAnalysisResults() async {
    newFile(mainFilePath, '');
    await initialize();
    await workspaceAnalysisComplete();

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
    await workspaceAnalysisComplete();
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
    await workspaceAnalysisComplete();
    expectFsStateContent(mainFilePath, '// CHANGED');
    expectOverlayContent(mainFilePath, '// CHANGED');
  }

  Future<void> test_pausesWatcherEvents() async {
    var mainFile = newFile(mainFilePath, '// ORIGINAL');
    await initialize();
    await workspaceAnalysisComplete();

    await _TestTemporaryOverlayOperation(server, () async {
      // Modify the file to trigger watcher events
      modifyFile2(mainFile, '// CHANGED');

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
    await workspaceAnalysisComplete();
    await openFile(mainFileUri, '// ORIGINAL OVERLAY');

    late _TestTemporaryOverlayOperation operation;
    operation = _TestTemporaryOverlayOperation(server, () async {
      operation.applyTemporaryOverlayEdits(
        SourceFileEdit(mainFilePath, -1, edits: [SourceEdit(3, 8, 'CHANGED')]),
      );
      expectOverlayContent(mainFilePath, '// CHANGED OVERLAY');
    });
    await operation.doWork();

    await workspaceAnalysisComplete();
    expectOverlayContent(mainFilePath, '// ORIGINAL OVERLAY');
  }

  Future<void> test_temporarilyRemovesAddedFiles() async {
    newFile(mainFilePath, '');
    await initialize();
    await workspaceAnalysisComplete();

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

  new(super.server, this.operation);

  Future<void> doWork() => pauseSchedulerWithTemporaryOverlays(operation);
}
