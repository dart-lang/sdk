// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as pathos;

/// Returns a path to the directory containing source code for packages such as
/// kernel, front_end, and analyzer.
String get packageRoot {
  // If the package root directory is specified on the command line using
  // -DpkgRoot=..., use it.
  const pkgRootVar =
      bool.hasEnvironment('pkgRoot') ? String.fromEnvironment('pkgRoot') : null;
  if (pkgRootVar != null) {
    var path = pathos.join(Directory.current.path, pkgRootVar);
    if (!path.endsWith(pathos.separator)) path += pathos.separator;
    return path;
  }
  // Otherwise try to guess based on the script path.
  var scriptPath = pathos.fromUri(Platform.script);
  var pathFromScript = _tryGetPkgRoot(scriptPath);
  if (pathFromScript != null) {
    return pathFromScript;
  }

  // Try google3 environment. We expect that all packages that will be
  // accessed via this root are configured in the BUILD file, and located
  // inside this single root.
  final runFiles = Platform.environment['RUNFILES'];
  final analyzerPackagesRoot = Platform.environment['ANALYZER_PACKAGES_ROOT'];
  if (runFiles != null && analyzerPackagesRoot != null) {
    return pathos.join(runFiles, analyzerPackagesRoot);
  }

  // Finally, try the current working directory.
  var pathFromCwd = _tryGetPkgRoot(Directory.current.path);
  if (pathFromCwd != null) {
    return pathFromCwd;
  }

  throw StateError('Unable to find sdk/pkg/ in $scriptPath');
}

/// Try to find the path to the pkg folder from [path].
String? _tryGetPkgRoot(String path) {
  var parts = pathos.split(path);
  var pkgIndex = parts.indexOf('pkg');
  if (pkgIndex != -1) {
    return pathos.joinAll(parts.sublist(0, pkgIndex + 1)) + pathos.separator;
  }
  return null;
}
