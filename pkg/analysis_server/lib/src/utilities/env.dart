// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:platform/platform.dart' as platform;
import 'package:unified_analytics/unified_analytics.dart';

DashTool? get topLevelTool {
  var toolValue = _readEnv(DashEnvVar.tool.name);
  if (toolValue != null) {
    try {
      return DashTool.fromLabel(toolValue);
    } on Exception {
      // Unsupported tools are skipped.
      // We could consider logging or crash-reporting but we can't collect
      // analytics since telemetry for an unknown tool can't be opted into.
    }
  }
  return null;
}

Map<String, String> get _locaEnvironment =>
    const platform.LocalPlatform().environment;

/// Returns a copy of the current environment with the given analytics values set.
Map<String, String> map({
  required DashTool? tool,
  required bool suppressAnalytics,
}) => <String, String>{
  ..._locaEnvironment,
  DashEnvVar.suppressAnalytics.name: suppressAnalytics.toString(),
  if (tool != null) DashEnvVar.tool.name: tool.label,
};

String? _readEnv(String key) => _locaEnvironment[key];
