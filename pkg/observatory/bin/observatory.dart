// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IMPORTANT: to pick up changes made in this file, activate.dart must be
// re-run to delete the old snapshot.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:browser_launcher/browser_launcher.dart';

class ObservatoryCommand extends CommandRunner<void> {
  ObservatoryCommand()
    : super('Observatory', 'Serves the Observatory developer tool.');

  static const String kHelp = 'help';
  static const String kDebug = 'debug';
  static const String kLaunch = 'launch';

  @override
  final ArgParser argParser = ArgParser()
    ..addFlag(
      kDebug,
      help:
          'Run Observatory in debug mode. Useful when making changes to '
          'Observatory to automatically pick up code changes.',
    )
    ..addFlag(kLaunch, help: 'Launch Observatory in Chrome.');

  @override
  Future<void> runCommand(ArgResults results) async {
    if (results.flag(kHelp)) {
      printUsage();
      return;
    }
    if (!_checkForWebDev()) {
      print('Warning: webdev is not installed. Installing it now...');
      _activateWebDev();
      print('webdev installed successfully.');
    }

    await _startWebDev(
      debug: results.flag(kDebug),
      launch: results.flag(kLaunch),
    );
  }

  bool _checkForWebDev() {
    final result = Process.runSync(Platform.resolvedExecutable, <String>[
      'pub',
      'global',
      'list',
    ]);
    return result.stdout.contains('webdev');
  }

  void _activateWebDev() {
    final result = Process.runSync(Platform.resolvedExecutable, <String>[
      'pub',
      'global',
      'activate',
      'webdev',
    ]);
    if (result.exitCode != 0) {
      throw StateError('''
Unexpected issue encountered while activating webdev.'

STDOUT:
${result.stdout}

STDERR:
${result.stderr}
''');
    }
  }

  Future<void> _startWebDev({required bool debug, required bool launch}) async {
    Directory.current = _findObservatoryProjectRoot();
    final process = await Process.start(Platform.resolvedExecutable, <String>[
      'pub',
      'global',
      'run',
      'webdev',
      'serve',
      if (!debug) '--release',
    ]);
    final uriCompleter = Completer<String>();
    final uriRegExp = RegExp('Serving `web` on (http://.*)');
    final sub = process.stdout.transform(utf8.decoder).listen((e) {
      if (uriRegExp.hasMatch(e)) {
        uriCompleter.complete(uriRegExp.firstMatch(e)!.group(1));
      }
    });

    final observatoryUri = await uriCompleter.future;
    print('Observatory is available at: $observatoryUri');

    if (launch) {
      Chrome.start(<String>[observatoryUri]);
    }
    await process.exitCode;

    // Don't cancel this stream until the process has exited as it will close
    // the file descriptor for stdout and cause a crash when webdev tries to
    // write logs.
    await sub.cancel();
  }

  String _findObservatoryProjectRoot() {
    final uri = Platform.script;
    String relativePath = '..';
    if (uri.path.endsWith('.snapshot')) {
      relativePath = '../../../..';
    }
    return uri.resolve(relativePath).toFilePath();
  }
}

Future<void> main(List<String> args) async {
  await ObservatoryCommand().run(args);
}
