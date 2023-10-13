// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:collection/collection.dart';
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

  /// Test that `part`/`part of` that point to each other are updated correctly.
  ///
  /// Updating each file individually would try to update the other so this will
  /// produce conflicting edits if not handled correctly.
  Future<void> test_part_partOf() async {
    // mainFileUri = lib/main.dart
    final mainFileNewUri =
        toUri(join(projectFolderPath, 'lib', 'dest1', 'main.dart'));
    final otherFileUri =
        toUri(join(projectFolderPath, 'lib', 'other', 'other.dart'));
    final otherFileNewUri =
        toUri(join(projectFolderPath, 'lib', 'dest2', 'other.dart'));

    final mainContent = "part 'other/other.dart';";
    final otherContent = "part of '../main.dart';";

    final expectedContent = '''
>>>>>>>>>> lib/main.dart
part '../dest2/other.dart';<<<<<<<<<<
>>>>>>>>>> lib/other/other.dart
part of '../dest1/main.dart';<<<<<<<<<<
''';

    await initialize();
    await openFile(mainFileUri, mainContent);
    await openFile(otherFileUri, otherContent);
    final edit = await onWillRename([
      FileRename(
        oldUri: mainFileUri.toString(),
        newUri: mainFileNewUri.toString(),
      ),
      FileRename(
        oldUri: otherFileUri.toString(),
        newUri: otherFileNewUri.toString(),
      ),
    ]);

    verifyEdit(edit, expectedContent);
  }

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
    final otherFileUri = toUri(otherFilePath);
    final otherFileNewPath = join(projectFolderPath, 'lib', 'other_new.dart');
    final otherFileNewUri = toUri(otherFileNewPath);

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
    final otherFileUri = toUri(otherFilePath);

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
        oldUri: toUri(oldFolderPath).toString(),
        newUri: toUri(newFolderPath).toString(),
      ),
    ]);

    verifyEdit(edit, expectedMainContent);
  }

  Future<void> test_renameMultipleFiles_updatesImports() async {
    /// Helper to build content for a set of files that all import each other
    /// using both 'package:' and relative imports.
    ///
    /// Returns a map where the key is the relative path and the value is the
    /// file content.
    ///
    /// If [fileMapping] is supplied, it will be used to replace the imported
    /// paths (so that this method can also be used to build expected content).
    Map<String, String> buildFiles(List<String> relativePaths,
        [Map<String, String>? fileMapping]) {
      final contentMap = <String, String>{};

      for (final relativePath in relativePaths) {
        final absolutePath = join(projectFolderPath, 'lib',
            fileMapping?[relativePath] ?? relativePath);

        // Add imports for every other file.
        final content = relativePaths
            .where((other) => other != relativePath) // Exclude self.
            .map((other) => fileMapping?[other] ?? other)
            .expand((other) => [
                  // Create both package + relative imports.
                  'package:test/${_asUriString(other)}',
                  _asRelativeUri(absolutePath, _asAbsolute(other)),
                ])
            .map((uri) => "import '$uri';")
            .join('\n');

        contentMap[relativePath] = '$content\n';
      }
      return contentMap;
    }

    // Create a set of files at multiple levels that will references each other
    // both by relative and 'package:' import.
    // A file from each folder will be moved, and a file from each will remain.
    // All files will be moved into the same folder, so the relative paths
    // change,
    final relativeTestPaths = [
      'moving1.dart',
      'not_moving1.dart',
      'f1/moving2.dart',
      'f1/not_moving2.dart',
      'f1/f1f2/moving3.dart',
      'f1/f1f2/not_moving3.dart',
      'dest/not_moving4.dart',
    ]
        .map(convertPath)
        // Sort the files so when we build the expected string, it's in the same
        // order that [LspChangeVerifier] produces.
        .sorted((a, b) => a.compareTo(b))
        .toList();

    // Build a mapping of old -> new paths.
    final pathMappings = {
      for (final relativeTestPath in relativeTestPaths)
        relativeTestPath: relativeTestPath.contains('not_moving')
            ? relativeTestPath
            : convertPath('dest/${pathContext.basename(relativeTestPath)}')
    };

    await initialize();

    final initialContent = buildFiles(pathMappings.keys.toList());
    final expectedContent =
        buildFiles(pathMappings.keys.toList(), pathMappings);

    // Open files with initial content.
    for (final MapEntry(key: filePath, value: content)
        in initialContent.entries) {
      await openFile(_asAbsoluteUri(filePath), content);
    }

    // Collect edits for the renames.
    final edit = await onWillRename([
      for (final MapEntry(key: originalPath, value: newPath)
          in pathMappings.entries)
        FileRename(
          oldUri: _asAbsoluteUri(originalPath).toString(),
          newUri: _asAbsoluteUri(newPath).toString(),
        ),
    ]);

    // Build expected edits in the format the change verifier uses (to avoid
    // hard-coding ~100 lines of files/imports here).
    final expectedEdits = expectedContent.entries
        .expand((entry) => [
              '>>>>>>>>>> lib/${_asUriString(entry.key)}\n',
              entry.value,
            ])
        .join();

    // Verify they match what the content would be using the destination paths.
    verifyEdit(edit, expectedEdits);
  }

  /// Returns an absolute path relative to the test projects 'lib' folder.
  String _asAbsolute(String relativePath) {
    return join(projectFolderPath, 'lib', relativePath);
  }

  /// Creates an absolute 'file://' URI relative to the test projects 'lib'
  /// folder.
  Uri _asAbsoluteUri(String relativePath) {
    return toUri(_asAbsolute(relativePath));
  }

  /// Creates a relative URI (for use in an `import`) to import [to] into
  /// [from].
  String _asRelativeUri(String from, String to) {
    return _asUriString(
        pathContext.relative(to, from: pathContext.dirname(from)));
  }

  /// Formats a relative path with forward slashes for use as an import.
  String _asUriString(String relativePath) {
    return relativePath.replaceAll(r'\', '/');
  }
}
