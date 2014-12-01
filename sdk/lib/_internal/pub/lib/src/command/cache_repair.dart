// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache_repair;

import 'dart:async';

import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;
import '../source/cached.dart';
import '../utils.dart';

/// Handles the `cache repair` pub command.
class CacheRepairCommand extends PubCommand {
  String get description => "Reinstall cached packages.";
  String get usage => "pub cache repair";
  String get docUrl => "http://dartlang.org/tools/pub/cmd/pub-cache.html";

  Future onRun() async {
    var successes = 0;
    var failures = 0;

    // Repair every cached source.
    for (var source in cache.sources) {
      if (source is! CachedSource) continue;

      var results = await source.repairCachedPackages();
      successes += results.first;
      failures += results.last;
    }

    if (successes > 0) {
      var packages = pluralize("package", successes);
      log.message("Reinstalled ${log.green(successes)} $packages.");
    }

    if (failures > 0) {
      var packages = pluralize("package", failures);
      log.message("Failed to reinstall ${log.red(failures)} $packages.");
    }

    var results = await globals.repairActivatedPackages();
    if (results.first > 0) {
      var packages = pluralize("package", results.first);
      log.message("Reactivated ${log.green(results.first)} $packages.");
    }

    if (results.last > 0) {
      var packages = pluralize("package", results.last);
      log.message("Failed to reactivate ${log.red(results.last)} $packages.");
    }

    if (successes == 0 && failures == 0) {
      log.message("No packages in cache, so nothing to repair.");
    }

    if (failures > 0) await flushThenExit(exit_codes.UNAVAILABLE);
  }
}
