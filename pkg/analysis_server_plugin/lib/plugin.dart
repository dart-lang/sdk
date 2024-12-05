// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/registry.dart';

abstract class Plugin {
  FutureOr<void> register(PluginRegistry registry);

  FutureOr<void> shutDown() {}

  FutureOr<void> start() {}
}
