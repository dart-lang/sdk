// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.version;

import 'dart:async';

import '../command.dart';
import '../log.dart' as log;
import '../sdk.dart' as sdk;

/// Handles the `version` pub command.
class VersionCommand extends PubCommand {
  String get description => "Print pub version.";
  String get usage => "pub version";

  Future onRun() {
    log.message("Pub ${sdk.version}");
    return null;
  }
}
