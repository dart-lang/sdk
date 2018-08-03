// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as pathos;

/// Returns a path to the directory contaning source code for packages such as
/// kernel, front_end, and analyzer.
String get packageRoot {
  // If the package root directory is specified on the command line using
  // -DpkgRoot=..., use it.
  var pkgRootVar = const String.fromEnvironment('pkgRoot');
  if (pkgRootVar != null) {
    var path = pathos.join(Directory.current.path, pkgRootVar);
    if (!path.endsWith(pathos.separator)) path += pathos.separator;
    return path;
  }
  // Otherwise try to guess based on the script path.
  String scriptPath = pathos.fromUri(Platform.script);
  List<String> parts = pathos.split(scriptPath);
  int pkgIndex = parts.indexOf('pkg');
  if (pkgIndex != -1) {
    return pathos.joinAll(parts.sublist(0, pkgIndex + 1)) + pathos.separator;
  }
  throw new StateError('Unable to find sdk/pkg/ in $scriptPath');
}
