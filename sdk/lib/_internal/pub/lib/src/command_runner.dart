// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.command_runner;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:stack_trace/stack_trace.dart';

import 'command/build.dart';
import 'command/cache.dart';
import 'command/deps.dart';
import 'command/downgrade.dart';
import 'command/get.dart';
import 'command/global.dart';
import 'command/lish.dart';
import 'command/list_package_dirs.dart';
import 'command/run.dart';
import 'command/serve.dart';
import 'command/upgrade.dart';
import 'command/uploader.dart';
import 'command/version.dart';
import 'exceptions.dart';
import 'exit_codes.dart' as exit_codes;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'sdk.dart' as sdk;
import 'solver/version_solver.dart';
import 'utils.dart';

class PubCommandRunner extends CommandRunner {
  String get usageFooter => "See http://dartlang.org/tools/pub for detailed "
      "documentation.";

  PubCommandRunner()
      : super("pub", "Pub is a package manager for Dart.") {
    argParser.addFlag('version', negatable: false,
        help: 'Print pub version.');
    argParser.addFlag('trace',
         help: 'Print debugging information when an error occurs.');
    argParser.addOption('verbosity',
        help: 'Control output verbosity.',
        allowed: ['normal', 'io', 'solver', 'all'],
        allowedHelp: {
          'normal': 'Show errors, warnings, and user messages.',
          'io':     'Also show IO operations.',
          'solver': 'Show steps during version resolution.',
          'all':    'Show all output including internal tracing messages.'
        });
    argParser.addFlag('verbose', abbr: 'v', negatable: false,
        help: 'Shortcut for "--verbosity=all".');
    argParser.addFlag('with-prejudice', hide: !isAprilFools,
        negatable: false, help: 'Execute commands with prejudice.');
    argParser.addFlag('package-symlinks', hide: true, negatable: true,
        defaultsTo: true);

    addCommand(new BuildCommand());
    addCommand(new CacheCommand());
    addCommand(new DepsCommand());
    addCommand(new DowngradeCommand());
    addCommand(new GlobalCommand());
    addCommand(new GetCommand());
    addCommand(new ListPackageDirsCommand());
    addCommand(new LishCommand());
    addCommand(new RunCommand());
    addCommand(new ServeCommand());
    addCommand(new UpgradeCommand());
    addCommand(new UploaderCommand());
    addCommand(new VersionCommand());
  }

  Future run(List<String> arguments) async {
    var options;
    try {
      options = super.parse(arguments);
    } on UsageException catch (error) {
      log.error(error.message);
      await flushThenExit(exit_codes.USAGE);
    }
    await runCommand(options);
  }

  Future runCommand(ArgResults options) async {
    log.withPrejudice = options['with-prejudice'];

    if (options['version']) {
      log.message('Pub ${sdk.version}');
      return;
    }

    if (options['trace']) {
      log.recordTranscript();
    }

    switch (options['verbosity']) {
      case 'normal': log.verbosity = log.Verbosity.NORMAL; break;
      case 'io':     log.verbosity = log.Verbosity.IO; break;
      case 'solver': log.verbosity = log.Verbosity.SOLVER; break;
      case 'all':    log.verbosity = log.Verbosity.ALL; break;
      default:
        // No specific verbosity given, so check for the shortcut.
        if (options['verbose']) log.verbosity = log.Verbosity.ALL;
        break;
    }

    log.fine('Pub ${sdk.version}');

    await _validatePlatform();

    var captureStackChains =
        options['trace'] ||
        options['verbose'] ||
        options['verbosity'] == 'all';

    try {
      await captureErrors(() => super.runCommand(options),
          captureStackChains: captureStackChains);

      // Explicitly exit on success to ensure that any dangling dart:io handles
      // don't cause the process to never terminate.
      await flushThenExit(exit_codes.SUCCESS);
    } catch (error, chain) {
      log.exception(error, chain);

      if (options['trace']) {
        log.dumpTranscript();
      } else if (!isUserFacingException(error)) {
        log.error("""
This is an unexpected error. Please run

    pub --trace ${options.arguments.map((arg) => "'$arg'").join(' ')}

and include the results in a bug report on http://dartbug.com/new.
""");
      }

      await flushThenExit(_chooseExitCode(error));
    }
  }

  void printUsage() {
    log.message(usage);
  }

  /// Returns the appropriate exit code for [exception], falling back on 1 if no
  /// appropriate exit code could be found.
  int _chooseExitCode(exception) {
    while (exception is WrappedException) exception = exception.innerError;

    if (exception is HttpException || exception is http.ClientException ||
        exception is SocketException || exception is PubHttpException ||
        exception is DependencyNotFoundException) {
      return exit_codes.UNAVAILABLE;
    } else if (exception is FormatException || exception is DataException) {
      return exit_codes.DATA;
    } else if (exception is UsageException) {
      return exit_codes.USAGE;
    } else {
      return 1;
    }
  }

  /// Checks that pub is running on a supported platform.
  ///
  /// If it isn't, it prints an error message and exits. Completes when the
  /// validation is done.
  Future _validatePlatform() async {
    if (Platform.operatingSystem != 'windows') return;

    var result = await runProcess('ver', []);
    if (result.stdout.join('\n').contains('XP')) {
      log.error('Sorry, but pub is not supported on Windows XP.');
      await flushThenExit(exit_codes.USAGE);
    }
  }
}
