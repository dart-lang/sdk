// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'package:status_file/expectation.dart';

import 'command_output.dart';
import 'configuration.dart';
import 'path.dart';
import 'utils.dart';

/// A command executed as a step in a test case.
class Command {
  static Command browserTest(String url, TestConfiguration configuration,
      {bool retry}) {
    return new BrowserTestCommand._(url, configuration, retry);
  }

  static Command compilation(
      String displayName,
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment,
      {bool alwaysCompile: false,
      String workingDirectory}) {
    return new CompilationCommand._(displayName, outputFile, alwaysCompile,
        bootstrapDependencies, executable, arguments, environment,
        workingDirectory: workingDirectory);
  }

  static Command vmKernelCompilation(
      String outputFile,
      bool neverSkipCompilation,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environment) {
    return new VMKernelCompilationCommand._(outputFile, neverSkipCompilation,
        bootstrapDependencies, executable, arguments, environment);
  }

  static Command analysis(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new AnalysisCommand._(executable, arguments, environmentOverrides);
  }

  static Command compareAnalyzerCfe(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new CompareAnalyzerCfeCommand._(
        executable, arguments, environmentOverrides);
  }

  static Command specParse(String executable, List<String> arguments,
      Map<String, String> environmentOverrides) {
    return new SpecParseCommand._(executable, arguments, environmentOverrides);
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

  static Command fasta(
      Uri compilerLocation,
      Uri outputFile,
      List<Uri> bootstrapDependencies,
      Uri executable,
      List<String> arguments,
      Map<String, String> environment,
      Uri workingDirectory) {
    return new FastaCompilationCommand._(
        compilerLocation,
        outputFile.toFilePath(),
        bootstrapDependencies,
        executable.toFilePath(),
        arguments,
        environment,
        workingDirectory?.toFilePath());
  }

  /// A descriptive name for this command.
  final String displayName;

  /// When cloning a command object to run it multiple times, we give
  /// the different copies distinct values for index.
  int index;

  /// Number of times this command *can* be retried.
  int get maxNumRetries => 2;

  /// Reproduction command.
  String get reproductionCommand => null;

  /// We compute the Command.hashCode lazily and cache it here, since it might
  /// be expensive to compute (and hashCode is called often).
  int _cachedHashCode;

  Command._(this.displayName, {this.index = 0});

  /// A virtual clone method for a member of the Command hierarchy.
  /// Two clones with the same index will be equal, with different indices
  /// will be distinct. Used to run tests multiple times, since identical
  /// commands are only run once by the dependency graph scheduler.
  Command indexedCopy(int index) {
    return Command._(displayName, index: index);
  }

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
    builder.add(index);
  }

  bool _equal(covariant Command other) =>
      hashCode == other.hashCode &&
      displayName == other.displayName &&
      index == other.index;

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
      [this.environmentOverrides, this.workingDirectory, int index = 0])
      : super._(displayName, index: index) {
    if (io.Platform.operatingSystem == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // NOTE: Issue 1306
      executable = executable.replaceAll('/', '\\');
    }
  }

  ProcessCommand indexedCopy(int index) {
    return ProcessCommand._(displayName, executable, arguments,
        environmentOverrides, workingDirectory, index);
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
      Map<String, String> environmentOverrides,
      {String workingDirectory,
      int index = 0})
      : super._(displayName, executable, arguments, environmentOverrides,
            workingDirectory, index);

  CompilationCommand indexedCopy(int index) => CompilationCommand._(
      displayName,
      _outputFile,
      _alwaysCompile,
      _bootstrapDependencies,
      executable,
      arguments,
      environmentOverrides,
      workingDirectory: workingDirectory,
      index: index);

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

class FastaCompilationCommand extends CompilationCommand {
  final Uri _compilerLocation;

  FastaCompilationCommand._(
      this._compilerLocation,
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      String workingDirectory,
      {int index = 0})
      : super._("fasta", outputFile, true, bootstrapDependencies, executable,
            arguments, environmentOverrides,
            workingDirectory: workingDirectory, index: index);

  @override
  FastaCompilationCommand indexedCopy(int index) => FastaCompilationCommand._(
      _compilerLocation,
      _outputFile,
      _bootstrapDependencies,
      executable,
      arguments,
      environmentOverrides,
      workingDirectory,
      index: index);

  @override
  List<String> get batchArguments {
    return <String>[
      '--enable-asserts',
      _compilerLocation.resolve("batch.dart").toFilePath(),
    ];
  }

  @override
  String get reproductionCommand {
    String relativizeAndEscape(String argument) {
      if (workingDirectory != null) {
        argument = argument.replaceAll(
            workingDirectory, new Uri.directory(".").toFilePath());
      }
      return escapeCommandLineArgument(argument);
    }

    StringBuffer buffer = new StringBuffer();
    if (workingDirectory != null && !io.Platform.isWindows) {
      buffer.write("(cd ");
      buffer.write(escapeCommandLineArgument(workingDirectory));
      buffer.write(" ; ");
    }
    environmentOverrides?.forEach((key, value) {
      if (io.Platform.isWindows) {
        buffer.write("set ");
      }
      buffer.write(key);
      buffer.write("=");
      buffer.write(relativizeAndEscape(value));
      if (io.Platform.isWindows) {
        buffer.write(" &");
      }
      buffer.write(" ");
    });
    buffer.writeAll(
        (<String>[executable]
              ..add(_compilerLocation.toFilePath())
              ..addAll(arguments))
            .map(relativizeAndEscape),
        " ");
    if (workingDirectory != null) {
      if (io.Platform.isWindows) {
        buffer.write(" (working directory: $workingDirectory)");
      } else {
        buffer.write(" )");
      }
    }
    return "$buffer";
  }

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(_compilerLocation);
  }

  @override
  bool _equal(FastaCompilationCommand other) {
    return super._equal(other) && _compilerLocation == other._compilerLocation;
  }
}

class VMKernelCompilationCommand extends CompilationCommand {
  VMKernelCompilationCommand._(
      String outputFile,
      bool alwaysCompile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      {int index = 0})
      : super._('vm_compile_to_kernel', outputFile, alwaysCompile,
            bootstrapDependencies, executable, arguments, environmentOverrides,
            index: index);

  VMKernelCompilationCommand indexedCopy(int index) =>
      VMKernelCompilationCommand._(_outputFile, _alwaysCompile,
          _bootstrapDependencies, executable, arguments, environmentOverrides,
          index: index);

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

class BrowserTestCommand extends Command {
  Runtime get browser => configuration.runtime;
  final String url;
  final TestConfiguration configuration;
  final bool retry;

  BrowserTestCommand._(this.url, this.configuration, this.retry,
      {int index = 0})
      : super._(configuration.runtime.name, index: index);

  BrowserTestCommand indexedCopy(int index) =>
      BrowserTestCommand._(url, configuration, retry, index: index);

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

class AnalysisCommand extends ProcessCommand {
  AnalysisCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super._('dart2analyzer', executable, arguments, environmentOverrides,
            null, index);

  AnalysisCommand indexedCopy(int index) =>
      AnalysisCommand._(executable, arguments, environmentOverrides,
          index: index);
}

class CompareAnalyzerCfeCommand extends ProcessCommand {
  CompareAnalyzerCfeCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super._('compare_analyzer_cfe', executable, arguments,
            environmentOverrides, null, index);

  CompareAnalyzerCfeCommand indexedCopy(int index) =>
      CompareAnalyzerCfeCommand._(executable, arguments, environmentOverrides,
          index: index);
}

class SpecParseCommand extends ProcessCommand {
  SpecParseCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super._('spec_parser', executable, arguments, environmentOverrides,
            null, index);

  SpecParseCommand indexedCopy(int index) =>
      SpecParseCommand._(executable, arguments, environmentOverrides,
          index: index);
}

class VmCommand extends ProcessCommand {
  VmCommand._(String executable, List<String> arguments,
      Map<String, String> environmentOverrides,
      {int index = 0})
      : super._('vm', executable, arguments, environmentOverrides, null, index);

  VmCommand indexedCopy(int index) =>
      VmCommand._(executable, arguments, environmentOverrides, index: index);
}

class VmBatchCommand extends ProcessCommand implements VmCommand {
  final String dartFile;
  final bool checked;

  VmBatchCommand._(String executable, String dartFile, List<String> arguments,
      Map<String, String> environmentOverrides,
      {this.checked: true, int index = 0})
      : this.dartFile = dartFile,
        super._('vm-batch', executable, arguments, environmentOverrides, null,
            index);

  VmBatchCommand indexedCopy(int index) =>
      VmBatchCommand._(executable, dartFile, arguments, environmentOverrides,
          checked: checked, index: index);

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
      this.useBlobs,
      {int index = 0})
      : super._("adb_precompilation", index: index);

  AdbPrecompilationCommand indexedCopy(int index) => AdbPrecompilationCommand._(
      precompiledRunnerFilename,
      processTestFilename,
      precompiledTestDirectory,
      arguments,
      useBlobs,
      index: index);
  _buildHashCode(HashCodeBuilder builder) {
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
      [Map<String, String> environmentOverrides = null, int index = 0])
      : super._(displayName, executable, arguments, environmentOverrides, null,
            index);

  JSCommandlineCommand indexedCopy(int index) => JSCommandlineCommand._(
      displayName, executable, arguments, environmentOverrides, index);
}

/// [ScriptCommand]s are executed by dart code.
abstract class ScriptCommand extends Command {
  ScriptCommand._(String displayName, {int index = 0})
      : super._(displayName, index: index);

  Future<ScriptCommandOutput> run();
}

class CleanDirectoryCopyCommand extends ScriptCommand {
  final String _sourceDirectory;
  final String _destinationDirectory;

  CleanDirectoryCopyCommand._(this._sourceDirectory, this._destinationDirectory,
      {int index = 0})
      : super._('dir_copy', index: index);

  CleanDirectoryCopyCommand indexedCopy(int index) =>
      CleanDirectoryCopyCommand._(_sourceDirectory, _destinationDirectory,
          index: index);

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

  MakeSymlinkCommand._(this._link, this._target, {int index = 0})
      : super._('make_symlink', index: index);

  MakeSymlinkCommand indexedCopy(int index) =>
      MakeSymlinkCommand._(_link, _target, index: index);

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
        if (exists) link.deleteSync();
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
