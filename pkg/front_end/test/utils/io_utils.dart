// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.9

import 'dart:io' show Directory, File, Platform, Process, ProcessResult;

String computeRepoDir() {
  ProcessResult result = Process.runSync(
      'git', ['rev-parse', '--show-toplevel'],
      runInShell: true,
      workingDirectory: new File.fromUri(Platform.script).parent.path);
  if (result.exitCode != 0) {
    throw "Git returned non-zero error code (${result.exitCode}):\n\n"
        "stdout: ${result.stdout}\n\n"
        "stderr: ${result.stderr}";
  }
  String dirPath = (result.stdout as String).trim();
  if (!new Directory(dirPath).existsSync()) {
    throw "The path returned by git ($dirPath) does not actually exist.";
  }
  return dirPath;
}

Uri computeRepoDirUri() {
  String dirPath = computeRepoDir();
  return new Directory(dirPath).uri;
}
