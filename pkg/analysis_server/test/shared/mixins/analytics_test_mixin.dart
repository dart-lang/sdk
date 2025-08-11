// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';

/// A mixin that provides helpers for verifying analytics.
mixin AnalyticsTestMixin {
  AnalyticsManager get analyticsManager;

  /// Expects that [command] was logged to the analytics manager.
  void expectCommandLogged(String command) {
    expect(
      analyticsManager
          .getRequestData(Method.workspace_executeCommand.toString())
          .additionalEnumCounts['command']!
          .keys,
      contains(command),
    );
  }
}
