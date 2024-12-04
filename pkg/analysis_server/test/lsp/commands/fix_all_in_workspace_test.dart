// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../tool/lsp_spec/matchers.dart';
import '../server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApplyAllFixesInWorkspace);
    defineReflectiveTests(PreviewAllFixesInWorkspace);
  });
}

abstract class AbstractFixAllInWorkspaceTest
    extends AbstractLspAnalysisServerTest {
  String get commandId;
  String get commandName;
  bool get expectRequiresConfirmation;

  Future<void> check_multipleFixes_multipleFiles() async {
    // Set up multiple lints that have fixes.
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - prefer_is_empty
    - prefer_single_quotes
    ''');

    // Write multiple files with violations.
    for (var fileName in ['a', 'b']) {
      newFile(join(projectFolderPath, 'lib', '$fileName.dart'), '''
bool f() {
  var files = ["$fileName"];
  return files.length == 0;
}
''');
    }

    await initialize();
    var verifier = await verifyCommandEdits(
      Command(command: commandId, title: 'UNUSED'),
      '''
>>>>>>>>>> lib/a.dart
>>>>>>>>>>   Convert to single quoted string: line 2, line 2
>>>>>>>>>>   Replace with 'isEmpty': line 3
bool f() {
  var files = ['a'];
  return files.isEmpty;
}
>>>>>>>>>> lib/b.dart
>>>>>>>>>>   Convert to single quoted string: line 2, line 2
>>>>>>>>>>   Replace with 'isEmpty': line 3
bool f() {
  var files = ['b'];
  return files.isEmpty;
}
''',
    );
    var annotations = verifier.edit.changeAnnotations?.values ?? [];
    for (var annotation in annotations) {
      expect(annotation.needsConfirmation, expectRequiresConfirmation);
    }
  }

  @override
  void setUp() {
    super.setUp();

    registerLintRules();
    registerBuiltInProducers();

    // We need applyEdit support to send edits from server to client
    // out-of-band (which commands have to do because they cannot return edits).
    setApplyEditSupport();
    setChangeAnnotationSupport();
  }

  Future<void> test_documentChanges_notSupported() async {
    setDocumentChangesSupport(false);

    await check_multipleFixes_multipleFiles();
  }

  Future<void> test_documentChanges_supported() async {
    setDocumentChangesSupport();

    await check_multipleFixes_multipleFiles();
  }

  /// Some fixes computer their FixKind lazily so we need to test they're
  /// generating the right labels.
  Future<void> test_lazyFixKind() async {
    // Set up multiple lints that have fixes.
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - unnecessary_final
    ''');

    // Write violations that will result in both kinds of fixes produced by
    // unnecessary final.
    newFile(mainFilePath, '''
void f() {
  final int a = 1;
  final b = 1;
}
''');

    await initialize();
    var verifier = await verifyCommandEdits(
      Command(command: commandId, title: 'UNUSED'),
      '''
>>>>>>>>>> lib/main.dart
>>>>>>>>>>   Remove unnecessary 'final': line 2
>>>>>>>>>>   Replace 'final' with 'var': line 3
void f() {
  int a = 1;
  var b = 1;
}
''',
    );
    var annotations = verifier.edit.changeAnnotations?.values ?? [];
    for (var annotation in annotations) {
      expect(annotation.needsConfirmation, expectRequiresConfirmation);
    }
  }

  Future<void> test_serverAdvertisesCommand() async {
    await initialize();
    expect(
      serverCapabilities.executeCommandProvider!.commands,
      contains(commandId),
    );
  }

  Future<void> test_unsupported_clientLacksApplyEdit() async {
    setApplyEditSupport(false);
    await initialize();

    await expectLater(
      executeCommand(Command(command: commandId, title: 'UNUSED')),
      throwsA(
        isResponseError(
          ServerErrorCodes.FeatureDisabled,
          message:
              '"$commandName" is only available for '
              'clients that support workspace/applyEdit',
        ),
      ),
    );
  }

  Future<void> test_unsupported_clientLacksChangeAnnotations() async {
    setChangeAnnotationSupport(false);
    await initialize();

    await expectLater(
      executeCommand(Command(command: commandId, title: 'UNUSED')),
      throwsA(
        isResponseError(
          ServerErrorCodes.FeatureDisabled,
          message:
              '"$commandName" is only available for '
              'clients that support change annotations',
        ),
      ),
    );
  }
}

/// Tests the "Apply All Fixes in Workspace" command that has change annotations
/// but does not require confirmation.
@reflectiveTest
class ApplyAllFixesInWorkspace extends AbstractFixAllInWorkspaceTest {
  @override
  String get commandId => Commands.fixAllInWorkspace;

  @override
  String get commandName => 'Apply All Fixes in Workspace';

  @override
  bool get expectRequiresConfirmation => false;
}

/// Tests the "Preview All Fixes in Workspace" command that has change
/// annotations and requires confirmation.
@reflectiveTest
class PreviewAllFixesInWorkspace extends AbstractFixAllInWorkspaceTest {
  @override
  String get commandId => Commands.previewFixAllInWorkspace;

  @override
  String get commandName => 'Preview All Fixes in Workspace';

  @override
  bool get expectRequiresConfirmation => true;
}
