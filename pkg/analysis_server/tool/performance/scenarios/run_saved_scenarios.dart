// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory;
import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';

import '../project_generator/git_clone_project_generator.dart';
import '../project_generator/git_worktree_project_generator.dart';
import 'scenario.dart';

void main() async {
  for (var scenario in await scenarios()) {
    await scenario.run();
  }
}

final analysisServerRoot = Isolate.resolvePackageUriSync(
  Uri.parse('package:analysis_server/'),
)!;

final logsRoot = analysisServerRoot.resolve(
  '../tool/performance/scenarios/logs/',
);

final sdkRoot = analysisServerRoot.resolve('../../');

Future<List<Scenario>> scenarios() async {
  var fileSystem = PhysicalResourceProvider.INSTANCE;
  return [
    Scenario(
      logFile: fileSystem.getFile(
        logsRoot.resolve('sdk_rename_driver_class.json').toFilePath(),
      ),
      project: GitWorktreeProjectGenerator(Directory.fromUri(sdkRoot), 'main'),
    ),
    Scenario(
      logFile: fileSystem.getFile(
        logsRoot.resolve('initialize.json').toFilePath(),
      ),
      project: GitCloneProjectGenerator(
        'https://github.com/dart-lang/tools',
        'main',
      ),
    ),
  ];
}
