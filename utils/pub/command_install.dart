// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_install;

import 'entrypoint.dart';
import 'pub.dart';

/** Handles the `install` pub command. */
class InstallCommand extends PubCommand {
  String get description => "install the current package's dependencies";
  String get usage => "pub install";

  Future onRun() {
    return entrypoint.installDependencies().transform((_) {
      print("Dependencies installed!");
    });
  }
}
