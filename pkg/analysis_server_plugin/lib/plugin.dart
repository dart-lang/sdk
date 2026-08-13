// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server_plugin/src/plugin_server.dart';
library;

import 'dart:async';

import 'package:analysis_server_plugin/registry.dart';

abstract class Plugin {
  /// A user-visible name for this plugin, used for error-reporting and
  /// insights-reporting purposes.
  String get name;

  /// Registers analysis rules, quick fixes, and assists.
  FutureOr<void> register(PluginRegistry registry);

  FutureOr<void> shutDown() {}

  /// Initializes any necessary start-up state that is required for this plugin
  /// to run.
  ///
  /// This is called once by the plugin server, in [PluginServer.initialize],
  /// per analysis context.
  FutureOr<void> start() {}
}
