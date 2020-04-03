// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeWorkspaceFoldersTest);
  });
}

@reflectiveTest
class ChangeWorkspaceFoldersTest extends AbstractLspAnalysisServerTest {
  String workspaceFolder1Path, workspaceFolder2Path, workspaceFolder3Path;
  Uri workspaceFolder1Uri, workspaceFolder2Uri, workspaceFolder3Uri;

  @override
  void setUp() {
    super.setUp();
    workspaceFolder1Path = convertPath('/workspace1');
    workspaceFolder2Path = convertPath('/workspace2');
    workspaceFolder3Path = convertPath('/workspace3');
    workspaceFolder1Uri = Uri.file(workspaceFolder1Path);
    workspaceFolder2Uri = Uri.file(workspaceFolder2Path);
    workspaceFolder3Uri = Uri.file(workspaceFolder3Path);
  }

  Future<void> test_changeWorkspaceFolders_add() async {
    await initialize(rootUri: workspaceFolder1Uri);
    await changeWorkspaceFolders(
        add: [workspaceFolder2Uri, workspaceFolder3Uri]);

    expect(
      server.contextManager.includedPaths,
      unorderedEquals([
        workspaceFolder1Path,
        workspaceFolder2Path,
        workspaceFolder3Path,
      ]),
    );
  }

  Future<void> test_changeWorkspaceFolders_addAndRemove() async {
    await initialize(
      workspaceFolders: [workspaceFolder1Uri, workspaceFolder2Uri],
    );

    await changeWorkspaceFolders(
      add: [workspaceFolder3Uri],
      remove: [workspaceFolder2Uri],
    );
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path, workspaceFolder3Path]),
    );
  }

  Future<void> test_changeWorkspaceFolders_remove() async {
    await initialize(
      workspaceFolders: [workspaceFolder1Uri, workspaceFolder2Uri],
    );

    await changeWorkspaceFolders(
      remove: [workspaceFolder2Uri],
    );
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );
  }

  Future<void> test_changeWorkspaceFolders_removeFlushesDiagnostics() async {
    // Add our standard test project as well as a dummy project.
    await initialize(workspaceFolders: [projectFolderUri, workspaceFolder1Uri]);

    // Generate an error in the test project.
    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await openFile(mainFileUri, 'String a = 1;');
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));

    // Ensure the error is removed if we removed the workspace folder.
    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await changeWorkspaceFolders(remove: [projectFolderUri]);
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(0));
  }
}
