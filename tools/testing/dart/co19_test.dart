// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tool for running co19 tests. Used when updating co19.
 *
 * Currently, this tool is merely a convenience around multiple
 * invocations of test.dart. Long term, we hope to evolve this into a
 * script that can automate most of the tasks necessary when updating
 * co19.
 *
 * Usage:
 * [: dart tools/testing/dart/co19_test.dart :]
 */

library co19_test;

import "dart:io";

import "test_options.dart";
import "test_suite.dart";
import "test_configurations.dart";

const List<String> COMMON_ARGUMENTS = const <String>[
  '--report',
  '--progress=diff',
  'co19'
];

const List<List<String>> COMMAND_LINES = const <List<String>>[
  const <String>['-mrelease,debug', '-rvm', '-cnone'],
  const <String>['-mrelease,debug', '-rvm', '-cnone', '--checked'],
  const <String>['-mrelease', '-rnone', '-cdart2analyzer'],
  const <String>['-mrelease', '-rd8', '-cdart2js', '--use-sdk'],
  const <String>[
    '-mrelease',
    '-rd8,jsshell',
    '-cdart2js',
    '--use-sdk',
    '--minified'
  ],
  const <String>[
    '-mrelease',
    '-rd8,jsshell',
    '-cdart2js',
    '--use-sdk',
    '--checked'
  ],
  const <String>[
    '-mrelease',
    '-rdartium',
    '-cnone',
    '--use-sdk',
    '--fast-startup'
  ],
  const <String>['-mrelease', '-rdartium', '-cnone', '--use-sdk'],
];

void main(List<String> args) {
  TestUtils.setDartDirUri(Platform.script.resolve('../../..'));
  var optionsParser = new TestOptionsParser();
  var configurations = <Map>[];
  for (var commandLine in COMMAND_LINES) {
    var arguments = <String>[];
    arguments.addAll(COMMON_ARGUMENTS);
    arguments.addAll(args);
    arguments.addAll(commandLine);
    configurations.addAll(optionsParser.parse(arguments));
  }

  if (configurations != null || configurations.length > 0) {
    testConfigurations(configurations);
  }
}
