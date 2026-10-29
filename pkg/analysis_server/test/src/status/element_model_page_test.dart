// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/pages/element_model_page.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';
import 'test_socket_server.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementModelPageTest);
  });
}

@reflectiveTest
class ElementModelPageTest extends PubPackageAnalysisServerTest {
  late DiagnosticsSite site;
  late ElementModelPage page;

  @override
  void setUp() {
    super.setUp();
    site = DiagnosticsSite(TestSocketServer(server), []);
    page = ElementModelPage(site);
  }

  Future<void> test_fileParameter_escaped() async {
    var html = await page.generate({'file': '<svg onload=alert(1)>'});
    expect(html, isNot(contains('<svg onload=')));
    expect(html, contains('&lt;svg onload=alert(1)&gt;'));
  }
}
