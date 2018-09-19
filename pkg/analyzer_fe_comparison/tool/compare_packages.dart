// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer_fe_comparison/comparison.dart';
import 'package:path/path.dart' as path;

/// Compares the analyzer and front_end behavior when compiling a package.
///
/// Currently hardcoded to use the package "analyzer".
main() async {
  var scriptPath = Platform.script.toFilePath();
  var sdkRepoPath =
      path.normalize(path.join(path.dirname(scriptPath), '..', '..', '..'));
  var buildPath = await _findBuildDir(sdkRepoPath, 'ReleaseX64');
  var dillPath = path.join(buildPath, 'vm_platform_strong.dill');
  var analyzerLibPath = path.join(sdkRepoPath, 'pkg', 'analyzer', 'lib');
  var packagesFilePath = path.join(sdkRepoPath, '.packages');
  comparePackages(dillPath, analyzerLibPath, packagesFilePath);
}

Future<String> _findBuildDir(String sdkRepoPath, String targetName) async {
  for (var subdirName in ['out', 'xcodebuild']) {
    var candidatePath = path.join(sdkRepoPath, subdirName, targetName);
    if (await new Directory(candidatePath).exists()) {
      return candidatePath;
    }
  }
  throw new StateError('Cannot find build directory');
}
