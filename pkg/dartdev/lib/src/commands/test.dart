// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:pub/pub.dart';

import '../core.dart';
import '../vm_interop_handler.dart';

/// Implement `dart test`.
///
/// This command largely delegates to `pub run test`.
class TestCommand extends DartdevCommand {
  static const String cmdName = 'test';

  TestCommand() : super(cmdName, 'Run tests for a project.', false);

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser.allowAnything();
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;
    try {
      final testExecutable = await getExecutableForCommand('test:test');
      log.trace('dart $testExecutable ${args.rest.join(' ')}');
      VmInteropHandler.run(testExecutable.executable, args.rest,
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
      return 65;
    }
  }
}
