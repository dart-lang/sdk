#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool that runs dartanalyzer on a sdk under the perspective of
/// one tool.
// TODO(sigmund): generalize this to support other tools, not just ddc.

import 'dart:io';
import 'package:args/args.dart';
import 'package:front_end/src/fasta/resolve_input_uri.dart';

import 'patch_sdk.dart' as patch;

void main(List<String> argv) {
  var args = _parser.parse(argv);
  if (args['help'] as bool || argv.isEmpty) {
    print('Apply patch file to the SDK and report analysis errors from the '
        'resulting libraries.\n\n'
        'Usage: ${Platform.script.pathSegments.last} [options...]\n\n'
        '${_parser.usage}');
    return;
  }
  String baseDir = args['out'] as String;
  if (baseDir == null) {
    var tmp = Directory.systemTemp.createTempSync('check_sdk-');
    baseDir = tmp.path;
  }
  var baseUri = resolveInputUri(baseDir.endsWith('/') ? baseDir : '$baseDir/');
  var sdkDir = baseUri.resolve('sdk/').toFilePath();
  print('Generating a patched sdk at ${baseUri.path}');

  Uri librariesJson = args['libraries'] != null
      ? resolveInputUri(args['libraries'] as String)
      : Platform.script.resolve('../../../sdk_nnbd/lib/libraries.json');
  patch.main([
    '--libraries',
    librariesJson.toFilePath(),
    '--target',
    args['target'] as String,
    '--out',
    sdkDir,
    '--merge-parts',
    '--nnbd',
  ]);

  var emptyProgramUri = baseUri.resolve('empty_program.dart');
  File.fromUri(emptyProgramUri).writeAsStringSync('main() {}');

  print('Running dartanalyzer');
  var dart = Uri.base.resolve(Platform.resolvedExecutable);
  var analyzerSnapshot = Uri.base
      .resolve(Platform.resolvedExecutable)
      .resolve('snapshots/dartanalyzer.dart.snapshot');
  var result = Process.runSync(dart.toFilePath(), [
    analyzerSnapshot.toFilePath(),
    '--dart-sdk=${sdkDir}',
    '--format',
    'machine',
    '--sdk-warnings',
    '--no-hints',
    '--enable-experiment',
    'non-nullable',
    emptyProgramUri.toFilePath()
  ]);

  stdout.write(result.stdout);
  String errors = result.stderr as String;
  var count = errors.isEmpty ? 0 : errors.trim().split('\n').length;
  print('$count analyzer errors. Errors emitted to ${baseUri.path}errors.txt');
  File.fromUri(baseUri.resolve('errors.txt')).writeAsStringSync(errors);
  exit(count == 0 ? 0 : 1);
}

final _parser = ArgParser()
  ..addOption('libraries',
      help: 'Path to the nnbd libraries.json (defaults to the one under '
          'sdk_nnbd/lib/libraries.json.')
  ..addOption('out',
      help: 'Path to an output folder (defaults to a new tmp folder).')
  ..addOption('target',
      help: 'The target tool. '
          'This name matches one of the possible targets in libraries.json '
          'and it is used to pick which patch files will be applied.',
      allowed: ['dartdevc', 'dart2js', 'dart2js_server', 'vm', 'flutter'],
      defaultsTo: 'dartdevc')
  ..addFlag('help', abbr: 'h', help: 'Display this message.');
