// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parse_all_test;

import 'package:unittest/unittest.dart';
import 'package:args/args.dart';

main() {
  group('ArgParser.parse() starting with a non-option', () {
    test('followed by flag', () {
      var parser = new ArgParser()..addFlag('flag');
      var args = ['A', '--flag'];

      var results = parser.parse(args);
      expect(results['flag'], isFalse);
      expect(results.rest, orderedEquals(args));
    });

    test('followed by option', () {
      var parser = new ArgParser()..addOption('opt');
      var args = ['A', '--opt'];

      var results = parser.parse(args);
      expect(results['opt'], isNull);
      expect(results.rest, orderedEquals(args));
    });

    test('followed by option and value', () {
      var parser = new ArgParser()..addOption('opt');
      var args = ['A', '--opt', 'V'];

      var results = parser.parse(args);
      expect(results['opt'], isNull);
      expect(results.rest, orderedEquals(args));
    });

    test('followed by unknown flag', () {
      var parser = new ArgParser();
      var args = ['A', '--xflag'];
      var results = parser.parse(args);
      expect(results.rest, orderedEquals(args));
    });

    test('followed by unknown option and value', () {
      var parser = new ArgParser();
      var args = ['A', '--xopt', 'V'];
      var results = parser.parse(args);
      expect(results.rest, orderedEquals(args));
    });

    test('followed by command', () {
      var parser = new ArgParser()..addCommand('com');
      var args = ['A', 'com'];

      var results = parser.parse(args);
      expect(results.command, isNull);
      expect(results.rest, orderedEquals(args));
    });
  });
}
