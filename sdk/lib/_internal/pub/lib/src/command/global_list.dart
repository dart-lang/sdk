// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.global_list;

import 'dart:async';

import '../command.dart';

/// Handles the `global list` pub command.
class GlobalListCommand extends PubCommand {
  bool get allowTrailingOptions => false;
  String get description => 'List globally activated packages.';
  String get usage => 'pub global list';

  Future onRun() {
    globals.listActivePackages();
    return null;
  }
}
