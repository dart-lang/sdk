// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_cache;

import 'dart:async';
import 'dart:io';
import 'dart:json' as json;

import 'exit_codes.dart' as exit_codes;
import 'log.dart' as log;
import 'pub.dart';


/// Handles the `cache` pub command.
class CacheCommand extends PubCommand {
  String get description => "Inspect the system cache.";
  String get usage => 'pub cache list';
  bool get requiresEntrypoint => false;

  Future onRun() {
    if (commandOptions.rest.length != 1) {
      log.error('The cache command expects one argument.');
      this.printUsage();
      exit(exit_codes.USAGE);
    }

    if ((commandOptions.rest[0] != 'list')) {
      log.error('Unknown cache command "${commandOptions.rest[0]}".');
      this.printUsage();
      exit(exit_codes.USAGE);
    }

    // TODO(keertip): Add flag to list packages from non default sources
    var packagesObj = <String, Map>{};
    for (var package in cache.sources.defaultSource.getCachedPackages()) {
      packagesObj[package.name] = {
        'version': package.version.toString(),
        'location': package.dir
      };
    }

    // TODO(keertip): Add support for non-JSON format
    // and check for --format flag
    log.message(json.stringify({'packages': packagesObj}));
  }
}

