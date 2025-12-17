// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory;
import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';

import '../project_generator/git_clone_project_generator.dart';
import '../project_generator/git_worktree_project_generator.dart';
import 'scenario.dart';

void main(List<String> args) async {
  var parsed = argParser.parse(args);
  if (parsed.flag('help')) {
    print(argParser.usage);
    return;
  }
  var scenarioNames = parsed.multiOption('scenario');
  for (var scenario in scenarios) {
    if (scenarioNames.isNotEmpty && !scenarioNames.contains(scenario.name)) {
      continue;
    }
    await scenario.run(Duration(seconds: int.parse(parsed.option('timeout')!)));
  }
}

final analysisServerRoot = Isolate.resolvePackageUriSync(
  Uri.parse('package:analysis_server/'),
)!;

final argParser = ArgParser()
  ..addMultiOption(
    'scenario',
    abbr: 's',
    help: 'The name(s) of specific scenario(s) to run',
    allowed: scenarios.map((s) => s.name).toList(),
  )
  ..addOption(
    'timeout',
    abbr: 't',
    help: 'Number of seconds to wait for analyzer responses',
    defaultsTo: '5',
  )
  ..addFlag('help');

final logsRoot = analysisServerRoot.resolve(
  '../tool/performance/scenarios/logs/',
);

final List<Scenario> scenarios = () {
  var fileSystem = PhysicalResourceProvider.INSTANCE;
  return [
    Scenario(
      name: 'sdk_rename_driver_class',
      logFile: fileSystem.getFile(
        logsRoot.resolve('sdk_rename_driver_class.json').toFilePath(),
      ),
      project: GitWorktreeProjectGenerator(
        Directory.fromUri(sdkRoot),
        'main',
        isSdkRepo: true,
      ),
    ),
    Scenario(
      name: 'initialize',
      logFile: fileSystem.getFile(
        logsRoot.resolve('initialize.json').toFilePath(),
      ),
      project: GitCloneProjectGenerator(
        'https://github.com/dart-lang/tools',
        'main',
      ),
    ),
  ];
}();

final sdkRoot = analysisServerRoot.resolve('../../../');
