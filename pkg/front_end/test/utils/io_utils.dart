// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:io' show Directory, File, Platform, Process, ProcessResult;

String computeRepoDir() {
  ProcessResult result = Process.runSync(
      'git', ['rev-parse', '--show-toplevel'],
      runInShell: true,
      workingDirectory: new File.fromUri(Platform.script).parent.path);
  return (result.stdout as String).trim();
}

Uri computeRepoDirUri() {
  String dirPath = computeRepoDir();
  return new Directory(dirPath).uri;
}
