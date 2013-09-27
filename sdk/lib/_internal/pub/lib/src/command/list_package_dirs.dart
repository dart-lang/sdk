// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.list_package_dirs;

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as path;

import '../command.dart';
import '../exit_codes.dart' as exit_codes;
import '../io.dart';
import '../log.dart' as log;

/// Handles the `list-package-dirs` pub command.
class ListPackageDirsCommand extends PubCommand {
  String get description => "Print local paths to dependencies.";
  String get usage => "pub list-package-dirs";
  bool get hidden => true;

  ListPackageDirsCommand() {
    commandParser.addOption("format",
        help: "How output should be displayed.",
        allowed: ["json"]);
  }

  Future onRun() {
    if (!entrypoint.lockFileExists) {
      log.error(JSON.encode(
          'Package "myapp" has no lockfile. Please run "pub install" first.'));
      return flushThenExit(exit_codes.NO_INPUT);
    }

    var output = {};

    // Include the local paths to all locked packages.
    var packages = {};
    var futures = [];
    entrypoint.loadLockFile().packages.forEach((name, package) {
      var source = entrypoint.cache.sources[package.source];
      futures.add(source.getDirectory(package).then((packageDir) {
        packages[name] = path.join(packageDir, "lib");
      }));
    });

    output["packages"] = packages;

    // Include the self link.
    packages[entrypoint.root.name] = path.join(entrypoint.root.dir, "lib");

    // Include the file(s) which when modified will affect the results. For pub,
    // that's just the lockfile.
    output["input_files"] = [entrypoint.lockFilePath];

    return Future.wait(futures).then((_) {
      log.message(JSON.encode(output));
    });
  }
}

