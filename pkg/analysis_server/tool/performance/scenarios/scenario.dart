// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

import '../../log_player/log.dart';
import '../../log_player/log_player.dart';
import '../../log_player/server_driver.dart';
import '../project_generator/project_generator.dart';

/// A [Scenario] represents a combination of a [project], a [logFile], and a
/// [serverProtocol] which can be used to reproduce specific set of actions
/// against a codebase.
class Scenario {
  final File logFile;
  final ProjectGenerator project;
  final ServerProtocol serverProtocol;

  Scenario({
    required this.logFile,
    required this.project,
    required this.serverProtocol,
  });

  Future<void> run() async {
    var watch = Stopwatch()..start();
    void log(String message) {
      print('${watch.elapsed}: $message');
    }

    log('Initializing scenario for project: ${project.description}');

    log('Reading logs');
    var logs = Log.fromFile(logFile);

    log('Starting analysis server');
    var server = ServerDriver(protocol: serverProtocol);
    await server.start();

    log('Creating log player');
    var logPlayer = LogPlayer(log: logs, server: server);

    log('Setting up project');
    var projectDir = await project.setUp();
    log('Scenario initialized with project at ${projectDir.path}');

    try {
      var scenarioWatch = Stopwatch()..start();
      log('Replaying scenario');
      await logPlayer.play();
      log('Scenario completed, took ${scenarioWatch.elapsed} to replay');
    } catch (e, s) {
      print('''
Scenario failed with Error: $e

StackTrace:
$s
''');
    } finally {
      log('Tearing down scenario for project');
      await project.tearDown(projectDir);
      server.exit();
      log('Scenario cleaned up');
    }
  }
}
