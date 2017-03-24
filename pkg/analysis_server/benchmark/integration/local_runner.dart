// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart';

import 'main.dart' as performance;

// Local driver for performance measurement

main(List<String> args) {
  /*
   * Parse arguments
   */
  if (args.length < 3) printHelp('Expected 3 arguments');
  var gitDir = new Directory(args[0]);
  if (!gitDir.existsSync()) printHelp('${gitDir.path} does not exist');
  if (!new Directory(join(gitDir.path, '.git')).existsSync())
    printHelp('${gitDir.path} does not appear to be a local git repository');
  var branch = args[1];
  var inputFile = new File(args[2]);
  if (!inputFile.existsSync()) printHelp('${inputFile.path} does not exist');
  /*
   * Create a new temp directory
   */
  var tmpDir = new Directory(
      join(Directory.systemTemp.path, 'analysis_server_perf_target'));
  if (!tmpDir.path.contains('tmp')) throw 'invalid tmp directory\n  $tmpDir';
  print('Extracting target analysis environment into\n  ${tmpDir.path}');
  if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  tmpDir.createSync(recursive: true);
  /*
   * Setup the initial target source in the temp directory
   */
  var tarFilePath = join(tmpDir.path, 'targetSrc.tar');
  var result = Process.runSync('git', ['archive', branch, '-o', tarFilePath],
      workingDirectory: gitDir.path);
  if (result.exitCode != 0) throw 'failed to obtain target source: $result';
  var tmpSrcDirPath = join(tmpDir.path, 'targetSrc');
  new Directory(tmpSrcDirPath).createSync();
  result = Process.runSync('tar', ['-xf', tarFilePath],
      workingDirectory: tmpSrcDirPath);
  if (result.exitCode != 0) throw 'failed to extract target source: $result';
  /*
   * Symlink the out or xcodebuild directory
   */
  var outDirName = 'out';
  if (!new Directory(join(gitDir.path, outDirName)).existsSync()) {
    outDirName = 'xcodebuild';
  }
  if (!new Directory(join(gitDir.path, outDirName)).existsSync()) {
    throw 'failed to find out or xcodebuild directory';
  }
  result = Process.runSync('ln',
      ['-s', join(gitDir.path, outDirName), join(tmpSrcDirPath, outDirName)]);
  if (result.exitCode != 0) throw 'failed to link out or xcodebuild: $result';
  /*
   * Collect arguments
   */
  var perfArgs = [
    '-i${inputFile.path}',
    '-t$tmpSrcDirPath',
  ];
  for (int index = 3; index < args.length; ++index) {
    perfArgs.add(args[index].replaceAll('@tmpSrcDir@', tmpSrcDirPath));
  }
  perfArgs.add('-m${gitDir.path},$tmpSrcDirPath');
  /*
   * Launch the performance analysis tool
   */
  performance.main(perfArgs);
}

/// Print help and exit
void printHelp([String errMsg]) {
  if (errMsg != null) {
    print('');
    print('Error: $errMsg');
    print('');
  }
  print('''Required arguments: <gitDir> <branch> <inputFile>
gitDir = a path to the git repository containing the initial target source
branch = the branch containing the initial target source
inputFile = the instrumentation or log file

Optional arguments:''');
  print(performance.argParser.usage);
  exit(1);
}
