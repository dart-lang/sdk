// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_diagnostic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticDomainTest);
  });
}

@reflectiveTest
class DiagnosticDomainTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    generateSummaryFiles = true;
    super.setUp();
    handler = new DiagnosticDomainHandler(server);
    server.handlers = [handler];
  }

  test_getDiagnostics() async {
    String file = '/project/bin/test.dart';
    resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
    resourceProvider.newFile(file, 'main() {}');

    server.setAnalysisRoots('0', ['/project/'], [], {});

    await server.onAnalysisComplete;

    var request = new DiagnosticGetDiagnosticsParams().toRequest('0');
    var response = handler.handleRequest(request);
    var result = new DiagnosticGetDiagnosticsResult.fromResponse(response);

    expect(result.contexts, hasLength(1));

    ContextData context = result.contexts[0];
    expect(context.name, '/project');
    expect(context.explicitFileCount, 1); /* test.dart */

    expect(context.implicitFileCount, 4);

    expect(context.workItemQueueLength, isNotNull);
  }

  test_getDiagnostics_noRoot() async {
    var request = new DiagnosticGetDiagnosticsParams().toRequest('0');
    var response = handler.handleRequest(request);
    var result = new DiagnosticGetDiagnosticsResult.fromResponse(response);
    expect(result.contexts, isEmpty);
  }
}
