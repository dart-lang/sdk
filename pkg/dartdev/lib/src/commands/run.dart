// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../utils.dart';
import '../vm_interop_handler.dart';

class RunCommand extends DartdevCommand<int> {
  static bool launchDds = false;
  @override
  final ArgParser argParser = ArgParser.allowAnything();

  @override
  final bool verbose;

  RunCommand({this.verbose = false}) : super('run', '''
Run a Dart file.''');

  @override
  String get invocation => '${super.invocation} <dart file | package target>';

  @override
  void printUsage() {
    // Override [printUsage] for invocations of 'dart help run' which won't
    // execute [run] below.  Without this, the 'dart help run' reports the
    // command pub with no commands or flags.
    final command = sdk.dart;
    final args = [
      '--disable-dart-dev',
      '--help',
      if (verbose) '--verbose',
    ];

    log.trace('$command ${args.first}');

    // Call 'dart --help'
    // Process.runSync(..) is used since [printUsage] is not an async method,
    // and we want to guarantee that the result (the help text for the console)
    // is printed before command exits.
    final result = Process.runSync(command, args);
    if (result.stderr.isNotEmpty) {
      stderr.write(result.stderr);
    }
    if (result.stdout.isNotEmpty) {
      stdout.write(result.stdout);
    }
  }

  @override
  FutureOr<int> run() async {
    // The command line arguments after 'run'
    var args = argResults.arguments.toList();

    var argsContainFile = false;
    for (var arg in args) {
      // The arg.contains('.') matches a file name pattern, i.e. some 'foo.dart'
      if (arg.contains('.')) {
        argsContainFile = true;
      } else if (arg == '--help' || arg == '-h' || arg == 'help') {
        printUsage();
        return 0;
      }
    }

    final cwd = Directory.current;
    if (!argsContainFile && cwd.existsSync()) {
      var foundImplicitFileToRun = false;
      var cwdName = cwd.name;
      for (var entity in cwd.listSync(followLinks: false)) {
        if (entity is Directory && entity.name == 'bin') {
          var filesInBin =
              entity.listSync(followLinks: false).whereType<File>();

          // Search for a dart file in bin/ with the pattern foo/bin/foo.dart
          for (var fileInBin in filesInBin) {
            if (fileInBin.isDartFile && fileInBin.name == '$cwdName.dart') {
              args.add('bin/${fileInBin.name}');
              foundImplicitFileToRun = true;
              break;
            }
          }
          // break here, no actions taken on any entities that are not bin/
          break;
        }
      }

      if (!foundImplicitFileToRun) {
        log.stderr(
          'Could not find the implicit file to run: '
          'bin$separator$cwdName.dart.',
        );
        // Error exit code, as defined in runtime/bin/error_exit.h
        return 255;
      }
    }

    // Pass any --enable-experiment options along.
    if (args.isNotEmpty && wereExperimentsSpecified) {
      List<String> experimentIds = specifiedExperiments;
      args = [
        '--$experimentFlagName=${experimentIds.join(',')}',
        ...args,
      ];
    }

    // If the user wants to start a debugging session we need to do some extra
    // work and spawn a Dart Development Service (DDS) instance. DDS is a VM
    // service intermediary which implements the VM service protocol and
    // provides non-VM specific extensions (e.g., log caching, client
    // synchronization).
    // TODO(bkonyi): Handle race condition made possible by Observatory
    // listening message being printed to console before DDS is started.
    // See https://github.com/dart-lang/sdk/issues/42727
    launchDds = false;
    _DebuggingSession debugSession;
    if (launchDds) {
      debugSession = _DebuggingSession();
      if (!await debugSession.start()) {
        return 255;
      }
    }
    final path = args.firstWhere((e) => !e.startsWith('-'));
    final runArgs = args.length == 1 ? <String>[] : args.sublist(1);
    VmInteropHandler.run(path, runArgs);
    return 0;
  }
}

class _DebuggingSession {
  Future<bool> start() async {
    final serviceInfo = await Service.getInfo();
    final ddsSnapshot = (dirname(sdk.dart).endsWith('bin'))
        ? sdk.ddsSnapshot
        : absolute(dirname(sdk.dart), 'gen', 'dds.dart.snapshot');
    if (!Sdk.checkArtifactExists(ddsSnapshot)) {
      return false;
    }
    final process = await Process.start(
        sdk.dart,
        [
          if (dirname(sdk.dart).endsWith('bin'))
            sdk.ddsSnapshot
          else
            absolute(dirname(sdk.dart), 'gen', 'dds.dart.snapshot'),
          serviceInfo.serverUri.toString()
        ],
        mode: ProcessStartMode.detachedWithStdio);
    final completer = Completer<void>();
    StreamSubscription sub;
    sub = process.stderr.transform(utf8.decoder).listen((event) {
      if (event == 'DDS started') {
        sub.cancel();
        completer.complete();
      }
    });

    await completer.future;
    return true;
  }
}
