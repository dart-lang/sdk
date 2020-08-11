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
  ]);
  expectOk(output);
  print(output.stdout);

  var panaJson = jsonDecode(output.stdout as String);
  var scores = panaJson['scores'];
  print(scores);

  var failureReport = '';
  var baselinePoints = baseline['grantedPoints'] as int;
  var currentPoints = scores['grantedPoints'] as int;
  if (currentPoints < baselinePoints) {
    if (failureReport.isNotEmpty) {
      failureReport += ', ';
    }
    failureReport +=
        'granted points dropped from $baselinePoints to $currentPoints';
  }
  if (failureReport.isNotEmpty) {
    print('Baseline check failed: $failureReport');
    exit(13);
  }
  print('Baseline check passed ✅');

  if (currentPoints != baselinePoints) {
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
