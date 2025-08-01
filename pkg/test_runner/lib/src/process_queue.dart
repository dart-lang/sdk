// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:collection/collection.dart';

import 'android.dart';
import 'browser_controller.dart';
import 'command.dart';
import 'command_output.dart';
import 'configuration.dart';
import 'dependency_graph.dart';
import 'output_log.dart';
import 'runtime_configuration.dart';
import 'test_case.dart';
import 'test_file.dart';
import 'test_progress.dart';
import 'test_suite.dart';
import 'utils.dart';

const unhandledCompilerExceptionExitCode = 253;
const parseFailExitCode = 245;

const _cannotOpenDisplayMessage = 'Gtk-WARNING **: cannot open display';
const _failedToRunCommandMessage = 'Failed to run command. return code=1';

typedef _StepFunction = Future<AdbCommandResult> Function();

class ProcessQueue {
  final TestConfiguration _globalConfiguration;
  final void Function() _allDone;
  final Graph<Command> _graph = Graph();
  final List<EventListener> _eventListener;

  ProcessQueue(
      this._globalConfiguration,
      int maxProcesses,
      int maxBrowserProcesses,
      List<TestSuite> testSuites,
      this._eventListener,
      this._allDone,
      [bool verbose = false,
      AdbDevicePool? adbDevicePool]) {
    void setupForListing(TestCaseEnqueuer testCaseEnqueuer) {
      _graph.sealed.listen((_) {
        var testCases = testCaseEnqueuer.remainingTestCases.toList();
        testCases.sort((a, b) => a.displayName.compareTo(b.displayName));

        print("\nGenerating all matching test cases ....\n");

        for (var testCase in testCases) {
          eventFinishedTestCase(testCase);
          var outcomes = testCase.expectedOutcomes.map((o) => '$o').toList()
            ..sort();
          print("${testCase.displayName}   "
              "Expectations: ${outcomes.join(', ')}   "
              "Configuration: '${testCase.configurationString}'");
        }
        eventAllTestsKnown();
      });
    }

    TestCaseEnqueuer testCaseEnqueuer;
    late CommandQueue commandQueue;

    void setupForRunning(TestCaseEnqueuer testCaseEnqueuer) {
      Timer? debugTimer;
      // If we haven't seen a single test finishing during a 10 minute period
      // something is definitely wrong, so we dump the debugging information.
      final debugTimerDuration = const Duration(minutes: 10);

      void cancelDebugTimer() {
        debugTimer?.cancel();
      }

      void resetDebugTimer() {
        cancelDebugTimer();
        debugTimer = Timer(debugTimerDuration, () {
          print("The debug timer of test.dart expired. Please report this issue"
              " to dart-engprod@ and provide the following information:");
          print("");
          print("Graph is sealed: ${_graph.isSealed}");
          print("");
          _graph.dumpCounts();
          print("");
          var unfinishedNodeStates = [
            NodeState.initialized,
            NodeState.waiting,
            NodeState.enqueuing,
            NodeState.processing
          ];

          for (var nodeState in unfinishedNodeStates) {
            if (_graph.stateCount(nodeState) > 0) {
              print("Commands in state '$nodeState':");
              print("=================================");
              print("");
              for (var node in _graph.nodes) {
                if (node.state == nodeState) {
                  var command = node.data;
                  var testCases = testCaseEnqueuer.command2testCases[command]!;
                  print("  Command: $command");
                  for (var testCase in testCases) {
                    print("    Enqueued by: ${testCase.configurationString} "
                        "-- ${testCase.displayName}");
                  }
                  print("");
                }
              }
              print("");
              print("");
            }
          }
          commandQueue.dumpState();
        });
      }

      // When the graph building is finished, notify event listeners.
      _graph.sealed.listen((_) {
        eventAllTestsKnown();
      });

      // Queue commands as they become "runnable"
      CommandEnqueuer(_graph);

      // CommandExecutor will execute commands
      var executor = CommandExecutorImpl(
          _globalConfiguration, maxProcesses, maxBrowserProcesses,
          adbDevicePool: adbDevicePool);

      // Run "runnable commands" using [executor] subject to
      // maxProcesses/maxBrowserProcesses constraint
      commandQueue = CommandQueue(_graph, testCaseEnqueuer, executor,
          maxProcesses, maxBrowserProcesses, verbose);

      // Finish test cases when all commands were run (or some failed)
      var testCaseCompleter =
          TestCaseCompleter(_graph, testCaseEnqueuer, commandQueue);
      testCaseCompleter.finishedTestCases.listen((TestCase finishedTestCase) {
        resetDebugTimer();

        eventFinishedTestCase(finishedTestCase);
      }, onDone: () {
        // Wait until the commandQueue/executor is done (it may need to stop
        // batch runners, browser controllers, ....)
        commandQueue.done.then((_) {
          cancelDebugTimer();
          eventAllTestsDone();
        });
      });

      resetDebugTimer();
    }

    // Build up the dependency graph
    testCaseEnqueuer = TestCaseEnqueuer(_graph, eventTestAdded);

    // Either list or run the tests
    if (_globalConfiguration.listTests) {
      setupForListing(testCaseEnqueuer);
    } else {
      setupForRunning(testCaseEnqueuer);
    }

    // Start enqueuing all TestCases
    testCaseEnqueuer.enqueueTestSuites(testSuites);
  }

  void eventFinishedTestCase(TestCase testCase) {
    for (var listener in _eventListener) {
      listener.done(testCase);
    }
  }

  void eventTestAdded(TestCase testCase) {
    for (var listener in _eventListener) {
      listener.testAdded();
    }
  }

  void eventAllTestsKnown() {
    for (var listener in _eventListener) {
      listener.allTestsKnown();
    }
  }

  void eventAllTestsDone() {
    for (var listener in _eventListener) {
      listener.allDone();
    }
    _allDone();
  }
}

/// [TestCaseEnqueuer] takes a list of TestSuites, generates TestCases and
/// builds a dependency graph of all commands in every TestSuite.
///
/// It maintains three helper data structures:
///
/// - command2node: A mapping from a [Command] to a node in the dependency
///   graph.
///
/// - command2testCases: A mapping from [Command] to all TestCases that it is
///   part of.
///
/// - remainingTestCases: A set of TestCases that were enqueued but are not
///   finished.
///
/// [Command] and it's subclasses all have hashCode/operator== methods defined
/// on them, so we can safely use them as keys in Map/Set objects.
class TestCaseEnqueuer {
  final Graph<Command> graph;
  final Function _onTestCaseAdded;

  final command2node = <Command, Node<Command>>{};
  final command2testCases = <Command, List<TestCase>>{};
  final remainingTestCases = <TestCase>{};

  TestCaseEnqueuer(this.graph, this._onTestCaseAdded);

  void enqueueTestSuites(List<TestSuite> testSuites) {
    // Cache information about test cases per test suite. For multiple
    // configurations there is no need to repeatedly search the file
    // system, generate tests, and search test files for options.
    var testCache = <String, List<TestFile>>{};

    for (var suite in testSuites) {
      suite.findTestCases(_add, testCache);
    }

    // We're finished with building the dependency graph.
    graph.seal();
  }

  /// Adds a test case to the list of active test cases, and adds its commands
  /// to the dependency graph of commands.
  ///
  /// If the repeat flag is > 1, replicates the test case and its commands,
  /// adding an index field with a distinct value to each of the copies.
  ///
  /// Each copy of the test case depends on the previous copy of the test
  /// case completing, with its first command having a dependency on the last
  /// command of the previous copy of the test case. This dependency is
  /// marked as a "timingDependency", so that it doesn't depend on the previous
  /// test completing successfully, just on it completing.
  void _add(TestCase testCase) {
    Node<Command>? lastNode;
    for (var i = 0; i < testCase.repeat; ++i) {
      if (i > 0) {
        testCase = testCase.indexedCopy(i);
      }
      remainingTestCases.add(testCase);
      var isFirstCommand = true;
      for (var command in testCase.commands) {
        // Make exactly *one* node in the dependency graph for every command.
        // This ensures that we never have two commands c1 and c2 in the graph
        // with "c1 == c2".
        var node = command2node[command];
        if (node == null) {
          var requiredNodes =
              (lastNode != null) ? [lastNode] : <Node<Command>>[];
          node = graph.add(command, requiredNodes,
              timingDependency: isFirstCommand);
          command2node[command] = node;
          command2testCases[command] = <TestCase>[];
        }
        // Keep mapping from command to all testCases that refer to it.
        command2testCases[command]!.add(testCase);

        lastNode = node;
        isFirstCommand = false;
      }
      _onTestCaseAdded(testCase);
    }
  }
}

/// [CommandEnqueuer] will:
///
/// - Change node.state to NodeState.enqueuing as soon as all dependencies have
///   a state of NodeState.Successful.
/// - Change node.state to NodeState.unableToRun if one or more dependencies
///   have a state of NodeState.failed/NodeState.unableToRun.
class CommandEnqueuer {
  static const _initStates = [NodeState.initialized, NodeState.waiting];

  static const _finishedStates = [
    NodeState.successful,
    NodeState.failed,
    NodeState.unableToRun
  ];

  final Graph<Command> _graph;

  CommandEnqueuer(this._graph) {
    _graph.added.listen(_changeNodeStateIfNecessary);

    _graph.changed.listen((event) {
      if (event.from == NodeState.waiting ||
          event.from == NodeState.processing) {
        if (_finishedStates.contains(event.to)) {
          for (var dependentNode in event.node.neededFor) {
            _changeNodeStateIfNecessary(dependentNode);
          }
        }
      }
    });
  }

  /// Called when either a new node was added or if one of it's dependencies
  /// changed it's state.
  void _changeNodeStateIfNecessary(Node<Command> node) {
    if (_initStates.contains(node.state)) {
      var allDependenciesFinished =
          node.dependencies.every((dep) => _finishedStates.contains(dep.state));
      var anyDependenciesUnsuccessful = node.dependencies.any((dep) =>
          [NodeState.failed, NodeState.unableToRun].contains(dep.state));
      var allDependenciesSuccessful =
          node.dependencies.every((dep) => dep.state == NodeState.successful);

      var newState = NodeState.waiting;
      if (allDependenciesSuccessful ||
          (allDependenciesFinished && node.timingDependency)) {
        newState = NodeState.enqueuing;
      } else if (anyDependenciesUnsuccessful) {
        newState = NodeState.unableToRun;
      }
      if (node.state != newState) {
        _graph.changeState(node, newState);
      }
    }
  }
}

/// [CommandQueue] will listen for nodes entering the NodeState.enqueuing state,
/// queue them up and run them. While nodes are processed they will be in the
/// NodeState.processing state. After running a command, the node will change
/// to a state of NodeState.Successful or NodeState.failed.
///
/// It provides a synchronous stream [completedCommands] which provides the
/// [CommandOutput]s for the finished commands.
///
/// It provides a [done] future, which will complete once there are no more
/// nodes left in the states Initialized/Waiting/Enqueuing/Processing
/// and the [executor] has cleaned up its resources.
class CommandQueue {
  final Graph<Command> graph;
  final CommandExecutor executor;
  final TestCaseEnqueuer enqueuer;

  final _runQueue = Queue<Command>();
  final _commandOutputStream = StreamController<CommandOutput>(sync: true);
  final _completer = Completer<void>();

  int _numProcesses = 0;
  final int _maxProcesses;
  int _numBrowserProcesses = 0;
  final int _maxBrowserProcesses;
  bool _finishing = false;
  final bool _verbose;

  CommandQueue(this.graph, this.enqueuer, this.executor, this._maxProcesses,
      this._maxBrowserProcesses, this._verbose) {
    graph.changed.listen((event) {
      if (event.to == NodeState.enqueuing) {
        assert(event.from == NodeState.initialized ||
            event.from == NodeState.waiting);
        graph.changeState(event.node, NodeState.processing);
        var command = event.node.data;
        if (event.node.dependencies.isNotEmpty) {
          _runQueue.addFirst(command);
        } else {
          _runQueue.add(command);
        }
        Timer.run(_tryRunNextCommand);
      } else if (event.to == NodeState.unableToRun) {
        _checkDone();
      }
    });

    // We're finished if the graph is sealed and all nodes are in a finished
    // state (Successful, Failed or UnableToRun).
    // So we're calling '_checkDone()' to check whether that condition is met
    // and we can cleanup.
    graph.sealed.listen((_) {
      _checkDone();
    });
  }

  Stream<CommandOutput> get completedCommands => _commandOutputStream.stream;

  Future get done => _completer.future;

  void _tryRunNextCommand() {
    _checkDone();

    if (_numProcesses < _maxProcesses && _runQueue.isNotEmpty) {
      var command = _runQueue.removeFirst();
      var isBrowserCommand = command is BrowserTestCommand;

      if (isBrowserCommand && _numBrowserProcesses == _maxBrowserProcesses) {
        // If there is no free browser runner, put it back into the queue.
        _runQueue.add(command);
        // Don't lose a process.
        Timer(const Duration(milliseconds: 100), _tryRunNextCommand);
        return;
      }

      _numProcesses++;
      if (isBrowserCommand) _numBrowserProcesses++;

      var node = enqueuer.command2node[command]!;
      Iterable<TestCase> testCases = enqueuer.command2testCases[command]!;
      // If a command is part of many TestCases we set the timeout to be
      // the maximum over all [TestCase.timeout]s. At some point, we might
      // eliminate [TestCase.timeout] completely and move it to [Command].
      var timeout =
          testCases.map((TestCase test) => test.timeout).fold(0, math.max);

      if (_verbose) {
        print('Running "${command.displayName}" command: $command');
      }

      executor.runCommand(command, timeout).then((CommandOutput output) {
        assert(command == output.command);

        _commandOutputStream.add(output);
        if (output.canRunDependentCommands) {
          graph.changeState(node, NodeState.successful);
        } else {
          graph.changeState(node, NodeState.failed);
        }

        _numProcesses--;
        if (isBrowserCommand) _numBrowserProcesses--;

        // Don't lose a process
        Timer.run(_tryRunNextCommand);
      });
    }
  }

  void _checkDone() {
    if (!_finishing &&
        _runQueue.isEmpty &&
        _numProcesses == 0 &&
        graph.isSealed &&
        graph.stateCount(NodeState.initialized) == 0 &&
        graph.stateCount(NodeState.waiting) == 0 &&
        graph.stateCount(NodeState.enqueuing) == 0 &&
        graph.stateCount(NodeState.processing) == 0) {
      _finishing = true;
      executor.cleanup().then((_) {
        _completer.complete();
        _commandOutputStream.close();
      });
    }
  }

  void dumpState() {
    print("");
    print("CommandQueue state:");
    print("  Processes: used: $_numProcesses max: $_maxProcesses");
    print("  BrowserProcesses: used: $_numBrowserProcesses "
        "max: $_maxBrowserProcesses");
    print("  Finishing: $_finishing");
    print("  Queue (length = ${_runQueue.length}):");
    for (var command in _runQueue) {
      print("      $command");
    }
  }
}

/// [CommandExecutor] is responsible for executing commands. It will make sure
/// that the following two constraints are satisfied
///  - `numberOfProcessesUsed <= maxProcesses`
///  - `numberOfBrowserProcessesUsed <= maxBrowserProcesses`
///
/// It provides a [runCommand] method which will complete with a
/// [CommandOutput] object.
///
/// It provides a [cleanup] method to free all the allocated resources.
abstract class CommandExecutor {
  Future cleanup();
  // TODO(kustermann): The [timeout] parameter should be a property of Command.
  Future<CommandOutput> runCommand(Command command, int timeout);
}

class CommandExecutorImpl implements CommandExecutor {
  final TestConfiguration globalConfiguration;
  final int maxProcesses;
  final int maxBrowserProcesses;
  AdbDevicePool? adbDevicePool;

  /// We keep a BrowserTestRunner for every configuration.
  final _browserTestRunners = <TestConfiguration, Future<BrowserTestRunner>>{};

  bool _finishing = false;

  CommandExecutorImpl(
      this.globalConfiguration, this.maxProcesses, this.maxBrowserProcesses,
      {this.adbDevicePool});

  @override
  Future cleanup() {
    assert(!_finishing);
    _finishing = true;

    Future terminateBrowserRunners() async {
      var futures = _browserTestRunners.values
          .map((runner) async => (await runner).terminate());
      return Future.wait(futures);
    }

    return Future.wait([
      BatchRunnerProcess.terminateAll(),
      terminateBrowserRunners(),
    ]);
  }

  @override
  Future<CommandOutput> runCommand(Command command, int timeout) {
    assert(!_finishing);

    Future<CommandOutput> runCommand(int retriesLeft) {
      return _runCommand(command, timeout).then((CommandOutput output) {
        if (retriesLeft > 0 && shouldRetryCommand(output)) {
          DebugLogger.warning("Rerunning Command: ($retriesLeft "
              "attempt(s) remains) [cmd: $command]");
          return runCommand(retriesLeft - 1);
        } else {
          return Future.value(output);
        }
      });
    }

    return runCommand(command.maxNumRetries);
  }

  Future<CommandOutput> _runCommand(Command command, int timeout) {
    if (command is BrowserTestCommand) {
      return _startBrowserControllerTest(command, timeout);
    } else if (command is VMKernelCompilationCommand) {
      // For now, we always run vm_compile_to_kernel in batch mode.
      var name = command.displayName;
      assert(name == 'vm_compile_to_kernel');
      return _getBatchRunner(name).runCommand(command, timeout);
    } else if (command is AnalysisCommand && globalConfiguration.batch) {
      return _getBatchRunner(command.displayName).runCommand(command, timeout);
    } else if (command is CompilationCommand &&
        (command.displayName == 'dart2js' ||
            command.displayName == 'ddc' ||
            command.displayName == 'fasta') &&
        globalConfiguration.batch) {
      return _getBatchRunner(command.displayName).runCommand(command, timeout);
    } else if (command is ScriptCommand) {
      return command.run();
    } else if (command is AdbPrecompilationCommand ||
        command is AdbDartkCommand) {
      return adbDevicePool!.acquireDevice().then((AdbDevice device) async {
        try {
          if (command is AdbPrecompilationCommand) {
            return await _runAdbPrecompilationCommand(device, command, timeout);
          } else {
            return await _runAdbDartkCommand(
                device, command as AdbDartkCommand, timeout);
          }
        } finally {
          adbDevicePool!.releaseDevice(device);
        }
      });
    } else if (command is ProcessCommand) {
      return RunningProcess(command, timeout,
              configuration: globalConfiguration)
          .run();
    } else if (command is RRCommand) {
      return command.run(timeout, globalConfiguration);
    } else {
      throw ArgumentError("Unknown command type ${command.runtimeType}.");
    }
  }

  List<_StepFunction> _pushLibraries(AdbCommand command, AdbDevice device,
      String deviceDir, String deviceTestDir) {
    var steps = <_StepFunction>[];
    for (var lib in command.extraLibraries) {
      var libName = "lib$lib.so";
      steps.add(() => device.runAdbCommand([
            'push',
            '${command.buildPath}/$libName',
            '$deviceTestDir/$libName'
          ]));
    }
    return steps;
  }

  Future<CommandOutput> _runAdbPrecompilationCommand(
      AdbDevice device, AdbPrecompilationCommand command, int timeout) async {
    var buildPath = command.buildPath;
    var processTest = command.processTestFilename;
    var abstractSocketTest = command.abstractSocketTestFilename;
    var testdir = command.precompiledTestDirectory;
    var arguments = command.arguments;
    var devicedir = DartPrecompiledAdbRuntimeConfiguration.deviceDir;
    var deviceTestDir = DartPrecompiledAdbRuntimeConfiguration.deviceTestDir;

    // We copy all the files which the vm precompiler puts into the test
    // directory.
    var files = io.Directory(testdir)
        .listSync()
        .map((file) => file.path)
        .map((path) => path.substring(path.lastIndexOf('/') + 1))
        .toList();

    var timeoutDuration = Duration(seconds: timeout);

    var steps = <_StepFunction>[];

    steps.add(() => device.runAdbShellCommand(['rm', '-Rf', deviceTestDir]));
    steps.add(() => device.runAdbShellCommand(['mkdir', '-p', deviceTestDir]));
    steps.add(() => device.pushCachedData(
        '$buildPath/exe.stripped/dartaotruntime', '$devicedir/dartaotruntime'));
    steps.add(() => device.pushCachedData(
        '$buildPath/dartaotruntime.sym', '$devicedir/dartaotruntime.sym'));
    steps.add(
        () => device.pushCachedData(processTest, '$devicedir/process_test'));
    steps.add(() => device.pushCachedData(
        abstractSocketTest, '$devicedir/abstract_socket_test'));
    steps.add(() => device.runAdbShellCommand([
          'chmod',
          '777',
          '$devicedir/dartaotruntime $devicedir/process_test $devicedir/abstract_socket_test'
        ]));

    steps.addAll(_pushLibraries(command, device, devicedir, deviceTestDir));

    for (var file in files) {
      steps.add(() => device
          .runAdbCommand(['push', '$testdir/$file', '$deviceTestDir/$file']));
    }

    steps.add(() => device.runAdbShellCommand([
          'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$deviceTestDir;'
              'export TEST_COMPILATION_DIR=$deviceTestDir;'
              '$devicedir/dartaotruntime',
          '--android-log-to-stderr',
          ...arguments,
        ], timeout: timeoutDuration));

    var stopwatch = Stopwatch()..start();
    var writer = StringBuffer();

    await device.waitForBootCompleted();
    await device.waitForDevice();

    late AdbCommandResult result;
    var exitCode = 0;
    for (var i = 0; i < steps.length; i++) {
      var fun = steps[i];
      var commandStopwatch = Stopwatch()..start();
      result = await fun();

      writer.writeln("Executing ${result.command}");
      if (result.stdout.isNotEmpty) {
        writer.writeln("Stdout:\n${result.stdout.trim()}");
      }
      if (result.stderr.isNotEmpty) {
        writer.writeln("Stderr:\n${result.stderr.trim()}");
      }
      writer.writeln("ExitCode: ${result.exitCode}");
      writer.writeln("Time: ${commandStopwatch.elapsed}");
      writer.writeln("");

      // If one command fails, we stop processing the others and return
      // immediately.
      if (result.exitCode != 0) {
        // A failure in any adb step except the final step that runs the test
        // must be reported with an adb infra failure exit code.
        // This will make the test runner exit with an infra failure.
        // See VMCommandOutput for the adb infra failure exit codes.
        if (i != steps.length - 1) {
          exitCode = 10;
        } else {
          exitCode = result.exitCode;
        }
        break;
      }
    }
    return command.createOutput(exitCode, result.timedOut,
        utf8.encode('$writer'), [], stopwatch.elapsed, false);
  }

  Future<CommandOutput> _runAdbDartkCommand(
      AdbDevice device, AdbDartkCommand command, int timeout) async {
    var buildPath = command.buildPath;
    var hostKernelFile = command.kernelFile;
    var arguments = command.arguments;
    var devicedir = DartkAdbRuntimeConfiguration.deviceDir;
    var deviceTestDir = DartkAdbRuntimeConfiguration.deviceTestDir;

    var timeoutDuration = Duration(seconds: timeout);

    var steps = <_StepFunction>[];

    steps.add(() => device.runAdbShellCommand(['rm', '-Rf', deviceTestDir]));
    steps.add(() => device.runAdbShellCommand(['mkdir', '-p', deviceTestDir]));
    steps
        .add(() => device.pushCachedData("$buildPath/dart", '$devicedir/dart'));
    steps.add(() => device
        .pushCachedData("$buildPath/dartvm", '$devicedir/dartvm'));
    steps.add(() => device
        .runAdbCommand(['push', hostKernelFile, '$deviceTestDir/out.dill']));

    steps.addAll(_pushLibraries(command, device, devicedir, deviceTestDir));

    steps.add(() => device.runAdbShellCommand([
          'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$deviceTestDir;'
              '$devicedir/dart',
          '--android-log-to-stderr',
          ...arguments,
        ], timeout: timeoutDuration));

    var stopwatch = Stopwatch()..start();
    var writer = StringBuffer();

    await device.waitForBootCompleted();
    await device.waitForDevice();

    late AdbCommandResult result;
    for (var i = 0; i < steps.length; i++) {
      var step = steps[i];
      var commandStopwatch = Stopwatch()..start();
      result = await step();

      writer.writeln("Executing ${result.command}");
      if (result.stdout.isNotEmpty) {
        writer.writeln("Stdout:\n${result.stdout.trim()}");
      }
      if (result.stderr.isNotEmpty) {
        writer.writeln("Stderr:\n${result.stderr.trim()}");
      }
      writer.writeln("ExitCode: ${result.exitCode}");
      writer.writeln("Time: ${commandStopwatch.elapsed}");
      writer.writeln("");

      // If one command fails, we stop processing the others and return
      // immediately.
      if (result.exitCode != 0) break;
    }
    return command.createOutput(result.exitCode, result.timedOut,
        utf8.encode('$writer'), [], stopwatch.elapsed, false);
  }

  BatchRunnerProcess _getBatchRunner(String identifier) =>
      BatchRunnerProcess.byIdentifier(identifier, maxProcesses);

  Future<CommandOutput> _startBrowserControllerTest(
      BrowserTestCommand browserCommand, int timeout) async {
    var completer = Completer<CommandOutput>();

    callback(BrowserTestOutput output) {
      completer.complete(BrowserCommandOutput(browserCommand, output));
    }

    var browserTest = BrowserTest(browserCommand.url, callback, timeout);
    (await _getBrowserTestRunner(browserCommand.configuration))!
        .enqueueTest(browserTest);
    return completer.future;
  }

  Future<BrowserTestRunner?> _getBrowserTestRunner(
      TestConfiguration configuration) async {
    for (var failures = 0; failures < 10; failures++) {
      BrowserTestRunner? runner;
      try {
        runner = await _browserTestRunners.putIfAbsent(
            configuration,
            () => BrowserTestRunner(configuration, globalConfiguration.localIP,
                    maxBrowserProcesses)
                .start());
      } catch (error) {
        DebugLogger.error('Failed to start browser test runner.', error);
        _browserTestRunners.remove(configuration);
        await runner!.terminate();
        continue;
      }
      if (globalConfiguration.isVerbose) {
        runner.logger = DebugLogger.info;
      }
      return runner;
    }
    print('FATAL: Failed to get a browser test runner 10 times in a row.');
    io.exit(1);
  }
}

bool shouldRetryCommand(CommandOutput output) {
  if (output.successful) {
    return false;
  }

  late var stdout = decodeUtf8(output.stdout).split("\n");
  late var stderr = decodeUtf8(output.stderr).split("\n");

  final command = output.command;

  // The dartk batch compiler sometimes runs out of memory. In such a case we
  // will retry running it.
  if (command is VMKernelCompilationCommand) {
    if (output.hasCrashed) {
      bool containsOutOfMemoryMessage(String line) {
        return line.contains('Exhausted heap space, trying to allocat');
      }

      if (stdout.any(containsOutOfMemoryMessage) ||
          stderr.any(containsOutOfMemoryMessage)) {
        return true;
      }
    }
  }

  if (io.Platform.operatingSystem == 'linux') {
    // No matter which command we ran: If we get failures due to the
    // "xvfb-run" issue 7564, try re-running the test.
    bool containsFailureMsg(String line) {
      return line.contains(_cannotOpenDisplayMessage) ||
          line.contains(_failedToRunCommandMessage);
    }

    if (stdout.any(containsFailureMsg) || stderr.any(containsFailureMsg)) {
      return true;
    }
  }
  return false;
}

/// [TestCaseCompleter] will listen for
/// NodeState.processing -> NodeState.{successful,failed} state changes and
/// will complete a TestCase if it is finished.
///
/// It provides a stream [finishedTestCases], which will stream all TestCases
/// once they're finished. After all TestCases are done, the stream will be
/// closed.
class TestCaseCompleter {
  static const _completedStates = [NodeState.failed, NodeState.successful];

  final Graph<Command> _graph;
  final TestCaseEnqueuer _enqueuer;
  final CommandQueue _commandQueue;

  final Map<Command, CommandOutput> _outputs = {};
  final StreamController<TestCase> _controller = StreamController();
  bool _closed = false;

  TestCaseCompleter(this._graph, this._enqueuer, this._commandQueue) {
    var finishedRemainingTestCases = false;

    // Store all the command outputs -- they will be delivered synchronously
    // (i.e. before state changes in the graph)
    _commandQueue.completedCommands.listen((CommandOutput output) {
      _outputs[output.command] = output;
    }, onDone: () {
      _completeTestCasesIfPossible(List.from(_enqueuer.remainingTestCases));
      finishedRemainingTestCases = true;
      assert(_enqueuer.remainingTestCases.isEmpty);
      _checkDone();
    });

    // Listen for NodeState.Processing -> NodeState.{Successful,Failed}
    // changes.
    _graph.changed.listen((event) {
      if (event.from == NodeState.processing && !finishedRemainingTestCases) {
        var command = event.node.data;

        assert(_completedStates.contains(event.to));
        assert(_outputs[command] != null);

        _completeTestCasesIfPossible(_enqueuer.command2testCases[command]!);
        _checkDone();
      }
    });

    // Listen also for GraphSealedEvents. If there is not a single node in the
    // graph, we still want to finish after the graph was sealed.
    _graph.sealed.listen((_) {
      if (!_closed && _enqueuer.remainingTestCases.isEmpty) {
        _controller.close();
        _closed = true;
      }
    });
  }

  Stream<TestCase> get finishedTestCases => _controller.stream;

  void _checkDone() {
    if (!_closed && _graph.isSealed && _enqueuer.remainingTestCases.isEmpty) {
      _controller.close();
      _closed = true;
    }
  }

  void _completeTestCasesIfPossible(Iterable<TestCase> testCases) {
    // Update TestCases with command outputs.
    for (var test in testCases) {
      for (var icommand in test.commands) {
        var output = _outputs[icommand];
        if (output != null) {
          test.commandOutputs[icommand] = output;
        }
      }
    }

    void completeTestCase(TestCase testCase) {
      if (_enqueuer.remainingTestCases.contains(testCase)) {
        _controller.add(testCase);
        _enqueuer.remainingTestCases.remove(testCase);
      } else {
        DebugLogger.error("${testCase.displayName} would be finished twice");
      }
    }

    for (var testCase in testCases) {
      // Ask the [testCase] if it's done. Note that we assume, that
      // [TestCase.isFinished] will return true if all commands were executed
      // or if a previous one failed.
      if (testCase.isFinished) {
        completeTestCase(testCase);
      }
    }
  }
}

class BatchRunnerProcess {
  /// For dart2js and analyzer batch processing,
  /// we keep a list of batch processes.
  static final _batchProcesses = <String, List<BatchRunnerProcess>>{};

  /// When true, the command line is passed to the test runner as a
  /// JSON-encoded list of strings.
  final bool _useJson;

  ProcessCommand? _command;
  late List<String> _arguments;

  bool _processJustStarted = false;
  io.Process? _process;
  Map<String, String>? _processEnvironmentOverrides;
  late Completer<void> _stdoutCompleter;
  late Completer<void> _stderrCompleter;
  late StreamSubscription<String> _stdoutSubscription;
  late StreamSubscription<String> _stderrSubscription;
  late Function(int) _processExitHandler;

  late OutputLog _testStdout;
  late OutputLog _testStderr;
  String? _status;
  late DateTime _startTime;
  Timer? _timer;

  static const int _extraStartupTimeout = 60;

  static Future terminateAll() => Future.wait([
        for (var runners in _batchProcesses.values)
          for (var runner in runners) runner.terminate()
      ]);

  BatchRunnerProcess._(this._useJson);

  factory BatchRunnerProcess.byIdentifier(String identifier, int maxProcesses) {
    // Start batch processes if needed.
    var runners = _batchProcesses.putIfAbsent(
        identifier,
        () => List<BatchRunnerProcess>.generate(
            maxProcesses, (_) => BatchRunnerProcess._(identifier == "fasta")));

    for (var runner in runners) {
      if (!runner._currentlyRunning) return runner;
    }
    throw Exception('Unable to find inactive batch runner.');
  }

  bool get _currentlyRunning => _command != null;

  bool isCompatibleRunner(ProcessCommand command) => const MapEquality()
      .equals(_processEnvironmentOverrides, command.environmentOverrides);

  bool get hasRunningProcess => _process != null;

  Future<CommandOutput> runCommand(ProcessCommand command, int timeout) async {
    assert(!_currentlyRunning);

    if (!isCompatibleRunner(command)) {
      await terminate();
    }
    _command = command;
    _arguments = command.arguments;
    _processEnvironmentOverrides = command.environmentOverrides;
    if (_process == null) {
      await _startProcess();
    }
    return await _doStartTest(timeout);
  }

  Future<void> terminate() async {
    if (_process == null) return;
    var terminateCompleter = Completer<void>();
    final sigkillTimer = Timer(const Duration(seconds: 5), () {
      _process?.kill(io.ProcessSignal.sigkill);
    });
    _processExitHandler = (_) {
      sigkillTimer.cancel();
      _process = null;
      terminateCompleter.complete();
    };
    _process!.kill();
    _stdoutSubscription.cancel();
    _stderrSubscription.cancel();

    return terminateCompleter.future;
  }

  Future<CommandOutput> _doStartTest(int timeout) async {
    if (_processJustStarted) {
      // We just started the process, add some extra timeout to account for
      // the startup cost of the batch compiler.
      _processJustStarted = false;
      timeout += _extraStartupTimeout;
    }
    _startTime = DateTime.now();
    _testStdout = OutputLog();
    _testStderr = OutputLog();
    _status = null;
    _stdoutCompleter = Completer();
    _stderrCompleter = Completer();
    _stdoutSubscription.resume();
    _stderrSubscription.resume();
    _timer = Timer(Duration(seconds: timeout), _timeoutHandler);

    var line = _createArgumentsLine(_arguments, timeout);
    _process!.stdin.write(line);
    await (_stdoutCompleter.future, _stderrCompleter.future).wait;
    if (_status == null) {
      await _process!.exitCode;
    }
    return _reportResult();
  }

  String _createArgumentsLine(List<String> arguments, int timeout) {
    arguments = arguments.map(escapeCommandLineArgument).toList();
    if (_useJson) {
      return "${jsonEncode(arguments)}\n";
    } else {
      return '${arguments.join(' ')}\n';
    }
  }

  CommandOutput _reportResult() {
    var outcome = _status!.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = unhandledCompilerExceptionExitCode;
    if (outcome == "PARSE_FAIL") exitCode = parseFailExitCode;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;

    // Fail if the output was too long or incorrectly formatted.
    if (_testStdout.hasNonUtf8 || _testStderr.hasNonUtf8) {
      exitCode = nonUtfFakeExitCode;
    } else if (_testStdout.wasTruncated || _testStderr.wasTruncated) {
      exitCode = truncatedFakeExitCode;
    }

    var output = _command!.createOutput(
        exitCode,
        outcome == "TIMEOUT",
        _testStdout.bytes,
        _testStderr.bytes,
        DateTime.now().difference(_startTime),
        false);
    _command = null;
    return output;
  }

  void Function(int) _makeExitHandler(String status) {
    return (int exitCode) {
      if (_currentlyRunning) {
        _timer?.cancel();
        _status = status;
        _stdoutSubscription.cancel();
        _stderrSubscription.cancel();
      }
      // No active test case running.
      _process = null;
    };
  }

  void _timeoutHandler() {
    _processExitHandler = _makeExitHandler(">>> TEST TIMEOUT");
    _process!.kill();
  }

  Future<void> _startProcess() async {
    var executable = _command!.executable;
    var arguments = [..._command!.batchArguments, '--batch'];
    var environment = {
      ...io.Platform.environment,
      ...?_processEnvironmentOverrides,
    };
    try {
      _process = await io.Process.start(executable, arguments,
          environment: environment);
      _processJustStarted = true;
    } catch (e) {
      // TODO(floitsch): should we try to report the stacktrace?
      print("Process error:");
      print("  Command: $executable ${arguments.join(' ')} ($_arguments)");
      print("  Error: $e");
      // If there is an error starting a batch process, chances are that
      // it will always fail. So rather than re-trying a 1000+ times, we
      // exit.
      io.exit(1);
    }

    var stdoutStream = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    _stdoutSubscription = stdoutStream.listen((String line) {
      if (line.startsWith('>>> TEST')) {
        _status = line;
      } else if (line.startsWith('>>> BATCH')) {
        // ignore
      } else if (line.startsWith('>>> ')) {
        throw Exception("Unexpected command from batch runner: '$line'.");
      } else {
        _testStdout.add(utf8.encode(line));
        _testStdout.add("\n".codeUnits);
      }
      if (_status != null) {
        _stdoutSubscription.pause();
        _timer!.cancel();
        _stdoutCompleter.complete();
      }
    }, onDone: () => _stdoutCompleter.complete());
    _stdoutSubscription.pause();

    var stderrStream = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    _stderrSubscription = stderrStream.listen((String line) {
      if (line.startsWith('>>> EOF STDERR')) {
        _stderrSubscription.pause();
        _stderrCompleter.complete();
      } else {
        _testStderr.add(utf8.encode(line));
        _testStderr.add("\n".codeUnits);
      }
    }, onDone: () => _stderrCompleter.complete());
    _stderrSubscription.pause();

    _process!.stdin.done.catchError((Object err) {
      print('Error on batch runner input stream stdin');
      print('  Previous test\'s status: $_status');
      print('  Error: $err');
      throw err;
    });

    _processExitHandler = _makeExitHandler(">>> TEST CRASH");
    _process!.exitCode.then((exitCode) => _processExitHandler(exitCode));
  }
}
