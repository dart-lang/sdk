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

  Future<void>
      test_changeWorkspaceFolders_addExplicitParentOfImplicit_closeFile() async {
    final nestedFolderPath =
        join(workspaceFolder1Path, 'nested', 'deeply', 'in', 'folders');
    final nestedFilePath = join(nestedFolderPath, 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    await initialize(allowEmptyRootUri: true);
    await openFile(nestedFileUri, '');

    // Expect implicit root for the open file.
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([nestedFolderPath]),
    );

    // Add the real project root to the workspace (which should become an
    // explicit root).
    await changeWorkspaceFolders(add: [workspaceFolder1Uri]);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path, nestedFolderPath]),
    );

    // Closing the file should not result in the project being removed.
    await closeFile(nestedFileUri);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );
  }

  Future<void>
      test_changeWorkspaceFolders_addExplicitParentOfImplicit_closeFolder() async {
    final nestedFolderPath =
        join(workspaceFolder1Path, 'nested', 'deeply', 'in', 'folders');
    final nestedFilePath = join(nestedFolderPath, 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    await initialize(allowEmptyRootUri: true);
    await openFile(nestedFileUri, '');

    // Expect implicit root for the open file.
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([nestedFolderPath]),
    );

    // Add the real project root to the workspace (which should become an
    // explicit root).
    await changeWorkspaceFolders(add: [workspaceFolder1Uri]);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path, nestedFolderPath]),
    );

    // Removing the workspace folder should result in falling back to just the
    // nested folder.
    await changeWorkspaceFolders(remove: [workspaceFolder1Uri]);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([nestedFolderPath]),
    );
  }

  Future<void>
      test_changeWorkspaceFolders_addImplicitChildOfExplicitParent_closeFile() async {
    final nestedFolderPath =
        join(workspaceFolder1Path, 'nested', 'deeply', 'in', 'folders');
    final nestedFilePath = join(nestedFolderPath, 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    await initialize(workspaceFolders: [workspaceFolder1Uri]);

    // Expect explicit root for the workspace folder.
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Open a file, though no new root is expected as it was mapped to the existing
    // open folder.
    await openFile(nestedFileUri, '');
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Closing the file should not result in the project being removed.
    await closeFile(nestedFileUri);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );
  }

  Future<void>
      test_changeWorkspaceFolders_addImplicitChildOfExplicitParent_closeFolder() async {
    final nestedFolderPath =
        join(workspaceFolder1Path, 'nested', 'deeply', 'in', 'folders');
    final nestedFilePath = join(nestedFolderPath, 'test.dart');
    final nestedFileUri = Uri.file(nestedFilePath);
    newFile(nestedFilePath);

    await initialize(workspaceFolders: [workspaceFolder1Uri]);

    // Expect explicit root for the workspace folder.
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Open a file, though no new root is expected as it was mapped to the existing
    // open folder.
    await openFile(nestedFileUri, '');
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Removing the workspace folder will retain the workspace folder, as that's
    // the folder we picked when the file was opened since there was already
    // a root for it.
    await changeWorkspaceFolders(remove: [workspaceFolder1Uri]);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );
  }

  Future<void> test_changeWorkspaceFolders_openFileOutsideRoot() async {
    // When a file is opened that is outside of the analysis roots, the first
    // analysis driver will be used (see [AbstractAnalysisServer.getAnalysisDriver]).
    // This means as long as there is already an analysis root, the implicit root
    // will be the original root and not the path of the opened file.
    // For example, Go-to-Definition into a file in PubCache must *not* result in
    // the pub cache folder being added as an analysis root, it should be analyzed
    // by the existing project's driver.
    final workspace1FilePath = join(workspaceFolder1Path, 'test.dart');
    newFile(workspace1FilePath);
    final workspace2FilePath = join(workspaceFolder2Path, 'test.dart');
    final workspace2FileUri = Uri.file(workspace2FilePath);
    newFile(workspace2FilePath);

    await initialize(workspaceFolders: [workspaceFolder1Uri]);

    // Expect explicit root for the workspace folder.
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Open a file in workspaceFolder2 (which is not in the analysis roots).
    await openFile(workspace2FileUri, '');
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
    );

    // Closing the file should not result in the project being removed.
    await closeFile(workspace2FileUri);
    expect(
      server.contextManager.includedPaths,
      unorderedEquals([workspaceFolder1Path]),
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
    newFile(mainFilePath, content: 'String a = 1;');
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(1));

    // Ensure the error is removed if we removed the workspace folder.
    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await changeWorkspaceFolders(remove: [projectFolderUri]);
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(0));
  }
}
