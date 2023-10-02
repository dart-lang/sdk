// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform, Process, ProcessResult;

import 'package:_fe_analyzer_shared/src/util/filenames.dart';

String computeRepoDir() {
  Uri uri;
  if (Platform.script.hasAbsolutePath) {
    uri = Platform.script;
  } else if (Platform.packageConfig != null) {
    String packageConfig = Platform.packageConfig!;
    final String prefix = "file://";
    if (packageConfig.startsWith(prefix)) {
      uri = Uri.parse(packageConfig);
    } else {
      uri = Uri.base.resolve(nativeToUriPath(packageConfig));
    }
  } else {
    throw "Can't obtain the path to the SDK either via "
        "Platform.script or Platform.packageConfig";
  }
  String path = new File.fromUri(uri).parent.path;
  ProcessResult result = Process.runSync(
      'git', ['rev-parse', '--show-toplevel'],
      runInShell: true, workingDirectory: path);
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
