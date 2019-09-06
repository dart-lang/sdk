// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tool for running co19 tests. Used when updating co19.
///
/// Currently, this tool is merely a convenience around multiple
/// invocations of test.dart. Long term, we hope to evolve this into a
/// script that can automate most of the tasks necessary when updating
/// co19.
///
/// Usage:
/// [: dart pkg/test_runner/tool/co19.dart :]
import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';
import 'package:test_runner/src/test_configurations.dart';

const List<String> _commonArguments = <String>[
  '--report',
  '--progress=diff',
  'co19'
];

const List<List<String>> _commandLines = <List<String>>[
  <String>['-mrelease,debug', '-rvm', '-cnone'],
  <String>['-mrelease,debug', '-rvm', '-cnone', '--checked'],
  <String>['-mrelease', '-rnone', '-cdart2analyzer'],
  <String>['-mrelease', '-rd8', '-cdart2js', '--use-sdk'],
  <String>['-mrelease', '-rd8,jsshell', '-cdart2js', '--use-sdk', '--minified'],
  <String>['-mrelease', '-rd8,jsshell', '-cdart2js', '--use-sdk', '--checked'],
  <String>[
    '-mrelease',
    '-rd8,jsshell',
    '-cdart2js',
    '--use-sdk',
    '--checked',
    '--fast-startup'
  ],
];

void main(List<String> args) {
  var optionsParser = OptionsParser();
  var configurations = <TestConfiguration>[];
  for (var commandLine in _commandLines) {
    var arguments = <String>[];
    arguments.addAll(_commonArguments);
    arguments.addAll(args);
    arguments.addAll(commandLine);
    configurations.addAll(optionsParser.parse(arguments));
  }

  if (configurations != null || configurations.isNotEmpty) {
    testConfigurations(configurations);
  }
}
