// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Runs `git` with [args] in the specified [workingDirectory].
///
/// Throws a [StateError] if it has a non-zero exit code.
Future<ProcessResult> runGitCommand(
  List<String> args,
  Directory workingDirectory,
) async {
  var result = await Process.run(
    'git',
    args,
    workingDirectory: workingDirectory.path,
  );
  if (result.exitCode != 0) {
    throw StateError('''
Error running `git ${args.join(' ')}`:

Stderr:
${result.stderr}

Stdout:
${result.stdout}''');
  }
  return result;
}
