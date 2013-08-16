// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.list_package_dirs;

import 'dart:async';
import 'dart:io';
import 'dart:json' as json;

import '../command.dart';
import '../exit_codes.dart' as exit_codes;
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
      log.error(json.stringify(
          'Package "myapp" has no lockfile. Please run "pub install" first.'));
      exit(exit_codes.NO_INPUT);
    }

    var output = {};
    var futures = [];
    entrypoint.loadLockFile().packages.forEach((name, package) {
      var source = entrypoint.cache.sources[package.source];
      futures.add(source.getDirectory(package).then((packageDir) {
        output[name] = packageDir;
      }));
    });

    return Future.wait(futures).then((_) {
      log.message(json.stringify(output));
    });
  }
}

