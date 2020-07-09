// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CancelRequestTest);
  });
}

@reflectiveTest
class CancelRequestTest extends AbstractLspAnalysisServerTest {
  Future<void> test_cancel() async {
    final content = '''
main() {
  InOtherF^
}
    ''';

    final initialAnalysis = waitForAnalysisComplete();
    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));
    await initialAnalysis;

    // Create a completion request that we'll cancel.
    final completionRequest = makeRequest(
      Method.textDocument_completion,
      CompletionParams(
        textDocument: TextDocumentIdentifier(uri: mainFileUri.toString()),
        position: positionFromMarker(content),
      ),
    );
    // And a request to cancel it.
    final cancelNotification = makeNotification(
        Method.cancelRequest, CancelParams(id: completionRequest.id));

    // Send both (without waiting for the results of the first).
    final completionRequestFuture = sendRequestToServer(completionRequest);
    await sendNotificationToServer(cancelNotification);

    final result = await completionRequestFuture;
    expect(result.result, isNull);
    expect(result.error, isNotNull);
    expect(result.error, isResponseError(ErrorCodes.RequestCancelled));
  }
}
