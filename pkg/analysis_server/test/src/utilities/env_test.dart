// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/env.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unified_analytics/unified_analytics.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FallbackRootToolForClientIdTest);
  });
}

@reflectiveTest
class FallbackRootToolForClientIdTest {
  void test_androidStudio() {
    expect(
      fallbackRootToolForClientId('Android-Studio'),
      DashTool.androidStudioPlugins,
    );
  }

  void test_intelliJ() {
    expect(
      fallbackRootToolForClientId('IntelliJ-IDEA'),
      DashTool.intellijPlugins,
    );
  }

  void test_null() {
    expect(fallbackRootToolForClientId(null), isNull);
  }

  void test_resultsCanBeRootTools() {
    // `Analytics` asserts that a `fallbackRootTool` can be a root tool.
    for (var clientId in [
      'VS-Code',
      'VS-Code-Remote',
      'IntelliJ-IDEA',
      'Android-Studio',
    ]) {
      var tool = fallbackRootToolForClientId(clientId);
      expect(tool, isNotNull, reason: clientId);
      expect(tool!.canBeRootTool, isTrue, reason: clientId);
    }
  }

  void test_unknown() {
    expect(fallbackRootToolForClientId('unknown.client.lsp'), isNull);
    expect(fallbackRootToolForClientId('unknown.client.classic'), isNull);
    expect(fallbackRootToolForClientId('vs-code'), isNull);
  }

  void test_vsCode() {
    expect(fallbackRootToolForClientId('VS-Code'), DashTool.vscodePlugins);
  }

  void test_vsCodeRemote() {
    expect(
      fallbackRootToolForClientId('VS-Code-Remote'),
      DashTool.vscodePlugins,
    );
  }
}
