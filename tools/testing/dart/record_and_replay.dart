// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library record_and_replay;

import 'dart:io';
import 'dart:convert';

import 'path.dart';
import 'test_runner.dart';

/*
 * Json files look like this:
 *
 * [
 *   {
 *     'name' : '...',
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

List<String> makePathsRelativeToDart(String cwd, List<String> arguments) {
  var relativeArguments = [];
  for (var rawArgument in arguments) {
    if (rawArgument.startsWith(cwd)) {
      var relative = new Path(rawArgument).relativeTo(new Path(cwd));
      relativeArguments.add(relative.toNativePath());
    } else {
      relativeArguments.add(rawArgument);
    }
  }
  return relativeArguments;
}

class TestCaseRecorder {
  Path _outputPath;
  List<Map> _recordedCommandInvocations = [];
  var _cwd;

  TestCaseRecorder(this._outputPath) {
    _cwd  = Directory.current.path;
  }

  void nextCommand(ProcessCommand command, int timeout) {
    // Convert arguments from absolute to relative paths (relative to the dart
    // directory) because the absolute path on the machine where we record
    // may be different from the absolute path on the machine where we execute
    // the commands.
    var arguments = makePathsRelativeToDart(_cwd, command.arguments);

    var commandExecution = {
      'name' : command.displayName,
      'command' : {
        'timeout_limit' : timeout,
        'executable' : command.executable,
        'arguments' : arguments,
      },
    };
    _recordedCommandInvocations.add(commandExecution);
  }

  void finish() {
    var file = new File(_outputPath.toNativePath());
    var jsonString = JSON.encode(_recordedCommandInvocations);
    file.writeAsStringSync(jsonString);
    print("TestCaseRecorder: written all TestCases to ${_outputPath}");
  }
}

class TestCaseOutputArchive {
  Map<String, Map> _commandOutputRecordings;
  var _cwd;

  TestCaseOutputArchive() {
    _cwd  = Directory.current.path;
  }

  void loadFromPath(Path recordingPath) {
    var file = new File(recordingPath.toNativePath());
    var commandRecordings = JSON.decode(file.readAsStringSync());
    _commandOutputRecordings = {};
    for (var commandRecording in commandRecordings) {
      var key = _indexKey(commandRecording['command']['executable'],
                          commandRecording['command']['arguments'].join(' '));
      _commandOutputRecordings[key] = commandRecording['command_output'];
    }
  }

  CommandOutput outputOf(ProcessCommand command) {
    // Convert arguments from absolute to relative paths (relative to the dart
    // directory) because the absolute path on the machine where we record
    // may be different from the absolute path on the machine where we execute
    // the commands.
    var arguments = makePathsRelativeToDart(_cwd, command.arguments);

    var key = _indexKey(command.executable, arguments.join(' '));
    var command_output = _commandOutputRecordings[key];
    if (command_output == null) {
      print("Sorry, but there is no command output for ${command.displayName}"
            " ($command)");
      exit(42);
    }

    double seconds = command_output['duration'];
    var duration = new Duration(seconds: seconds.round(),
                                milliseconds: (seconds/1000).round());
    var commandOutput = createCommandOutput(
        command,
        command_output['exit_code'],
        command_output['did_timeout'],
        UTF8.encode(command_output['stdout']),
        UTF8.encode(command_output['stderr']),
        duration,
        false);
    return commandOutput;
  }

  String _indexKey(String executable, String arguments) {
    return "${executable}__$arguments";
  }
}

