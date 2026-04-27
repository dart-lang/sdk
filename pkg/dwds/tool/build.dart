// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

void main() async {
  // 1. Extract the version from pubspec.yaml
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(r'version: (.*)').firstMatch(pubspec);
  final version = versionMatch?.group(1);
  if (version == null) {
    throw Exception('Failed to find version in pubspec.yaml');
  }

  // 2. Generate lib/src/version.dart
  final versionFile = File('lib/src/version.dart');
  versionFile.writeAsStringSync('''
// Generated code. Do not modify.
const packageVersion = '$version';
''');

  // 3. Compile the web client to JavaScript
  print('Compiling client.js...');
  final result = await Process.run(Platform.executable, [
    'compile',
    'js',
    '-O1',
    '--no-source-maps',
    '-o',
    'lib/src/injected/client.js',
    'web/client.dart',
  ]);

  if (result.exitCode != 0) {
    print('Failed to compile client.js');
    print(result.stdout);
    print(result.stderr);
    exit(result.exitCode);
  }

  print('Compilation successful');

  // 4. Clean up the generated .deps file
  final depsFile = File('lib/src/injected/client.js.deps');
  if (depsFile.existsSync()) {
    depsFile.deleteSync();
  }

  // 5. Generate injected_client_js.dart
  print('Generating injected_client_js.dart...');

  final clientDartString = File(
    'web/client.dart',
  ).readAsStringSync().replaceAll('\r\n', '\n');
  final clientDartHash = sha256
      .convert(utf8.encode(clientDartString))
      .toString();

  final compiledJs = File('lib/src/injected/client.js').readAsStringSync();
  final lines = compiledJs.replaceAll('\r\n', '\n').split('\n');

  // Escape JS payload line-by-line using jsonEncode for multiline readability,
  // ensure newlines are preserved identically, and manually escape the dollar
  // sign ($) to avoid Dart interpolation.
  final safeDartString = [
    for (var i = 0; i < lines.length; i++)
      jsonEncode(
        i == lines.length - 1 ? lines[i] : '${lines[i]}\n',
      ).replaceAll(r'$', r'\$'),
  ].join('\n');

  final injectedClientJsFile = File('lib/src/handlers/injected_client_js.dart');
  injectedClientJsFile.writeAsStringSync('''
// Generated code. Do not modify.
// Emits the transpiled client.js directly into a statically embeddable string.
// dart format off

const injectedClientJs = $safeDartString;

const clientDartHash = '$clientDartHash';
''');
  print('Successfully packed client.js into injected_client_js.dart');
}
