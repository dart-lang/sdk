// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WillRenameFilesTest);
  });
}

@reflectiveTest
class WillRenameFilesTest extends AbstractLspAnalysisServerTest {
  bool isWillRenameFilesRegistration(Registration registration) =>
      registration.method == Method.workspace_willRenameFiles.toJson();

  Future<void> test_registration_defaultsEnabled() async {
    setAllSupportedWorkspaceDynamicRegistrations();

    final registrations = <Registration>[];
    await monitorDynamicRegistrations(registrations, initialize);

    expect(
      registrations.where(isWillRenameFilesRegistration),
      hasLength(1),
    );
  }

  Future<void> test_registration_disabled() async {
    setAllSupportedTextDocumentDynamicRegistrations();
    setAllSupportedWorkspaceDynamicRegistrations();
    setConfigurationSupport();

    final registrations = <Registration>[];
    await provideConfig(
      () => monitorDynamicRegistrations(
        registrations,
        initialize,
      ),
      {'updateImportsOnRename': false},
    );

    expect(
      registrations.where(isWillRenameFilesRegistration),
      isEmpty,
    );
  }

  Future<void> test_registration_disabledThenEnabled() async {
    setAllSupportedTextDocumentDynamicRegistrations();
    setAllSupportedWorkspaceDynamicRegistrations();
    setConfigurationSupport();
    // Start disabled.
    await provideConfig(
      initialize,
      {'updateImportsOnRename': false},
    );

    // Collect any new registrations when enabled.
    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      () => updateConfig({'updateImportsOnRename': true}),
    );

    // Expect that willRenameFiles was included.
    expect(
      registrations.where(isWillRenameFilesRegistration),
      hasLength(1),
    );
  }

  Future<void> test_renameFile_updatesImports() async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);
    final otherFileNewPath = join(projectFolderPath, 'lib', 'other_new.dart');
    final otherFileNewUri = pathContext.toUri(otherFileNewPath);

    final mainContent = '''
import 'other.dart';

final a = A();
''';

    final otherContent = '''
class A {}
''';

    final expectedContent = '''
>>>>>>>>>> lib/main.dart
import 'other_new.dart';

final a = A();
''';

    await initialize();
    await openFile(mainFileUri, mainContent);
    await openFile(otherFileUri, otherContent);
    final edit = await onWillRename([
      FileRename(
        oldUri: otherFileUri.toString(),
        newUri: otherFileNewUri.toString(),
      ),
    ]);

    verifyEdit(edit, expectedContent);
  }

  Future<void> test_renameFolder_updatesImports() async {
    final oldFolderPath = join(projectFolderPath, 'lib', 'folder');
    final newFolderPath = join(projectFolderPath, 'lib', 'folder_new');
    final otherFilePath = join(oldFolderPath, 'other.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);

    final mainContent = '''
import 'folder/other.dart';

final a = A();
''';

    final otherContent = '''
class A {}
''';

    final expectedMainContent = '''
>>>>>>>>>> lib/main.dart
import 'folder_new/other.dart';

final a = A();
''';

    await initialize();
    await openFile(mainFileUri, mainContent);
    await openFile(otherFileUri, otherContent);
    final edit = await onWillRename([
      FileRename(
        oldUri: pathContext.toUri(oldFolderPath).toString(),
        newUri: pathContext.toUri(newFolderPath).toString(),
      ),
    ]);

    verifyEdit(edit, expectedMainContent);
  }
}
