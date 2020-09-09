// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:meta/meta.dart';

import '../core.dart';
import '../events.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

/// Implement `dart test`.
///
/// This command largely delegates to `pub run test`.
class TestCommand extends DartdevCommand<int> {
  static const String cmdName = 'test';

  TestCommand() : super(cmdName, 'Run tests in this package.');

  @override
  final ArgParser argParser = ArgParser.allowAnything();

  @override
  void printUsage() {
    _runImpl(['-h']);
  }

  @override
  FutureOr<int> runImpl() async {
    return _runImpl(argResults.arguments.toList());
  }

  int _runImpl(List<String> testArgs) {
    if (!Sdk.checkArtifactExists(sdk.pubSnapshot)) {
      return 255;
    }

    final pubSnapshot = sdk.pubSnapshot;

    bool isHelpCommand = testArgs.contains('--help') || testArgs.contains('-h');

    // Check for no pubspec.yaml file.
    if (!project.hasPubspecFile) {
      _printNoPubspecMessage(isHelpCommand);
      return 65;
    }

    // Handle the case of no .dart_tool/package_config.json file.
    if (!project.hasPackageConfigFile) {
      _printRunPubGetInstructions(isHelpCommand);
      return 65;
    }

    // "Could not find package "test". Did you forget to add a dependency?"
    if (!project.packageConfig.hasDependency('test')) {
      _printMissingDepInstructions(isHelpCommand);
      return 65;
    }

    final args = [
      'run',
      if (wereExperimentsSpecified)
        '--$experimentFlagName=${specifiedExperiments.join(',')}',
      'test',
      ...testArgs,
    ];

    log.trace('$pubSnapshot ${args.join(' ')}');
    VmInteropHandler.run(pubSnapshot, args);
    return 0;
  }

  @override
  UsageEvent createUsageEvent(int exitCode) => TestUsageEvent(
        usagePath,
        exitCode: exitCode,
        specifiedExperiments: specifiedExperiments,
        args: argResults.arguments,
      );

  void _printNoPubspecMessage(bool wasHelpCommand) {
    log.stdout('''
No pubspec.yaml file found; please run this command from the root of your project.
''');

    if (wasHelpCommand) {
      log.stdout(_terseHelp);
      log.stdout('');
    }

    log.stdout(_usageHelp);
  }

  void _printRunPubGetInstructions(bool wasHelpCommand) {
    log.stdout('''
No .dart_tool/package_config.json file found, please run 'dart pub get'.
''');

    if (wasHelpCommand) {
      log.stdout(_terseHelp);
      log.stdout('');
    }

    log.stdout(_usageHelp);
  }

  void _printMissingDepInstructions(bool wasHelpCommand) {
    final ansi = log.ansi;

    log.stdout('''
No dependency on package:test found. In order to run tests, you need to add a dependency
on package:test in your pubspec.yaml file:

${ansi.emphasized('dev_dependencies:\n  test: ^1.0.0')}

See https://pub.dev/packages/test/install for more information on adding package:test,
and https://dart.dev/guides/testing for general information on testing.
''');

    if (wasHelpCommand) {
      log.stdout(_terseHelp);
      log.stdout('');
    }

    log.stdout(_usageHelp);
  }
}

/// The [UsageEvent] for the test command.
class TestUsageEvent extends UsageEvent {
  TestUsageEvent(String usagePath,
      {String label,
      @required int exitCode,
      @required List<String> specifiedExperiments,
      @required List<String> args})
      : super(TestCommand.cmdName, usagePath,
            label: label,
            exitCode: exitCode,
            specifiedExperiments: specifiedExperiments,
            args: args);
}

const String _terseHelp = 'Run tests in this package.';

const String _usageHelp = 'Usage: dart test [files or directories...]';
