// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReanalyzeTest);
  });
}

@reflectiveTest
class ReanalyzeTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  Future<void> test_reanalyze() async {
    var b = convertPath('/other/b.dart');

    newFile(testFile, content: r'''
import '../../other/b.dart';

var b = B();
''');
    createProject();

    // b.dart does not exist, and `B` is unresolved.
    await waitForTasksFinished();
    expect(filesErrors[testFile], hasLength(2));

    // Clear errors, so that we'll notice new results.
    filesErrors.clear();

    // Create b.dart, reanalyzing should fix the error.
    newFile(b, content: 'class B {}');

    // Reanalyze.
    server.reanalyze();
    await waitForTasksFinished();

    // No errors.
    expect(filesErrors[testFile], isEmpty);
  }
}
