// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:cli_util/cli_util.dart';

import '../../log_player/log.dart';
import '../../log_player/log_player.dart';
import '../project_generator/project_generator.dart';

/// A [Scenario] represents a combination of a [project] and a [logFile] to
/// replay in that project.
class Scenario {
  /// Can be used on the command line to select this scenario.
  ///
  /// Should be lowercase with underscores and no spaces.
  final String name;

  /// The log file to replay for this scenario.
  final File logFile;

  /// Handles project setup.
  final ProjectGenerator project;

  new({required this.name, required this.logFile, required this.project});

  Future<void> run(Duration timeout, {bool verbose = false}) async {
    var watch = Stopwatch()..start();
    await runZoned(
      () => _run(timeout, verbose: verbose),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) =>
            stdout.writeln('${watch.elapsed}: $message'),
      ),
    );
  }

  Future<void> _run(Duration timeout, {bool verbose = false}) async {
    print('Initializing scenario for project: ${project.description}');

    print('Setting up project');
    var workspace = await project.setUp();
    late StreamSubscription<ProcessSignal> exitListener;
    exitListener = ProcessSignal.sigint.watch().listen((_) async {
      print('cleaning up project for clean exit... hit ctrl+c again to force');
      unawaited(exitListener.cancel());
      await project.tearDown(workspace);
      exit(1);
    });

    // Set up the normalizer that will be used to reverse the normalization.
    var normalizer = LogNormalizer();
    normalizer.addReplacementsForPath(sdkPath, 'dartSdkRoot');
    // TODO(somebody): replace {{flutterSdkRoot}} with the flutter SDK path
    for (var i = 0; i < workspace.workspaceDirectories.length; i++) {
      normalizer.addReplacementsForPath(
        workspace.workspaceDirectories.elementAt(i).path,
        'workspaceFolder-$i',
      );
    }
    for (var i = 0; i < workspace.contextRoots.length; i++) {
      for (var package in workspace.contextRoots[i].packageConfig.packages) {
        normalizer.addReplacementsForUri(
          package.root,
          'context-$i:package-root:${package.name}',
        );
      }
    }

    print('Reading logs');
    Log? logs;
    try {
      logs = Log.fromFile(logFile, normalizer.denormalize);
    } catch (e, s) {
      print('''
Scenario failed with Error: $e

StackTrace:
$s
''');
      exit(1);
    }
    print('Creating log player');
    var logPlayer = LogPlayer(log: logs, timeout: timeout, verbose: verbose);

    print(
      'Scenario initialized with workpace dirs:\n'
      '${workspace.workspaceDirectories.map((dir) => '  - ${dir.path}').join('\n')}',
    );
    try {
      var scenarioWatch = Stopwatch()..start();
      print('Replaying scenario');
      await logPlayer.play();
      print('Scenario completed, took ${scenarioWatch.elapsed} to replay');
    } catch (e, s) {
      print('''
Scenario failed with Error: $e

StackTrace:
$s
''');
    } finally {
      print('Tearing down scenario for project');
      await project.tearDown(workspace);
      await exitListener.cancel();
      print('Scenario cleaned up');
    }
  }
}
