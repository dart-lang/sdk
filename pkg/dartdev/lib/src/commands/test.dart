// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:pub/pub.dart';

import '../core.dart';
import '../vm_interop_handler.dart';

/// Implement `dart test`.
///
/// This command largely delegates to `pub run test`.
class TestCommand extends DartdevCommand {
  static const String cmdName = 'test';

  TestCommand() : super(cmdName, 'Run tests in this package.');

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser.allowAnything();
  }

  @override
  FutureOr<int> run() async {
    if (argResults.rest.contains('-h') || argResults.rest.contains('--help')) {
      printUsage();
      return 0;
    }
    if (!project.hasPubspecFile) {
      log.stdout('''
No pubspec.yaml file found; please run this command from the root of your project.
''');

      printUsage();
      return 65;
    }
    try {
      final testExecutable = await getExecutableForCommand('test:test');
      log.trace('dart $testExecutable ${argResults.rest.join(' ')}');
      VmInteropHandler.run(testExecutable, argResults.rest,
          packageConfigOverride:
              join(current, '.dart_tool', 'package_config.json'));
      return 0;
    } on CommandResolutionFailedException catch (e) {
      print(e.message);
      print('You need to add a dependency on package:test.');
      print('Try running `dart pub add test`.');
      return 65;
    }
  }
}
