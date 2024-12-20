// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/devtools_server.dart';
import 'package:test/test.dart';

void main() {
  group('DevToolsServer.buildUriToLaunch', () {
    var build = DevToolsServer.buildUriToLaunch;

    test('with no trailing slash', () async {
      var base = Uri.parse('http://localhost:1235');
      expect(build(base, null, {}), 'http://localhost:1235/');
      expect(build(base, 'inspector', {}), 'http://localhost:1235/inspector');
      expect(build(base, null, {'a': 'a'}), 'http://localhost:1235/?a=a');
      expect(build(base, 'inspector', {'a': 'a'}),
          'http://localhost:1235/inspector?a=a');
    });

    test('with trailing slash', () async {
      var base = Uri.parse('http://localhost:1235/');

      expect(build(base, null, {}), 'http://localhost:1235/');
      expect(build(base, 'inspector', {}), 'http://localhost:1235/inspector');
      expect(build(base, null, {'a': 'a'}), 'http://localhost:1235/?a=a');
      expect(build(base, 'inspector', {'a': 'a'}),
          'http://localhost:1235/inspector?a=a');
    });

    test('with folder and no trailing slash', () async {
      var base = Uri.parse('http://localhost:1235/devtools');
      expect(build(base, null, {}), 'http://localhost:1235/devtools/');
      expect(build(base, 'inspector', {}),
          'http://localhost:1235/devtools/inspector');
      expect(
          build(base, null, {'a': 'a'}), 'http://localhost:1235/devtools/?a=a');
      expect(build(base, 'inspector', {'a': 'a'}),
          'http://localhost:1235/devtools/inspector?a=a');
    });

    test('with folder and trailing slash', () async {
      var base = Uri.parse('http://localhost:1235/devtools/');

      expect(build(base, null, {}), 'http://localhost:1235/devtools/');
      expect(build(base, 'inspector', {}),
          'http://localhost:1235/devtools/inspector');
      expect(
          build(base, null, {'a': 'a'}), 'http://localhost:1235/devtools/?a=a');
      expect(build(base, 'inspector', {'a': 'a'}),
          'http://localhost:1235/devtools/inspector?a=a');
    });

    test('with existing query params', () async {
      var base = Uri.parse('http://localhost:1235/devtools/?a=orig&b=b');

      expect(
          build(base, null, {}), 'http://localhost:1235/devtools/?a=orig&b=b');
      expect(build(base, 'inspector', {}),
          'http://localhost:1235/devtools/inspector?a=orig&b=b');
      expect(build(base, null, {'a': 'a', 'c': 'c'}),
          'http://localhost:1235/devtools/?a=a&b=b&c=c');
      expect(build(base, 'inspector', {'a': 'a', 'c': 'c'}),
          'http://localhost:1235/devtools/inspector?a=a&b=b&c=c');
    });
  });
}
