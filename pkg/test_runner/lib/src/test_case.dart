// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import "package:status_file/expectation.dart";

import 'command.dart';
import 'command_output.dart';
import 'configuration.dart';
import 'options.dart';
import 'output_log.dart';
import 'process_queue.dart';
import 'test_file.dart';
import 'utils.dart';

const _slowTimeoutMultiplier = 4;
const _extraSlowTimeoutMultiplier = 8;
const nonUtfFakeExitCode = 0xFFFD;

/// Some IO tests use these variables and get confused if the host environment
/// variables are inherited so they are excluded.
const _excludedEnvironmentVariables = [
  'http_proxy',
  'https_proxy',
  'no_proxy',
  'HTTP_PROXY',
  'HTTPS_PROXY',
  'NO_PROXY'
];

/// TestCase contains all the information needed to run a test and evaluate
/// its output.  Running a test involves starting a separate process, with
/// the executable and arguments given by the TestCase, and recording its
/// stdout and stderr output streams, and its exit code.  TestCase only
/// contains static information about the test; actually running the test is
/// performed by [ProcessQueue] using a [RunningProcess] object.
///
/// The output information is stored in a [CommandOutput] instance contained
/// in TestCase.commandOutputs. The last CommandOutput instance is responsible
/// for evaluating if the test has passed, failed, crashed, or timed out, and
/// the TestCase has information about what the expected result of the test
/// should be.
class TestCase {
  /// A list of commands to execute. Most test cases have a single command.
  /// Dart2js tests have two commands, one to compile the source and another
  /// to execute it. Some isolate tests might even have three, if they require
  /// compiling multiple sources that are run in isolation.
  List<Command> commands;
  Map<Command, CommandOutput> commandOutputs = {};

  TestConfiguration configuration;
  String displayName;
  Set<Expectation> expectedOutcomes;
  final TestFile testFile;

  TestCase(this.displayName, this.commands, this.configuration,
      this.expectedOutcomes,
      {this.testFile}) {
    // A test case should do something.
    assert(commands.isNotEmpty);
  }

  TestCase indexedCopy(int index) {
    var newCommands = commands.map((c) => c.indexedCopy(index)).toList();
    return TestCase(displayName, newCommands, configuration, expectedOutcomes,
        testFile: testFile);
  }

  bool get hasRuntimeError => testFile?.hasRuntimeError ?? false;
  bool get hasStaticWarning => testFile?.hasStaticWarning ?? false;
  bool get hasSyntaxError => testFile?.hasSyntaxError ?? false;
  bool get hasCompileError => testFile?.hasCompileError ?? false;
  bool get hasCrash => testFile?.hasCrash ?? false;

  bool get unexpectedOutput {
    var outcome = result;
    return !expectedOutcomes.any((expectation) {
      return outcome.canBeOutcomeOf(expectation);
    });
  }

  Expectation get result => lastCommandOutput.result(this);
  Expectation get realResult => lastCommandOutput.realResult(this);
  Expectation get realExpected {
    if (hasCrash) {
      return Expectation.crash;
    }
    if (configuration.compiler == Compiler.specParser) {
      if (hasSyntaxError) {
        return Expectation.syntaxError;
      }
    } else if (hasCompileError) {
      if (hasRuntimeError && configuration.runtime != Runtime.none) {
        return Expectation.fail;
      }
      return Expectation.compileTimeError;
    }
    if (hasRuntimeError) {
      if (configuration.runtime != Runtime.none) {
        return Expectation.runtimeError;
      }
      return Expectation.pass;
    }
    if (configuration.compiler == Compiler.dart2analyzer && hasStaticWarning) {
      return Expectation.staticWarning;
    }
    return Expectation.pass;
  }

  CommandOutput get lastCommandOutput {
    if (commandOutputs.isEmpty) {
      throw Exception("CommandOutputs is empty, maybe no command was run? ("
          "displayName: '$displayName', "
          "configurationString: '$configurationString')");
    }
    return commandOutputs[commands[commandOutputs.length - 1]];
  }

  Command get lastCommandExecuted {
    if (commandOutputs.isEmpty) {
      throw Exception("CommandOutputs is empty, maybe no command was run? ("
          "displayName: '$displayName', "
          "configurationString: '$configurationString')");
    }
    return commands[commandOutputs.length - 1];
  }

  int get timeout {
    var result = configuration.timeout;
    if (expectedOutcomes.contains(Expectation.slow)) {
      result *= _slowTimeoutMultiplier;
    } else if (expectedOutcomes.contains(Expectation.extraSlow)) {
      result *= _extraSlowTimeoutMultiplier;
    }
    return result;
  }

  String get configurationString {
    var compiler = configuration.compiler.name;
    var runtime = configuration.runtime.name;
    var mode = configuration.mode.name;
    var arch = configuration.architecture.name;
    var checked = configuration.isChecked ? '-checked' : '';
    return "$compiler-$runtime$checked ${mode}_$arch";
  }

  List<String> get batchTestArguments {
    assert(commands.last is ProcessCommand);
    return (commands.last as ProcessCommand).arguments;
  }

  bool get isFlaky {
    if (expectedOutcomes.contains(Expectation.skip) ||
        expectedOutcomes.contains(Expectation.skipByDesign)) {
      return false;
    }

    return expectedOutcomes
            .where((expectation) => expectation.isOutcome)
            .length >
        1;
  }

  bool get isFinished {
    return commandOutputs.isNotEmpty &&
        (!lastCommandOutput.successful ||
            commands.length == commandOutputs.length);
  }
}

/// Helper to get a list of all child pids for a parent process.
Future<List<int>> _getPidList(int parentId, List<String> diagnostics) async {
  var pids = [parentId];
  List<String> lines;
  var startLine = 0;
  if (io.Platform.isLinux || io.Platform.isMacOS) {
    var result =
        await io.Process.run("pgrep", ["-P", "${pids[0]}"], runInShell: true);
    lines = (result.stdout as String).split('\n');
  } else if (io.Platform.isWindows) {
    var result = await io.Process.run(
        "wmic",
        [
          "process",
          "where",
          "(ParentProcessId=${pids[0]})",
          "get",
          "ProcessId"
        ],
        runInShell: true);
    lines = (result.stdout as String).split('\n');
    // Skip first line containing header "ProcessId".
    startLine = 1;
  } else {
    assert(false);
  }
  if (lines.length > startLine) {
    for (var i = startLine; i < lines.length; ++i) {
      var pid = int.tryParse(lines[i]);
      if (pid != null) pids.add(pid);
    }
  } else {
    diagnostics.add("Could not find child pids");
    diagnostics.addAll(lines);
  }
  return pids;
}

/// A RunningProcess actually runs a test, getting the command lines from
/// its [TestCase], starting the test process (and first, a compilation
/// process if the TestCase needs compilation), creating a timeout timer, and
/// recording the results in a new [CommandOutput] object, which it attaches to
/// the TestCase. The lifetime of the RunningProcess is limited to the time it
/// takes to start the process, run the process, and record the result. There
/// are no pointers to it, so it should be available to be garbage collected as
/// soon as it is done.
class RunningProcess {
  ProcessCommand command;
  int timeout;
  bool timedOut = false;
  DateTime startTime;
  int pid;
  OutputLog stdout;
  OutputLog stderr = OutputLog();
  List<String> diagnostics = <String>[];
  bool compilationSkipped = false;
  Completer<CommandOutput> completer;
  TestConfiguration configuration;

  RunningProcess(this.command, this.timeout,
      {this.configuration, io.File outputFile}) {
    stdout = outputFile != null ? FileOutputLog(outputFile) : OutputLog();
  }

  Future<CommandOutput> run() {
    completer = Completer<CommandOutput>();
    startTime = DateTime.now();
    _runCommand();
    return completer.future;
  }

  void _runCommand() {
    if (command.outputIsUpToDate) {
      compilationSkipped = true;
      _commandComplete(0);
    } else {
      var processEnvironment = _createProcessEnvironment();
      var args = command.arguments;
      var processFuture = io.Process.start(command.executable, args,
          environment: processEnvironment,
          workingDirectory: command.workingDirectory);
      processFuture.then<dynamic>((io.Process process) {
        var stdoutFuture = process.stdout.pipe(stdout);
        var stderrFuture = process.stderr.pipe(stderr);
        pid = process.pid;

        // Close stdin so that tests that try to block on input will fail.
        process.stdin.close();
        timeoutHandler() async {
          timedOut = true;
          if (process != null) {
            String executable;
            if (io.Platform.isLinux) {
              executable = 'eu-stack';
            } else if (io.Platform.isMacOS) {
              // Try to print stack traces of the timed out process.
              // `sample` is a sampling profiler but we ask it sample for 1
              // second with a 4 second delay between samples so that we only
              // sample the threads once.
              executable = '/usr/bin/sample';
            } else if (io.Platform.isWindows) {
              var isX64 = command.executable.contains("X64") ||
                  command.executable.contains("SIMARM64");
              if (configuration.windowsSdkPath != null) {
                executable = configuration.windowsSdkPath +
                    "\\Debuggers\\${isX64 ? 'x64' : 'x86'}\\cdb.exe";
                diagnostics.add("Using $executable to print stack traces");
              } else {
                diagnostics.add("win_sdk_path not found");
              }
            } else {
              diagnostics.add("Capturing stack traces on"
                  "${io.Platform.operatingSystem} not supported");
            }
            if (executable != null) {
              var pids = await _getPidList(process.pid, diagnostics);
              diagnostics.add("Process list including children: $pids");
              for (pid in pids) {
                List<String> arguments;
                if (io.Platform.isLinux) {
                  arguments = ['-p $pid'];
                } else if (io.Platform.isMacOS) {
                  arguments = ['$pid', '1', '4000', '-mayDie'];
                } else if (io.Platform.isWindows) {
                  arguments = ['-p', '$pid', '-c', '!uniqstack;qd'];
                } else {
                  assert(false);
                }
                diagnostics.add("Trying to capture stack trace for pid $pid");
                try {
                  var result = await io.Process.run(executable, arguments);
                  diagnostics.addAll((result.stdout as String).split('\n'));
                  diagnostics.addAll((result.stderr as String).split('\n'));
                } catch (error) {
                  diagnostics.add("Unable to capture stack traces: $error");
                }
              }
            }

            if (!process.kill()) {
              diagnostics.add("Unable to kill ${process.pid}");
            }
          }
        }

        // Wait for the process to finish or timeout.
        process.exitCode
            .timeout(Duration(seconds: timeout), onTimeout: timeoutHandler)
            .then((exitCode) {
          // This timeout is used to close stdio to the subprocess once we got
          // the exitCode. Sometimes descendants of the subprocess keep stdio
          // handles alive even though the direct subprocess is dead.
          Future.wait([stdoutFuture, stderrFuture]).timeout(maxStdioDelay,
              onTimeout: () async {
            DebugLogger.warning(
                "$maxStdioDelayPassedMessage (command: $command)");
            await stdout.cancel();
            await stderr.cancel();
            return null;
          }).then((_) {
            if (stdout is FileOutputLog) {
              // Prevent logging data that has already been written to a file
              // and is unlikely too add value in the logs because the command
              // succeeded.
              stdout.complete = <int>[];
            }
            _commandComplete(exitCode);
          });
        });
      }).catchError((e) {
        // TODO(floitsch): should we try to report the stacktrace?
        print("Process error:");
        print("  Command: $command");
        print("  Error: $e");
        _commandComplete(-1);
        return true;
      });
    }
  }

  void _commandComplete(int exitCode) {
    var commandOutput = _createCommandOutput(command, exitCode);
    completer.complete(commandOutput);
  }

  CommandOutput _createCommandOutput(ProcessCommand command, int exitCode) {
    var stdoutData = stdout.toList();
    var stderrData = stderr.toList();
    if (stdout.hasNonUtf8 || stderr.hasNonUtf8) {
      // If the output contained non-utf8 formatted data, then make the exit
      // code non-zero if it isn't already.
      if (exitCode == 0) {
        exitCode = nonUtfFakeExitCode;
      }
    }
    var commandOutput = command.createOutput(
        exitCode,
        timedOut,
        stdoutData,
        stderrData,
        DateTime.now().difference(startTime),
        compilationSkipped,
        pid);
    commandOutput.diagnostics.addAll(diagnostics);
    return commandOutput;
  }

  Map<String, String> _createProcessEnvironment() {
    final environment = Map<String, String>.from(io.Platform.environment);
    environment.addAll(sanitizerEnvironmentVariables);
    if (command.environmentOverrides != null) {
      for (var key in command.environmentOverrides.keys) {
        environment[key] = command.environmentOverrides[key];
      }
    }
    for (var excludedEnvironmentVariable in _excludedEnvironmentVariables) {
      environment.remove(excludedEnvironmentVariable);
    }

    // TODO(terry): Needed for roll 50?
    environment["GLIBCPP_FORCE_NEW"] = "1";
    environment["GLIBCXX_FORCE_NEW"] = "1";

    return environment;
  }
}
