// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, FileSystemEntity, Process, ProcessResult;

import 'package:testing/testing.dart' show Chain, TestDescription;

Future<List<TestDescription>> filterList(
    Chain suite, bool onlyInGit, List<TestDescription> base) async {
  Set<Uri> gitFiles = {};
  if (onlyInGit) {
    for (Uri subRoot in suite.subRoots) {
      gitFiles.addAll(await getGitFiles(subRoot));
    }
  }
  List<TestDescription> result = [];
  for (TestDescription description in base) {
    if (onlyInGit && !gitFiles.contains(description.uri)) {
      continue;
    }
    result.add(description);
  }
  return result;
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

Future<List<Uri>> computeSourceFiles(Uri repoDir) async {
  Set<Uri> libUris = {};
  libUris.add(repoDir.resolve("pkg/front_end/lib/"));
  libUris.add(repoDir.resolve("pkg/front_end/test/"));
  libUris.add(repoDir.resolve("pkg/front_end/tool/"));

  List<String> dataDirectories = [
    'pkg/front_end/test/class_hierarchy/data/',
    'pkg/front_end/test/extensions/data/',
    'pkg/front_end/test/id_testing/data/',
    'pkg/front_end/test/language_versioning/data/',
    'pkg/front_end/test/macros/application/data/',
    'pkg/front_end/test/macros/declaration/data/',
    'pkg/front_end/test/macros/incremental/data/',
    'pkg/front_end/test/patching/data/',
    'pkg/front_end/test/scopes/data/',
    'pkg/front_end/test/static_types/data/',
  ];

  List<Uri> inputs = [];
  for (Uri uri in libUris) {
    Set<Uri> gitFiles = await getGitFiles(uri);
    List<FileSystemEntity> entities =
        new Directory.fromUri(uri).listSync(recursive: true);
    for (FileSystemEntity entity in entities) {
      if (entity is File &&
          entity.path.endsWith(".dart") &&
          gitFiles.contains(entity.uri)) {
        if (dataDirectories
            .any((exclude) => entity.uri.path.contains(exclude))) {
          continue;
        }
        inputs.add(entity.uri);
      }
    }
  }
  return inputs;
}
