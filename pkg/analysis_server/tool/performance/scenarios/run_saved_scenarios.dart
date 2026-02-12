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
    defaultsTo: '30',
  )
  ..addFlag('help');

final logsRoot = analysisServerRoot.resolve(
  '../tool/performance/scenarios/logs/',
);

final List<Scenario> scenarios = () {
  var fileSystem = PhysicalResourceProvider.INSTANCE;
  return [
    Scenario(
      name: 'project_pigeon_format_generated_file',
      logFile: fileSystem.getFile(
        logsRoot
            .resolve('project_pigeon_format_generated_file.json')
            .toFilePath(),
      ),
      project: GitCloneProjectGenerator(
        'https://github.com/flutter/packages.git',
        '3c06856b09811617ee2d159953d980c286f8529b',
        openSubdirs: ['packages/pigeon'],
      ),
    ),
    Scenario(
      name: 'sdk_rename_driver_class',
      logFile: fileSystem.getFile(
        logsRoot.resolve('sdk_rename_driver_class.json').toFilePath(),
      ),
      project: GitWorktreeProjectGenerator(
        Directory.fromUri(sdkRoot),
        'ca7fdb162f13d8ae15d11a1a4d6357ecbdf6e70e',
        isSdkRepo: true,
        openSubdirs: ['pkg/analysis_server'],
      ),
    ),
    Scenario(
      name: 'package_build_find_references',
      logFile: fileSystem.getFile(
        logsRoot.resolve('package_build_find_references.json').toFilePath(),
      ),
      project: GitCloneProjectGenerator(
        'https://github.com/dart-lang/build',
        '9b97ea08021ee68947873bcdd4a550c0feb393a4',
      ),
    ),
    Scenario(
      name: 'cory_devtoolscompanion_test',
      logFile: fileSystem.getFile(
        logsRoot.resolve('DAS-test1-norm.json').toFilePath(),
      ),
      project: GitCloneProjectGenerator(
        'https://github.com/elliette/devtools_companion',
        '6c1673d7024f58776b2db67f2f1ecf5ad1aacaa0',
      ),
    ),
  ];
}();

final sdkRoot = analysisServerRoot.resolve('../../../');
