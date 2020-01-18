// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/src/driver.dart';

/// An object that can be used to start an analysis server plugin. This class
/// exists so that clients can configure a plugin before starting it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ServerPluginStarter {
  /// Create a starter that can be used to start the given [plugin].
  factory ServerPluginStarter(ServerPlugin plugin) => Driver(plugin);

  /// Establish the channel used to communicate with the server and start the
  /// plugin.
  void start(SendPort sendPort);
}
