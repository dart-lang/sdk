// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

const baseLinePath = 'tool/baseline/pana.json';

void main() async {
  print('Reading baseline...');
  var contents = File(baseLinePath).readAsStringSync();
  var baseline = jsonDecode(contents)['scores'];
  print(baseline);

  print('Installing pana...');
  var activate = await Process.run('pub', ['global', 'activate', 'pana']);
  expectOk(activate);
  print(activate.stdout);

  print('Running pana...');
  var output = await Process.run('pub', [
    'global',
    'run',
    'pana',
    '-s',
    'path',
    Directory.current.path,
    '-j',
    '--scores'
  ]);
  expectOk(output);
  print(output.stdout);

  var panaJson = jsonDecode(output.stdout as String);
  var health = panaJson['health'];
  print(health);
  var scores = panaJson['scores'];
  print(scores);

  var failureReport = '';
  var baselineHealth = baseline['health'] as double;
  var currentHealth = scores['health'] as double;
  var baselineMaintenance = baseline['maintenance'] as double;
  var currentMaintenance = scores['maintenance'] as double;
  if (currentHealth < baselineHealth) {
    failureReport = 'health dropped from $baselineHealth to $currentHealth';
  }
  if (currentMaintenance < baselineMaintenance) {
    if (failureReport.isNotEmpty) {
      failureReport += ', ';
    }
    failureReport +=
        'maintenance dropped from $baselineMaintenance to $currentMaintenance';
  }
  if (failureReport.isNotEmpty) {
    print('Baseline check failed: $failureReport');
    exit(13);
  }
  print('Baseline check passed ✅');

  if (currentHealth != baselineHealth ||
      currentMaintenance != baselineMaintenance) {
    print(
        '... you have a new baseline! 🎉 Consider updating $baseLinePath to match.');
  }
}

void expectOk(ProcessResult result) {
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    exit(result.exitCode);
  }
}
