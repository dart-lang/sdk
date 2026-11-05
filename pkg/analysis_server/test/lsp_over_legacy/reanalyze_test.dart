// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReanalyzeTest);
  });
}

/// More complete tests for dart/reanalyze are in
/// 'test/lsp/reanalyze_test.dart'.
@reflectiveTest
class ReanalyzeTest extends LspOverLegacyTest {
  final analysisStatuses = <bool>[];

  @override
  void processNotification(Notification notification) {
    super.processNotification(notification);
    if (notification.event == serverNotificationStatus) {
      var params = ServerStatusParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      if (params.analysis case var analysis?) {
        analysisStatuses.add(analysis.isAnalyzing);
      }
    }
  }

  Future<void> test_reanalyze() async {
    newFile(testFilePath, 'int a = 1;');
    await handleSuccessfulRequest(
      ServerSetSubscriptionsParams([ServerService.STATUS]).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
    await initializeServer();

    // Clear any statuses from initial analysis.
    analysisStatuses.clear();

    await sendRequestToServer(
      makeRequest(Method.fromJson(r'dart/reanalyze'), null),
    );
    await waitForTasksFinished();

    // Expect we saw analysis.
    expect(analysisStatuses, [true, false]);
  }
}
