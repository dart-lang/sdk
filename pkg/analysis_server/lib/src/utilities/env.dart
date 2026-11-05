// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:platform/platform.dart' as platform;
import 'package:unified_analytics/unified_analytics.dart';

/// The name of the AI coding agent running the analysis server, if any.
///
/// Detected from the environment using [AiAgent.detectAgentName].
String? get aiAgent => AiAgent.detectAgentName(_locaEnvironment);

Map<String, String> get _locaEnvironment =>
    // TODO(natebosch): bump dependency after package rollout is settled.
    // platform.NativePlatform.current!.environment;
    // ignore: deprecated_member_use
    const platform.LocalPlatform().environment;

/// Returns the [DashTool] for the IDE identified by [clientId], or `null` if
/// [clientId] doesn't identify a known IDE.
///
/// This is passed to `Analytics` as the `fallbackRootTool`, so that IDE
/// plugins that don't set the `DASH__TOOL` environment variable still report
/// analytics under the IDE that started the analysis server.
DashTool? fallbackRootToolForClientId(String? clientId) => switch (clientId) {
  'VS-Code' || 'VS-Code-Remote' => DashTool.vscodePlugins,
  'IntelliJ-IDEA' => DashTool.intellijPlugins,
  'Android-Studio' => DashTool.androidStudioPlugins,
  _ => null,
};
