// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'change_verifier.dart';
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

  Future<void> test_prepare_class_typeParameter_atDeclaration() async {
    const content = '''
class A<[[T^]]> {
  final List<T> values = [];
}
''';

    return _test_prepare(content, 'T');
  }

  Future<void> test_prepare_class_typeParameter_atReference() async {
    const content = '''
class A<T> {
  final List<[[T^]]> values = [];
}
''';

    return _test_prepare(content, 'T');
  }

  Future<void> test_prepare_classNewKeyword() async {
    const content = '''
class MyClass {}
final a = n^ew [[MyClass]]();
''';

    return _test_prepare(content, 'MyClass');
  }

  Future<void> test_prepare_enum() {
    const content = '''
enum [[My^Enum]] { one }
''';

    return _test_prepare(content, 'MyEnum');
  }

  Future<void> test_prepare_enumMember() {
    const content = '''
enum MyEnum { [[o^ne]] }
''';

    return _test_prepare(content, 'one');
  }

  Future<void> test_prepare_enumMember_reference() {
    const content = '''
enum MyEnum { one }
final a = MyEnum.[[o^ne]];
''';

    return _test_prepare(content, 'one');
  }

  Future<void> test_prepare_function_startOfParameterList() {
    const content = '''
void [[aaaa]]^() {}
''';

    return _test_prepare(content, 'aaaa');
  }

  Future<void> test_prepare_function_startOfTypeParameterList() {
    const content = '''
void [[aaaa]]^<T>() {}
''';

    return _test_prepare(content, 'aaaa');
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
void f() {
  // comm^ent
}
''';

    return _test_prepare(content, null);
  }

  Future<void> test_prepare_method_startOfParameterList() {
    const content = '''
class A {
  void [[aaaa]]^() {}
}
''';

    return _test_prepare(content, 'aaaa');
  }

  Future<void> test_prepare_method_startOfTypeParameterList() {
    const content = '''
class A {
  void [[aaaa]]^<T>() {}
}
''';

    return _test_prepare(content, 'aaaa');
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
        textDocument: TextDocumentIdentifier(uri: mainFileUri),
        position: positionFromMarker(content),
      ),
    );
    final response = await channel.sendRequestToServer(request);

    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error!.code, ServerErrorCodes.RenameNotValid);
    expect(response.error!.message, contains('is defined in the SDK'));
  }

  Future<void> test_prepare_variable() async {
    const content = '''
void f() {
  var variable = 0;
  print([[vari^able]]);
}
''';

    return _test_prepare(content, 'variable');
  }

  Future<void> test_prepare_variable_forEach_statement() async {
    const content = '''
void f(List<int> values) {
  for (final [[value^]] in values) {
    value;
  }
}
''';

    return _test_prepare(content, 'value');
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

  Future<void> test_rename_class_doesNotRenameFile_disabled() async {
    const content = '''
class Main {}
final a = new [[Ma^in]]();
''';
    const expectedContent = '''
class MyNewMain {}
final a = new MyNewMain();
''';
    await _test_rename_withDocumentChanges(
        content, 'MyNewMain', expectedContent);
  }

  Future<void>
      test_rename_class_doesNotRenameFile_showMessageRequestUnsupportedPreventsPrompt() async {
    const content = '''
class Main {}
final a = new [[Ma^in]]();
''';
    const expectedContent = '''
class MyNewMain {}
final a = new MyNewMain();
''';

    // Do the rename with setting enabled, but showMessageRequest not supported.
    await provideConfig(
      () => _test_rename_withDocumentChanges(
        content,
        'MyNewMain',
        expectedContent,
        // showMessageRequest not supported.
        supportsWindowShowMessageRequest: false,
      ),
      // Rename files with prompt enabled.
      {'renameFilesWithClasses': 'prompt'},
    );
  }

  Future<void> test_rename_class_doesRenameFile_afterPrompt() async {
    const content = '''
class Main {}
final a = new [[Ma^in]]();
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart renamed to lib/my_new_main.dart
>>>>>>>>>> lib/my_new_main.dart renamed from lib/main.dart
class MyNewMain {}
final a = new MyNewMain();
''';
    final newMainFilePath = join(projectFolderPath, 'lib', 'my_new_main.dart');

    /// Helper that will respond to the window/showMessageRequest request from
    /// the server when prompted about renaming the file.
    Future<MessageActionItem> promptHandler(
        ShowMessageRequestParams params) async {
      // Ensure the prompt is as expected.
      expect(params.type, equals(MessageType.Info));
      expect(
          params.message, equals("Rename 'main.dart' to 'my_new_main.dart'?"));
      expect(params.actions, hasLength(2));
      expect(params.actions![0],
          equals(MessageActionItem(title: UserPromptActions.yes)));
      expect(params.actions![1],
          equals(MessageActionItem(title: UserPromptActions.no)));

      // Respond to the request with the required action.
      return params.actions!.first;
    }

    // Run the test and provide the config + prompt handling function.
    return handleExpectedRequest(
      Method.window_showMessageRequest,
      ShowMessageRequestParams.fromJson,
      () => provideConfig(
        () => _test_rename_withDocumentChanges(
          content,
          'MyNewMain',
          expectedContent,
          expectedFilePath: newMainFilePath,
        ),
        {'renameFilesWithClasses': 'prompt'},
      ),
      handler: promptHandler,
    );
  }

  Future<void> test_rename_class_doesRenameFile_enabledWithoutPrompt() async {
    const content = '''
class Main {}
final a = new [[Ma^in]]();
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart renamed to lib/my_new_main.dart
>>>>>>>>>> lib/my_new_main.dart renamed from lib/main.dart
class MyNewMain {}
final a = new MyNewMain();
''';
    final newMainFilePath = join(projectFolderPath, 'lib', 'my_new_main.dart');
    await provideConfig(
      () => _test_rename_withDocumentChanges(
        content,
        'MyNewMain',
        expectedContent,
        expectedFilePath: newMainFilePath,
      ),
      {'renameFilesWithClasses': 'always'},
    );
  }

  Future<void> test_rename_class_doesRenameFile_renamedFromOtherFile() async {
    const mainContent = '''
class Main {}
''';
    const otherContent = '''
import 'main.dart';

final a = Ma^in();
''';
    // Since we don't actually perform the file rename (we only include an
    // instruction for the client to do so), the import will not be updated
    // by us. Instead, the client will send the rename event back to the server
    // and it would be handled normally as if the user had done it locally.
    const expectedContent = '''
>>>>>>>>>> lib/main.dart renamed to lib/my_new_main.dart
>>>>>>>>>> lib/my_new_main.dart renamed from lib/main.dart
class MyNewMain {}
>>>>>>>>>> lib/other.dart
import 'main.dart';

final a = MyNewMain();
''';

    final otherFilePath = join(projectFolderPath, 'lib', 'other.dart');
    newFile(mainFilePath, withoutMarkers(mainContent));
    await pumpEventQueue(times: 5000);
    await provideConfig(
      () => _test_rename_withDocumentChanges(
        otherContent,
        'MyNewMain',
        expectedContent,
        filePath: otherFilePath,
      ),
      {'renameFilesWithClasses': 'always'},
    );
  }

  Future<void> test_rename_class_typeParameter_atDeclaration() {
    const content = '''
class A<[[T^]]> {
  final List<T> values = [];
}
''';

    const expectedContent = '''
class A<U> {
  final List<U> values = [];
}
''';

    return _test_rename_withDocumentChanges(content, 'U', expectedContent);
  }

  Future<void> test_rename_classNewKeyword() {
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

  Future<void> test_rename_duplicateName_applyAfterDocumentChanges() async {
    // Perform a refactor that results in a prompt to the user, but then modify
    // the document before accepting/rejecting to make the rename invalid.
    const content = '''
class MyOtherClass {}
class MyClass {}
final a = n^ew MyClass();
''';
    final result = await _test_rename_prompt(
      content,
      'MyOtherClass',
      expectedMessage:
          'Library already declares class with name \'MyOtherClass\'.',
      action: UserPromptActions.renameAnyway,
      beforeResponding: () => replaceFile(999, mainFileUri, 'Updated content'),
    );
    expect(result.result, isNull);
    expect(result.error, isNotNull);
    expect(result.error, isResponseError(ErrorCodes.ContentModified));
  }

  Future<void> test_rename_duplicateName_applyAnyway() async {
    const content = '''
class MyOtherClass {}
class MyClass {}
final a = n^ew MyClass();
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart
class MyOtherClass {}
class MyOtherClass {}
final a = new MyOtherClass();
''';
    final response = await _test_rename_prompt(
      content,
      'MyOtherClass',
      expectedMessage:
          'Library already declares class with name \'MyOtherClass\'.',
      action: UserPromptActions.renameAnyway,
    );

    final error = response.error;
    if (error != null) {
      throw error;
    }

    final result =
        WorkspaceEdit.fromJson(response.result as Map<String, Object?>);

    verifyEdit(result, expectedContent);
  }

  Future<void> test_rename_duplicateName_reject() async {
    const content = '''
class MyOtherClass {}
class MyClass {}
final a = n^ew MyClass();
''';
    final response = await _test_rename_prompt(
      content,
      'MyOtherClass',
      expectedMessage:
          'Library already declares class with name \'MyOtherClass\'.',
      action: UserPromptActions.cancel,
    );
    // Expect a successful empty response if cancelled.
    expect(response.error, isNull);
    expect(
      WorkspaceEdit.fromJson(response.result as Map<String, Object?>),
      equals(emptyWorkspaceEdit),
    );
  }

  Future<void>
      test_rename_duplicateName_showMessageRequestUnsupportedPreventsPrompt() async {
    const content = '''
class MyOtherClass {}
class MyClass {}
final a = n^ew MyClass();
''';
    final error = await _test_rename_failure(
      content,
      'MyOtherClass',
      supportsWindowShowMessageRequest: false,
    );
    expect(error.code, equals(ServerErrorCodes.RenameNotValid));
    expect(error.message,
        contains('Library already declares class with name \'MyOtherClass\'.'));
  }

  Future<void> test_rename_enum() {
    const content = '''
enum MyEnum { one }
final a = MyE^num.one;
''';
    const expectedContent = '''
enum MyNewEnum { one }
final a = MyNewEnum.one;
''';
    return _test_rename_withDocumentChanges(
        content, 'MyNewEnum', expectedContent);
  }

  Future<void> test_rename_enumMember() {
    const content = '''
enum MyEnum { one }
final a = MyEnum.o^ne;
''';
    const expectedContent = '''
enum MyEnum { newOne }
final a = MyEnum.newOne;
''';
    return _test_rename_withDocumentChanges(content, 'newOne', expectedContent);
  }

  Future<void> test_rename_function_startOfParameterList() {
    const content = '''
void f^() {}
''';
    const expectedContent = '''
void newName() {}
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
  }

  Future<void> test_rename_function_startOfTypeParameterList() {
    const content = '''
void f^<T>() {}
''';
    const expectedContent = '''
void newName<T>() {}
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
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
void f() {
  // comm^ent
}
''';
    return _test_rename_withDocumentChanges(content, 'MyNewClass', null);
  }

  Future<void> test_rename_method_startOfParameterList() {
    const content = '''
class MyClass {
  void m^() {}
}
''';
    const expectedContent = '''
class MyClass {
  void newName() {}
}
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
  }

  Future<void> test_rename_method_startOfTypeParameterList() {
    const content = '''
class MyClass {
  void m^<T>() {}
}
''';
    const expectedContent = '''
class MyClass {
  void newName<T>() {}
}
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
  }

  Future<void> test_rename_multipleFiles() async {
    final referencedFilePath =
        join(projectFolderPath, 'lib', 'referenced.dart');
    final referencedFileUri = pathContext.toUri(referencedFilePath);
    const mainContent = '''
import 'referenced.dart';
final a = new My^Class();
''';
    const referencedContent = '''
class MyClass {}
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart
import 'referenced.dart';
final a = new MyNewClass();
>>>>>>>>>> lib/referenced.dart
class MyNewClass {}
''';
    const mainVersion = 111;
    const referencedVersion = 222;

    setDocumentChangesSupport();
    await initialize();
    await openFile(mainFileUri, withoutMarkers(mainContent),
        version: mainVersion);
    await openFile(referencedFileUri, withoutMarkers(referencedContent),
        version: referencedVersion);

    final result = (await rename(
      mainFileUri,
      mainVersion,
      positionFromMarker(mainContent),
      'MyNewClass',
    ))!;

    final expectedVersions = {
      mainFileUri: mainVersion,
      referencedFileUri: referencedVersion,
    };
    verifyEdit(result, expectedContent, expectedVersions: expectedVersions);
  }

  Future<void> test_rename_nonClass_doesNotRenameFile() async {
    const content = '''
final Ma^in = 'test';
''';
    const expectedContent = '''
final MyNewMain = 'test';
''';
    await provideConfig(
      () => _test_rename_withDocumentChanges(
        content,
        'MyNewMain',
        expectedContent,
      ),
      {'renameFilesWithClasses': 'always'},
    );
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

    newFile(mainFilePath, withoutMarkers(content));
    await initialize();

    final request = makeRequest(
      Method.textDocument_rename,
      RenameParams(
        newName: 'Object2',
        textDocument: TextDocumentIdentifier(uri: mainFileUri),
        position: positionFromMarker(content),
      ),
    );
    final response = await channel.sendRequestToServer(request);

    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error!.code, ServerErrorCodes.RenameNotValid);
    expect(response.error!.message, contains('is defined in the SDK'));
  }

  /// Unrelated dartdoc references should not be renamed.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/4131
  Future<void> test_rename_updatesCorrectDartdocReferences() {
    const content = '''
class A {
  int? origi^nalName;
}

class B {
  int? originalName;
}

/// [A.originalName]
/// [B.originalName]
/// [C.originalName]
var a;
''';
    const expectedContent = '''
class A {
  int? newName;
}

class B {
  int? originalName;
}

/// [A.newName]
/// [B.originalName]
/// [C.originalName]
var a;
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
  }

  Future<void> test_rename_usingLegacyChangeInterface() async {
    // This test initializes without support for DocumentChanges (versioning)
    // whereas the other tests all use DocumentChanges support (preferred).
    const content = '''
class MyClass {}
final a = new My^Class();
''';
    const expectedContent = '''
>>>>>>>>>> lib/main.dart
class MyNewClass {}
final a = new MyNewClass();
''';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content), version: 222);

    final result = (await rename(
      mainFileUri,
      222,
      positionFromMarker(content),
      'MyNewClass',
    ))!;

    verifyEdit(result, expectedContent);
  }

  Future<void> test_rename_variable() {
    const content = '''
void f() {
  var variable = 0;
  print([[vari^able]]);
}
''';
    const expectedContent = '''
void f() {
  var foo = 0;
  print(foo);
}
''';
    return _test_rename_withDocumentChanges(content, 'foo', expectedContent);
  }

  Future<void> test_rename_variable_forEach_statement() {
    const content = '''
void f(List<int> values) {
  for (final [[value^]] in values) {
    value;
  }
}
''';
    const expectedContent = '''
void f(List<int> values) {
  for (final newName in values) {
    newName;
  }
}
''';
    return _test_rename_withDocumentChanges(
        content, 'newName', expectedContent);
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

  Future<void> _test_prepare(
      String content, String? expectedPlaceholder) async {
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final result =
        await prepareRename(mainFileUri, positionFromMarker(content));

    if (expectedPlaceholder == null) {
      expect(result, isNull);
    } else {
      expect(result!.range, equals(rangeFromMarkers(content)));
      expect(result.placeholder, equals(expectedPlaceholder));
    }
  }

  Future<ResponseError> _test_rename_failure(
    String content,
    String newName, {
    int openFileVersion = 222,
    int renameRequestFileVersion = 222,
    bool supportsWindowShowMessageRequest = true,
  }) async {
    setDocumentChangesSupport();

    await initialize(
      experimentalCapabilities: supportsWindowShowMessageRequest
          ? const {
              'supportsWindowShowMessageRequest': true,
            }
          : null,
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
    return result.error!;
  }

  /// Tests a rename that is expected to cause an error, which will trigger
  /// a ShowMessageRequest from the server to the client to allow the refactor
  /// to be continued or rejected.
  Future<ResponseMessage> _test_rename_prompt(
    String content,
    String newName, {
    required String expectedMessage,
    Future<void> Function()? beforeResponding,
    required String action,
    int openFileVersion = 222,
    int renameRequestFileVersion = 222,
    bool supportsWindowShowMessageRequest = true,
  }) async {
    setDocumentChangesSupport();
    await initialize(
      experimentalCapabilities: supportsWindowShowMessageRequest
          ? const {
              'supportsWindowShowMessageRequest': true,
            }
          : null,
    );
    await openFile(mainFileUri, withoutMarkers(content),
        version: openFileVersion);

    // Expect the server to call us back with a ShowMessageRequest prompt about
    // the errors for us to accept/reject.
    return handleExpectedRequest(
      Method.window_showMessageRequest,
      ShowMessageRequestParams.fromJson,
      () => renameRaw(
        mainFileUri,
        renameRequestFileVersion,
        positionFromMarker(content),
        newName,
      ),
      handler: (ShowMessageRequestParams params) async {
        // Ensure the warning prompt is as expected.
        expect(params.type, equals(MessageType.Warning));
        expect(params.message, equals(expectedMessage));
        expect(params.actions, hasLength(2));
        expect(params.actions![0],
            equals(MessageActionItem(title: UserPromptActions.renameAnyway)));
        expect(params.actions![1],
            equals(MessageActionItem(title: UserPromptActions.cancel)));

        // Allow the test to run some code before we send the response.
        await beforeResponding?.call();

        // Respond to the request with the required action.
        return MessageActionItem(title: action);
      },
    );
  }

  Future<void> _test_rename_withDocumentChanges(
    String content,
    String newName,
    String? expectedContent, {
    String? filePath,
    String? expectedFilePath,
    bool sendRenameVersion = true,
    bool supportsWindowShowMessageRequest = true,
  }) async {
    filePath ??= mainFilePath;
    expectedFilePath ??= filePath;
    final fileUri = pathContext.toUri(filePath);

    // The specific number doesn't matter here, it's just a placeholder to confirm
    // the values match.
    final documentVersion = 222;
    final expectedVersions = {
      fileUri: documentVersion,
    };

    setDocumentChangesSupport();
    setFileRenameSupport();
    final initialAnalysis = waitForAnalysisComplete();
    await initialize(
      experimentalCapabilities: supportsWindowShowMessageRequest
          ? const {
              'supportsWindowShowMessageRequest': true,
            }
          : null,
    );
    await openFile(fileUri, withoutMarkers(content), version: documentVersion);
    await initialAnalysis;

    final result = await rename(
      fileUri,
      sendRenameVersion ? documentVersion : null,
      positionFromMarker(content),
      newName,
    );

    if (expectedContent == null) {
      expect(result, isNull);
    } else {
      // For convenience, if a test doesn't provide an full set of edits
      // we assume only a single edit of the file that was being modified.
      if (!expectedContent.startsWith(LspChangeVerifier.editMarkerStart)) {
        expectedContent = '''
${LspChangeVerifier.editMarkerStart} ${relativePath(filePath)}
$expectedContent''';
      }
      verifyEdit(
        result!,
        expectedContent,
        expectedVersions: expectedVersions,
      );
    }
  }
}
