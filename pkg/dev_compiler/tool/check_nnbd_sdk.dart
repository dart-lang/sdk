#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Command-line tool that runs dartanalyzer on a sdk under the perspective of
/// one tool.
// TODO(sigmund): generalize this to support other tools, not just ddc.

import 'dart:io';
import 'package:args/args.dart';
import 'package:front_end/src/fasta/resolve_input_uri.dart';

import 'patch_sdk.dart' as patch;

void main(List<String> argv) {
  if (Platform.isWindows) {
    print('Golden file does not support Windows.  Skipping.');
    return;
  }
  var args = _parser.parse(argv);
  if (args['help'] as bool) {
    print('Apply patch file to the SDK and report analysis errors from the '
        'resulting libraries.\n\n'
        'Usage: ${Platform.script.pathSegments.last} [options...]\n\n'
        '${_parser.usage}');
    return;
  }
  var baseDir = args['out'] as String;
  if (baseDir == null) {
    var tmp = Directory.systemTemp.createTempSync('check_sdk-');
    baseDir = tmp.path;
  }
  var baseUri = resolveInputUri(baseDir.endsWith('/') ? baseDir : '$baseDir/');
  var sdkDir = baseUri.resolve('sdk/').toFilePath();
  print('Generating a patched sdk at ${baseUri.path}');

  var librariesJson = args['libraries'] != null
      ? resolveInputUri(args['libraries'] as String)
      : Platform.script.resolve('../../../sdk/lib/libraries.json');
  var target = args['target'] as String;
  patch.main([
    '--libraries',
    librariesJson.toFilePath(),
    '--target',
    target,
    '--out',
    sdkDir,
    '--merge-parts',
    '--nnbd',
  ]);

  var isWeb = false;
  var isNative = false;
  switch (target) {
    case 'dartdevc':
    case 'dart2js':
      isWeb = true;
      break;
    case 'flutter':
    case 'vm':
      isNative = true;
      break;
  }

  var core = '''
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
''';

  var web = !isWeb
      ? ''
      : '''
import 'dart:js';
import 'dart:js_util';
import 'dart:indexed_db';
import 'dart:html';
import 'dart:html_common';
import 'dart:svg';
import 'dart:web_audio';
import 'dart:web_gl';
import 'dart:web_sql';
''';

  var native = !isNative
      ? '''
import 'dart:io';
import 'dart:isolate';
'''
      : '''
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';
''';

  var emptyProgramUri = baseUri.resolve('empty_program.dart');
  File.fromUri(emptyProgramUri).writeAsStringSync('''
$core
$web
$native

main() {}
''');

  print('Running dartanalyzer');
  var dart = resolveInputUri(Platform.resolvedExecutable);
  var analyzerSnapshot =
      dart.resolve('snapshots/dartanalyzer.dart.snapshot').toFilePath();
  var result = Process.runSync(dart.toFilePath(), [
    // The NNBD dart binaries / snapshots require this flag to be enabled at
    // VM level.
    if (analyzerSnapshot.contains('NNBD')) '--enable-experiment=non-nullable',
    analyzerSnapshot,
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
  var errors = result.stderr as String;

  // Trim temporary directory paths and sort errors.
  errors = errors.replaceAll(sdkDir, '');
  var errorList = errors.isEmpty ? <String>[] : errors.trim().split('\n');
  var count = errorList.length;
  print('$count analyzer errors.');
  errorList.sort();
  errors = errorList.join('\n') + '\n';
  var errorFile = baseUri.resolve('errors.txt');
  print('Errors emitted to ${errorFile.path}');
  File.fromUri(errorFile).writeAsStringSync(errors, flush: true);

  // Check against golden file.
  var goldenFile =
      Platform.script.resolve('${target}_nnbd_sdk_error_golden.txt');
  var golden = File.fromUri(goldenFile).readAsStringSync();
  if (errors != golden) {
    if (args['update-golden'] as bool) {
      // Update the golden file.
      File.fromUri(goldenFile).writeAsStringSync(errors, flush: true);
      print('Golden file updated.');
      exit(0);
    } else {
      // Fail.
      print('Golden file does not match.');
      print('\nTo update the golden file, run:'
          '\n  ${Platform.executable} ${Platform.script} '
          '${argv.join(' ')} --update-golden');

      // Compare the two sorted lists to show what errors changed.  Note, we
      // don't use `diff` as an external tool because it is not available on
      // windows bots.
      var toAdd = <String>[];
      var toRemove = <String>[];
      var goldenList = golden.trim().split('\n');
      var i = 0, j = 0;
      for (; i < errorList.length && j < goldenList.length;) {
        var compare = errorList[i].compareTo(goldenList[j]);
        if (compare == 0) {
          i++;
          j++;
        } else if (compare < 0) {
          toAdd.add(errorList[i]);
          i++;
        } else {
          toRemove.add(goldenList[j]);
          j++;
        }
      }
      for (; i < errorList.length; i++) {
        toAdd.add(errorList[i]);
      }
      for (; j < goldenList.length; j++) {
        toRemove.add(goldenList[j]);
      }
      print('\nNew errors:');
      print(toAdd.join('\n'));
      print('\nErrors that can be removed from the golden file:');
      print(toRemove.join('\n'));
      exit(1);
    }
  }
  exit(0);
}

final _parser = ArgParser()
  ..addOption('libraries',
      help: 'Path to the nnbd libraries.json (defaults to the one under '
          'sdk/lib/libraries.json.')
  ..addOption('out',
      help: 'Path to an output folder (defaults to a new tmp folder).')
  ..addOption('target',
      help: 'The target tool. '
          'This name matches one of the possible targets in libraries.json '
          'and it is used to pick which patch files will be applied.',
      allowed: ['dartdevc', 'dart2js', 'dart2js_server', 'vm', 'flutter'],
      defaultsTo: 'dartdevc')
  ..addFlag('update-golden', help: 'Update the golden file.', defaultsTo: false)
  ..addFlag('help', abbr: 'h', help: 'Display this message.');
