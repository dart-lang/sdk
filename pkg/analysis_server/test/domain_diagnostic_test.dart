// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticDomainTest);
  });
}

@reflectiveTest
class DiagnosticDomainTest extends AbstractAnalysisTest {
  Future<void> test_getDiagnostics() async {
    newPubspecYamlFile('/project', 'name: project');
    newFile2('/project/bin/test.dart', 'main() {}');

    await server.setAnalysisRoots('0', [convertPath('/project')], []);

    await server.onAnalysisComplete;

    var request = DiagnosticGetDiagnosticsParams().toRequest('0');
    var response = await waitResponse(request);
    var result = DiagnosticGetDiagnosticsResult.fromResponse(response);

    expect(result.contexts, hasLength(1));

    var context = result.contexts[0];
    expect(context.name, convertPath('/project'));
    expect(context.explicitFileCount, 1); /* test.dart */

    expect(context.implicitFileCount, 5);

    expect(context.workItemQueueLength, isNotNull);
  }

  Future<void> test_getDiagnostics_noRoot() async {
    var request = DiagnosticGetDiagnosticsParams().toRequest('0');
    var response = await waitResponse(request);
    var result = DiagnosticGetDiagnosticsResult.fromResponse(response);
    expect(result.contexts, isEmpty);
  }
}
