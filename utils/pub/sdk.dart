// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Operations relative to the user's installed Dart SDK.
library sdk;

import 'dart:io';

import '../../pkg/path/lib/path.dart' as path;
import 'log.dart' as log;
import 'version.dart';

/// Gets the path to the root directory of the SDK.
String get rootDirectory {
  // If the environment variable was provided, use it. This is mainly used for
  // the pub tests.
  var dir = Platform.environment["DART_SDK"];
  if (dir != null) {
    log.fine("Using DART_SDK to find SDK at $dir");
    return dir;
  }

  var pubDir = path.dirname(new Options().script);
  dir = path.normalize(path.join(pubDir, "../../"));
  log.fine("Located SDK at $dir");
  return dir;
}

/// Gets the SDK's revision number formatted to be a semantic version.
Version version = _getVersion();

/// Determine the SDK revision number.
Version _getVersion() {
  var revisionPath = path.join(rootDirectory, "revision");
  var revision = new File(revisionPath).readAsStringSync();
  return new Version.parse("0.0.0-r.${revision.trim()}");
}