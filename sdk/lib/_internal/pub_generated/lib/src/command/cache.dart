// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache;

import '../command.dart';
import 'cache_add.dart';
import 'cache_list.dart';
import 'cache_repair.dart';

/// Handles the `cache` pub command.
class CacheCommand extends PubCommand {
  String get description => "Work with the system cache.";
  String get usage => "pub cache <subcommand>";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";

  final subcommands = {
    "add": new CacheAddCommand(),
    "list": new CacheListCommand(),
    "repair": new CacheRepairCommand()
  };
}
