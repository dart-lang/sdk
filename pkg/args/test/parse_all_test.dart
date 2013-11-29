// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parse_all_test;

import 'package:unittest/unittest.dart';
import 'package:args/args.dart';

void main() {
  group('ArgParser.parse(allowTrailingOptions: true) '
        'starting with a non-option', () {
    test('followed by flag', () {
      var parser = new ArgParser()..addFlag('flag');
      var args = ['A', '--flag'];

      var resultsAll = parser.parse(args, allowTrailingOptions: true);
      expect(resultsAll['flag'], isTrue);
      expect(resultsAll.rest, equals(['A']));
    });

    test('followed by option', () {
      var parser = new ArgParser()..addOption('opt');
      var args = ['A', '--opt'];

      expectThrows(parser, args);
    });

    test('followed by option and value', () {
      var parser = new ArgParser()..addOption('opt');
      var args = ['A', '--opt', 'V'];

      var resultsAll = parser.parse(args, allowTrailingOptions: true);
      expect(resultsAll['opt'], equals('V'));
      expect(resultsAll.rest, equals(['A']));
    });

    test('followed by unknown flag', () {
      var parser = new ArgParser();
      var args = ['A', '--xflag'];

      expectThrows(parser, args);
    });

    test('followed by unknown option and value', () {
      var parser = new ArgParser();
      var args = ['A', '--xopt', 'V'];

      expectThrows(parser, args);
    });

    test('followed by command', () {
      var parser = new ArgParser()..addCommand('com');
      var args = ['A', 'com'];

      expectThrows(parser, args);
    });
  });
}

void expectThrows(ArgParser parser, List<String> args) =>
  expect(() => parser.parse(args, allowTrailingOptions: true),
      throwsFormatException,
      reason: "with allowTrailingOptions: true");
