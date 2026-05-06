// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/servers/devtools.dart';
import 'package:dwds/src/services/expression_compiler.dart';

/// Configuration about the app, debug settings, and file system.
///
/// This is set by the code runner and passed to DWDS on start up.
class ToolConfiguration {
  final LoadStrategy loadStrategy;
  final DebugSettings debugSettings;
  final AppMetadata appMetadata;

  const ToolConfiguration({
    required this.loadStrategy,
    required this.debugSettings,
    required this.appMetadata,
  });
}

/// The tool configuration for the connected app.
///
/// TODO(elliette): Consider making this final (would require updating tests
/// that currently depend on changing the configuration between test cases).
late ToolConfiguration _globalToolConfiguration;
set globalToolConfiguration(ToolConfiguration configuration) =>
    _globalToolConfiguration = configuration;
ToolConfiguration get globalToolConfiguration => _globalToolConfiguration;

/// Metadata for the connected app.
///
/// These are set by the code runner and passed to DWDS on start up.
class AppMetadata {
  final String hostname;
  final bool isInternalBuild;
  final String? workspaceName;
  final String? codeRunner;

  const AppMetadata({
    this.hostname = 'localhost',
    this.isInternalBuild = false,
    this.workspaceName,
    this.codeRunner,
  });
}

typedef UrlEncoder = Future<String> Function(String url);

typedef DevToolsLauncher = Future<DevTools> Function(String hostname);

class DartDevelopmentServiceConfiguration {
  const DartDevelopmentServiceConfiguration({
    this.enable = true,
    this.port,
    this.serveDevTools = true,
    this.devToolsServerAddress,
    this.appName,
    this.dartExecutable,
  });

  final bool enable;
  final int? port;
  final bool serveDevTools;
  final Uri? devToolsServerAddress;
  final String? appName;
  final String? dartExecutable;
}

/// Debug settings for the connected app.
///
/// These are set by the code runner and passed to DWDS on start up.
class DebugSettings {
  final bool enableDebugging;
  final bool enableDebugExtension;
  final bool useSseForDebugProxy;
  final bool useSseForDebugBackend;
  final bool useSseForInjectedClient;

  @Deprecated('Use ddsConfiguration instead.')
  final bool spawnDds;
  @Deprecated('Use ddsConfiguration instead.')
  final int? ddsPort;
  final bool enableDevToolsLaunch;
  final bool launchDevToolsInNewWindow;
  final bool emitDebugEvents;
  @Deprecated(
    'Use ddsConfigurationInstead. DevTools will eventually only be '
    'served via DDS.',
  )
  final DevToolsLauncher? devToolsLauncher;
  final ExpressionCompiler? expressionCompiler;
  final UrlEncoder? urlEncoder;
  final DartDevelopmentServiceConfiguration ddsConfiguration;
  final Duration? sseIgnoreDisconnect;

  const DebugSettings({
    this.enableDebugging = true,
    this.enableDebugExtension = false,
    this.useSseForDebugProxy = true,
    this.useSseForDebugBackend = true,
    this.useSseForInjectedClient = true,
    @Deprecated('Use ddsConfiguration instead.') this.spawnDds = true,
    @Deprecated('Use ddsConfiguration instead.') this.ddsPort,
    this.enableDevToolsLaunch = true,
    this.launchDevToolsInNewWindow = true,
    this.emitDebugEvents = true,
    @Deprecated(
      'Use ddsConfigurationInstead. DevTools will eventually only be '
      'served via DDS.',
    )
    this.devToolsLauncher,
    this.expressionCompiler,
    this.urlEncoder,
    this.ddsConfiguration = const DartDevelopmentServiceConfiguration(),
    this.sseIgnoreDisconnect,
  });
}
