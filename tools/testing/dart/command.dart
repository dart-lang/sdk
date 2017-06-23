// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'command_output.dart';
import 'configuration.dart';
import 'expectation.dart';
import 'path.dart';
import 'utils.dart';

/// A command executed as a step in a test case.
class Command {
  static Command contentShell(
      String executable,
      String htmlFile,
      List<String> options,
      List<String> dartFlags,
      Map<String, String> environment) {
    return new ContentShellCommand._(
        executable, htmlFile, options, dartFlags, environment);
  }

  static Command browserTest(String url, Configuration configuration,
      {bool retry}) {
    return new BrowserTestCommand._(url, configuration, retry);
  }

  static Command browserHtmlTest(
      String url, Configuration configuration, List<String> expectedMessages,
      {bool retry}) {
    return new BrowserHtmlTestCommand._(
        url, configuration, expectedMessages, retry);
  }

  static Command compilation(
      String displayName,
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment,
      {bool alwaysCompile: false}) {
    return new CompilationCommand._(displayName, outputFile, alwaysCompile,
        bootstrapDependencies, executable, arguments, environment);
  }

  static Command kernelCompilation(
      String outputFile,
      bool neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment) {
    return new KernelCompilationCommand._(outputFile, neverSkipCompilation,
        bootstrapDependencies, executable, arguments, environment);
  }

  static Command analysis(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new AnalysisCommand._(executable, arguments, environmentOverrides);
  }

  static Command vm(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new VmCommand._(executable, arguments, environmentOverrides);
  }

  static Command vmBatch(String executable, String tester,
      List<String> arguments, Map<String, String> environmentOverrides,
      {bool checked: true}) {
    return new VmBatchCommand._(
        executable, tester, arguments, environmentOverrides,
        checked: checked);
  }

  static Command adbPrecompiled(String precompiledRunner, String processTest,
      String testDirectory, List<String> arguments, bool useBlobs) {
    return new AdbPrecompilationCommand._(
        precompiledRunner, processTest, testDirectory, arguments, useBlobs);
  }

  static Command jsCommandLine(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environment]) {
    return new JSCommandlineCommand._(
        displayName, executable, arguments, environment);
  }

  static Command process(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environment, String workingDirectory]) {
    return new ProcessCommand._(
        displayName, executable, arguments, environment, workingDirectory);
  }

  static Command copy(String sourceDirectory, String destinationDirectory) {
    return new CleanDirectoryCopyCommand._(
        sourceDirectory, destinationDirectory);
  }

  static Command makeSymlink(String link, String target) {
    return new MakeSymlinkCommand._(link, target);
  }

  /// A descriptive name for this command.
  final String displayName;

  /// Number of times this command *can* be retried.
  int get maxNumRetries => 2;

  /// Reproduction command.
  String get reproductionCommand => null;

  /// We compute the Command.hashCode lazily and cache it here, since it might
  /// be expensive to compute (and hashCode is called often).
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

  operator ==(Object other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType && _equal(other as Command));

  void _buildHashCode(HashCodeBuilder builder) {
    builder.addJson(displayName);
  }

  bool _equal(covariant Command other) =>
      hashCode == other.hashCode && displayName == other.displayName;

  String toString() => reproductionCommand;

  bool get outputIsUpToDate => false;
}

class ProcessCommand extends Command {
  /// Path to the executable of this command.
  String executable;

  /// Command line arguments to the executable.
  final List<String> arguments;

  /// Environment for the command.
  final Map<String, String> environmentOverrides;

  /// Working directory for the command.
  final String workingDirectory;

  ProcessCommand._(String displayName, this.executable, this.arguments,
      [this.environmentOverrides, this.workingDirectory])
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
    var command = ([executable]..addAll(batchArguments)..addAll(arguments))
        .map(escapeCommandLineArgument)
        .join(' ');
    if (workingDirectory != null) {
      command = "$command (working directory: $workingDirectory)";
    }
    return "$env$command";
  }

  bool get outputIsUpToDate => false;

  /// Arguments that are passed to the process when starting batch mode.
  ///
  /// In non-batch mode, they should be passed before [arguments].
  List<String> get batchArguments => const [];
}

class CompilationCommand extends ProcessCommand {
  final String _outputFile;

  /// If true, then the compilation is run even if the input files are older
  /// than the output file.
  final bool _alwaysCompile;
  final List<Uri> _bootstrapDependencies;

  CompilationCommand._(
      String displayName,
      this._outputFile,
      this._alwaysCompile,
      this._bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._(displayName, executable, arguments, environmentOverrides);

  bool get outputIsUpToDate {
    if (_alwaysCompile) return false;

    var file = new io.File(new Path("$_outputFile.deps").toNativePath());
    if (!file.existsSync()) return false;

    var lines = file.readAsLinesSync();
    var dependencies = <Uri>[];
    for (var line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        dependencies.add(Uri.parse(line));
      }
    }

    dependencies.addAll(_bootstrapDependencies);
    var jsOutputLastModified = TestUtils.lastModifiedCache
        .getLastModified(new Uri(scheme: 'file', path: _outputFile));
    if (jsOutputLastModified == null) return false;

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

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_outputFile);
    builder.addJson(_alwaysCompile);
    builder.addJson(_bootstrapDependencies);
  }

  bool _equal(CompilationCommand other) =>
      super._equal(other) &&
      _outputFile == other._outputFile &&
      _alwaysCompile == other._alwaysCompile &&
      deepJsonCompare(_bootstrapDependencies, other._bootstrapDependencies);
}

class KernelCompilationCommand extends CompilationCommand {
  KernelCompilationCommand._(
      String outputFile,
      bool neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._('dartk', outputFile, neverSkipCompilation,
            bootstrapDependencies, executable, arguments, environmentOverrides);

  int get maxNumRetries => 1;
}

/// This is just a Pair(String, Map) class with hashCode and operator ==
class AddFlagsKey {
  final String flags;
  final Map env;
  AddFlagsKey(this.flags, this.env);
  // Just use object identity for environment map
  bool operator ==(Object other) =>
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
  static Map<AddFlagsKey, Map<String, String>> environments = {};

  static Map<String, String> _getEnvironment(
      Map<String, String> env, List<String> dartFlags) {
    var needDartFlags = dartFlags != null && dartFlags.isNotEmpty;
    if (needDartFlags) {
      if (env == null) {
        env = const <String, String>{};
      }
      var flags = dartFlags.join(' ');
      return environments.putIfAbsent(
          new AddFlagsKey(flags, env),
          () => new Map<String, String>.from(env)
            ..addAll({'DART_FLAGS': flags, 'DART_FORWARDING_PRINT': '1'}));
    }
    return env;
  }

  static List<String> _getArguments(List<String> options, String htmlFile) {
    var arguments = options.toList();
    arguments.add(htmlFile);
    return arguments;
  }

  int get maxNumRetries => 3;
}

class BrowserTestCommand extends Command {
  Runtime get browser => configuration.runtime;
  final String url;
  final Configuration configuration;
  final bool retry;

  BrowserTestCommand._(this.url, this.configuration, this.retry)
      : super._(configuration.runtime.name);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(browser.name);
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
      browser.name,
      url
    ];
    return parts.map(escapeCommandLineArgument).join(' ');
  }

  int get maxNumRetries => 4;
}

class BrowserHtmlTestCommand extends BrowserTestCommand {
  List<String> expectedMessages;
  BrowserHtmlTestCommand._(String url, Configuration configuration,
      this.expectedMessages, bool retry)
      : super._(url, configuration, retry);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(expectedMessages);
  }

  bool _equal(BrowserHtmlTestCommand other) =>
      super._equal(other) &&
      identical(expectedMessages, other.expectedMessages);
}

class AnalysisCommand extends ProcessCommand {
  AnalysisCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._('dart2analyzer', executable, arguments, environmentOverrides);
}

class VmCommand extends ProcessCommand {
  VmCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides)
      : super._('vm', executable, arguments, environmentOverrides);
}

class VmBatchCommand extends ProcessCommand implements VmCommand {
  final String dartFile;
  final bool checked;

  VmBatchCommand._(String executable, String dartFile, List<String> arguments,
      Map<String, String> environmentOverrides,
      {this.checked: true})
      : this.dartFile = dartFile,
        super._('vm-batch', executable, arguments, environmentOverrides);

  @override
  List<String> get batchArguments =>
      checked ? ['--checked', dartFile] : [dartFile];

  @override
  bool _equal(VmBatchCommand other) {
    return super._equal(other) &&
        dartFile == other.dartFile &&
        checked == other.checked;
  }

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(dartFile);
    builder.addJson(checked);
  }
}

class AdbPrecompilationCommand extends Command {
  final String precompiledRunnerFilename;
  final String processTestFilename;
  final String precompiledTestDirectory;
  final List<String> arguments;
  final bool useBlobs;

  AdbPrecompilationCommand._(
      this.precompiledRunnerFilename,
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

/// [ScriptCommand]s are executed by dart code.
abstract class ScriptCommand extends Command {
  ScriptCommand._(String displayName) : super._(displayName);

  Future<ScriptCommandOutput> run();
}

class CleanDirectoryCopyCommand extends ScriptCommand {
  final String _sourceDirectory;
  final String _destinationDirectory;

  CleanDirectoryCopyCommand._(this._sourceDirectory, this._destinationDirectory)
      : super._('dir_copy');

  String get reproductionCommand =>
      "Copying '$_sourceDirectory' to '$_destinationDirectory'.";

  Future<ScriptCommandOutput> run() {
    var watch = new Stopwatch()..start();

    var destination = new io.Directory(_destinationDirectory);

    return destination.exists().then((bool exists) {
      Future cleanDirectoryFuture;
      if (exists) {
        cleanDirectoryFuture = TestUtils.deleteDirectory(_destinationDirectory);
      } else {
        cleanDirectoryFuture = new Future.value(null);
      }
      return cleanDirectoryFuture.then((_) {
        return TestUtils.copyDirectory(_sourceDirectory, _destinationDirectory);
      });
    }).then((_) {
      return new ScriptCommandOutput(this, Expectation.pass, "", watch.elapsed);
    }).catchError((error) {
      return new ScriptCommandOutput(
          this, Expectation.fail, "An error occured: $error.", watch.elapsed);
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

/// Makes a symbolic link to another directory.
class MakeSymlinkCommand extends ScriptCommand {
  String _link;
  String _target;

  MakeSymlinkCommand._(this._link, this._target) : super._('make_symlink');

  String get reproductionCommand =>
      "Make symbolic link '$_link' (target: $_target)'.";

  Future<ScriptCommandOutput> run() {
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
      return new ScriptCommandOutput(this, Expectation.pass, "", watch.elapsed);
    }).catchError((error) {
      return new ScriptCommandOutput(
          this, Expectation.fail, "An error occured: $error.", watch.elapsed);
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
