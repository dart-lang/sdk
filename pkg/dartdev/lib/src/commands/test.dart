// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:dartdev/src/experiments.dart';
import 'package:pub/pub.dart';

import '../core.dart';
import '../native_assets.dart';
import '../vm_interop_handler.dart';

/// Implement `dart test`.
///
/// This command largely delegates to `pub run test`.
class TestCommand extends DartdevCommand {
  static const String cmdName = 'test';

  final bool nativeAssetsExperimentEnabled;

  TestCommand({this.nativeAssetsExperimentEnabled = false})
      : super(cmdName, 'Run tests for a project.', false);

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser.allowAnything();
  }

  @override
  void printUsage() {
    print('''Usage: dart test [arguments]

Note: flags and options for this command are provided by the project's package:test dependency.
If package:test is not included as a dev_dependency in the project's pubspec.yaml, no flags or options will be listed.

Run "${runner!.executableName} help" to see global options.''');
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;

    String? nativeAssets;
    if (!nativeAssetsExperimentEnabled) {
      if (await warnOnNativeAssets()) {
        return DartdevCommand.errorExitCode;
      }
    } else {
      try {
        nativeAssets = (await compileNativeAssetsJitYamlFile(verbose: verbose))
            ?.toFilePath();
      } on Exception catch (e, stacktrace) {
        log.stderr('Error: Compiling native assets failed.');
        log.stderr(e.toString());
        log.stderr(stacktrace.toString());
        return DartdevCommand.errorExitCode;
      }
    }

    try {
      final testExecutable = await getExecutableForCommand('test:test',
          nativeAssets: nativeAssets);
      final argsRestNoExperiment = args.rest
          .where((e) => !e.startsWith('--$experimentFlagName='))
          .toList();
      log.trace('dart $testExecutable ${argsRestNoExperiment.join(' ')}');
      VmInteropHandler.run(testExecutable.executable, argsRestNoExperiment,
          packageConfigOverride: testExecutable.packageConfig!);
      return 0;
    } on CommandResolutionFailedException catch (e) {
      if (project.hasPubspecFile) {
        print(e.message);
        if (e.issue == CommandResolutionIssue.packageNotFound) {
          print('You need to add a dev_dependency on package:test.');
          print('Try running `dart pub add --dev test`.');
        }
      } else {
        print(
            'No pubspec.yaml file found - run this command in your project folder.');
      }
      if (args.rest.contains('-h') || args.rest.contains('--help')) {
        print('');
        printUsage();
      }
      return DartdevCommand.errorExitCode;
    }
  }
}
