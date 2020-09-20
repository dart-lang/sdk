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

class PubCommand extends DartdevCommand<int> {
  static const String cmdName = 'pub';

  PubCommand() : super(cmdName, 'Work with packages.');

  // TODO(jwren) as soon as pub commands are are implemented directly in
  //  dartdev, remove this static list.
  /// A list of all subcommands, used only for the implementation of
  /// [usagePath], see below.
  static List<String> pubSubcommands = [
    'cache',
    'deps',
    'downgrade',
    'get',
    'global',
    'logout',
    'outdated',
    'publish',
    'run',
    'upgrade',
    'uploader',
    'version',
  ];

  @override
  ArgParser createArgParser() => ArgParser.allowAnything();

  @override
  void printUsage() {
    // Override [printUsage] for invocations of 'dart help pub' which won't
    // execute [run] below.  Without this, the 'dart help pub' reports the
    // command pub with no commands or flags.
    if (!Sdk.checkArtifactExists(sdk.pubSnapshot)) {
      return;
    }
    final command = sdk.pubSnapshot;
    final args = ['help'];

    log.trace('$command ${args.first}');

    // Call 'pub help'
    VmInteropHandler.run(command, args);
  }

  /// Since the pub subcommands are not subclasses of DartdevCommand, we
  /// override [usagePath] here as a special case to cover the first subcommand
  /// under pub, i.e. we will have the path pub/cache
  @override
  String get usagePath {
    if (argResults == null) {
      return name;
    }
    var args = argResults.arguments;
    var cmdIndex = args.indexOf(name) ?? 0;
    for (int i = cmdIndex + 1; i < args.length; i++) {
      if (pubSubcommands.contains(args[i])) {
        return '$name/${args[i]}';
      }
    }
    return name;
  }

  @override
  FutureOr<int> runImpl() async {
    if (!Sdk.checkArtifactExists(sdk.pubSnapshot)) {
      return 255;
    }
    final command = sdk.pubSnapshot;
    var args = argResults.arguments;

    // Pass any --enable-experiment options along.
    if (args.isNotEmpty && wereExperimentsSpecified) {
      List<String> experimentIds = specifiedExperiments;

      if (args.first == 'run') {
        args = [
          ...args.sublist(0, 1),
          '--$experimentFlagName=${experimentIds.join(',')}',
          ...args.sublist(1),
        ];
      } else if (args.length > 1 && args[0] == 'global' && args[0] == 'run') {
        args = [
          ...args.sublist(0, 2),
          '--$experimentFlagName=${experimentIds.join(',')}',
          ...args.sublist(2),
        ];
      }
    }

    log.trace('$command ${args.join(' ')}');
    VmInteropHandler.run(command, args);
    return 0;
  }

  @override
  UsageEvent createUsageEvent(int exitCode) => PubUsageEvent(
        usagePath,
        exitCode: exitCode,
        specifiedExperiments: specifiedExperiments,
        args: argResults.arguments,
      );
}

/// The [UsageEvent] for the pub command.
class PubUsageEvent extends UsageEvent {
  PubUsageEvent(String usagePath,
      {String label,
      @required int exitCode,
      @required List<String> specifiedExperiments,
      @required List<String> args})
      : super(PubCommand.cmdName, usagePath,
            label: label,
            exitCode: exitCode,
            specifiedExperiments: specifiedExperiments,
            args: args);
}
