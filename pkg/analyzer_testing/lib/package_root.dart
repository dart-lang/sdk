// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Returns a path to the directory containing source code for packages such as
/// kernel, front_end, and analyzer.
String get packageRoot {
  // If the package root directory is specified on the command line using
  // `-DpkgRoot=...`, use that.
  const pkgRootVar = bool.hasEnvironment('pkgRoot')
      ? String.fromEnvironment('pkgRoot')
      : null;
  if (pkgRootVar != null) {
    var pkgRootPath = path.join(Directory.current.path, pkgRootVar);
    if (!pkgRootPath.endsWith(path.separator)) pkgRootPath += path.separator;
    return pkgRootPath;
  }
  // Otherwise try to guess based on the script path.
  var scriptPath = path.fromUri(Platform.script);
  var pathFromScript = _tryGetPkgRoot(scriptPath);
  if (pathFromScript != null) {
    return pathFromScript;
  }

  // Try a Bazel environment. We expect that all packages that will be
  // accessed via this root are configured in the BUILD file, and located
  // inside this single root.
  var runFiles = Platform.environment['TEST_SRCDIR'];
  var analyzerPackagesRoot = Platform.environment['ANALYZER_PACKAGES_ROOT'];
  if (runFiles != null && analyzerPackagesRoot != null) {
    return path.join(runFiles, analyzerPackagesRoot);
  }

  // Finally, try the current working directory.
  var pathFromCwd = _tryGetPkgRoot(Directory.current.path);
  if (pathFromCwd != null) {
    return pathFromCwd;
  }

  throw StateError('Unable to find sdk/pkg/ in $scriptPath');
}

/// Tries to find the path to the 'pkg' folder from [searchPath].
String? _tryGetPkgRoot(String searchPath) {
  var parts = path.split(searchPath);
  var pkgIndex = parts.indexOf('pkg');
  if (pkgIndex != -1) {
    return path.joinAll(parts.sublist(0, pkgIndex + 1)) + path.separator;
  }
  return null;
}
