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
 * [: ./tools/testing/bin/$OS/dart tools/testing/dart/co19_test.dart :]
 */

#library("co19_test");

#import("dart:io");
#import("test_runner.dart");
#import("test_options.dart");
#import("test_suite.dart");
#import("test_progress.dart");

#import("../../../tests/co19/test_config.dart");

const List<String> COMMON_ARGUMENTS = const <String>['--report'];

const List<List<String>> COMMAND_LINES = const <List<String>>[
    const <String>['-mrelease,debug', '-rvm', '-cnone'],
    const <String>['-mrelease,debug', '-rvm', '-cnone', '--checked'],
    const <String>['-mrelease', '-rnone', '-cdartc'],
    const <String>['-mrelease', '-rvm', '-cdart2dart'],
    const <String>['-mrelease', '-rd8', '-cdart2js'],
    const <String>['-mrelease', '-rd8', '-cdart2js', '--checked']];

void main() {
  File scriptFile = new File(new Options().script);
  Path scriptPath =
      new Path.fromNative(scriptFile.fullPathSync())
      .directoryPath.directoryPath.directoryPath.append('test.dart');
  TestUtils.testScriptPath = scriptPath.toNativePath();
  var startTime = new Date.now();
  var optionsParser = new TestOptionsParser();
  List<Map> configurations = <Map>[];
  for (var commandLine in COMMAND_LINES) {
    List arguments = <String>[];
    arguments.addAll(COMMON_ARGUMENTS);
    arguments.addAll(commandLine);
    arguments.add('co19');
    configurations.addAll(optionsParser.parse(arguments));
  }
  if (configurations == null || configurations.isEmpty()) return;

  var firstConfiguration = configurations[0];
  Map<String, RegExp> selectors = firstConfiguration['selectors'];
  var maxProcesses = firstConfiguration['tasks'];
  var verbose = firstConfiguration['verbose'];
  var listTests = firstConfiguration['list'];

  var configurationIterator = configurations.iterator();
  void enqueueConfiguration(ProcessQueue queue) {
    if (!configurationIterator.hasNext()) return;
    var configuration = configurationIterator.next();
    for (String selector in selectors.getKeys()) {
      if (selector == 'co19') {
        queue.addTestSuite(new Co19TestSuite(configuration));
      } else {
        throw 'Error: unexpected selector: "$selector".';
      }
    }
  }

  // Start process queue.
  var queue = new ProcessQueue(maxProcesses,
                               'diff',
                               startTime,
                               false,
                               enqueueConfiguration,
                               () {},
                               verbose,
                               listTests);
}
