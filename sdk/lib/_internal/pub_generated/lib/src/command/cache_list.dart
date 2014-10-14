// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command.cache_list;

import 'dart:async';
import 'dart:convert';

import '../command.dart';
import '../log.dart' as log;
import '../source/cached.dart';

/// Handles the `cache list` pub command.
class CacheListCommand extends PubCommand {
  String get description => "List packages in the system cache.";
  String get usage => "pub cache list";
  bool get hidden => true;

  Future onRun() {
    // TODO(keertip): Add flag to list packages from non default sources.
    var packagesObj = <String, Map>{};

    var source = cache.sources.defaultSource as CachedSource;
    for (var package in source.getCachedPackages()) {
      var packageInfo = packagesObj.putIfAbsent(package.name, () => {});
      packageInfo[package.version.toString()] = {
        'location': package.dir
      };
    }

    // TODO(keertip): Add support for non-JSON format and check for --format
    // flag.
    log.message(JSON.encode({
      'packages': packagesObj
    }));
    return null;
  }
}
