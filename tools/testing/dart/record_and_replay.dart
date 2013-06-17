// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library record_and_replay;

import 'dart:io';
import 'dart:json' as json;
import 'dart:utf';

import 'test_runner.dart';

/*
 * Json files look like this:
 *
 * [
 *   {
 *     'name' : '...',
 *     'configuration' : '...',
 *     'command' : {
 *       'timeout_limit' : 60,
 *       'executable' : '...',
 *       'arguments' : ['arg1, 'arg2', '...'],
 *     },
 *     'command_output' : {
 *       'exit_code' : 42,
 *       'stdout' : '...',
 *       'stderr' : '...',
 *       'duration' : 1.5,
 *       'did_timeout' : false,
 *     },
 *   },
 *   ....
 * ]
 */


class TestCaseRecorder {
  Path _outputPath;
  List<Map> _recordedCommandInvocations = [];
  var _cwd;

  TestCaseRecorder(this._outputPath) {
    _cwd  = new Directory.current().path;
  }

  void nextTestCase(TestCase testCase) {
    assert(testCase.commands.length == 1);

    var command = testCase.commands[0];
    assert(command.environment == null);

    var arguments = [];
    for (var rawArgument in command.arguments) {
      if (rawArgument.startsWith(_cwd)) {
        var relative = new Path(rawArgument).relativeTo(new Path(_cwd));
        arguments.add(relative.toNativePath());
      } else {
        arguments.add(rawArgument);
      }
    }

    var commandExecution = {
      'name' : testCase.displayName,
      'configuration' : testCase.configurationString,
      'command' : {
        'timeout_limit' : testCase.timeout,
        'executable' : command.executable,
        'arguments' : arguments,
      },
    };
    _recordedCommandInvocations.add(commandExecution);
  }

  void finish() {
    var file = new File.fromPath(_outputPath);
    var jsonString = json.stringify(_recordedCommandInvocations);
    file.writeAsStringSync(jsonString);
    print("TestCaseRecorder: written all TestCases to ${_outputPath}");
  }
}

class TestCaseOutputArchive {
  Map<String, Map> _testCaseOutputRecords;

  void loadFromPath(Path recordingPath) {
    var file = new File.fromPath(recordingPath);
    var testCases = json.parse(file.readAsStringSync());
    _testCaseOutputRecords = {};
    for (var testCase in testCases) {
      var key = _indexKey(testCase['configuration'], testCase['name']);
      _testCaseOutputRecords[key] = testCase['command_output'];
    }
  }

  CommandOutput outputOf(TestCase testCase) {
    var key = _indexKey(testCase.configurationString, testCase.displayName);
    var command_output = _testCaseOutputRecords[key];
    if (command_output == null) {
      print("Sorry, but there is no command output for "
            "${testCase.displayName}");

      exit(42);
    }

    double seconds = command_output['duration'];
    var duration = new Duration(seconds: seconds.round(),
                                milliseconds: (seconds/1000).round());
    var commandOutput = new CommandOutput.fromCase(
        testCase,
        testCase.commands.first,
        command_output['exit_code'],
        false,
        command_output['did_timeout'],
        encodeUtf8(command_output['stdout']),
        encodeUtf8(command_output['stderr']),
        duration,
        false);
    return commandOutput;
  }

  String _indexKey(String configuration, String name) {
    return "${configuration}__$name";
  }
}

