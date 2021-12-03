// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Process, ProcessResult;

import 'package:testing/testing.dart' show Chain, TestDescription;

Stream<TestDescription> filterList(
    Chain suite, bool onlyInGit, Stream<TestDescription> base) async* {
  Set<Uri>? gitFiles;
  if (onlyInGit) {
    gitFiles = await getGitFiles(suite.uri);
  }
  await for (TestDescription description in base) {
    if (onlyInGit && !gitFiles!.contains(description.uri)) {
      continue;
    }
    yield description;
  }
}

Future<Set<Uri>> getGitFiles(Uri uri) async {
  ProcessResult result = await Process.run("git", ["ls-files", "."],
      workingDirectory: new Directory.fromUri(uri).absolute.path,
      runInShell: true);
  if (result.exitCode != 0) {
    throw "Git returned non-zero error code (${result.exitCode}):\n\n"
        "stdout: ${result.stdout}\n\n"
        "stderr: ${result.stderr}";
  }
  String stdout = result.stdout;
  return stdout
      .split(new RegExp('^', multiLine: true))
      .map((line) => uri.resolve(line.trimRight()))
      .toSet();
}

void checkEnvironment(
    Map<String, String> environment, Set<String> knownEnvironmentKeys) {
  Set<String> environmentKeys = environment.keys.toSet();
  environmentKeys.removeAll(knownEnvironmentKeys);
  if (environmentKeys.isNotEmpty) {
    throw "Unknown environment(s) given:"
        "\n - ${environmentKeys.join("\n- ")}\n"
        "Knows about these environment(s):"
        "\n - ${knownEnvironmentKeys.join("\n - ")}";
  }
}
