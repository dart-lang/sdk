// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetServerPortTest);
  });
}

@reflectiveTest
class GetServerPortTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_connect() async {
    standardAnalysisSetup();

    var result = await sendDiagnosticGetServerPort();
    expect(result.port, isNotNull);
    expect(result.port, isNonZero);

    // Connect to the server and verify that it's serving the status page.
    var client = HttpClient();
    var request = await client
        .getUrl(Uri.parse('http://localhost:${result.port}/status'));
    var response = await request.close();
    var responseBody = await utf8.decodeStream(response.cast<List<int>>());
    expect(responseBody, contains('<title>Analysis Server</title>'));
  }
}
