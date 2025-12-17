// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as p;

import '../../log_player/log.dart';
import '../../log_player/log_player.dart';
import '../project_generator/project_generator.dart';

final dartSdkRoot = p.dirname(p.dirname(Platform.resolvedExecutable));

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

  Scenario({required this.name, required this.logFile, required this.project});

  Future<void> run(Duration timeout) async {
    var watch = Stopwatch()..start();
    await runZoned(
      () => _run(timeout),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) =>
            stdout.writeln('${watch.elapsed}: $message'),
      ),
    );
  }

  Future<void> _run(Duration timeout) async {
    print('Initializing scenario for project: ${project.description}');

    print('Setting up project');
    var projectDirs = await project.setUp();

    print('Reading logs');
    var logs = Log.fromFile(logFile, {
      for (var i = 0; i < projectDirs.length; i++)
        '{{workspaceFolder-$i}}': projectDirs.elementAt(i).path,
      '{{dartSdkRoot}}': dartSdkRoot,
    });

    print('Creating log player');
    var logPlayer = LogPlayer(log: logs, timeout: timeout);

    print(
      'Scenario initialized with workpace dirs:\n'
      '${projectDirs.map((dir) => '  - ${dir.path}').join('\n')}',
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
      await project.tearDown(projectDirs);
      print('Scenario cleaned up');
    }
  }
}
