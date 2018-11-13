// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer_fe_comparison/comparison.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Compares the analyzer and front_end behavior when compiling a program.
main(List<String> args) async {
  ArgResults options = _parseArgs(args);
  var sourcePaths = options.rest;
  if (sourcePaths.length != 1) {
    throw new StateError('Exactly one source file must be specified.');
  }
  var sourcePath = sourcePaths[0];
  var scriptPath = Platform.script.toFilePath();
  var sdkRepoPath =
      path.normalize(path.join(path.dirname(scriptPath), '..', '..', '..'));
  var buildPath = await _findBuildDir(sdkRepoPath, 'ReleaseX64');
  var dillPath = path.join(buildPath, 'vm_platform_strong.dill');
  var packagesFilePath = path.join(sdkRepoPath, '.packages');

  await compareTestPrograms(sourcePath, dillPath, packagesFilePath);
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

ArgResults _parseArgs(List<String> args) {
  var parser = new ArgParser(allowTrailingOptions: true);
  parser.addOption('dart-sdk', help: 'The path to the Dart SDK.');
  if (args.contains('--ignore-unrecognized-flags')) {
    args = filterUnknownArguments(args, parser);
  }
  return parser.parse(args);
}
