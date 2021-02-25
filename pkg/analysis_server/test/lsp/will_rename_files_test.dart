// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
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
  Future<void> test_rename_updatesImports() async {
    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    final otherFileUri = Uri.file(otherFilePath);
    final otherFileNewPath = join(projectFolderPath, 'lib', 'other_new.dart');
    final otherFileNewUri = Uri.file(otherFileNewPath);

    final mainContent = '''
import 'other.dart';

final a = A();
''';

    final otherContent = '''
class A {}
''';

    final expectedMainContent = '''
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

    // Ensure applying the edit will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(mainContent),
    };
    applyChanges(contents, edit.changes);
    expect(contents[mainFilePath], equals(expectedMainContent));
  }
}
