// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
// We need to use the 'io' prefix here, otherwise io.exitCode will shadow
// CommandOutput.exitCode in subclasses of CommandOutput.
import 'dart:io' as io;

import 'command_output.dart';
import 'configuration.dart';
import 'path.dart';
import 'test_case.dart';
import 'utils.dart';

/// A command executed as a step in a test case.
abstract class Command {
  /// A descriptive name for this command.
  final String displayName;

  /// When cloning a command object to run it multiple times, we give
  /// the different copies distinct values for index.
  final int index;

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
  Command indexedCopy(int index);

  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      CommandOutput(this, exitCode, timedOut, stdout, stderr, time,
          compilationSkipped, pid);

  int get hashCode {
    if (_cachedHashCode == null) {
      var builder = HashCodeBuilder();
      _buildHashCode(builder);
      _cachedHashCode = builder.value;
    }
    return _cachedHashCode;
  }

  operator ==(Object other) =>
      identical(this, other) ||
      (runtimeType == other.runtimeType && _equal(other as Command));

  void _buildHashCode(HashCodeBuilder builder) {
    builder.add(displayName);
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

  ProcessCommand(String displayName, this.executable, this.arguments,
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
    return ProcessCommand(displayName, executable, arguments,
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
    var env = StringBuffer();
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
  /// The primary output file that will be created by this command.
  final String outputFile;

  /// If true, then the compilation is run even if the input files are older
  /// than the output file.
  final bool _alwaysCompile;
  final List<Uri> _bootstrapDependencies;

  CompilationCommand(
      String displayName,
      this.outputFile,
      this._bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      {bool alwaysCompile,
      String workingDirectory,
      int index = 0})
      : _alwaysCompile = alwaysCompile ?? false,
        super(displayName, executable, arguments, environmentOverrides,
            workingDirectory, index);

  CompilationCommand indexedCopy(int index) => CompilationCommand(
      displayName,
      outputFile,
      _bootstrapDependencies,
      executable,
      arguments,
      environmentOverrides,
      alwaysCompile: _alwaysCompile,
      workingDirectory: workingDirectory,
      index: index);

  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
      List<int> stderr, Duration time, bool compilationSkipped,
      [int pid = 0]) {
    if (displayName == 'precompiler' || displayName == 'app_jit') {
      return VMCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, pid);
    } else if (displayName == 'dart2js') {
      return Dart2jsCompilerCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
    } else if (displayName == 'dartdevc') {
      return DevCompilerCommandOutput(this, exitCode, timedOut, stdout, stderr,
          time, compilationSkipped, pid);
    }

    return CompilationCommandOutput(
        this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  }

  bool get outputIsUpToDate {
    if (_alwaysCompile) return false;

    var file = io.File(Path("$outputFile.deps").toNativePath());
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
        .getLastModified(Uri(scheme: 'file', path: outputFile));
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

  @override
  List<String> get batchArguments {
    return [...arguments.where((arg) => arg.startsWith('--enable-experiment'))];
  }

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(outputFile);
    builder.addJson(_alwaysCompile);
    builder.addJson(_bootstrapDependencies);
  }

  bool _equal(CompilationCommand other) =>
      super._equal(other) &&
      outputFile == other.outputFile &&
      _alwaysCompile == other._alwaysCompile &&
      deepJsonCompare(_bootstrapDependencies, other._bootstrapDependencies);
}

class FastaCompilationCommand extends CompilationCommand {
  final Uri _compilerLocation;

  FastaCompilationCommand(
      this._compilerLocation,
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      String workingDirectory,
      {int index = 0})
      : super("fasta", outputFile, bootstrapDependencies, executable, arguments,
            environmentOverrides,
            alwaysCompile: true,
            workingDirectory: workingDirectory,
            index: index);

  @override
  FastaCompilationCommand indexedCopy(int index) => FastaCompilationCommand(
      _compilerLocation,
      outputFile,
      _bootstrapDependencies,
      executable,
      arguments,
      environmentOverrides,
      workingDirectory,
      index: index);

  FastaCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      FastaCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);

  @override
  List<String> get batchArguments {
    return <String>[
      ...super.batchArguments,
      '--enable-asserts',
      _compilerLocation.resolve("batch.dart").toFilePath(),
    ];
  }

  @override
  String get reproductionCommand {
    String relativizeAndEscape(String argument) {
      if (workingDirectory != null) {
        argument = argument.replaceAll(
            workingDirectory, Uri.directory(".").toFilePath());
      }
      return escapeCommandLineArgument(argument);
    }

    var buffer = StringBuffer();
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
  VMKernelCompilationCommand(
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      {bool alwaysCompile,
      int index = 0})
      : super('vm_compile_to_kernel', outputFile, bootstrapDependencies,
            executable, arguments, environmentOverrides,
            alwaysCompile: alwaysCompile, index: index);

  VMKernelCompilationCommand indexedCopy(int index) =>
      VMKernelCompilationCommand(outputFile, _bootstrapDependencies, executable,
          arguments, environmentOverrides,
          alwaysCompile: _alwaysCompile, index: index);

  VMKernelCompilationCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int pid = 0]) =>
      VMKernelCompilationCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);

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

  BrowserTestCommand(this.url, this.configuration, {int index = 0})
      : super._(configuration.runtime.name, index: index);

  BrowserTestCommand indexedCopy(int index) =>
      BrowserTestCommand(url, configuration, index: index);

  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(browser.name);
    builder.addJson(url);
    builder.add(configuration);
  }

  bool _equal(BrowserTestCommand other) =>
      super._equal(other) &&
      browser == other.browser &&
      url == other.url &&
      identical(configuration, other.configuration);

  String get reproductionCommand {
    var parts = [
      io.Platform.resolvedExecutable,
      'pkg/test_runner/bin/launch_browser.dart',
      browser.name,
      url
    ];
    return parts.map(escapeCommandLineArgument).join(' ');
  }

  int get maxNumRetries => 4;
}

class AnalysisCommand extends ProcessCommand {
  AnalysisCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super('dart2analyzer', executable, arguments, environmentOverrides,
            null, index);

  AnalysisCommand indexedCopy(int index) =>
      AnalysisCommand(executable, arguments, environmentOverrides,
          index: index);

  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      AnalysisCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
}

class CompareAnalyzerCfeCommand extends ProcessCommand {
  CompareAnalyzerCfeCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super('compare_analyzer_cfe', executable, arguments,
            environmentOverrides, null, index);

  CompareAnalyzerCfeCommand indexedCopy(int index) =>
      CompareAnalyzerCfeCommand(executable, arguments, environmentOverrides,
          index: index);

  CompareAnalyzerCfeCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int pid = 0]) =>
      CompareAnalyzerCfeCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
}

class SpecParseCommand extends ProcessCommand {
  SpecParseCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super('spec_parser', executable, arguments, environmentOverrides, null,
            index);

  SpecParseCommand indexedCopy(int index) =>
      SpecParseCommand(executable, arguments, environmentOverrides,
          index: index);

  SpecParseCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int pid = 0]) =>
      SpecParseCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
}

class VMCommand extends ProcessCommand {
  VMCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides,
      {int index = 0})
      : super('vm', executable, arguments, environmentOverrides, null, index);

  VMCommand indexedCopy(int index) =>
      VMCommand(executable, arguments, environmentOverrides, index: index);

  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);
}

class VMBatchCommand extends ProcessCommand implements VMCommand {
  final String dartFile;
  final bool checked;

  VMBatchCommand(String executable, this.dartFile, List<String> arguments,
      Map<String, String> environmentOverrides,
      {this.checked = true, int index = 0})
      : super('vm-batch', executable, arguments, environmentOverrides, null,
            index);

  VMBatchCommand indexedCopy(int index) =>
      VMBatchCommand(executable, dartFile, arguments, environmentOverrides,
          checked: checked, index: index);

  @override
  List<String> get batchArguments =>
      checked ? ['--checked', dartFile] : [dartFile];

  @override
  bool _equal(VMBatchCommand other) {
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

// Run a VM test under RR, and copy the trace if it crashes. Using a helper
// script like the precompiler does not work because the RR traces are large
// and we must diligently erase them for non-crashes even if the test times
// out and would be killed by the harness, so the copying and cleanup logic
// must be in the harness.
class RRCommand extends Command {
  VMCommand originalCommand;
  VMCommand wrappedCommand;
  io.Directory recordingDir;
  io.Directory savedDir;

  RRCommand(this.originalCommand)
      : super._("rr", index: originalCommand.index) {
    final suffix = "/rr-trace-" + originalCommand.hashCode.toString();
    recordingDir = io.Directory(io.Directory.systemTemp.path + suffix);
    savedDir = io.Directory("out" + suffix);
    final executable = "rr";
    final arguments = <String>[
      "record",
      "--chaos",
      "--output-trace-dir=" + recordingDir.path,
    ];
    arguments.add(originalCommand.executable);
    arguments.addAll(originalCommand.arguments);
    wrappedCommand = VMCommand(
        executable, arguments, originalCommand.environmentOverrides,
        index: originalCommand.index);
  }

  RRCommand indexedCopy(int index) =>
      RRCommand(originalCommand.indexedCopy(index));

  Future<CommandOutput> run(int timeout) async {
    // rr will fail if the output trace directory already exists. Delete any
    // that might be leftover from interrupting the harness.
    if (await recordingDir.exists()) {
      await recordingDir.delete(recursive: true);
    }
    final output = await RunningProcess(wrappedCommand, timeout).run();
    if (output.hasCrashed) {
      if (await savedDir.exists()) {
        await savedDir.delete(recursive: true);
      }
      await recordingDir.rename(savedDir.path);
      await io.File(savedDir.path + "/command.txt")
          .writeAsString(wrappedCommand.reproductionCommand);
      await io.File(savedDir.path + "/stdout.txt").writeAsBytes(output.stdout);
      await io.File(savedDir.path + "/stderr.txt").writeAsBytes(output.stderr);
    } else {
      await recordingDir.delete(recursive: true);
    }

    return VMCommandOutput(this, output.exitCode, output.hasTimedOut,
        output.stdout, output.stderr, output.time, output.pid);
  }

  String get reproductionCommand =>
      wrappedCommand.reproductionCommand + " (rr replay " + savedDir.path + ")";

  void _buildHashCode(HashCodeBuilder builder) {
    originalCommand._buildHashCode(builder);
    builder.add(42);
  }

  bool _equal(RRCommand other) =>
      hashCode == other.hashCode &&
      originalCommand._equal(other.originalCommand);
}

abstract class AdbCommand {
  String get buildPath;
  List<String> get extraLibraries;
}

class AdbPrecompilationCommand extends Command implements AdbCommand {
  final String buildPath; // Path to the output directory of the build.
  final String processTestFilename;
  final String precompiledTestDirectory;
  final List<String> arguments;
  final bool useElf;
  final List<String> extraLibraries;

  AdbPrecompilationCommand(
      this.buildPath,
      this.processTestFilename,
      this.precompiledTestDirectory,
      this.arguments,
      this.useElf,
      this.extraLibraries,
      {int index = 0})
      : super._("adb_precompilation", index: index);

  AdbPrecompilationCommand indexedCopy(int index) => AdbPrecompilationCommand(
      buildPath,
      processTestFilename,
      precompiledTestDirectory,
      arguments,
      useElf,
      extraLibraries,
      index: index);

  VMCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);

  _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(buildPath);
    builder.add(precompiledTestDirectory);
    builder.add(arguments);
    builder.add(useElf);
    extraLibraries.forEach(builder.add);
  }

  bool _equal(AdbPrecompilationCommand other) =>
      super._equal(other) &&
      buildPath == other.buildPath &&
      useElf == other.useElf &&
      arguments == other.arguments &&
      precompiledTestDirectory == other.precompiledTestDirectory &&
      deepJsonCompare(extraLibraries, other.extraLibraries);

  String toString() => 'Steps to push precompiled runner and precompiled code '
      'to an attached device. Uses (and requires) adb.';
}

class AdbDartkCommand extends Command implements AdbCommand {
  final String buildPath;
  final String processTestFilename;
  final String kernelFile;
  final List<String> arguments;
  final List<String> extraLibraries;

  AdbDartkCommand(this.buildPath, this.processTestFilename, this.kernelFile,
      this.arguments, this.extraLibraries,
      {int index = 0})
      : super._("adb_precompilation", index: index);

  AdbDartkCommand indexedCopy(int index) => AdbDartkCommand(
      buildPath, processTestFilename, kernelFile, arguments, extraLibraries,
      index: index);

  _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(buildPath);
    builder.add(kernelFile);
    builder.add(arguments);
    builder.add(extraLibraries);
  }

  bool _equal(AdbDartkCommand other) =>
      super._equal(other) &&
      buildPath == other.buildPath &&
      arguments == other.arguments &&
      extraLibraries == other.extraLibraries &&
      kernelFile == other.kernelFile;

  VMCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);

  String toString() => 'Steps to push Dart VM and Dill file '
      'to an attached device. Uses (and requires) adb.';
}

class JSCommandLineCommand extends ProcessCommand {
  JSCommandLineCommand(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environmentOverrides, int index = 0])
      : super(displayName, executable, arguments, environmentOverrides, null,
            index);

  JSCommandLineCommand indexedCopy(int index) => JSCommandLineCommand(
      displayName, executable, arguments, environmentOverrides, index);

  JSCommandLineOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int pid = 0]) =>
      JSCommandLineOutput(this, exitCode, timedOut, stdout, stderr, time);
}

/// [ScriptCommand]s are executed by dart code.
abstract class ScriptCommand extends Command {
  ScriptCommand._(String displayName, {int index = 0})
      : super._(displayName, index: index);

  Future<ScriptCommandOutput> run();
}
