// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Classes and methods for executing tests.
 *
 * This module includes:
 * - Managing parallel execution of tests, including timeout checks.
 * - Evaluating the output of each test as pass/fail/crash/timeout.
 */
library test_runner;

import "dart:async";
import "dart:collection" show Queue;
import "dart:convert" show LineSplitter, UTF8, JSON;
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import "dart:io" as io;
import "dart:math" as math;

import 'package:yaml/yaml.dart';

import 'android.dart';
import 'dependency_graph.dart' as dgraph;
import "browser_controller.dart";
import "path.dart";
import "status_file_parser.dart";
import "test_progress.dart";
import "test_suite.dart";
import "utils.dart";
import 'record_and_replay.dart';

const int CRASHING_BROWSER_EXITCODE = -10;
const int SLOW_TIMEOUT_MULTIPLIER = 4;

const MESSAGE_CANNOT_OPEN_DISPLAY = 'Gtk-WARNING **: cannot open display';
const MESSAGE_FAILED_TO_RUN_COMMAND = 'Failed to run command. return code=1';

typedef void TestCaseEvent(TestCase testCase);
typedef void ExitCodeEvent(int exitCode);
typedef void EnqueueMoreWork(ProcessQueue queue);

// Some IO tests use these variables and get confused if the host environment
// variables are inherited so they are excluded.
const List<String> EXCLUDED_ENVIRONMENT_VARIABLES = const [
  'http_proxy',
  'https_proxy',
  'no_proxy',
  'HTTP_PROXY',
  'HTTPS_PROXY',
  'NO_PROXY'
];

/** A command executed as a step in a test case. */
class Command {
  /** A descriptive name for this command. */
  String displayName;

  /** Number of times this command *can* be retried */
  int get maxNumRetries => 2;

  /** Reproduction command */
  String get reproductionCommand => null;

  // We compute the Command.hashCode lazily and cache it here, since it might
  // be expensive to compute (and hashCode is called often).
  int _cachedHashCode;

  Command._(this.displayName);

  int get hashCode {
    if (_cachedHashCode == null) {
      var builder = new HashCodeBuilder();
      _buildHashCode(builder);
      _cachedHashCode = builder.value;
    }
    return _cachedHashCode;
  }

  operator ==(other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType && _equal(other));

  void _buildHashCode(HashCodeBuilder builder) {
    builder.addJson(displayName);
  }

  bool _equal(Command other) =>
      hashCode == other.hashCode && displayName == other.displayName;

  String toString() => reproductionCommand;

  Future<bool> get outputIsUpToDate => new Future.value(false);
}

class ProcessCommand extends Command {
  /** Path to the executable of this command. */
  String executable;

  /** Command line arguments to the executable. */
  List<String> arguments;

  /** Environment for the command */
  Map<String, String> environmentOverrides;

  /** Working directory for the command */
  final String workingDirectory;

  ProcessCommand._(String displayName, this.executable, this.arguments,
      [this.environmentOverrides = null, this.workingDirectory = null])
      : super._(displayName) {
    if (io.Platform.operatingSystem == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // NOTE: Issue 1306
      executable = executable.replaceAll('/', '\\');
    }
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(executable);
    builder.addJson(workingDirectory);
    builder.addJson(arguments);
    builder.addJson(environmentOverrides);
  }

  bool _equal(ProcessCommand other) =>
      super._equal(other) &&
      executable == other.executable &&
      deepJsonCompare(arguments, other.arguments) &&
      workingDirectory == other.workingDirectory &&
      deepJsonCompare(environmentOverrides, other.environmentOverrides);

  String get reproductionCommand {
    var env = new StringBuffer();
    environmentOverrides?.forEach((key, value) =>
        (io.Platform.operatingSystem == 'windows')
            ? env.write('set $key=${escapeCommandLineArgument(value)} & ')
            : env.write('$key=${escapeCommandLineArgument(value)} '));
    var command = ([executable]..addAll(arguments))
        .map(escapeCommandLineArgument)
        .join(' ');
    if (workingDirectory != null) {
      command = "$command (working directory: $workingDirectory)";
    }
    return "$env$command";
  }

  Future<bool> get outputIsUpToDate => new Future.value(false);
}

class CompilationCommand extends ProcessCommand {
  final String _outputFile;
  final bool _neverSkipCompilation;
  final List<Uri> _bootstrapDependencies;

  CompilationCommand._(
      String displayName,
      this._outputFile,
      this._neverSkipCompilation,
      this._bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._(displayName, executable, arguments, environmentOverrides);

  Future<bool> get outputIsUpToDate {
    if (_neverSkipCompilation) return new Future.value(false);

    Future<List<Uri>> readDepsFile(String path) {
      var file = new io.File(new Path(path).toNativePath());
      if (!file.existsSync()) {
        return new Future.value(null);
      }
      return file.readAsLines().then((List<String> lines) {
        var dependencies = new List<Uri>();
        for (var line in lines) {
          line = line.trim();
          if (line.length > 0) {
            dependencies.add(Uri.parse(line));
          }
        }
        return dependencies;
      });
    }

    return readDepsFile("$_outputFile.deps").then((dependencies) {
      if (dependencies != null) {
        dependencies.addAll(_bootstrapDependencies);
        var jsOutputLastModified = TestUtils.lastModifiedCache
            .getLastModified(new Uri(scheme: 'file', path: _outputFile));
        if (jsOutputLastModified != null) {
          for (var dependency in dependencies) {
            var dependencyLastModified =
                TestUtils.lastModifiedCache.getLastModified(dependency);
            if (dependencyLastModified == null ||
                dependencyLastModified.isAfter(jsOutputLastModified)) {
              return false;
            }
          }
          return true;
        }
      }
      return false;
    });
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_outputFile);
    builder.addJson(_neverSkipCompilation);
    builder.addJson(_bootstrapDependencies);
  }

  bool _equal(CompilationCommand other) =>
      super._equal(other) &&
      _outputFile == other._outputFile &&
      _neverSkipCompilation == other._neverSkipCompilation &&
      deepJsonCompare(_bootstrapDependencies, other._bootstrapDependencies);
}

class KernelCompilationCommand extends CompilationCommand {
  KernelCompilationCommand._(
      String displayName,
      String outputFile,
      bool neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._(displayName, outputFile, neverSkipCompilation,
                bootstrapDependencies, executable, arguments,
                environmentOverrides);
}

/// This is just a Pair(String, Map) class with hashCode and operator ==
class AddFlagsKey {
  final String flags;
  final Map env;
  AddFlagsKey(this.flags, this.env);
  // Just use object identity for environment map
  bool operator ==(other) =>
      other is AddFlagsKey && flags == other.flags && env == other.env;
  int get hashCode => flags.hashCode ^ env.hashCode;
}

class ContentShellCommand extends ProcessCommand {
  ContentShellCommand._(
      String executable,
      String htmlFile,
      List<String> options,
      List<String> dartFlags,
      Map<String, String> environmentOverrides)
      : super._("content_shell", executable, _getArguments(options, htmlFile),
            _getEnvironment(environmentOverrides, dartFlags));

  // Cache the modified environments in a map from the old environment and
  // the string of Dart flags to the new environment.  Avoid creating new
  // environment object for each command object.
  static Map<AddFlagsKey, Map> environments = new Map<AddFlagsKey, Map>();

  static Map _getEnvironment(Map env, List<String> dartFlags) {
    var needDartFlags = dartFlags != null && dartFlags.length > 0;
    if (needDartFlags) {
      if (env == null) {
        env = const {};
      }
      var flags = dartFlags.join(' ');
      return environments.putIfAbsent(
          new AddFlagsKey(flags, env),
          () => new Map.from(env)
            ..addAll({'DART_FLAGS': flags, 'DART_FORWARDING_PRINT': '1'}));
    }
    return env;
  }

  static List<String> _getArguments(List<String> options, String htmlFile) {
    var arguments = new List.from(options);
    arguments.add(htmlFile);
    return arguments;
  }

  int get maxNumRetries => 3;
}

class BrowserTestCommand extends Command {
  final String browser;
  final String url;
  final Map configuration;
  final bool retry;

  BrowserTestCommand._(
      String _browser, this.url, this.configuration, this.retry)
      : super._(_browser),
        browser = _browser;

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(browser);
    builder.addJson(url);
    builder.add(configuration);
    builder.add(retry);
  }

  bool _equal(BrowserTestCommand other) =>
      super._equal(other) &&
      browser == other.browser &&
      url == other.url &&
      identical(configuration, other.configuration) &&
      retry == other.retry;

  String get reproductionCommand {
    var parts = [
      io.Platform.resolvedExecutable,
      'tools/testing/dart/launch_browser.dart',
      browser,
      url
    ];
    return parts.map(escapeCommandLineArgument).join(' ');
  }

  int get maxNumRetries => 4;
}

class BrowserHtmlTestCommand extends BrowserTestCommand {
  List<String> expectedMessages;
  BrowserHtmlTestCommand._(String browser, String url, Map configuration,
      this.expectedMessages, bool retry)
      : super._(browser, url, configuration, retry);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(expectedMessages);
  }

  bool _equal(BrowserHtmlTestCommand other) =>
      super._equal(other) &&
      identical(expectedMessages, other.expectedMessages);
}

class AnalysisCommand extends ProcessCommand {
  final String flavor;

  AnalysisCommand._(this.flavor, String displayName, String executable,
      List<String> arguments, Map<String, String> environmentOverrides)
      : super._(displayName, executable, arguments, environmentOverrides);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(flavor);
  }

  bool _equal(AnalysisCommand other) =>
      super._equal(other) && flavor == other.flavor;
}

class VmCommand extends ProcessCommand {
  VmCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._("vm", executable, arguments, environmentOverrides);
}

class AdbPrecompilationCommand extends Command {
  final String precompiledRunnerFilename;
  final String processTestFilename;
  final String precompiledTestDirectory;
  final List<String> arguments;
  final bool useBlobs;

  AdbPrecompilationCommand._(this.precompiledRunnerFilename,
                             this.processTestFilename,
                             this.precompiledTestDirectory,
                             this.arguments,
                             this.useBlobs)
      : super._("adb_precompilation");

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(precompiledRunnerFilename);
    builder.add(precompiledTestDirectory);
    builder.add(arguments);
    builder.add(useBlobs);
  }

  bool _equal(AdbPrecompilationCommand other) =>
      super._equal(other) &&
      precompiledRunnerFilename == other.precompiledRunnerFilename &&
      useBlobs == other.useBlobs &&
      arguments == other.arguments &&
      precompiledTestDirectory == other.precompiledTestDirectory;

  String toString() => 'Steps to push precompiled runner and precompiled code '
      'to an attached device. Uses (and requires) adb.';
}

class JSCommandlineCommand extends ProcessCommand {
  JSCommandlineCommand._(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environmentOverrides = null])
      : super._(displayName, executable, arguments, environmentOverrides);
}

class PubCommand extends ProcessCommand {
  final String command;

  PubCommand._(String pubCommand, String pubExecutable,
      String pubspecYamlDirectory, String pubCacheDirectory)
      : super._(
            'pub_$pubCommand',
            new io.File(pubExecutable).absolute.path,
            [pubCommand],
            {'PUB_CACHE': pubCacheDirectory},
            pubspecYamlDirectory),
        command = pubCommand;

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(command);
  }

  bool _equal(PubCommand other) =>
      super._equal(other) && command == other.command;
}

/* [ScriptCommand]s are executed by dart code. */
abstract class ScriptCommand extends Command {
  ScriptCommand._(String displayName) : super._(displayName);

  Future<ScriptCommandOutputImpl> run();
}

class CleanDirectoryCopyCommand extends ScriptCommand {
  final String _sourceDirectory;
  final String _destinationDirectory;

  CleanDirectoryCopyCommand._(this._sourceDirectory, this._destinationDirectory)
      : super._('dir_copy');

  String get reproductionCommand =>
      "Copying '$_sourceDirectory' to '$_destinationDirectory'.";

  Future<ScriptCommandOutputImpl> run() {
    var watch = new Stopwatch()..start();

    var destination = new io.Directory(_destinationDirectory);

    return destination.exists().then((bool exists) {
      var cleanDirectoryFuture;
      if (exists) {
        cleanDirectoryFuture = TestUtils.deleteDirectory(_destinationDirectory);
      } else {
        cleanDirectoryFuture = new Future.value(null);
      }
      return cleanDirectoryFuture.then((_) {
        return TestUtils.copyDirectory(_sourceDirectory, _destinationDirectory);
      });
    }).then((_) {
      return new ScriptCommandOutputImpl(
          this, Expectation.PASS, "", watch.elapsed);
    }).catchError((error) {
      return new ScriptCommandOutputImpl(
          this, Expectation.FAIL, "An error occured: $error.", watch.elapsed);
    });
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_sourceDirectory);
    builder.addJson(_destinationDirectory);
  }

  bool _equal(CleanDirectoryCopyCommand other) =>
      super._equal(other) &&
      _sourceDirectory == other._sourceDirectory &&
      _destinationDirectory == other._destinationDirectory;
}

class ModifyPubspecYamlCommand extends ScriptCommand {
  String _pubspecYamlFile;
  String _destinationFile;
  Map<String, Map> _dependencyOverrides;

  ModifyPubspecYamlCommand._(
      this._pubspecYamlFile, this._destinationFile, this._dependencyOverrides)
      : super._("modify_pubspec") {
    assert(_pubspecYamlFile.endsWith("pubspec.yaml"));
    assert(_destinationFile.endsWith("pubspec.yaml"));
  }

  static Map<String, Map> _filterOverrides(
      String pubspec, Map<String, Map> overrides) {
    if (overrides.isEmpty) return overrides;
    var yaml = loadYaml(pubspec);
    var deps = yaml['dependencies'];
    var filteredOverrides = <String, Map>{};
    if (deps != null) {
      for (var d in deps.keys) {
        if (!overrides.containsKey(d)) {
          // pub depends on compiler_unsupported instead of compiler
          // The dependency is so hackish that we currently ignore it here.
          if (d == 'compiler_unsupported') continue;
          throw "Repo doesn't have package $d used in $pubspec";
        }
        filteredOverrides[d] = overrides[d];
      }
    }
    return filteredOverrides;
  }

  String get reproductionCommand =>
      "Adding necessary dependency overrides to '$_pubspecYamlFile' "
      "(destination = $_destinationFile).";

  Future<ScriptCommandOutputImpl> run() {
    var watch = new Stopwatch()..start();

    var pubspecLockFile = _destinationFile.substring(
            0, _destinationFile.length - ".yaml".length) +
        ".lock";

    var file = new io.File(_pubspecYamlFile);
    var destinationFile = new io.File(_destinationFile);
    var lockfile = new io.File(pubspecLockFile);
    return file.readAsString().then((String yamlString) {
      var overrides = _filterOverrides(yamlString, _dependencyOverrides);
      var dependencyOverrideSection = new StringBuffer();
      if (_dependencyOverrides.isNotEmpty) {
        dependencyOverrideSection.write("\n"
            "# This section was autogenerated by test.py!\n"
            "dependency_overrides:\n");
        overrides.forEach((String packageName, Map override) {
          dependencyOverrideSection.write("  $packageName:\n");
          override.forEach((overrideKey, overrideValue) {
            dependencyOverrideSection
                .write("    $overrideKey: $overrideValue\n");
          });
        });
      }
      var modifiedYamlString = "$yamlString\n$dependencyOverrideSection";
      return destinationFile.writeAsString(modifiedYamlString).then((_) {
        lockfile.exists().then((bool lockfileExists) {
          if (lockfileExists) {
            return lockfile.delete();
          }
        });
      });
    }).then((_) {
      return new ScriptCommandOutputImpl(
          this, Expectation.PASS, "", watch.elapsed);
    }).catchError((error) {
      return new ScriptCommandOutputImpl(
          this, Expectation.FAIL, "An error occured: $error.", watch.elapsed);
    });
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_pubspecYamlFile);
    builder.addJson(_destinationFile);
    builder.addJson(_dependencyOverrides);
  }

  bool _equal(ModifyPubspecYamlCommand other) =>
      super._equal(other) &&
      _pubspecYamlFile == other._pubspecYamlFile &&
      _destinationFile == other._destinationFile &&
      deepJsonCompare(_dependencyOverrides, other._dependencyOverrides);
}

/*
 * [MakeSymlinkCommand] makes a symbolic link to another directory.
 */
class MakeSymlinkCommand extends ScriptCommand {
  String _link;
  String _target;

  MakeSymlinkCommand._(this._link, this._target) : super._('make_symlink');

  String get reproductionCommand =>
      "Make symbolic link '$_link' (target: $_target)'.";

  Future<ScriptCommandOutputImpl> run() {
    var watch = new Stopwatch()..start();
    var targetFile = new io.Directory(_target);
    return targetFile.exists().then((bool targetExists) {
      if (!targetExists) {
        throw new Exception("Target '$_target' does not exist");
      }
      var link = new io.Link(_link);

      return link.exists().then((bool exists) {
        if (exists) return link.delete();
      }).then((_) => link.create(_target));
    }).then((_) {
      return new ScriptCommandOutputImpl(
          this, Expectation.PASS, "", watch.elapsed);
    }).catchError((error) {
      return new ScriptCommandOutputImpl(
          this, Expectation.FAIL, "An error occured: $error.", watch.elapsed);
    });
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_link);
    builder.addJson(_target);
  }

  bool _equal(MakeSymlinkCommand other) =>
      super._equal(other) && _link == other._link && _target == other._target;
}

class CommandBuilder {
  static final CommandBuilder instance = new CommandBuilder._();

  bool _cleared = false;
  final _cachedCommands = new Map<Command, Command>();

  CommandBuilder._();

  void clearCommandCache() {
    _cachedCommands.clear();
    _cleared = true;
  }

  ContentShellCommand getContentShellCommand(
      String executable,
      String htmlFile,
      List<String> options,
      List<String> dartFlags,
      Map<String, String> environment) {
    ContentShellCommand command = new ContentShellCommand._(
        executable, htmlFile, options, dartFlags, environment);
    return _getUniqueCommand(command);
  }

  BrowserTestCommand getBrowserTestCommand(
      String browser, String url, Map configuration, bool retry) {
    var command = new BrowserTestCommand._(browser, url, configuration, retry);
    return _getUniqueCommand(command);
  }

  BrowserHtmlTestCommand getBrowserHtmlTestCommand(String browser, String url,
      Map configuration, List<String> expectedMessages, bool retry) {
    var command = new BrowserHtmlTestCommand._(
        browser, url, configuration, expectedMessages, retry);
    return _getUniqueCommand(command);
  }

  CompilationCommand getCompilationCommand(
      String displayName,
      outputFile,
      neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment) {
    var command = new CompilationCommand._(
        displayName,
        outputFile,
        neverSkipCompilation,
        bootstrapDependencies,
        executable,
        arguments,
        environment);
    return _getUniqueCommand(command);
  }

  CompilationCommand getKernelCompilationCommand(
      String displayName,
      outputFile,
      neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment) {
    var command = new KernelCompilationCommand._(
        displayName,
        outputFile,
        neverSkipCompilation,
        bootstrapDependencies,
        executable,
        arguments,
        environment);
    return _getUniqueCommand(command);
  }

  AnalysisCommand getAnalysisCommand(
      String displayName, executable, arguments, environmentOverrides,
      {String flavor: 'dart2analyzer'}) {
    var command = new AnalysisCommand._(
        flavor, displayName, executable, arguments, environmentOverrides);
    return _getUniqueCommand(command);
  }

  VmCommand getVmCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    var command = new VmCommand._(executable, arguments, environmentOverrides);
    return _getUniqueCommand(command);
  }

  AdbPrecompilationCommand getAdbPrecompiledCommand(String precompiledRunner,
                                                    String processTest,
                                                    String testDirectory,
                                                    List<String> arguments,
                                                    bool useBlobs) {
    var command = new AdbPrecompilationCommand._(
        precompiledRunner, processTest, testDirectory, arguments, useBlobs);
    return _getUniqueCommand(command);
  }

  Command getJSCommandlineCommand(String displayName, executable, arguments,
      [environment = null]) {
    var command = new JSCommandlineCommand._(
        displayName, executable, arguments, environment);
    return _getUniqueCommand(command);
  }

  Command getProcessCommand(String displayName, executable, arguments,
      [environment = null, workingDirectory = null]) {
    var command = new ProcessCommand._(
        displayName, executable, arguments, environment, workingDirectory);
    return _getUniqueCommand(command);
  }

  Command getCopyCommand(String sourceDirectory, String destinationDirectory) {
    var command =
        new CleanDirectoryCopyCommand._(sourceDirectory, destinationDirectory);
    return _getUniqueCommand(command);
  }

  Command getPubCommand(String pubCommand, String pubExecutable,
      String pubspecYamlDirectory, String pubCacheDirectory) {
    var command = new PubCommand._(
        pubCommand, pubExecutable, pubspecYamlDirectory, pubCacheDirectory);
    return _getUniqueCommand(command);
  }

  Command getMakeSymlinkCommand(String link, String target) {
    return _getUniqueCommand(new MakeSymlinkCommand._(link, target));
  }

  Command getModifyPubspecCommand(String pubspecYamlFile, Map depsOverrides,
      {String destinationFile: null}) {
    if (destinationFile == null) destinationFile = pubspecYamlFile;
    return _getUniqueCommand(new ModifyPubspecYamlCommand._(
        pubspecYamlFile, destinationFile, depsOverrides));
  }

  Command _getUniqueCommand(Command command) {
    // All Command classes implement hashCode and operator==.
    // We check if this command has already been built.
    //  If so, we return the cached one. Otherwise we
    // store the one given as [command] argument.
    if (_cleared) {
      throw new Exception(
          "CommandBuilder.get[type]Command called after cache cleared");
    }
    var cachedCommand = _cachedCommands[command];
    if (cachedCommand != null) {
      return cachedCommand;
    }
    _cachedCommands[command] = command;
    return command;
  }
}

/**
 * TestCase contains all the information needed to run a test and evaluate
 * its output.  Running a test involves starting a separate process, with
 * the executable and arguments given by the TestCase, and recording its
 * stdout and stderr output streams, and its exit code.  TestCase only
 * contains static information about the test; actually running the test is
 * performed by [ProcessQueue] using a [RunningProcess] object.
 *
 * The output information is stored in a [CommandOutput] instance contained
 * in TestCase.commandOutputs. The last CommandOutput instance is responsible
 * for evaluating if the test has passed, failed, crashed, or timed out, and the
 * TestCase has information about what the expected result of the test should
 * be.
 *
 * The TestCase has a callback function, [completedHandler], that is run when
 * the test is completed.
 */
class TestCase extends UniqueObject {
  // Flags set in _expectations from the optional argument info.
  static final int IS_NEGATIVE = 1 << 0;
  static final int HAS_RUNTIME_ERROR = 1 << 1;
  static final int HAS_STATIC_WARNING = 1 << 2;
  static final int IS_NEGATIVE_IF_CHECKED = 1 << 3;
  static final int HAS_COMPILE_ERROR = 1 << 4;
  static final int HAS_COMPILE_ERROR_IF_CHECKED = 1 << 5;
  static final int EXPECT_COMPILE_ERROR = 1 << 6;
  /**
   * A list of commands to execute. Most test cases have a single command.
   * Dart2js tests have two commands, one to compile the source and another
   * to execute it. Some isolate tests might even have three, if they require
   * compiling multiple sources that are run in isolation.
   */
  List<Command> commands;
  Map<Command, CommandOutput> commandOutputs =
      new Map<Command, CommandOutput>();

  Map configuration;
  String displayName;
  int _expectations = 0;
  int hash = 0;
  Set<Expectation> expectedOutcomes;

  TestCase(this.displayName, this.commands, this.configuration,
      this.expectedOutcomes,
      {isNegative: false, TestInformation info: null}) {
    if (isNegative || displayName.contains("negative_test")) {
      _expectations |= IS_NEGATIVE;
    }
    if (info != null) {
      _setExpectations(info);
      hash =
          info.originTestPath.relativeTo(TestUtils.dartDir).toString().hashCode;
    }
  }

  void _setExpectations(TestInformation info) {
    // We don't want to keep the entire (large) TestInformation structure,
    // so we copy the needed bools into flags set in a single integer.
    if (info.hasRuntimeError) _expectations |= HAS_RUNTIME_ERROR;
    if (info.hasStaticWarning) _expectations |= HAS_STATIC_WARNING;
    if (info.isNegativeIfChecked) _expectations |= IS_NEGATIVE_IF_CHECKED;
    if (info.hasCompileError) _expectations |= HAS_COMPILE_ERROR;
    if (info.hasCompileErrorIfChecked) {
      _expectations |= HAS_COMPILE_ERROR_IF_CHECKED;
    }
    if (info.hasCompileError ||
        (configuration['checked'] && info.hasCompileErrorIfChecked)) {
      _expectations |= EXPECT_COMPILE_ERROR;
    }
  }

  bool get isNegative => _expectations & IS_NEGATIVE != 0;
  bool get hasRuntimeError => _expectations & HAS_RUNTIME_ERROR != 0;
  bool get hasStaticWarning => _expectations & HAS_STATIC_WARNING != 0;
  bool get isNegativeIfChecked => _expectations & IS_NEGATIVE_IF_CHECKED != 0;
  bool get hasCompileError => _expectations & HAS_COMPILE_ERROR != 0;
  bool get hasCompileErrorIfChecked =>
      _expectations & HAS_COMPILE_ERROR_IF_CHECKED != 0;
  bool get expectCompileError => _expectations & EXPECT_COMPILE_ERROR != 0;

  bool get unexpectedOutput {
    var outcome = lastCommandOutput.result(this);
    return !expectedOutcomes.any((expectation) {
      return outcome.canBeOutcomeOf(expectation);
    });
  }

  Expectation get result => lastCommandOutput.result(this);

  CommandOutput get lastCommandOutput {
    if (commandOutputs.length == 0) {
      throw new Exception("CommandOutputs is empty, maybe no command was run? ("
          "displayName: '$displayName', "
          "configurationString: '$configurationString')");
    }
    return commandOutputs[commands[commandOutputs.length - 1]];
  }

  Command get lastCommandExecuted {
    if (commandOutputs.length == 0) {
      throw new Exception("CommandOutputs is empty, maybe no command was run? ("
          "displayName: '$displayName', "
          "configurationString: '$configurationString')");
    }
    return commands[commandOutputs.length - 1];
  }

  int get timeout {
    if (expectedOutcomes.contains(Expectation.SLOW)) {
      return configuration['timeout'] * SLOW_TIMEOUT_MULTIPLIER;
    } else {
      return configuration['timeout'];
    }
  }

  String get configurationString {
    final compiler = configuration['compiler'];
    final runtime = configuration['runtime'];
    final mode = configuration['mode'];
    final arch = configuration['arch'];
    final checked = configuration['checked'] ? '-checked' : '';
    return "$compiler-$runtime$checked ${mode}_$arch";
  }

  List<String> get batchTestArguments {
    assert(commands.last is ProcessCommand);
    return (commands.last as ProcessCommand).arguments;
  }

  bool get isFlaky {
    if (expectedOutcomes.contains(Expectation.SKIP) ||
        expectedOutcomes.contains(Expectation.SKIP_BY_DESIGN)) {
      return false;
    }

    return expectedOutcomes
            .where((expectation) => !expectation.isMetaExpectation)
            .length >
        1;
  }

  bool get isFinished {
    return commandOutputs.length > 0 &&
        (!lastCommandOutput.successful ||
            commands.length == commandOutputs.length);
  }
}

/**
 * BrowserTestCase has an extra compilation command that is run in a separate
 * process, before the regular test is run as in the base class [TestCase].
 * If the compilation command fails, then the rest of the test is not run.
 */
class BrowserTestCase extends TestCase {
  BrowserTestCase(displayName, commands, configuration, expectedOutcomes, info,
      isNegative, this._testingUrl)
      : super(displayName, commands, configuration, expectedOutcomes,
            isNegative: isNegative, info: info);

  String _testingUrl;

  String get testingUrl => _testingUrl;
}

class UnittestSuiteMessagesMixin {
  bool _isAsyncTest(String testOutput) {
    return testOutput.contains("unittest-suite-wait-for-done");
  }

  bool _isAsyncTestSuccessful(String testOutput) {
    return testOutput.contains("unittest-suite-success");
  }

  Expectation _negateOutcomeIfIncompleteAsyncTest(
      Expectation outcome, String testOutput) {
    // If this is an asynchronous test and the asynchronous operation didn't
    // complete successfully, it's outcome is Expectation.FAIL.
    // TODO: maybe we should introduce a AsyncIncomplete marker or so
    if (outcome == Expectation.PASS) {
      if (_isAsyncTest(testOutput) && !_isAsyncTestSuccessful(testOutput)) {
        return Expectation.FAIL;
      }
    }
    return outcome;
  }
}

/**
 * CommandOutput records the output of a completed command: the process's exit
 * code, the standard output and standard error, whether the process timed out,
 * and the time the process took to run.  It does not contain a pointer to the
 * [TestCase] this is the output of, so some functions require the test case
 * to be passed as an argument.
 */
abstract class CommandOutput {
  Command get command;

  Expectation result(TestCase testCase);

  bool get hasCrashed;

  bool get hasTimedOut;

  bool didFail(testcase);

  bool hasFailed(TestCase testCase);

  bool get canRunDependendCommands;

  bool get successful; // otherwise we might to retry running

  Duration get time;

  int get exitCode;

  int get pid;

  List<int> get stdout;

  List<int> get stderr;

  List<String> get diagnostics;

  bool get compilationSkipped;
}

class CommandOutputImpl extends UniqueObject implements CommandOutput {
  Command command;
  int exitCode;

  bool timedOut;
  List<int> stdout;
  List<int> stderr;
  Duration time;
  List<String> diagnostics;
  bool compilationSkipped;
  int pid;

  /**
   * A flag to indicate we have already printed a warning about ignoring the VM
   * crash, to limit the amount of output produced per test.
   */
  bool alreadyPrintedWarning = false;

  CommandOutputImpl(
      Command this.command,
      int this.exitCode,
      bool this.timedOut,
      List<int> this.stdout,
      List<int> this.stderr,
      Duration this.time,
      bool this.compilationSkipped,
      int this.pid) {
    diagnostics = [];
  }

  Expectation result(TestCase testCase) {
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;
    return hasFailed(testCase) ? Expectation.FAIL : Expectation.PASS;
  }

  bool get hasCrashed {
    // dart2js exits with code 253 in case of unhandled exceptions.
    // The dart binary exits with code 253 in case of an API error such
    // as an invalid snapshot file.
    // In either case an exit code of 253 is considered a crash.
    if (exitCode == 253) return true;
    if (io.Platform.operatingSystem == 'windows') {
      // The VM uses std::abort to terminate on asserts.
      // std::abort terminates with exit code 3 on Windows.
      if (exitCode == 3 || exitCode == CRASHING_BROWSER_EXITCODE) {
        return !timedOut;
      }
      // If a program receives an uncaught system exception, the program
      // terminates with the exception code as exit code.
      // The 0x3FFFFF00 mask here tries to determine if an exception indicates
      // a crash of the program.
      // System exception codes can be found in 'winnt.h', for example
      // "#define STATUS_ACCESS_VIOLATION  ((DWORD) 0xC0000005)"
      return (!timedOut && (exitCode < 0) && ((0x3FFFFF00 & exitCode) == 0));
    }
    return !timedOut && ((exitCode < 0));
  }

  bool get hasTimedOut => timedOut;

  bool didFail(TestCase testCase) {
    return (exitCode != 0 && !hasCrashed);
  }

  bool get canRunDependendCommands {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  bool get successful {
    // FIXME(kustermann): We may need to change this
    return !hasTimedOut && exitCode == 0;
  }

  // Reverse result of a negative test.
  bool hasFailed(TestCase testCase) {
    return testCase.isNegative ? !didFail(testCase) : didFail(testCase);
  }

  Expectation _negateOutcomeIfNegativeTest(
      Expectation outcome, bool isNegative) {
    if (!isNegative) return outcome;
    if (outcome == Expectation.IGNORE) return outcome;
    if (outcome.canBeOutcomeOf(Expectation.FAIL)) {
      return Expectation.PASS;
    }
    return Expectation.FAIL;
  }
}

class BrowserCommandOutputImpl extends CommandOutputImpl {
  // Although tests are reported as passing, content shell sometimes exits with
  // a nonzero exitcode which makes our dartium builders extremely falky.
  // See: http://dartbug.com/15139.
  static int WHITELISTED_CONTENTSHELL_EXITCODE = -1073740022;
  static bool isWindows = io.Platform.operatingSystem == 'windows';
  static bool _failedBecauseOfFlakyInfrastructure(List<int> stderrBytes) {
    // If the browser test failed, it may have been because content shell
    // and the virtual framebuffer X server didn't hook up, or it crashed with
    // a core dump. Sometimes content shell crashes after it has set the stdout
    // to PASS, so we have to do this check first.
    // Content shell also fails with a broken pipe message: Issue 26739
    var zygoteCrash =
        new RegExp(r"ERROR:zygote_linux\.cc\(\d+\)] write: Broken pipe");
    var stderr = decodeUtf8(stderrBytes);
    // TODO(whesse): Issue: 7564
    // This may not be happening anymore.  Test by removing this suppression.
    if (stderr.contains(MESSAGE_CANNOT_OPEN_DISPLAY) ||
        stderr.contains(MESSAGE_FAILED_TO_RUN_COMMAND)) {
      DebugLogger.warning(
          "Warning: Failure because of missing XDisplay. Test ignored");
      return true;
    }
    // Issue 26739
    if (zygoteCrash.hasMatch(stderr)) {
      DebugLogger.warning("Warning: Failure because of content_shell "
          "zygote crash. Test ignored");
      return true;
    }
    return false;
  }

  bool _infraFailure;

  BrowserCommandOutputImpl(
      command, exitCode, timedOut, stdout, stderr, time, compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0),
        _infraFailure = _failedBecauseOfFlakyInfrastructure(stderr);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    if (_infraFailure) {
      return Expectation.IGNORE;
    }
    var outcome = _getOutcome();

    if (testCase.hasRuntimeError) {
      if (!outcome.canBeOutcomeOf(Expectation.RUNTIME_ERROR)) {
        return Expectation.MISSING_RUNTIME_ERROR;
      }
    }
    if (testCase.isNegative) {
      if (outcome.canBeOutcomeOf(Expectation.FAIL)) return Expectation.PASS;
      return Expectation.FAIL;
    }
    return outcome;
  }

  bool get successful => canRunDependendCommands;

  bool get canRunDependendCommands {
    // We cannot rely on the exit code of content_shell as a method to
    // determine if we were successful or not.
    return super.canRunDependendCommands && !didFail(null);
  }

  bool get hasCrashed {
    return super.hasCrashed || _rendererCrashed;
  }

  Expectation _getOutcome() {
    if (_browserTestFailure) {
      return Expectation.RUNTIME_ERROR;
    }
    return Expectation.PASS;
  }

  bool get _rendererCrashed =>
      decodeUtf8(super.stdout).contains("#CRASHED - rendere");

  bool get _browserTestFailure {
    // Browser tests fail unless stdout contains
    // 'Content-Type: text/plain' followed by 'PASS'.
    bool hasContentType = false;
    var stdoutLines = decodeUtf8(super.stdout).split("\n");
    var containsFail = false;
    var containsPass = false;
    for (String line in stdoutLines) {
      switch (line) {
        case 'Content-Type: text/plain':
          hasContentType = true;
          break;
        case 'FAIL':
          if (hasContentType) {
            containsFail = true;
          }
          break;
        case 'PASS':
          if (hasContentType) {
            containsPass = true;
          }
          break;
      }
    }
    if (hasContentType) {
      if (containsFail && containsPass) {
        DebugLogger.warning("Test had 'FAIL' and 'PASS' in stdout. ($command)");
      }
      if (!containsFail && !containsPass) {
        DebugLogger.warning("Test had neither 'FAIL' nor 'PASS' in stdout. "
            "($command)");
        return true;
      }
      if (containsFail) {
        return true;
      }
      assert(containsPass);
      if (exitCode != 0) {
        var message = "All tests passed, but exitCode != 0. "
            "Actual exitcode: $exitCode. "
            "($command)";
        DebugLogger.warning(message);
        diagnostics.add(message);
      }
      return (!hasCrashed &&
          exitCode != 0 &&
          (!isWindows || exitCode != WHITELISTED_CONTENTSHELL_EXITCODE));
    }
    DebugLogger.warning("Couldn't find 'Content-Type: text/plain' in output. "
        "($command).");
    return true;
  }
}

class HTMLBrowserCommandOutputImpl extends BrowserCommandOutputImpl {
  HTMLBrowserCommandOutputImpl(
      command, exitCode, timedOut, stdout, stderr, time, compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped);

  bool didFail(TestCase testCase) {
    return _getOutcome() != Expectation.PASS;
  }

  bool get _browserTestFailure {
    // We should not need to convert back and forward.
    var output = decodeUtf8(super.stdout);
    if (output.contains("FAIL")) return true;
    return !output.contains("PASS");
  }
}

class BrowserTestJsonResult {
  static const ALLOWED_TYPES = const [
    'sync_exception',
    'window_onerror',
    'script_onerror',
    'window_compilationerror',
    'print',
    'message_received',
    'dom',
    'debug'
  ];

  final Expectation outcome;
  final String htmlDom;
  final List events;

  BrowserTestJsonResult(this.outcome, this.htmlDom, this.events);

  static BrowserTestJsonResult parseFromString(String content) {
    void validate(String assertion, bool value) {
      if (!value) {
        throw "InvalidFormat sent from browser driving page: $assertion:\n\n"
            "$content";
      }
    }

    var events;
    try {
      events = JSON.decode(content);
      if (events != null) {
        validate("Message must be a List", events is List);

        Map<String, List<String>> messagesByType = {};
        ALLOWED_TYPES.forEach((type) => messagesByType[type] = <String>[]);

        for (var entry in events) {
          validate("An entry must be a Map", entry is Map);

          var type = entry['type'];
          var value = entry['value'];
          var timestamp = entry['timestamp'];

          validate("'type' of an entry must be a String", type is String);
          validate("'type' has to be in $ALLOWED_TYPES.",
              ALLOWED_TYPES.contains(type));
          validate(
              "'timestamp' of an entry must be a number", timestamp is num);

          messagesByType[type].add(value);
        }
        validate("The message must have exactly one 'dom' entry.",
            messagesByType['dom'].length == 1);

        var dom = messagesByType['dom'][0];
        if (dom.endsWith('\n')) {
          dom = '$dom\n';
        }

        return new BrowserTestJsonResult(
            _getOutcome(messagesByType), dom, events);
      }
    } catch (error) {
      // If something goes wrong, we know the content was not in the correct
      // JSON format. So we can't parse it.
      // The caller is responsible for falling back to the old way of
      // determining if a test failed.
    }

    return null;
  }

  static Expectation _getOutcome(Map<String, List<String>> messagesByType) {
    occured(type) => messagesByType[type].length > 0;
    searchForMsg(types, message) {
      return types.any((type) => messagesByType[type].contains(message));
    }

    // FIXME(kustermann,ricow): I think this functionality doesn't work in
    // test_controller.js: So far I haven't seen anything being reported on
    // "window.compilationerror"
    if (occured('window_compilationerror')) {
      return Expectation.COMPILETIME_ERROR;
    }

    if (occured('sync_exception') ||
        occured('window_onerror') ||
        occured('script_onerror')) {
      return Expectation.RUNTIME_ERROR;
    }

    if (messagesByType['dom'][0].contains('FAIL')) {
      return Expectation.RUNTIME_ERROR;
    }

    // We search for these messages in 'print' and 'message_received' because
    // the unittest implementation posts these messages using
    // "window.postMessage()" instead of the normal "print()" them.

    var isAsyncTest = searchForMsg(
        ['print', 'message_received'], 'unittest-suite-wait-for-done');
    var isAsyncSuccess =
        searchForMsg(['print', 'message_received'], 'unittest-suite-success') ||
            searchForMsg(['print', 'message_received'], 'unittest-suite-done');

    if (isAsyncTest) {
      if (isAsyncSuccess) {
        return Expectation.PASS;
      }
      return Expectation.RUNTIME_ERROR;
    }

    var mainStarted =
        searchForMsg(['print', 'message_received'], 'dart-calling-main');
    var mainDone =
        searchForMsg(['print', 'message_received'], 'dart-main-done');

    if (mainStarted && mainDone) {
      return Expectation.PASS;
    }
    return Expectation.FAIL;
  }
}

class BrowserControllerTestOutcome extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  BrowserTestOutput _result;
  Expectation _rawOutcome;

  factory BrowserControllerTestOutcome(
      Command command, BrowserTestOutput result) {
    String indent(String string, int numSpaces) {
      var spaces = new List.filled(numSpaces, ' ').join('');
      return string
          .replaceAll('\r\n', '\n')
          .split('\n')
          .map((line) => "$spaces$line")
          .join('\n');
    }

    String stdout = "";
    String stderr = "";
    Expectation outcome;

    var parsedResult =
        BrowserTestJsonResult.parseFromString(result.lastKnownMessage);
    if (parsedResult != null) {
      outcome = parsedResult.outcome;
    } else {
      // Old way of determining whether a test failed or passed.
      if (result.lastKnownMessage.contains("FAIL")) {
        outcome = Expectation.RUNTIME_ERROR;
      } else if (result.lastKnownMessage.contains("PASS")) {
        outcome = Expectation.PASS;
      } else {
        outcome = Expectation.RUNTIME_ERROR;
      }
    }

    if (result.didTimeout) {
      if (result.delayUntilTestStarted != null) {
        stderr = "This test timed out. The delay until the test actually "
            "started was: ${result.delayUntilTestStarted}.";
      } else {
        stderr = "This test has not notified test.py that it started running.";
      }
    }

    if (parsedResult != null) {
      stdout = "events:\n${indent(prettifyJson(parsedResult.events), 2)}\n\n";
    } else {
      stdout = "message:\n${indent(result.lastKnownMessage, 2)}\n\n";
    }

    stderr = '$stderr\n\n'
        'BrowserOutput while running the test (* EXPERIMENTAL *):\n'
        'BrowserOutput.stdout:\n'
        '${indent(result.browserOutput.stdout.toString(), 2)}\n'
        'BrowserOutput.stderr:\n'
        '${indent(result.browserOutput.stderr.toString(), 2)}\n'
        '\n';
    return new BrowserControllerTestOutcome._internal(
        command, result, outcome, encodeUtf8(stdout), encodeUtf8(stderr));
  }

  BrowserControllerTestOutcome._internal(
      Command command,
      BrowserTestOutput result,
      this._rawOutcome,
      List<int> stdout,
      List<int> stderr)
      : super(command, 0, result.didTimeout, stdout, stderr, result.duration,
            false, 0) {
    _result = result;
  }

  Expectation result(TestCase testCase) {
    // Handle timeouts first
    if (_result.didTimeout) return Expectation.TIMEOUT;

    // Multitests are handled specially
    if (testCase.hasRuntimeError) {
      if (_rawOutcome == Expectation.RUNTIME_ERROR) return Expectation.PASS;
      return Expectation.MISSING_RUNTIME_ERROR;
    }

    return _negateOutcomeIfNegativeTest(_rawOutcome, testCase.isNegative);
  }
}

class AnalysisCommandOutputImpl extends CommandOutputImpl {
  // An error line has 8 fields that look like:
  // ERROR|COMPILER|MISSING_SOURCE|file:/tmp/t.dart|15|1|24|Missing source.
  final int ERROR_LEVEL = 0;
  final int ERROR_TYPE = 1;
  final int FILENAME = 3;
  final int FORMATTED_ERROR = 7;

  AnalysisCommandOutputImpl(
      command, exitCode, timedOut, stdout, stderr, time, compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  Expectation result(TestCase testCase) {
    // TODO(kustermann): If we run the analyzer not in batch mode, make sure
    // that command.exitCodes matches 2 (errors), 1 (warnings), 0 (no warnings,
    // no errors)

    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    // Get the errors/warnings from the analyzer
    List<String> errors = [];
    List<String> warnings = [];
    parseAnalyzerOutput(errors, warnings);

    // Handle errors / missing errors
    if (testCase.expectCompileError) {
      if (errors.length > 0) {
        return Expectation.PASS;
      }
      return Expectation.MISSING_COMPILETIME_ERROR;
    }
    if (errors.length > 0) {
      return Expectation.COMPILETIME_ERROR;
    }

    // Handle static warnings / missing static warnings
    if (testCase.hasStaticWarning) {
      if (warnings.length > 0) {
        return Expectation.PASS;
      }
      return Expectation.MISSING_STATIC_WARNING;
    }
    if (warnings.length > 0) {
      return Expectation.STATIC_WARNING;
    }

    assert(errors.length == 0 && warnings.length == 0);
    assert(!testCase.hasCompileError && !testCase.hasStaticWarning);
    return Expectation.PASS;
  }

  void parseAnalyzerOutput(List<String> outErrors, List<String> outWarnings) {
    // Parse a line delimited by the | character using \ as an escape charager
    // like:  FOO|BAR|FOO\|BAR|FOO\\BAZ as 4 fields: FOO BAR FOO|BAR FOO\BAZ
    List<String> splitMachineError(String line) {
      StringBuffer field = new StringBuffer();
      List<String> result = [];
      bool escaped = false;
      for (var i = 0; i < line.length; i++) {
        var c = line[i];
        if (!escaped && c == '\\') {
          escaped = true;
          continue;
        }
        escaped = false;
        if (c == '|') {
          result.add(field.toString());
          field = new StringBuffer();
          continue;
        }
        field.write(c);
      }
      result.add(field.toString());
      return result;
    }

    for (String line in decodeUtf8(super.stderr).split("\n")) {
      if (line.length == 0) continue;
      List<String> fields = splitMachineError(line);
      // We only consider errors/warnings for files of interest.
      if (fields.length > FORMATTED_ERROR) {
        if (fields[ERROR_LEVEL] == 'ERROR') {
          outErrors.add(fields[FORMATTED_ERROR]);
        } else if (fields[ERROR_LEVEL] == 'WARNING') {
          outWarnings.add(fields[FORMATTED_ERROR]);
        }
        // OK to Skip error output that doesn't match the machine format
      }
    }
  }
}

class VmCommandOutputImpl extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  static const DART_VM_EXITCODE_COMPILE_TIME_ERROR = 254;
  static const DART_VM_EXITCODE_UNCAUGHT_EXCEPTION = 255;

  VmCommandOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time, int pid)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, pid);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    // Multitests are handled specially
    if (testCase.expectCompileError) {
      if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
        return Expectation.PASS;
      }
      return Expectation.MISSING_COMPILETIME_ERROR;
    }
    if (testCase.hasRuntimeError) {
      // TODO(kustermann): Do we consider a "runtimeError" only an uncaught
      // exception or does any nonzero exit code fullfil this requirement?
      if (exitCode != 0) {
        return Expectation.PASS;
      }
      return Expectation.MISSING_RUNTIME_ERROR;
    }

    // The actual outcome depends on the exitCode
    Expectation outcome;
    if (exitCode == DART_VM_EXITCODE_COMPILE_TIME_ERROR) {
      outcome = Expectation.COMPILETIME_ERROR;
    } else if (exitCode == DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      outcome = Expectation.RUNTIME_ERROR;
    } else if (exitCode != 0) {
      // This is a general fail, in case we get an unknown nonzero exitcode.
      outcome = Expectation.FAIL;
    } else {
      outcome = Expectation.PASS;
    }
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class CompilationCommandOutputImpl extends CommandOutputImpl {
  static const DART2JS_EXITCODE_CRASH = 253;

  CompilationCommandOutputImpl(
      Command command,
      int exitCode,
      bool timedOut,
      List<int> stdout,
      List<int> stderr,
      Duration time,
      bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
            compilationSkipped, 0);

  Expectation result(TestCase testCase) {
    // Handle general crash/timeout detection.
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) {
      bool isWindows = io.Platform.operatingSystem == 'windows';
      bool isBrowserTestCase =
          testCase.commands.any((command) => command is BrowserTestCommand);
      // TODO(26060) Dart2js batch mode hangs on Windows under heavy load.
      return (isWindows && isBrowserTestCase)
          ? Expectation.IGNORE
          : Expectation.TIMEOUT;
    }

    // Handle dart2js specific crash detection
    if (exitCode == DART2JS_EXITCODE_CRASH ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_COMPILE_TIME_ERROR ||
        exitCode == VmCommandOutputImpl.DART_VM_EXITCODE_UNCAUGHT_EXCEPTION) {
      return Expectation.CRASH;
    }

    // Multitests are handled specially
    if (testCase.expectCompileError) {
      // Nonzero exit code of the compiler means compilation failed
      // TODO(kustermann): Do we have a special exit code in that case???
      if (exitCode != 0) {
        return Expectation.PASS;
      }
      return Expectation.MISSING_COMPILETIME_ERROR;
    }

    // TODO(kustermann): This is a hack, remove it
    if (testCase.hasRuntimeError && testCase.commands.length > 1) {
      // We expected to run the test, but we got an compile time error.
      // If the compilation succeeded, we wouldn't be in here!
      assert(exitCode != 0);
      return Expectation.COMPILETIME_ERROR;
    }

    Expectation outcome =
        exitCode == 0 ? Expectation.PASS : Expectation.COMPILETIME_ERROR;
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class KernelCompilationCommandOutputImpl extends CompilationCommandOutputImpl {
  KernelCompilationCommandOutputImpl(
      Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr,
      Duration time, bool compilationSkipped)
      : super(command, exitCode, timedOut, stdout, stderr, time,
              compilationSkipped);

  bool get canRunDependendCommands {
    // See [BatchRunnerProcess]: 0 means success, 1 means compile-time error.
    // TODO(asgerf): When the frontend supports it, continue running even if
    //   there were compile-time errors. See kernel_sdk issue #18.
    return !hasCrashed && !timedOut && exitCode == 0;
  }

  // If the compiler was able to produce a Kernel IR file we want to run the
  // result on the Dart VM.  We therefore mark the [KernelCompilationCommand] as
  // successful.
  // => This ensures we test that the DartVM produces correct CompileTime errors
  //    as it is supposed to for our test suites.
  bool get successful => canRunDependendCommands;
}

class JsCommandlineOutputImpl extends CommandOutputImpl
    with UnittestSuiteMessagesMixin {
  JsCommandlineOutputImpl(Command command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    if (testCase.hasRuntimeError) {
      if (exitCode != 0) return Expectation.PASS;
      return Expectation.MISSING_RUNTIME_ERROR;
    }

    var outcome = exitCode == 0 ? Expectation.PASS : Expectation.RUNTIME_ERROR;
    outcome = _negateOutcomeIfIncompleteAsyncTest(outcome, decodeUtf8(stdout));
    return _negateOutcomeIfNegativeTest(outcome, testCase.isNegative);
  }
}

class PubCommandOutputImpl extends CommandOutputImpl {
  PubCommandOutputImpl(PubCommand command, int exitCode, bool timedOut,
      List<int> stdout, List<int> stderr, Duration time)
      : super(command, exitCode, timedOut, stdout, stderr, time, false, 0);

  Expectation result(TestCase testCase) {
    // Handle crashes and timeouts first
    if (hasCrashed) return Expectation.CRASH;
    if (hasTimedOut) return Expectation.TIMEOUT;

    if (exitCode == 0) {
      return Expectation.PASS;
    } else if ((command as PubCommand).command == 'get') {
      return Expectation.PUB_GET_ERROR;
    } else {
      return Expectation.FAIL;
    }
  }
}

class ScriptCommandOutputImpl extends CommandOutputImpl {
  final Expectation _result;

  ScriptCommandOutputImpl(ScriptCommand command, this._result,
      String scriptExecutionInformation, Duration time)
      : super(command, 0, false, [], [], time, false, 0) {
    var lines = scriptExecutionInformation.split("\n");
    diagnostics.addAll(lines);
  }

  Expectation result(TestCase testCase) => _result;

  bool get canRunDependendCommands => _result == Expectation.PASS;

  bool get successful => _result == Expectation.PASS;
}

CommandOutput createCommandOutput(Command command, int exitCode, bool timedOut,
    List<int> stdout, List<int> stderr, Duration time, bool compilationSkipped,
    [int pid = 0]) {
  if (command is ContentShellCommand) {
    return new BrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is BrowserTestCommand) {
    return new HTMLBrowserCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AnalysisCommand) {
    return new AnalysisCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is VmCommand) {
    return new VmCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is KernelCompilationCommand) {
    return new KernelCompilationCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is AdbPrecompilationCommand) {
    return new VmCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, pid);
  } else if (command is CompilationCommand) {
    if (command.displayName == 'precompiler' ||
        command.displayName == 'dart2snapshot') {
      return new VmCommandOutputImpl(
          command, exitCode, timedOut, stdout, stderr, time, pid);
    }
    return new CompilationCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  } else if (command is JSCommandlineCommand) {
    return new JsCommandlineOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  } else if (command is PubCommand) {
    return new PubCommandOutputImpl(
        command, exitCode, timedOut, stdout, stderr, time);
  }

  return new CommandOutputImpl(command, exitCode, timedOut, stdout, stderr,
      time, compilationSkipped, pid);
}

/**
 * An OutputLog records the output from a test, but truncates it if
 * it is longer than MAX_HEAD characters, and just keeps the head and
 * the last TAIL_LENGTH characters of the output.
 */
class OutputLog {
  static const int MAX_HEAD = 100 * 1024;
  static const int TAIL_LENGTH = 10 * 1024;
  List<int> head = <int>[];
  List<int> tail;
  List<int> complete;
  bool dataDropped = false;

  OutputLog();

  void add(List<int> data) {
    if (complete != null) {
      throw new StateError("Cannot add to OutputLog after calling toList");
    }
    if (tail == null) {
      head.addAll(data);
      if (head.length > MAX_HEAD) {
        tail = head.sublist(MAX_HEAD);
        head.length = MAX_HEAD;
      }
    } else {
      tail.addAll(data);
    }
    if (tail != null && tail.length > 2 * TAIL_LENGTH) {
      tail = _truncatedTail();
      dataDropped = true;
    }
  }

  List<int> _truncatedTail() => tail.length > TAIL_LENGTH
      ? tail.sublist(tail.length - TAIL_LENGTH)
      : tail;

  List<int> toList() {
    if (complete == null) {
      complete = head;
      if (dataDropped) {
        complete.addAll("""

*****************************************************************************

Data removed due to excessive length

*****************************************************************************

"""
            .codeUnits);
        complete.addAll(_truncatedTail());
      } else if (tail != null) {
        complete.addAll(tail);
      }
      head = null;
      tail = null;
    }
    return complete;
  }
}

/**
 * A RunningProcess actually runs a test, getting the command lines from
 * its [TestCase], starting the test process (and first, a compilation
 * process if the TestCase is a [BrowserTestCase]), creating a timeout
 * timer, and recording the results in a new [CommandOutput] object, which it
 * attaches to the TestCase.  The lifetime of the RunningProcess is limited
 * to the time it takes to start the process, run the process, and record
 * the result; there are no pointers to it, so it should be available to
 * be garbage collected as soon as it is done.
 */
class RunningProcess {
  ProcessCommand command;
  int timeout;
  bool timedOut = false;
  DateTime startTime;
  Timer timeoutTimer;
  int pid;
  OutputLog stdout = new OutputLog();
  OutputLog stderr = new OutputLog();
  List<String> diagnostics = <String>[];
  bool compilationSkipped = false;
  Completer<CommandOutput> completer;

  RunningProcess(this.command, this.timeout);

  Future<CommandOutput> run() {
    completer = new Completer<CommandOutput>();
    startTime = new DateTime.now();
    _runCommand();
    return completer.future;
  }

  void _runCommand() {
    command.outputIsUpToDate.then((bool isUpToDate) {
      if (isUpToDate) {
        compilationSkipped = true;
        _commandComplete(0);
      } else {
        var processEnvironment = _createProcessEnvironment();
        Future processFuture = io.Process.start(
            command.executable, command.arguments,
            environment: processEnvironment,
            workingDirectory: command.workingDirectory);
        processFuture.then((io.Process process) {
          StreamSubscription stdoutSubscription =
              _drainStream(process.stdout, stdout);
          StreamSubscription stderrSubscription =
              _drainStream(process.stderr, stderr);

          var stdoutCompleter = new Completer();
          var stderrCompleter = new Completer();

          bool stdoutDone = false;
          bool stderrDone = false;
          pid = process.pid;

          // This timer is used to close stdio to the subprocess once we got
          // the exitCode. Sometimes descendants of the subprocess keep stdio
          // handles alive even though the direct subprocess is dead.
          Timer watchdogTimer;

          closeStdout([_]) {
            if (!stdoutDone) {
              stdoutCompleter.complete();
              stdoutDone = true;
              if (stderrDone && watchdogTimer != null) {
                watchdogTimer.cancel();
              }
            }
          }
          closeStderr([_]) {
            if (!stderrDone) {
              stderrCompleter.complete();
              stderrDone = true;

              if (stdoutDone && watchdogTimer != null) {
                watchdogTimer.cancel();
              }
            }
          }

          // Close stdin so that tests that try to block on input will fail.
          process.stdin.close();
          timeoutHandler() async {
            timedOut = true;
            if (process != null) {
              var executable, arguments;
              if (io.Platform.isLinux) {
                executable = 'eu-stack';
                arguments = ['-p ${process.pid}'];
              } else if (io.Platform.isMacOS) {
                // Try to print stack traces of the timed out process.
                // `sample` is a sampling profiler but we ask it sample for 1
                // second with a 4 second delay between samples so that we only
                // sample the threads once.
                executable = '/usr/bin/sample';
                arguments = ['${process.pid}', '1', '4000', '-mayDie'];
              }

              if (executable != null) {
                try {
                  var result = await io.Process.run(executable, arguments);
                  diagnostics.addAll(result.stdout.split('\n'));
                  diagnostics.addAll(result.stderr.split('\n'));
                } catch (error) {
                  diagnostics.add("Unable to capture stack traces: $error");
                }
              }

              if (!process.kill()) {
                diagnostics.add("Unable to kill ${process.pid}");
              }
            }
          }

          stdoutSubscription.asFuture().then(closeStdout);
          stderrSubscription.asFuture().then(closeStderr);

          process.exitCode.then((exitCode) {
            if (!stdoutDone || !stderrDone) {
              watchdogTimer = new Timer(MAX_STDIO_DELAY, () {
                DebugLogger.warning(
                    "$MAX_STDIO_DELAY_PASSED_MESSAGE (command: $command)");
                watchdogTimer = null;
                stdoutSubscription.cancel();
                stderrSubscription.cancel();
                closeStdout();
                closeStderr();
              });
            }

            Future.wait([stdoutCompleter.future, stderrCompleter.future]).then(
                (_) {
              _commandComplete(exitCode);
            });
          });

          timeoutTimer =
              new Timer(new Duration(seconds: timeout), timeoutHandler);
        }).catchError((e) {
          // TODO(floitsch): should we try to report the stacktrace?
          print("Process error:");
          print("  Command: $command");
          print("  Error: $e");
          _commandComplete(-1);
          return true;
        });
      }
    });
  }

  void _commandComplete(int exitCode) {
    if (timeoutTimer != null) {
      timeoutTimer.cancel();
    }
    var commandOutput = _createCommandOutput(command, exitCode);
    completer.complete(commandOutput);
  }

  CommandOutput _createCommandOutput(ProcessCommand command, int exitCode) {
    var commandOutput = createCommandOutput(
        command,
        exitCode,
        timedOut,
        stdout.toList(),
        stderr.toList(),
        new DateTime.now().difference(startTime),
        compilationSkipped,
        pid);
    commandOutput.diagnostics.addAll(diagnostics);
    return commandOutput;
  }

  StreamSubscription _drainStream(
      Stream<List<int>> source, OutputLog destination) {
    return source.listen(destination.add);
  }

  Map<String, String> _createProcessEnvironment() {
    var environment = new Map.from(io.Platform.environment);

    if (command.environmentOverrides != null) {
      for (var key in command.environmentOverrides.keys) {
        environment[key] = command.environmentOverrides[key];
      }
    }
    for (var excludedEnvironmentVariable in EXCLUDED_ENVIRONMENT_VARIABLES) {
      environment.remove(excludedEnvironmentVariable);
    }

    return environment;
  }
}

class BatchRunnerProcess {
  Completer<CommandOutput> _completer;
  ProcessCommand _command;
  List<String> _arguments;
  String _runnerType;

  io.Process _process;
  Map _processEnvironmentOverrides;
  Completer _stdoutCompleter;
  Completer _stderrCompleter;
  StreamSubscription<String> _stdoutSubscription;
  StreamSubscription<String> _stderrSubscription;
  Function _processExitHandler;

  bool _currentlyRunning = false;
  OutputLog _testStdout;
  OutputLog _testStderr;
  String _status;
  DateTime _startTime;
  Timer _timer;

  BatchRunnerProcess();

  Future<CommandOutput> runCommand(String runnerType, ProcessCommand command,
      int timeout, List<String> arguments) {
    assert(_completer == null);
    assert(!_currentlyRunning);

    _completer = new Completer<CommandOutput>();
    bool sameRunnerType = _runnerType == runnerType &&
        _dictEquals(_processEnvironmentOverrides, command.environmentOverrides);
    _runnerType = runnerType;
    _currentlyRunning = true;
    _command = command;
    _arguments = arguments;
    _processEnvironmentOverrides = command.environmentOverrides;

    if (_process == null) {
      // Start process if not yet started.
      _startProcess(() {
        doStartTest(command, timeout);
      });
    } else if (!sameRunnerType) {
      // Restart this runner with the right executable for this test if needed.
      _processExitHandler = (_) {
        _startProcess(() {
          doStartTest(command, timeout);
        });
      };
      _process.kill();
      _stdoutSubscription.cancel();
      _stderrSubscription.cancel();
    } else {
      doStartTest(command, timeout);
    }
    return _completer.future;
  }

  Future terminate() {
    if (_process == null) return new Future.value(true);
    Completer terminateCompleter = new Completer();
    _processExitHandler = (_) {
      terminateCompleter.complete(true);
    };
    _process.kill();
    _stdoutSubscription.cancel();
    _stderrSubscription.cancel();

    return terminateCompleter.future;
  }

  void doStartTest(Command command, int timeout) {
    _startTime = new DateTime.now();
    _testStdout = new OutputLog();
    _testStderr = new OutputLog();
    _status = null;
    _stdoutCompleter = new Completer();
    _stderrCompleter = new Completer();
    _timer = new Timer(new Duration(seconds: timeout), _timeoutHandler);

    var line = _createArgumentsLine(_arguments, timeout);
    _process.stdin.write(line);
    _stdoutSubscription.resume();
    _stderrSubscription.resume();
    Future.wait([_stdoutCompleter.future, _stderrCompleter.future]).then(
        (_) => _reportResult());
  }

  String _createArgumentsLine(List<String> arguments, int timeout) {
    return arguments.join(' ') + '\n';
  }

  void _reportResult() {
    if (!_currentlyRunning) return;
    // _status == '>>> TEST {PASS, FAIL, OK, CRASH, FAIL, TIMEOUT}'

    var outcome = _status.split(" ")[2];
    var exitCode = 0;
    if (outcome == "CRASH") exitCode = CRASHING_BROWSER_EXITCODE;
    if (outcome == "FAIL" || outcome == "TIMEOUT") exitCode = 1;
    var output = createCommandOutput(
        _command,
        exitCode,
        (outcome == "TIMEOUT"),
        _testStdout.toList(),
        _testStderr.toList(),
        new DateTime.now().difference(_startTime),
        false);
    assert(_completer != null);
    _completer.complete(output);
    _completer = null;
    _currentlyRunning = false;
  }

  ExitCodeEvent makeExitHandler(String status) {
    void handler(int exitCode) {
      if (_currentlyRunning) {
        if (_timer != null) _timer.cancel();
        _status = status;
        _stdoutSubscription.cancel();
        _stderrSubscription.cancel();
        _startProcess(_reportResult);
      } else {
        // No active test case running.
        _process = null;
      }
    }
    return handler;
  }

  void _timeoutHandler() {
    _processExitHandler = makeExitHandler(">>> TEST TIMEOUT");
    _process.kill();
  }

  _startProcess(callback) {
    assert(_command is ProcessCommand);
    var executable = _command.executable;
    var arguments = ['--batch'];
    var environment = new Map.from(io.Platform.environment);
    if (_processEnvironmentOverrides != null) {
      for (var key in _processEnvironmentOverrides.keys) {
        environment[key] = _processEnvironmentOverrides[key];
      }
    }
    Future processFuture =
        io.Process.start(executable, arguments, environment: environment);
    processFuture.then((io.Process p) {
      _process = p;

      var _stdoutStream =
          _process.stdout.transform(UTF8.decoder).transform(new LineSplitter());
      _stdoutSubscription = _stdoutStream.listen((String line) {
        if (line.startsWith('>>> TEST')) {
          _status = line;
        } else if (line.startsWith('>>> BATCH')) {
          // ignore
        } else if (line.startsWith('>>> ')) {
          throw new Exception("Unexpected command from batch runner: '$line'.");
        } else {
          _testStdout.add(encodeUtf8(line));
          _testStdout.add("\n".codeUnits);
        }
        if (_status != null) {
          _stdoutSubscription.pause();
          _timer.cancel();
          _stdoutCompleter.complete(null);
        }
      });
      _stdoutSubscription.pause();

      var _stderrStream =
          _process.stderr.transform(UTF8.decoder).transform(new LineSplitter());
      _stderrSubscription = _stderrStream.listen((String line) {
        if (line.startsWith('>>> EOF STDERR')) {
          _stderrSubscription.pause();
          _stderrCompleter.complete(null);
        } else {
          _testStderr.add(encodeUtf8(line));
          _testStderr.add("\n".codeUnits);
        }
      });
      _stderrSubscription.pause();

      _processExitHandler = makeExitHandler(">>> TEST CRASH");
      _process.exitCode.then((exitCode) {
        _processExitHandler(exitCode);
      });

      _process.stdin.done.catchError((err) {
        print('Error on batch runner input stream stdin');
        print('  Previous test\'s status: $_status');
        print('  Error: $err');
        throw err;
      });
      callback();
    }).catchError((e) {
      // TODO(floitsch): should we try to report the stacktrace?
      print("Process error:");
      print("  Command: $executable ${arguments.join(' ')} ($_arguments)");
      print("  Error: $e");
      // If there is an error starting a batch process, chances are that
      // it will always fail. So rather than re-trying a 1000+ times, we
      // exit.
      io.exit(1);
      return true;
    });
  }

  bool _dictEquals(Map a, Map b) {
    if (a == null) return b == null;
    if (b == null) return false;
    for (var key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/**
 * [TestCaseEnqueuer] takes a list of TestSuites, generates TestCases and
 * builds a dependency graph of all commands in every TestSuite.
 *
 * It will maintain three helper data structures
 *  - command2node: A mapping from a [Command] to a node in the dependency graph
 *  - command2testCases: A mapping from [Command] to all TestCases that it is
 *    part of.
 *  - remainingTestCases: A set of TestCases that were enqueued but are not
 *    finished
 *
 * [Command] and it's subclasses all have hashCode/operator== methods defined
 * on them, so we can safely use them as keys in Map/Set objects.
 */
class TestCaseEnqueuer {
  final dgraph.Graph graph;
  final Function _onTestCaseAdded;

  final command2node = new Map<Command, dgraph.Node>();
  final command2testCases = new Map<Command, List<TestCase>>();
  final remainingTestCases = new Set<TestCase>();

  TestCaseEnqueuer(this.graph, this._onTestCaseAdded);

  void enqueueTestSuites(List<TestSuite> testSuites) {
    void newTest(TestCase testCase) {
      remainingTestCases.add(testCase);

      var lastNode;
      for (var command in testCase.commands) {
        // Make exactly *one* node in the dependency graph for every command.
        // This ensures that we never have two commands c1 and c2 in the graph
        // with "c1 == c2".
        var node = command2node[command];
        if (node == null) {
          var requiredNodes = (lastNode != null) ? [lastNode] : [];
          node = graph.newNode(command, requiredNodes);
          command2node[command] = node;
          command2testCases[command] = <TestCase>[];
        }
        // Keep mapping from command to all testCases that refer to it
        command2testCases[command].add(testCase);

        lastNode = node;
      }
      _onTestCaseAdded(testCase);
    }

    // Cache information about test cases per test suite. For multiple
    // configurations there is no need to repeatedly search the file
    // system, generate tests, and search test files for options.
    var testCache = new Map<String, List<TestInformation>>();

    Iterator<TestSuite> iterator = testSuites.iterator;
    void enqueueNextSuite() {
      if (!iterator.moveNext()) {
        // We're finished with building the dependency graph.
        graph.sealGraph();
      } else {
        iterator.current.forEachTest(newTest, testCache, enqueueNextSuite);
      }
    }
    enqueueNextSuite();
  }
}

/*
 * [CommandEnqueuer] will
 *  - change node.state to NodeState.Enqueuing as soon as all dependencies have
 *    a state of NodeState.Successful
 *  - change node.state to NodeState.UnableToRun if one or more dependencies
 *    have a state of NodeState.Failed/NodeState.UnableToRun.
 */
class CommandEnqueuer {
  static final INIT_STATES = [
    dgraph.NodeState.Initialized,
    dgraph.NodeState.Waiting
  ];
  static final FINISHED_STATES = [
    dgraph.NodeState.Successful,
    dgraph.NodeState.Failed,
    dgraph.NodeState.UnableToRun
  ];
  final dgraph.Graph _graph;

  CommandEnqueuer(this._graph) {
    var eventCondition = _graph.events.where;

    eventCondition((e) => e is dgraph.NodeAddedEvent).listen((event) {
      dgraph.Node node = event.node;
      _changeNodeStateIfNecessary(node);
    });

    eventCondition((e) => e is dgraph.StateChangedEvent).listen((event) {
      if ([dgraph.NodeState.Waiting, dgraph.NodeState.Processing]
          .contains(event.from)) {
        if (FINISHED_STATES.contains(event.to)) {
          for (var dependendNode in event.node.neededFor) {
            _changeNodeStateIfNecessary(dependendNode);
          }
        }
      }
    });
  }

  // Called when either a new node was added or if one of it's dependencies
  // changed it's state.
  void _changeNodeStateIfNecessary(dgraph.Node node) {
    if (INIT_STATES.contains(node.state)) {
      bool anyDependenciesUnsuccessful = node.dependencies.any((dep) => [
            dgraph.NodeState.Failed,
            dgraph.NodeState.UnableToRun
          ].contains(dep.state));

      var newState = dgraph.NodeState.Waiting;
      if (anyDependenciesUnsuccessful) {
        newState = dgraph.NodeState.UnableToRun;
      } else {
        bool allDependenciesSuccessful = node.dependencies
            .every((dep) => dep.state == dgraph.NodeState.Successful);

        if (allDependenciesSuccessful) {
          newState = dgraph.NodeState.Enqueuing;
        }
      }
      if (node.state != newState) {
        _graph.changeState(node, newState);
      }
    }
  }
}

/*
 * [CommandQueue] will listen for nodes entering the NodeState.ENQUEUING state,
 * queue them up and run them. While nodes are processed they will be in the
 * NodeState.PROCESSING state. After running a command, the node will change
 * to a state of NodeState.Successful or NodeState.Failed.
 *
 * It provides a synchronous stream [completedCommands] which provides the
 * [CommandOutputs] for the finished commands.
 *
 * It provides a [done] future, which will complete once there are no more
 * nodes left in the states Initialized/Waiting/Enqueing/Processing
 * and the [executor] has cleaned up it's resources.
 */
class CommandQueue {
  final dgraph.Graph graph;
  final CommandExecutor executor;
  final TestCaseEnqueuer enqueuer;

  final Queue<Command> _runQueue = new Queue<Command>();
  final _commandOutputStream = new StreamController<CommandOutput>(sync: true);
  final _completer = new Completer();

  int _numProcesses = 0;
  int _maxProcesses;
  int _numBrowserProcesses = 0;
  int _maxBrowserProcesses;
  bool _finishing = false;
  bool _verbose = false;

  CommandQueue(this.graph, this.enqueuer, this.executor, this._maxProcesses,
      this._maxBrowserProcesses, this._verbose) {
    var eventCondition = graph.events.where;
    eventCondition((event) => event is dgraph.StateChangedEvent)
        .listen((event) {
      if (event.to == dgraph.NodeState.Enqueuing) {
        assert(event.from == dgraph.NodeState.Initialized ||
            event.from == dgraph.NodeState.Waiting);
        graph.changeState(event.node, dgraph.NodeState.Processing);
        var command = event.node.userData;
        if (event.node.dependencies.length > 0) {
          _runQueue.addFirst(command);
        } else {
          _runQueue.add(command);
        }
        Timer.run(() => _tryRunNextCommand());
      }
    });
    // We're finished if the graph is sealed and all nodes are in a finished
    // state (Successful, Failed or UnableToRun).
    // So we're calling '_checkDone()' to check whether that condition is met
    // and we can cleanup.
    graph.events.listen((dgraph.GraphEvent event) {
      if (event is dgraph.GraphSealedEvent) {
        _checkDone();
      } else if (event is dgraph.StateChangedEvent) {
        if (event.to == dgraph.NodeState.UnableToRun) {
          _checkDone();
        }
      }
    });
  }

  Stream<CommandOutput> get completedCommands => _commandOutputStream.stream;

  Future get done => _completer.future;

  void _tryRunNextCommand() {
    _checkDone();

    if (_numProcesses < _maxProcesses && !_runQueue.isEmpty) {
      Command command = _runQueue.removeFirst();
      var isBrowserCommand = command is BrowserTestCommand;

      if (isBrowserCommand && _numBrowserProcesses == _maxBrowserProcesses) {
        // If there is no free browser runner, put it back into the queue.
        _runQueue.add(command);
        // Don't lose a process.
        new Timer(new Duration(milliseconds: 100), _tryRunNextCommand);
        return;
      }

      _numProcesses++;
      if (isBrowserCommand) _numBrowserProcesses++;

      var node = enqueuer.command2node[command];
      Iterable<TestCase> testCases = enqueuer.command2testCases[command];
      // If a command is part of many TestCases we set the timeout to be
      // the maximum over all [TestCase.timeout]s. At some point, we might
      // eliminate [TestCase.timeout] completely and move it to [Command].
      int timeout =
          testCases.map((TestCase test) => test.timeout).fold(0, math.max);

      if (_verbose) {
        print('Running "${command.displayName}" command: $command');
      }

      executor.runCommand(node, command, timeout).then((CommandOutput output) {
        assert(command == output.command);

        _commandOutputStream.add(output);
        if (output.canRunDependendCommands) {
          graph.changeState(node, dgraph.NodeState.Successful);
        } else {
          graph.changeState(node, dgraph.NodeState.Failed);
        }

        _numProcesses--;
        if (isBrowserCommand) _numBrowserProcesses--;

        // Don't lose a process
        Timer.run(() => _tryRunNextCommand());
      });
    }
  }

  void _checkDone() {
    if (!_finishing &&
        _runQueue.isEmpty &&
        _numProcesses == 0 &&
        graph.isSealed &&
        graph.stateCount(dgraph.NodeState.Initialized) == 0 &&
        graph.stateCount(dgraph.NodeState.Waiting) == 0 &&
        graph.stateCount(dgraph.NodeState.Enqueuing) == 0 &&
        graph.stateCount(dgraph.NodeState.Processing) == 0) {
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

/*
 * [CommandExecutor] is responsible for executing commands. It will make sure
 * that the following two constraints are satisfied
 *  - [:numberOfProcessesUsed <= maxProcesses:]
 *  - [:numberOfBrowserProcessesUsed <= maxBrowserProcesses:]
 *
 * It provides a [runCommand] method which will complete with a
 * [CommandOutput] object.
 *
 * It provides a [cleanup] method to free all the allocated resources.
 */
abstract class CommandExecutor {
  Future cleanup();
  // TODO(kustermann): The [timeout] parameter should be a property of Command
  Future<CommandOutput> runCommand(
      dgraph.Node node, Command command, int timeout);
}

class CommandExecutorImpl implements CommandExecutor {
  final Map globalConfiguration;
  final int maxProcesses;
  final int maxBrowserProcesses;
  AdbDevicePool adbDevicePool;

  // For dart2js and analyzer batch processing,
  // we keep a list of batch processes.
  final _batchProcesses = new Map<String, List<BatchRunnerProcess>>();
  // We keep a BrowserTestRunner for every configuration.
  final _browserTestRunners = new Map<Map, BrowserTestRunner>();

  bool _finishing = false;

  CommandExecutorImpl(
      this.globalConfiguration, this.maxProcesses, this.maxBrowserProcesses,
      {this.adbDevicePool});

  Future cleanup() {
    assert(!_finishing);
    _finishing = true;

    Future _terminateBatchRunners() {
      var futures = [];
      for (var runners in _batchProcesses.values) {
        futures.addAll(runners.map((runner) => runner.terminate()));
      }
      return Future.wait(futures);
    }

    Future _terminateBrowserRunners() {
      var futures =
          _browserTestRunners.values.map((runner) => runner.terminate());
      return Future.wait(futures);
    }

    return Future.wait([_terminateBatchRunners(), _terminateBrowserRunners()]);
  }

  Future<CommandOutput> runCommand(node, Command command, int timeout) {
    assert(!_finishing);

    Future<CommandOutput> runCommand(int retriesLeft) {
      return _runCommand(command, timeout).then((CommandOutput output) {
        if (retriesLeft > 0 && shouldRetryCommand(output)) {
          DebugLogger.warning("Rerunning Command: ($retriesLeft "
              "attempt(s) remains) [cmd: $command]");
          return runCommand(retriesLeft - 1);
        } else {
          return new Future.value(output);
        }
      });
    }
    return runCommand(command.maxNumRetries);
  }

  Future<CommandOutput> _runCommand(Command command, int timeout) {
    var batchMode = !globalConfiguration['noBatch'];
    var dart2jsBatchMode = globalConfiguration['dart2js_batch'];

    if (command is BrowserTestCommand) {
      return _startBrowserControllerTest(command, timeout);
    } else if (command is KernelCompilationCommand) {
      // For now, we always run dartk in batch mode.
      var name = command.displayName;
      assert(name == 'dartk');
      return _getBatchRunner(name)
          .runCommand(name, command, timeout, command.arguments);
    } else if (command is CompilationCommand && dart2jsBatchMode) {
      return _getBatchRunner("dart2js")
          .runCommand("dart2js", command, timeout, command.arguments);
    } else if (command is AnalysisCommand && batchMode) {
      return _getBatchRunner(command.flavor)
          .runCommand(command.flavor, command, timeout, command.arguments);
    } else if (command is ScriptCommand) {
      return command.run();
    } else if (command is AdbPrecompilationCommand) {
      assert(adbDevicePool != null);
      return adbDevicePool.acquireDevice().then((AdbDevice device) {
        return _runAdbPrecompilationCommand(device, command, timeout)
            .whenComplete(() {
          adbDevicePool.releaseDevice(device);
        });
      });
    } else {
      return new RunningProcess(command, timeout).run();
    }
  }

  Future<CommandOutput> _runAdbPrecompilationCommand(
      AdbDevice device, AdbPrecompilationCommand command, int timeout) async {
    var runner = command.precompiledRunnerFilename;
    var processTest = command.processTestFilename;
    var testdir = command.precompiledTestDirectory;
    var arguments = command.arguments;
    var devicedir = '/data/local/tmp/precompilation-testing';
    var deviceTestDir = '/data/local/tmp/precompilation-testing/test';

    // We copy all the files which the vm precompiler puts into the test
    // directory.
    List<String> files = new io.Directory(testdir)
        .listSync()
        .map((file) => file.path)
        .map((path) => path.substring(path.lastIndexOf('/') + 1))
        .toList();

    var timeoutDuration = new Duration(seconds: timeout);

    // All closures are of type "Future<AdbCommandResult> run()"
    List<Function> steps = [];

    steps.add(() => device.runAdbShellCommand(['rm', '-Rf', deviceTestDir]));
    steps.add(() => device.runAdbShellCommand(['mkdir', '-p', deviceTestDir]));
    // TODO: We should find a way for us to cache the runner binary and avoid
    // pushhing it for every single test (this is bad for SSD cycle time, test
    // timing).
    steps.add(() => device.runAdbCommand(
        ['push', runner, '$devicedir/dart_precompiled_runtime']));
    steps.add(() => device.runAdbCommand(
        ['push', processTest, '$devicedir/process_test']));
    steps.add(() => device.runAdbShellCommand(
        ['chmod', '777', '$devicedir/dart_precompiled_runtime $devicedir/process_test']));

    for (var file in files) {
      steps.add(() => device
          .runAdbCommand(['push', '$testdir/$file', '$deviceTestDir/$file']));
    }

    var args = new List();
    args.addAll(arguments);
    for (var i = 0; i < args.length; i++) {
      if (args[i].endsWith(".dart")) {
        args[i] = "$deviceTestDir/out.aotsnapshot";
      }
    }

    steps.add(() => device.runAdbShellCommand(
        [
          '$devicedir/dart_precompiled_runtime',
        ]..addAll(args),
        timeout: timeoutDuration));

    var stopwatch = new Stopwatch()..start();
    var writer = new StringBuffer();

    await device.waitForBootCompleted();
    await device.waitForDevice();

    AdbCommandResult result;
    for (var i = 0; i < steps.length; i++) {
      var fun = steps[i];
      var commandStopwatch = new Stopwatch()..start();
      result = await fun();

      writer.writeln("Executing ${result.command}");
      if (result.stdout.length > 0) {
        writer.writeln("Stdout:\n${result.stdout.trim()}");
      }
      if (result.stderr.length > 0) {
        writer.writeln("Stderr:\n${result.stderr.trim()}");
      }
      writer.writeln("ExitCode: ${result.exitCode}");
      writer.writeln("Time: ${commandStopwatch.elapsed}");
      writer.writeln("");

      // If one command fails, we stop processing the others and return
      // immediately.
      if (result.exitCode != 0) break;
    }
    return createCommandOutput(command, result.exitCode, result.timedOut,
        UTF8.encode('$writer'), [], stopwatch.elapsed, false);
  }

  BatchRunnerProcess _getBatchRunner(String identifier) {
    // Start batch processes if needed
    var runners = _batchProcesses[identifier];
    if (runners == null) {
      runners = new List<BatchRunnerProcess>(maxProcesses);
      for (int i = 0; i < maxProcesses; i++) {
        runners[i] = new BatchRunnerProcess();
      }
      _batchProcesses[identifier] = runners;
    }

    for (var runner in runners) {
      if (!runner._currentlyRunning) return runner;
    }
    throw new Exception('Unable to find inactive batch runner.');
  }

  Future<CommandOutput> _startBrowserControllerTest(
      BrowserTestCommand browserCommand, int timeout) {
    var completer = new Completer<CommandOutput>();

    var callback = (BrowserTestOutput output) {
      completer
          .complete(new BrowserControllerTestOutcome(browserCommand, output));
    };

    BrowserTest browserTest;
    if (browserCommand is BrowserHtmlTestCommand) {
      browserTest = new HtmlTest(browserCommand.url, callback, timeout,
          browserCommand.expectedMessages);
    } else {
      browserTest = new BrowserTest(browserCommand.url, callback, timeout);
    }
    _getBrowserTestRunner(browserCommand.browser, browserCommand.configuration)
        .then((testRunner) {
      testRunner.enqueueTest(browserTest);
    });

    return completer.future;
  }

  Future<BrowserTestRunner> _getBrowserTestRunner(
      String browser, Map configuration) async {
    var localIp = globalConfiguration['local_ip'];
    if (_browserTestRunners[configuration] == null) {
      var testRunner = new BrowserTestRunner(
          configuration, localIp, browser, maxBrowserProcesses);
      if (globalConfiguration['verbose']) {
        testRunner.logger = DebugLogger.info;
      }
      _browserTestRunners[configuration] = testRunner;
      await testRunner.start();
    }
    return _browserTestRunners[configuration];
  }
}

class RecordingCommandExecutor implements CommandExecutor {
  TestCaseRecorder _recorder;

  RecordingCommandExecutor(Path path) : _recorder = new TestCaseRecorder(path);

  Future<CommandOutput> runCommand(node, ProcessCommand command, int timeout) {
    assert(node.dependencies.length == 0);
    assert(_cleanEnvironmentOverrides(command.environmentOverrides));
    _recorder.nextCommand(command, timeout);
    // Return dummy CommandOutput
    var output =
        createCommandOutput(command, 0, false, [], [], const Duration(), false);
    return new Future.value(output);
  }

  Future cleanup() {
    _recorder.finish();
    return new Future.value();
  }

  // Returns [:true:] if the environment contains only 'DART_CONFIGURATION'
  bool _cleanEnvironmentOverrides(Map environment) {
    if (environment == null) return true;
    return environment.length == 0 ||
        (environment.length == 1 &&
            environment.containsKey("DART_CONFIGURATION"));
  }
}

class ReplayingCommandExecutor implements CommandExecutor {
  TestCaseOutputArchive _archive = new TestCaseOutputArchive();

  ReplayingCommandExecutor(Path path) {
    _archive.loadFromPath(path);
  }

  Future cleanup() => new Future.value();

  Future<CommandOutput> runCommand(node, ProcessCommand command, int timeout) {
    assert(node.dependencies.length == 0);
    return new Future.value(_archive.outputOf(command));
  }
}

bool shouldRetryCommand(CommandOutput output) {
  if (!output.successful) {
    List<String> stdout, stderr;

    decodeOutput() {
      if (stdout == null && stderr == null) {
        stdout = decodeUtf8(output.stderr).split("\n");
        stderr = decodeUtf8(output.stderr).split("\n");
      }
    }

    if (io.Platform.operatingSystem == 'linux') {
      decodeOutput();
      // No matter which command we ran: If we get failures due to the
      // "xvfb-run" issue 7564, try re-running the test.
      bool containsFailureMsg(String line) {
        return line.contains(MESSAGE_CANNOT_OPEN_DISPLAY) ||
            line.contains(MESSAGE_FAILED_TO_RUN_COMMAND);
      }
      if (stdout.any(containsFailureMsg) || stderr.any(containsFailureMsg)) {
        return true;
      }
    }

    // We currently rerun dartium tests, see issue 14074.
    final command = output.command;
    if (command is BrowserTestCommand &&
        command.retry &&
        command.browser == 'dartium') {
      return true;
    }
  }
  return false;
}

/*
 * [TestCaseCompleter] will listen for
 * NodeState.Processing -> NodeState.{Successful,Failed} state changes and
 * will complete a TestCase if it is finished.
 *
 * It provides a stream [finishedTestCases], which will stream all TestCases
 * once they're finished. After all TestCases are done, the stream will be
 * closed.
 */
class TestCaseCompleter {
  static final COMPLETED_STATES = [
    dgraph.NodeState.Failed,
    dgraph.NodeState.Successful
  ];
  final dgraph.Graph graph;
  final TestCaseEnqueuer enqueuer;
  final CommandQueue commandQueue;

  Map<Command, CommandOutput> _outputs = new Map<Command, CommandOutput>();
  bool _closed = false;
  StreamController<TestCase> _controller = new StreamController<TestCase>();

  TestCaseCompleter(this.graph, this.enqueuer, this.commandQueue) {
    var eventCondition = graph.events.where;
    bool finishedRemainingTestCases = false;

    // Store all the command outputs -- they will be delivered synchronously
    // (i.e. before state changes in the graph)
    commandQueue.completedCommands.listen((CommandOutput output) {
      _outputs[output.command] = output;
    }, onDone: () {
      _completeTestCasesIfPossible(new List.from(enqueuer.remainingTestCases));
      finishedRemainingTestCases = true;
      assert(enqueuer.remainingTestCases.isEmpty);
      _checkDone();
    });

    // Listen for NodeState.Processing -> NodeState.{Successful,Failed}
    // changes.
    eventCondition((event) => event is dgraph.StateChangedEvent)
        .listen((dgraph.StateChangedEvent event) {
      if (event.from == dgraph.NodeState.Processing &&
          !finishedRemainingTestCases) {
        var command = event.node.userData;

        assert(COMPLETED_STATES.contains(event.to));
        assert(_outputs[command] != null);

        _completeTestCasesIfPossible(enqueuer.command2testCases[command]);
        _checkDone();
      }
    });

    // Listen also for GraphSealedEvent's. If there is not a single node in the
    // graph, we still want to finish after the graph was sealed.
    eventCondition((event) => event is dgraph.GraphSealedEvent)
        .listen((dgraph.GraphSealedEvent event) {
      if (!_closed && enqueuer.remainingTestCases.isEmpty) {
        _controller.close();
        _closed = true;
      }
    });
  }

  Stream<TestCase> get finishedTestCases => _controller.stream;

  void _checkDone() {
    if (!_closed && graph.isSealed && enqueuer.remainingTestCases.isEmpty) {
      _controller.close();
      _closed = true;
    }
  }

  void _completeTestCasesIfPossible(Iterable<TestCase> testCases) {
    // Update TestCases with command outputs
    for (TestCase test in testCases) {
      for (var icommand in test.commands) {
        var output = _outputs[icommand];
        if (output != null) {
          test.commandOutputs[icommand] = output;
        }
      }
    }

    void completeTestCase(TestCase testCase) {
      if (enqueuer.remainingTestCases.contains(testCase)) {
        _controller.add(testCase);
        enqueuer.remainingTestCases.remove(testCase);
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

class ProcessQueue {
  Map _globalConfiguration;

  Function _allDone;
  final dgraph.Graph _graph = new dgraph.Graph();
  List<EventListener> _eventListener;

  ProcessQueue(this._globalConfiguration, maxProcesses, maxBrowserProcesses,
      DateTime startTime, testSuites, this._eventListener, this._allDone,
      [bool verbose = false,
      String recordingOutputFile,
      String recordedInputFile,
      AdbDevicePool adbDevicePool]) {
    void setupForListing(TestCaseEnqueuer testCaseEnqueuer) {
      _graph.events
          .where((event) => event is dgraph.GraphSealedEvent)
          .listen((dgraph.GraphSealedEvent event) {
        var testCases = new List.from(testCaseEnqueuer.remainingTestCases);
        testCases.sort((a, b) => a.displayName.compareTo(b.displayName));

        print("\nGenerating all matching test cases ....\n");

        for (TestCase testCase in testCases) {
          eventFinishedTestCase(testCase);
          print("${testCase.displayName}   "
              "Expectations: ${testCase.expectedOutcomes.join(', ')}   "
              "Configuration: '${testCase.configurationString}'");
        }
        eventAllTestsKnown();
      });
    }

    var testCaseEnqueuer;
    CommandQueue commandQueue;

    void setupForRunning(TestCaseEnqueuer testCaseEnqueuer) {
      Timer _debugTimer;
      // If we haven't seen a single test finishing during a 10 minute period
      // something is definitly wrong, so we dump the debugging information.
      final debugTimerDuration = const Duration(minutes: 10);

      void cancelDebugTimer() {
        if (_debugTimer != null) {
          _debugTimer.cancel();
        }
      }

      void resetDebugTimer() {
        cancelDebugTimer();
        _debugTimer = new Timer(debugTimerDuration, () {
          print("The debug timer of test.dart expired. Please report this issue"
              " to whesse@ and provide the following information:");
          print("");
          print("Graph is sealed: ${_graph.isSealed}");
          print("");
          _graph.DumpCounts();
          print("");
          var unfinishedNodeStates = [
            dgraph.NodeState.Initialized,
            dgraph.NodeState.Waiting,
            dgraph.NodeState.Enqueuing,
            dgraph.NodeState.Processing
          ];

          for (var nodeState in unfinishedNodeStates) {
            if (_graph.stateCount(nodeState) > 0) {
              print("Commands in state '$nodeState':");
              print("=================================");
              print("");
              for (var node in _graph.nodes) {
                if (node.state == nodeState) {
                  var command = node.userData;
                  var testCases = testCaseEnqueuer.command2testCases[command];
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

          if (commandQueue != null) {
            commandQueue.dumpState();
          }
        });
      }

      bool recording = recordingOutputFile != null;
      bool replaying = recordedInputFile != null;

      // When the graph building is finished, notify event listeners.
      _graph.events
          .where((event) => event is dgraph.GraphSealedEvent)
          .listen((event) {
        eventAllTestsKnown();
      });

      // Queue commands as they become "runnable"
      var commandEnqueuer = new CommandEnqueuer(_graph);

      // CommandExecutor will execute commands
      var executor;
      if (recording) {
        executor = new RecordingCommandExecutor(new Path(recordingOutputFile));
      } else if (replaying) {
        executor = new ReplayingCommandExecutor(new Path(recordedInputFile));
      } else {
        executor = new CommandExecutorImpl(
            _globalConfiguration, maxProcesses, maxBrowserProcesses,
            adbDevicePool: adbDevicePool);
      }

      // Run "runnable commands" using [executor] subject to
      // maxProcesses/maxBrowserProcesses constraint
      commandQueue = new CommandQueue(_graph, testCaseEnqueuer, executor,
          maxProcesses, maxBrowserProcesses, verbose);

      // Finish test cases when all commands were run (or some failed)
      var testCaseCompleter =
          new TestCaseCompleter(_graph, testCaseEnqueuer, commandQueue);
      testCaseCompleter.finishedTestCases.listen((TestCase finishedTestCase) {
        resetDebugTimer();

        // If we're recording, we don't report any TestCases to listeners.
        if (!recording) {
          eventFinishedTestCase(finishedTestCase);
        }
      }, onDone: () {
        // Wait until the commandQueue/execturo is done (it may need to stop
        // batch runners, browser controllers, ....)
        commandQueue.done.then((_) {
          cancelDebugTimer();
          eventAllTestsDone();
        });
      });

      resetDebugTimer();
    }

    // Build up the dependency graph
    testCaseEnqueuer = new TestCaseEnqueuer(_graph, (TestCase newTestCase) {
      eventTestAdded(newTestCase);
    });

    // Either list or run the tests
    if (_globalConfiguration['list']) {
      setupForListing(testCaseEnqueuer);
    } else {
      setupForRunning(testCaseEnqueuer);
    }

    // Start enqueing all TestCases
    testCaseEnqueuer.enqueueTestSuites(testSuites);
  }

  void freeEnqueueingStructures() {
    CommandBuilder.instance.clearCommandCache();
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
    freeEnqueueingStructures();
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
