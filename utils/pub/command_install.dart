// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_install;

import 'dart:async';

import 'entrypoint.dart';
import 'log.dart' as log;
import 'pub.dart';

/// Handles the `install` pub command. 
class InstallCommand extends PubCommand {
  String get description => "Install the current package's dependencies.";
  String get usage => "pub install";

  Future onRun() {
    return entrypoint.installDependencies().then((_) {
      log.message("Dependencies installed!");
    });
  }
}
