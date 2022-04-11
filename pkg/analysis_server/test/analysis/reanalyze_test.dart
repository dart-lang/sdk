// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReanalyzeTest);
  });
}

@reflectiveTest
class ReanalyzeTest extends PubPackageAnalysisServerTest {
  Map<File, List<AnalysisError>> filesErrors = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[getFile(decoded.file)] = decoded.errors;
    }
  }

  Future<void> test_reanalyze() async {
    var b = getFolder(testPackageLibPath).parent.getChildAssumingFile('b.dart');

    var file = newFile2('$testPackageTestPath/a.dart', r'''
import '../b.dart';

var b = B();
''');

    await setRoots(included: [testPackageTestPath], excluded: []);

    // b.dart does not exist, and `B` is unresolved.
    await waitForTasksFinished();
    expect(filesErrors[file], hasLength(2));

    // Clear errors, so that we'll notice new results.
    filesErrors.clear();

    // Create b.dart, reanalyzing should fix the error.
    b.writeAsStringSync('class B {}');

    // Reanalyze.
    await handleSuccessfulRequest(
      AnalysisReanalyzeParams().toRequest('0'),
    );
    await waitForTasksFinished();

    // No errors.
    expect(filesErrors[file], isEmpty);
  }
}
