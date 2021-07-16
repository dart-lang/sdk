// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('validate source formatting', () async {
    var result = await Process.run(
        'dart', ['format', '-o', 'none', '--set-exit-if-changed', '.']);
    var violations = result.stdout.toString().split('\n')
      ..removeWhere(lineIgnored);
    expect(violations, isEmpty, reason: '''Some files need formatting. 
  
Run `dart format` and (re)commit.''');
  });
}

bool lineIgnored(String line) =>
    line.isEmpty ||
    line.startsWith('Changed test_data${Platform.pathSeparator}') ||
    line.startsWith('Formatted ');
