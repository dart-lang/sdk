// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Script used to extract symbols with locations from runtime/vm files using
// cquery. See README.md for more information.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:xref_extractor/cquery_driver.dart';
import 'package:xref_extractor/xref_extractor.dart';

// Note: not using Directory.createTemp to reduce indexing costs.
const cqueryCachePath = '/tmp/cquery-cache-for-dart-sdk';

void main(List<String> args) async {
  if (args.length != 1 || !File(args[0]).existsSync()) {
    print('''
Usage: dart runtime/tools/wiki/xref_extractor/bin/main.dart <path-to-cquery>
''');
    exit(1);
  }

  final cqueryBinary = args[0];

  // Sanity check that we are running from SDK checkout root.
  final sdkCheckoutRoot = Directory.current.absolute;
  final runtimeVmDirectory =
      Directory(p.join(sdkCheckoutRoot.path, 'runtime/vm'));
  final gitDirectory = Directory(p.join(sdkCheckoutRoot.path, '.git'));

  if (!gitDirectory.existsSync() || !runtimeVmDirectory.existsSync()) {
    print('This script expects to be run from SDK checkout root');
    exit(1);
  }

  // Generate compile_commands.json from which cquery will extract compilation
  // flags for individual C++ files.
  await generateCompileCommands();

  // Start cquery process and request indexing of runtimeVmDirectory.
  final cquery = await CqueryDriver.start(cqueryBinary);

  print('Indexing ${runtimeVmDirectory.path} with cquery');
  cquery.progress.listen((files) =>
      stdout.write('\rcquery is running ($files files left to index)'));

  await cquery.request('initialize', params: {
    'processId': 123,
    'rootUri': sdkCheckoutRoot.uri.toString(),
    'capabilities': {
      'textDocument': {'codeLens': null}
    },
    'trace': 'on',
    'initializationOptions': {
      'cacheDirectory': cqueryCachePath,
      'progressReportFrequencyMs': 1000,
    },
    'workspaceFolders': [
      {
        'uri': runtimeVmDirectory.uri.toString(),
        'name': 'vm',
      }
    ]
  });

  // Tell cquery to wait for the indexing to complete and then exit.
  cquery.notify(r'$cquery/wait');
  cquery.notify(r'exit');

  // Wait for cquery to exit.
  final exitCode = await cquery.exitCode;
  print('\r\x1b[K... completed (cquery exited with exit code ${exitCode})');

  // Process cquery cache folder to extract symbolic information.
  await generateXRef(cqueryCachePath, sdkCheckoutRoot.path,
      (path) => path.startsWith('runtime/'));
}

/// Generate compile_commands.json for cquery so that it could index VM sources.
///
/// We ask ninja to produce compilation database for X64 release build and then
/// post process it to limit it to libdart_vm_precompiler_host_targeting_host
/// target, because otherwise we get duplicated compilation commands for the
/// same input C++ files and this greatly confuses cquery.
Future<void> generateCompileCommands() async {
  print('Extracting compilation commands from build files for ReleaseX64');
  final result = await Process.run('ninja', [
    '-C',
    '${Platform.isMacOS ? 'xcodebuild' : 'out'}/ReleaseX64',
    '-t',
    'compdb',
    'cxx'
  ]);
  final List<dynamic> commands = jsonDecode(result.stdout);
  final re = RegExp(r'/libdart(_vm)?_precompiler_host_targeting_host\.');
  final filteredCommands = commands
      .cast<Map<String, dynamic>>()
      .where((item) => item['command'].contains(re))
      .toList(growable: false);
  File('compile_commands.json').writeAsStringSync(jsonEncode(filteredCommands));
  print('''
... generated compile_commands.json with ${filteredCommands.length} entries''');
}
