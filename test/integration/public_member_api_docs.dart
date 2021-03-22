// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('public_member_api_docs', () {
    test('lint lib/ sources and non-lib/ sources', () async {
      var pubResult = Process.runSync(
          'dart',
          [
            'pub',
            'get',
          ],
          workingDirectory: 'test/_data/public_member_api_docs');
      expect(pubResult.exitCode, 0);

      var result = Process.runSync(
        'dart',
        ['analyze', 'test/_data/public_member_api_docs'],
      );
      expect(
          result.stdout.trim(),
          stringContainsInOrder([
            'a.dart:7:1 - Document all public members. - public_member_api_docs',
            'a.dart:9:11 - Document all public members. - public_member_api_docs',
            'a.dart:10:9 - Document all public members. - public_member_api_docs',
            'a.dart:14:16 - Document all public members. - public_member_api_docs',
            'a.dart:22:11 - Document all public members. - public_member_api_docs',
            'a.dart:26:16 - Document all public members. - public_member_api_docs',
            'a.dart:29:3 - Document all public members. - public_member_api_docs',
            'a.dart:30:5 - Document all public members. - public_member_api_docs',
            'a.dart:32:8 - Document all public members. - public_member_api_docs',
            'a.dart:34:8 - Document all public members. - public_member_api_docs',
            'a.dart:42:3 - Document all public members. - public_member_api_docs',
            'a.dart:44:3 - Document all public members. - public_member_api_docs',
            'a.dart:52:9 - Document all public members. - public_member_api_docs',
            'a.dart:60:14 - Document all public members. - public_member_api_docs',
            'a.dart:66:6 - Document all public members. - public_member_api_docs',
            'a.dart:68:3 - Document all public members. - public_member_api_docs',
            'a.dart:87:1 - Document all public members. - public_member_api_docs',
            'a.dart:92:5 - Document all public members. - public_member_api_docs',
            'a.dart:96:6 - Document all public members. - public_member_api_docs',
            'a.dart:111:1 - Document all public members. - public_member_api_docs',
            'a.dart:112:11 - Document all public members. - public_member_api_docs',
            'a.dart:119:14 - Document all public members. - public_member_api_docs',
            'a.dart:132:1 - Document all public members. - public_member_api_docs',
            'a.dart:134:7 - Document all public members. - public_member_api_docs',
            'a.dart:135:1 - Document all public members. - public_member_api_docs',
          ]));
      expect(result.exitCode, 0);
    });
  });
}
