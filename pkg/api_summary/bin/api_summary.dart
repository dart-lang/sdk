// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:api_summary/api_summary.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<void> main(List<String> arguments) async {
  try {
    final results = parser.parse(arguments);

    if (results.flag('help')) {
      print('Usage: api_summary [options]');
      print(parser.usage);
      return;
    }

    final packagePath =
        results.option('package-path') ?? Directory.current.path;
    final absolutePath = p.normalize(p.absolute(packagePath));
    final pubspecFile = File(p.join(absolutePath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      stderr.writeln('Error: No pubspec.yaml found at "$absolutePath".');
      exitCode = 1;
      return;
    }

    final packageName = _extractPackageName(pubspecFile);
    final summary = await summarizePackage(absolutePath, packageName);
    stdout.write(summary);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('\nUsage: api_summary [options]');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }
}

final parser = ArgParser()
  ..addOption(
    'package-path',
    abbr: 'p',
    help:
        'The path to the package to summarize. Defaults to the current '
        'directory.',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Print this usage information.',
    negatable: false,
  );

String _extractPackageName(File pubspecFile) {
  final content = pubspecFile.readAsStringSync();
  final yaml = loadYaml(content);
  if (yaml is! Map) {
    throw ArgumentError(
      'Expected pubspec.yaml at ${pubspecFile.path} to be a YAML map.',
    );
  }
  final name = yaml['name'];
  if (name == null) {
    throw ArgumentError(
      'Could not find a "name" field in pubspec.yaml at ${pubspecFile.path}.',
    );
  }
  if (name is! String) {
    throw ArgumentError(
      'The "name" field in pubspec.yaml at ${pubspecFile.path} must be a '
      'String.',
    );
  }
  return name;
}
