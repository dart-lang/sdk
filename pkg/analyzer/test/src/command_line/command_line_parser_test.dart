// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.command_line.command_line_parser_test;

import 'package:analyzer/src/command_line/command_line_parser.dart';
import 'package:args/args.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommandLineParserTest);
  });
}

@reflectiveTest
class CommandLineParserTest {
  void test_usage() {
    CommandLineParser parser = new CommandLineParser();
    parser.addOption('bar');
    String usage = parser.parser.usage;
    expect(usage, contains('--bar'));
    expect(usage, contains(CommandLineParser.IGNORE_UNRECOGNIZED_FLAG));
  }

  void test_unrecognizedFlags1() {
    CommandLineParser parser = new CommandLineParser();
    expect(() {
      return parser.parse(['--bar', '--baz', 'foo.dart']);
    }, throwsA(new isInstanceOf<FormatException>()));
  }

  void test_unrecognizedFlags2() {
    CommandLineParser parser = new CommandLineParser();
    parser.addFlag('bar');
    expect(() {
      return parser.parse(['--bar', '--baz', 'foo.dart']);
    }, throwsA(new isInstanceOf<FormatException>()));
  }

  void test_unrecognizedFlags_ignore() {
    CommandLineParser parser =
        new CommandLineParser(alwaysIgnoreUnrecognized: true);
    parser.addOption('optA');
    parser.addOption('optB');
    parser.addOption('optG');
    parser.addFlag('flagA');
    ArgResults argResults = parser.parse([
      '--optA=1',
      '--optB',
      '2',
      '--optC=3',
      '--flagA',
      '--optD',
      '4',
      '5',
      '--optG=9',
      '--optH=10'
    ]);
    expect(argResults['optA'], '1');
    expect(argResults['optB'], '2');
    expect(argResults['optG'], '9');
    expect(argResults['flagA'], isTrue);
    expect(() {
      return argResults['optC'];
    }, throwsA(new isInstanceOf<ArgumentError>()));
    expect(() {
      return argResults['optD'];
    }, throwsA(new isInstanceOf<ArgumentError>()));
    expect(argResults.rest, orderedEquals(<String>['4', '5']));
  }
}
