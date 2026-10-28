#!/usr/bin/env dart
// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Rolls the browsers and JS engines pinned in DEPS (Chrome, Firefox, d8,
// jsshell and jsc) following go/dart-engprod/browsers.md.
//
// The tool checks for newer upstream releases, requests any missing CIPD
// packaging builds through the tool proxy, waits for the MPA requests to be
// approved and the packages to be built, uploads a DEPS roll CL, and waits
// for the CL to be approved and land.
//
// Each run posts to a single thread in the Dart Web team chat: the thread
// starts with the batched MPA approval links (or the roll CL if no builds
// were needed), and the roll CL, any failures and a final message when the
// CL lands are posted as replies. Use --dry-run to see what would happen
// without side effects.

import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'roll_browsers/engines.dart';
import 'roll_browsers/gerrit.dart';
import 'roll_browsers/git.dart';
import 'roll_browsers/notifier.dart';
import 'roll_browsers/roller.dart';
import 'roll_browsers/tool_proxy.dart';
import 'roll_browsers/upstream.dart';

const _defaultReason =
    'b/334962955 -- Read go/dart-release-eng#reviewing-mpa-requests';

Future<void> main(List<String> arguments) async {
  final parser = _buildParser();
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    _exitWithUsage(parser, e.message);
  }
  if (args.flag('help')) {
    print(_usage(parser));
    return;
  }
  exitCode = await _run(args);
}

ArgParser _buildParser() => ArgParser()
  ..addMultiOption(
    'only',
    help: 'Only consider these engines.',
    allowed: [for (final engine in allEngines) engine.name],
  )
  ..addFlag(
    'dry-run',
    abbr: 'n',
    negatable: false,
    help: 'Report what would happen without requesting builds, uploading '
        'CLs or posting to chat.',
  )
  ..addFlag(
    'ignore-cadence',
    negatable: false,
    help: 'Roll to any newer version, ignoring the per-engine roll policy.',
  )
  ..addMultiOption(
    'reviewer',
    abbr: 'r',
    help: 'Reviewer email for uploaded roll CLs.',
  )
  ..addOption(
    'chat-space',
    help: 'Google Chat space ID for the thread with MPA approval requests, '
        'the roll CL and failures.',
    defaultsTo: defaultChatSpace,
  )
  ..addOption(
    'reason',
    help: 'Justification for tool proxy MPA requests.',
    defaultsTo: _defaultReason,
  )
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

Future<int> _run(ArgResults args) async {
  final checkoutRoot = _checkoutRoot();
  final client = http.Client();
  final notifier = Notifier(
    chatSpace: args.option('chat-space')!,
    dryRun: args.flag('dry-run'),
  );
  try {
    final only = args.multiOption('only');
    final roller = BrowserRoller(
      checkout: GitCheckout(checkoutRoot),
      upstream: Upstream(client),
      toolProxy: ToolProxy(reason: args.option('reason')!),
      gerrit: Gerrit(client),
      notifier: notifier,
      options: RollerOptions(
        engines: [
          for (final engine in allEngines)
            if (only.isEmpty || only.contains(engine.name)) engine,
        ],
        dryRun: args.flag('dry-run'),
        ignoreCadence: args.flag('ignore-cadence'),
        reviewers: args.multiOption('reviewer'),
      ),
    );
    return await roller.run() ? 0 : 1;
  } catch (e, stackTrace) {
    await notifier.reportFailure(
      'unexpected error',
      details: '$e\n\n$stackTrace',
    );
    return 1;
  } finally {
    // Post any failures that were waiting for the thread to start.
    await notifier.flush();
    client.close();
  }
}

/// The SDK checkout containing this script.
String _checkoutRoot() {
  final root = p.dirname(p.dirname(p.fromUri(Platform.script)));
  if (!File(p.join(root, 'DEPS')).existsSync()) {
    stderr.writeln('Could not find DEPS in $root.');
    exit(1);
  }
  return root;
}

String _usage(ArgParser parser) => '''
Usage: dart tools/roll_browsers.dart [options]

Rolls the browsers and JS engines pinned in DEPS following
go/dart-engprod/browsers.md.

${parser.usage}''';

Never _exitWithUsage(ArgParser parser, String message) {
  stderr.writeln(message);
  stderr.writeln(_usage(parser));
  exit(64);
}
