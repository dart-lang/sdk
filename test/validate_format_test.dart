// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('validate source formatting', () async {
    try {
      final result = await Process.run(
          'dartfmt', ['--dry-run', '--set-exit-if-changed', '.']);
      final violations = result.stdout.toString().split('\n')
        ..removeWhere(formattingIgnored);
      expect(violations, isEmpty, reason: '''Some files need formatting. 
  
Run `dartfmt` and (re)commit.''');
    } on ProcessException {
      // This occurs, notably, on appveyor.
      print('[WARNING] format validation skipped -- `dartfmt` not on PATH');
    }
  });
}

bool formattingIgnored(String location) =>
    location.isEmpty ||
    location.startsWith('test/_data/') ||
    location.startsWith('test/rules/');
