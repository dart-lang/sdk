// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A custom entrypoint used by `dart mcp-server`. Injects an analytics instance
/// using the [DashTool.dartTool] tool.
library;

import 'dart:io';

import 'package:dart_mcp_server/dart_mcp_server.dart';
import 'package:unified_analytics/unified_analytics.dart';

void main(List<String> args) async {
  DashTool? tool;
  if (Platform.environment['DASH__TOOL'] case final toolEnv?) {
    try {
      tool = DashTool.fromLabel(toolEnv);
    } catch (e) {
      // Ignore errors, but don't track analytics for unrecognized tools.
    }
  } else {
    // We default to the `dart` tool if none specified.
    tool = DashTool.dartTool;
  }

  final analytics = tool != null
      ? Analytics(
          tool: tool,
          // The actual version is the part up to the first space.
          dartVersion: Platform.version.split(' ').first,
        )
      : null;

  exitCode = await DartMCPServer.run(args, analytics: analytics);
}
