// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pub/src/command/cache.dart';
import 'package:pub/src/command/deps.dart';
import 'package:pub/src/command/downgrade.dart';
import 'package:pub/src/command/get.dart';
import 'package:pub/src/command/global.dart';
import 'package:pub/src/command/lish.dart';
import 'package:pub/src/command/list_package_dirs.dart';
import 'package:pub/src/command/logout.dart';
import 'package:pub/src/command/run.dart';
import 'package:pub/src/command/serve.dart';
import 'package:pub/src/command/upgrade.dart';
import 'package:pub/src/command/uploader.dart';
import 'package:pub/src/command_runner.dart';

import '../core.dart';
import '../utils.dart';

class PubCommand extends DartdevCommand<int> {
  var pubCommandRunner = PubCommandRunner();

  PubCommand({bool verbose = false})
      : super('pub', 'Pub is a package manager for Dart.') {
    argParser.addFlag('version', negatable: false, help: 'Print pub version.');
    argParser.addFlag('trace',
        help: 'Print debugging information when an error occurs.');
    argParser
        .addOption('verbosity', help: 'Control output verbosity.', allowed: [
      'error',
      'warning',
      'normal',
      'io',
      'solver',
      'all'
    ], allowedHelp: {
      'error': 'Show only errors.',
      'warning': 'Show only errors and warnings.',
      'normal': 'Show errors, warnings, and user messages.',
      'io': 'Also show IO operations.',
      'solver': 'Show steps during version resolution.',
      'all': 'Show all output including internal tracing messages.'
    });
    argParser.addFlag('verbose',
        abbr: 'v', negatable: false, help: 'Shortcut for "--verbosity=all".');
    argParser.addFlag('with-prejudice',
        hide: !isAprilFools,
        negatable: false,
        help: 'Execute commands with prejudice.');
    argParser.addFlag('sparkle',
        hide: !isAprilFools,
        negatable: false,
        help: 'A more sparkly experience.');

    addSubcommand(CacheCommand());
    addSubcommand(DepsCommand());
    addSubcommand(DowngradeCommand());
    addSubcommand(GlobalCommand());
    addSubcommand(GetCommand());
    addSubcommand(ListPackageDirsCommand());
    addSubcommand(LishCommand());
    addSubcommand(RunCommand());
    addSubcommand(ServeCommand());
    addSubcommand(UpgradeCommand());
    addSubcommand(UploaderCommand());
    addSubcommand(LogoutCommand());
  }

  @override
  FutureOr<int> run() async {
    await pubCommandRunner.run(argResults.arguments);
    return 0;
  }
}
