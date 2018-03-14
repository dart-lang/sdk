// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetServerPortTest);
    defineReflectiveTests(GetServerPortTest_UseCFE);
  });
}

@reflectiveTest
class GetServerPortTest extends AbstractAnalysisServerIntegrationTest {
  test_connect() async {
    standardAnalysisSetup();

    DiagnosticGetServerPortResult result = await sendDiagnosticGetServerPort();
    expect(result.port, isNotNull);
    expect(result.port, isNonZero);

    // Connect to the server and verify that it's serving the status page.
    HttpClient client = new HttpClient();
    HttpClientRequest request = await client
        .getUrl(Uri.parse('http://localhost:${result.port}/status'));
    HttpClientResponse response = await request.close();
    String responseBody = await utf8.decodeStream(response);
    expect(responseBody, contains('<title>Analysis Server</title>'));
  }
}

@reflectiveTest
class GetServerPortTest_UseCFE extends GetServerPortTest {
  @override
  bool get useCFE => true;
}
