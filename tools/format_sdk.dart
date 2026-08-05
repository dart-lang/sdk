// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Runs the Dart formatter on every directory in the SDK that should be
/// formatted. Skips directories that are brought in by DEPS.
///
/// Invokes `dart format` using the same executable used to run this script.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

const skippedTopLevelDirectories = [
  'build',
  'out',
  'third_party',
  'tests',
  'xcodebuild'
];

const skippedTestDirectories = ['co19'];

final repoRoot = p.normalize(p.join(Platform.script.toFilePath(), '../..'));

void main() async {
  final entries = [
    for (final entry in Directory(repoRoot).listSync(recursive: false))
      if (!skippedTopLevelDirectories.contains(p.basename(entry.path))) entry,
    for (final entry
        in Directory(p.join(repoRoot, 'tests')).listSync(recursive: false))
      if (!skippedTestDirectories.contains(p.basename(entry.path))) entry,
  ];

  for (final entry in entries) {
    if (entry is! Directory) continue;

    final relative = p.relative(entry.path, from: repoRoot);
    if (p.basename(relative).startsWith('.')) continue;

    print('');
    print('=== Formatting $relative/ ===');
    final process = await Process.start(
        Platform.resolvedExecutable, ['format', relative],
        workingDirectory: repoRoot, mode: ProcessStartMode.inheritStdio);
    await process.exitCode;
  }
}
