// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import '../lib/src/command.dart';
import '../lib/src/exit_codes.dart' as exit_codes;
import '../lib/src/io.dart';
import '../lib/src/log.dart' as log;
import '../lib/src/sdk.dart' as sdk;
import '../lib/src/utils.dart';

void main(List<String> arguments) {
  ArgResults options;

  try {
    options = PubCommand.pubArgParser.parse(arguments,
        allowTrailingOptions: true);
  } on FormatException catch (e) {
    log.error(e.message);
    log.error('Run "pub help" to see available options.');
    flushThenExit(exit_codes.USAGE);
    return;
  }

  if (options['version']) {
    log.message('Pub ${sdk.version}');
    return;
  }

  if (options['help']) {
    PubCommand.printGlobalUsage();
    return;
  }

  if (options.command == null) {
    if (options.rest.isEmpty) {
      // No command was chosen.
      PubCommand.printGlobalUsage();
    } else {
      log.error('Could not find a command named "${options.rest[0]}".');
      log.error('Run "pub help" to see available commands.');
      flushThenExit(exit_codes.USAGE);
    }
    return;
  }

  if (options['trace']) {
    log.recordTranscript();
  }

  switch (options['verbosity']) {
    case 'normal': log.showNormal(); break;
    case 'io':     log.showIO(); break;
    case 'solver': log.showSolver(); break;
    case 'all':    log.showAll(); break;
    default:
      // No specific verbosity given, so check for the shortcut.
      if (options['verbose']) {
        log.showAll();
      } else {
        log.showNormal();
      }
      break;
  }

  log.fine('Pub ${sdk.version}');

  var cacheDir;
  if (Platform.environment.containsKey('PUB_CACHE')) {
    cacheDir = Platform.environment['PUB_CACHE'];
  } else if (Platform.operatingSystem == 'windows') {
    var appData = Platform.environment['APPDATA'];
    cacheDir = path.join(appData, 'Pub', 'Cache');
  } else {
    cacheDir = '${Platform.environment['HOME']}/.pub-cache';
  }

  validatePlatform().then((_) {
    PubCommand.commands[options.command.name].run(cacheDir, options, arguments);
  });
}

/// Checks that pub is running on a supported platform. If it isn't, it prints
/// an error message and exits. Completes when the validation is done.
Future validatePlatform() {
  return syncFuture(() {
    if (Platform.operatingSystem != 'windows') return null;

    return runProcess('ver', []).then((result) {
      if (result.stdout.join('\n').contains('XP')) {
        log.error('Sorry, but pub is not supported on Windows XP.');
        return flushThenExit(exit_codes.USAGE);
      }
    });
  });
}
