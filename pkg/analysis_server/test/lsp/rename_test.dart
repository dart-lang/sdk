// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameTest);
  });
}

@reflectiveTest
class RenameTest extends AbstractLspAnalysisServerTest {
  Future<void> test_prepare_class() {
    const content = '''
    class MyClass {}
    final a = new [[My^Class]]();
    ''';

    return _test_prepare(content, 'MyClass');
  }

  Future<void> test_prepare_classNewKeyword() async {
    const content = '''
    class MyClass {}
    final a = n^ew [[MyClass]]();
    ''';

    return _test_prepare(content, 'MyClass');
  }

  Future<void> test_prepare_importPrefix() async {
    const content = '''
    import 'dart:async' as [[myPr^efix]];
    ''';

    return _test_prepare(content, 'myPrefix');
  }

  Future<void> test_prepare_importWithoutPrefix() async {
    const content = '''
    imp[[^]]ort 'dart:async';
    ''';

    return _test_prepare(content, '');
  }

  Future<void> test_prepare_importWithPrefix() async {
    const content = '''
    imp^ort 'dart:async' as [[myPrefix]];
    ''';

    return _test_prepare(content, 'myPrefix');
  }

  Future<void> test_prepare_invalidRenameLocation() async {
    const content = '''
    main() {
      // comm^ent
    }
    ''';

    return _test_prepare(content, null);
  }

  Future<void> test_prepare_sdkClass() async {
    const content = '''
    final a = new [[Ob^ject]]();
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final request = makeRequest(
      Method.textDocument_prepareRename,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: mainFileUri.toString()),
        position: positionFromMarker(content),
      ),
    );
    final response = await channel.sendRequestToServer(request);

    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error.code, ServerErrorCodes.RenameNotValid);
    expect(response.error.message, contains('is defined in the SDK'));
  }

  Future<void> test_prepare_variable() async {
    const content = '''
    main() {
      var variable = 0;
      print([[vari^able]]);
    }
    ''';

    return _test_prepare(content, 'variable');
  }

  Future<void> test_rename_class() {
    const content = '''
    class MyClass {}
    final a = new [[My^Class]]();
    ''';
    const expectedContent = '''
    class MyNewClass {}
    final a = new MyNewClass();
    ''';
    return _test_rename_withDocumentChanges(
        content, 'MyNewClass', expectedContent);
  }

  Future<void> test_rename_classNewKeyword() async {
    const content = '''
    class MyClass {}
    final a = n^ew MyClass();
    ''';
    const expectedContent = '''
    class MyNewClass {}
    final a = new MyNewClass();
    ''';
    return _test_rename_withDocumentChanges(
        content, 'MyNewClass', expectedContent);
  }

  Future<void> test_rename_importPrefix() {
    const content = '''
    import 'dart:async' as myPr^efix;
    ''';
    const expectedContent = '''
    import 'dart:async' as myNewPrefix;
    ''';
    return _test_rename_withDocumentChanges(
        content, 'myNewPrefix', expectedContent);
  }

  Future<void> test_rename_importWithoutPrefix() {
    const content = '''
    imp^ort 'dart:async';
    ''';
    const expectedContent = '''
    import 'dart:async' as myAddedPrefix;
    ''';
    return _test_rename_withDocumentChanges(
        content, 'myAddedPrefix', expectedContent);
  }

  Future<void> test_rename_importWithPrefix() {
    const content = '''
    imp^ort 'dart:async' as myPrefix;
    ''';
    const expectedContent = '''
    import 'dart:async' as myNewPrefix;
    ''';
    return _test_rename_withDocumentChanges(
        content, 'myNewPrefix', expectedContent);
  }

  Future<void> test_rename_invalidRenameLocation() {
    const content = '''
    main() {
      // comm^ent
    }
    ''';
    return _test_rename_withDocumentChanges(content, 'MyNewClass', null);
  }

  Future<void> test_rename_multipleFiles() async {
    final referencedFilePath =
        join(projectFolderPath, 'lib', 'referenced.dart');
    final referencedFileUri = Uri.file(referencedFilePath);
    const mainContent = '''
    import 'referenced.dart';
    final a = new My^Class();
    ''';
    const referencedContent = '''
    class MyClass {}
    ''';
    const expectedMainContent = '''
    import 'referenced.dart';
    final a = new MyNewClass();
    ''';
    const expectedReferencedContent = '''
    class MyNewClass {}
    ''';
    const mainVersion = 111;
    const referencedVersion = 222;

    await initialize(
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(mainContent),
        version: mainVersion);
    await openFile(referencedFileUri, withoutMarkers(referencedContent),
        version: referencedVersion);

    final result = await rename(
      mainFileUri,
      mainVersion,
      positionFromMarker(mainContent),
      'MyNewClass',
    );

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(mainContent),
      referencedFilePath: withoutMarkers(referencedContent),
    };
    final documentVersions = {
      mainFilePath: mainVersion,
      referencedFilePath: referencedVersion,
    };
    applyDocumentChanges(
      contents,
      result.documentChanges,
      expectedVersions: documentVersions,
    );
    expect(contents[mainFilePath], equals(expectedMainContent));
    expect(contents[referencedFilePath], equals(expectedReferencedContent));
  }

  Future<void> test_rename_rejectedForBadName() async {
    const content = '''
    class MyClass {}
    final a = n^ew MyClass();
    ''';
    final error = await _test_rename_failure(content, 'not a valid class name');
    expect(error.code, equals(ServerErrorCodes.RenameNotValid));
    expect(error.message, contains('name must not contain'));
  }

  Future<void> test_rename_rejectedForDuplicateName() async {
    const content = '''
    class MyOtherClass {}
    class MyClass {}
    final a = n^ew MyClass();
    ''';
    final error = await _test_rename_failure(content, 'MyOtherClass');
    expect(error.code, equals(ServerErrorCodes.RenameNotValid));
    expect(error.message, contains('already declares class with name'));
  }

  Future<void> test_rename_rejectedForSameName() async {
    const content = '''
    class My^Class {}
    ''';
    final error = await _test_rename_failure(content, 'MyClass');
    expect(error.code, equals(ServerErrorCodes.RenameNotValid));
    expect(error.message,
        contains('new name must be different than the current name'));
  }

  Future<void> test_rename_rejectedForStaleDocument() async {
    const content = '''
    class MyClass {}
    final a = n^ew MyClass();
    ''';
    final error =
        await _test_rename_failure(content, 'MyNewClass', openFileVersion: 111);
    expect(error.code, equals(ErrorCodes.ContentModified));
    expect(error.message, contains('Document was modified'));
  }

  Future<void> test_rename_rejectionsDoNotCrashServer() async {
    // Checks that a rename failure does not stop the server from responding
    // as was previously the case in https://github.com/dart-lang/sdk/issues/42573
    // because the error code was duplicated/reused for ClientServerInconsistentState.
    const content = '''
    /// Test Class
    class My^Class {}
    ''';
    final error = await _test_rename_failure(content, 'MyClass');
    expect(error.code, isNotNull);

    // Send any other request to ensure the server is still responsive.
    final hover = await getHover(mainFileUri, positionFromMarker(content));
    expect(hover?.contents, isNotNull);
  }

  Future<void> test_rename_sdkClass() async {
    const content = '''
    final a = new [[Ob^ject]]();
    ''';

    await newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final request = makeRequest(
      Method.textDocument_rename,
      RenameParams(
        newName: 'Object2',
        textDocument: TextDocumentIdentifier(uri: mainFileUri.toString()),
        position: positionFromMarker(content),
      ),
    );
    final response = await channel.sendRequestToServer(request);

    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error.code, ServerErrorCodes.RenameNotValid);
    expect(response.error.message, contains('is defined in the SDK'));
  }

  Future<void> test_rename_usingLegacyChangeInterface() async {
    // This test initializes without support for DocumentChanges (versioning)
    // whereas the other tests all use DocumentChanges support (preferred).
    const content = '''
    class MyClass {}
    final a = new My^Class();
    ''';
    const expectedContent = '''
    class MyNewClass {}
    final a = new MyNewClass();
    ''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content), version: 222);

    final result = await rename(
      mainFileUri,
      222,
      positionFromMarker(content),
      'MyNewClass',
    );

    // Ensure applying the changes will give us the expected content.
    final contents = {
      mainFilePath: withoutMarkers(content),
    };
    applyChanges(contents, result.changes);
    expect(contents[mainFilePath], equals(expectedContent));
  }

  Future<void> test_rename_variable() {
    const content = '''
    main() {
      var variable = 0;
      print([[vari^able]]);
    }
    ''';
    const expectedContent = '''
    main() {
      var foo = 0;
      print(foo);
    }
    ''';
    return _test_rename_withDocumentChanges(content, 'foo', expectedContent);
  }

  Future<void> test_rename_withoutVersionedIdentifier() {
    // Without sending a document version, the rename should still work because
    // the server should use the version it had at the start of the rename
    // operation.
    const content = '''
    class MyClass {}
    final a = new [[My^Class]]();
    ''';
    const expectedContent = '''
    class MyNewClass {}
    final a = new MyNewClass();
    ''';
    return _test_rename_withDocumentChanges(
        content, 'MyNewClass', expectedContent,
        sendRenameVersion: false);
  }

  Future<void> _test_prepare(String content, String expectedPlaceholder) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final result =
        await prepareRename(mainFileUri, positionFromMarker(content));

    if (expectedPlaceholder == null) {
      expect(result, isNull);
    } else {
      expect(result.range, equals(rangeFromMarkers(content)));
      expect(result.placeholder, equals(expectedPlaceholder));
    }
  }

  Future<ResponseError> _test_rename_failure(
    String content,
    String newName, {
    int openFileVersion = 222,
    int renameRequestFileVersion = 222,
  }) async {
    await initialize(
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content),
        version: openFileVersion);

    final result = await renameRaw(
      mainFileUri,
      renameRequestFileVersion,
      positionFromMarker(content),
      newName,
    );

    expect(result.result, isNull);
    expect(result.error, isNotNull);
    return result.error;
  }

  Future<void> _test_rename_withDocumentChanges(
    String content,
    String newName,
    String expectedContent, {
    sendDocumentVersion = true,
    sendRenameVersion = true,
  }) async {
    // The specific number doesn't matter here, it's just a placeholder to confirm
    // the values match.
    final documentVersion = 222;
    await initialize(
      workspaceCapabilities:
          withDocumentChangesSupport(emptyWorkspaceClientCapabilities),
    );
    await openFile(mainFileUri, withoutMarkers(content),
        version: sendDocumentVersion ? documentVersion : null);

    final result = await rename(
      mainFileUri,
      sendRenameVersion ? documentVersion : null,
      positionFromMarker(content),
      newName,
    );
    if (expectedContent == null) {
      expect(result, isNull);
    } else {
      // Ensure applying the changes will give us the expected content.
      final contents = {
        mainFilePath: withoutMarkers(content),
      };
      final documentVersions = {
        mainFilePath: documentVersion,
      };
      applyDocumentChanges(
        contents,
        result.documentChanges,
        expectedVersions: documentVersions,
      );
      expect(contents[mainFilePath], equals(expectedContent));
    }
  }
}
