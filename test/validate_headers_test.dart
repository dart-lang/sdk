// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('check for copyright headers', () {
    test('... in lib', () async {
      await validate('lib');
    });
    test('... in tool', () async {
      await validate('tool');
    });
  });
}

Future validate(String dir) async {
  final violations = <String>[];
  await for (FileSystemEntity entity
      in Directory(dir).list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final file = await entity.open();
      List<int> bytes = await file.read(40);
      final header = String.fromCharCodes(bytes);
      if (!header.startsWith(
          RegExp('// Copyright \\(c\\) 20[0-9][0-9], the Dart project'))) {
        violations.add(entity.path);
      }
    }
  }
  expect(violations, isEmpty, reason: '''Files missing copyright headers.

See CONTRIBUTING.md for format details.''');
}
