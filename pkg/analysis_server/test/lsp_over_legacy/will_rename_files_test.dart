// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handler_will_rename_files.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WillRenameFilesTest);
  });
}

@reflectiveTest
class WillRenameFilesTest extends LspOverLegacyTest {
  /// Test that sending a (legacy) cancellation request can cancel this LSP
  /// request.
  Future<void> test_cancellation() async {
    var testFileNewPath = join(testPackageLibPath, 'test_new.dart');

    await addOverlay(testFilePath, 'original');
    // Don't await, need to send cancellation.
    var editFuture = onWillRename([
      FileRename(
        oldUri: toUri(testFilePath).toString(),
        newUri: toUri(testFileNewPath).toString(),
      ),
    ]);

    var cancelRequest = createLegacyRequest(
      ServerCancelRequestParams(lastSentLegacyRequestId),
    );
    var req1 = handleRequest(cancelRequest);
    // Expect the cancellation was forwarded and handled by the LSP handler.
    await expectLater(
      editFuture,
      throwsA(isResponseError(ErrorCodes.RequestCancelled)),
    );
    await req1;
  }

  Future<void> test_inconsistentAnalysis() async {
    var testFileNewPath = join(testPackageLibPath, 'test_new.dart');

    // Use a Completer to control when the refactor finishes computing so that
    // we can ensure the overlay modification had time to be applied and trigger
    // creation of new sessions.
    var completer = Completer<void>();
    WillRenameFilesHandler.delayDuringComputeForTests = completer.future;
    try {
      await addOverlay(testFilePath, 'original');
      // Don't await, need to send modification.
      var editFuture = onWillRename([
        FileRename(
          oldUri: toUri(testFilePath).toString(),
          newUri: toUri(testFileNewPath).toString(),
        ),
      ]);
      // Allow the refactor time to start before sending the update. We know the
      // refactor won't complete because it's waiting for the future we control.
      var request = updateOverlay(testFilePath, SourceEdit(0, 0, 'inserted'));
      completer.complete();
      await expectLater(
        editFuture,
        throwsA(isResponseError(ErrorCodes.ContentModified)),
      );
      await request;
    } finally {
      // Ensure we never leave an incomplete future if anything above throws.
      WillRenameFilesHandler.delayDuringComputeForTests = null;
    }
  }

  /// Test moving multiple items at once. Both files reference each other
  /// by way of `part`/`part of`.
  Future<void> test_multiple() async {
    var testFileNewPath = join(testPackageLibPath, 'dest1', 'test.dart');
    var otherFilePath = join(testPackageLibPath, 'other', 'other.dart');
    var otherFileNewPath = join(testPackageLibPath, 'dest2', 'other.dart');

    var mainContent = "part 'other/other.dart';";
    var otherContent = "part of '../test.dart';";

    var expectedContent = '''
>>>>>>>>>> lib/other/other.dart
part of '../dest1/test.dart';<<<<<<<<<<
>>>>>>>>>> lib/test.dart
part '../dest2/other.dart';<<<<<<<<<<
''';

    newFile(testFilePath, mainContent);
    newFile(otherFilePath, otherContent);
    await pumpEventQueue(times: 5000);

    var edit = await onWillRename([
      FileRename(
        oldUri: toUri(testFilePath).toString(),
        newUri: toUri(testFileNewPath).toString(),
      ),
      FileRename(
        oldUri: toUri(otherFilePath).toString(),
        newUri: toUri(otherFileNewPath).toString(),
      ),
    ]);

    verifyEdit(edit, expectedContent);
  }

  Future<void> test_single() async {
    var otherFilePath = join(testPackageLibPath, 'other.dart');
    var otherFileNewPath = join(testPackageLibPath, 'other_new.dart');

    var mainContent = normalizeNewlinesForPlatform('''
import 'other.dart';

final a = A();
''');

    var otherContent = normalizeNewlinesForPlatform('''
class A {}
''');

    var expectedContent = normalizeNewlinesForPlatform('''
>>>>>>>>>> lib/test.dart
import 'other_new.dart';

final a = A();
''');

    newFile(testFilePath, mainContent);
    newFile(otherFilePath, otherContent);
    await pumpEventQueue(times: 5000);

    var edit = await onWillRename([
      FileRename(
        oldUri: toUri(otherFilePath).toString(),
        newUri: toUri(otherFileNewPath).toString(),
      ),
    ]);

    verifyEdit(edit, expectedContent);
  }
}
