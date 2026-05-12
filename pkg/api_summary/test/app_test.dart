// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('api_summary output matches api_summary.txt', () async {
    final packageDir = _pkgDir();

    final result = await Process.run(Platform.resolvedExecutable, [
      if (Platform.packageConfig != null)
        '--packages=${Platform.packageConfig}',
      p.join(packageDir, 'bin', 'api_summary.dart'),
      '-p',
      packageDir,
    ], workingDirectory: packageDir);

    expect(
      result.exitCode,
      equals(0),
      reason: 'CLI run failed with stderr:\n${result.stderr}',
    );

    final goldenFile = File(p.join(packageDir, 'api_summary.txt'));
    final expectedOutput = LineSplitter.split(
      goldenFile.readAsStringSync(),
    ).join('\n');
    final actualOutput = LineSplitter.split(
      result.stdout.toString(),
    ).join('\n');

    expect(actualOutput, equals(expectedOutput));
  });
}

// Dynamically locate the api_summary package root
String _pkgDir() {
  var packageDir = p.normalize(p.absolute(Directory.current.path));
  if (!_isApiSummaryDir(packageDir)) {
    // We might be running from the SDK root
    final candidate = p.join(packageDir, 'pkg', 'api_summary');
    if (_isApiSummaryDir(candidate)) {
      packageDir = candidate;
    }
  }

  return packageDir;
}

bool _isApiSummaryDir(String dir) {
  final pubspec = File(p.join(dir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  return pubspec.readAsStringSync().contains('name: api_summary');
}
