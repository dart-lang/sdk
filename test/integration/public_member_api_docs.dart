// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../test_constants.dart';

void main() {
  group('public_member_api_docs', () {
    test('lint lib/ sources and non-lib/ sources', () async {
      var pubResult = Process.runSync(
          'dart',
          [
            'pub',
            'get',
          ],
          workingDirectory: '$integrationTestDir/public_member_api_docs');
      expect(pubResult.exitCode, 0);

      var result = Process.runSync(
        'dart',
        ['analyze', '$integrationTestDir/public_member_api_docs'],
      );
      expect(
          result.stdout.trim(),
          stringContainsInOrder([
            'a.dart:7:1',
            'a.dart:8:16',
            'a.dart:9:11',
            'a.dart:10:9',
            'a.dart:14:16',
            'a.dart:22:11',
            'a.dart:26:16',
            'a.dart:29:3',
            'a.dart:30:5',
            'a.dart:32:8',
            'a.dart:34:8',
            'a.dart:42:3',
            'a.dart:44:3',
            'a.dart:52:9',
            'a.dart:60:14',
            'a.dart:66:6',
            'a.dart:68:3',
            'a.dart:87:1',
            'a.dart:92:5',
            'a.dart:96:6',
            'a.dart:111:1',
            'a.dart:112:11',
            'a.dart:119:14',
            'a.dart:132:1',
            'a.dart:134:7',
            'a.dart:135:1',
          ]));
      expect(result.exitCode, 0);
    });
  });
}
