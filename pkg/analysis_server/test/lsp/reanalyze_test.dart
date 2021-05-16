// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReanalyzeTest);
  });
}

@reflectiveTest
class ReanalyzeTest extends AbstractLspAnalysisServerTest {
  Future<void> test_reanalyze() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    final initialAnalysis = waitForAnalysisComplete();

    await initialize();
    await initialAnalysis;

    // Set up futures to wait for the new events.
    final startNotification = waitForAnalysisStart();
    final completeNotification = waitForAnalysisComplete();

    final request = makeRequest(Method.fromJson(r'dart/reanalyze'), null);
    await channel.sendRequestToServer(request);

    // Ensure the notifications come through again.
    await startNotification;
    await completeNotification;
  }
}
