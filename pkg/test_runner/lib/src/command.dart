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
  String get reproductionCommand;

  /// We compute the Command.hashCode lazily and cache it here, since it might
  /// be expensive to compute (and hashCode is called often).
  int? _cachedHashCode;

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

  @override
  int get hashCode {
    if (_cachedHashCode == null) {
      var builder = HashCodeBuilder();
      _buildHashCode(builder);
      _cachedHashCode = builder.value;
    }
    return _cachedHashCode!;
  }

  @override
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

  @override
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
  final String? workingDirectory;

  ProcessCommand(String displayName, this.executable, this.arguments,
      [this.environmentOverrides = const {},
      this.workingDirectory,
      int index = 0])
      : super._(displayName, index: index) {
    if (io.Platform.operatingSystem == 'windows') {
      // Windows can't handle the first command if it is a .bat file or the like
      // with the slashes going the other direction.
      // NOTE: Issue 1306
      executable = executable.replaceAll('/', '\\');
    }
  }

  @override
  ProcessCommand indexedCopy(int index) {
    return ProcessCommand(displayName, executable, arguments,
        environmentOverrides, workingDirectory, index);
  }

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(executable);
    builder.addJson(workingDirectory);
    builder.addJson(arguments);
    builder.addJson(environmentOverrides);
  }

  @override
  bool _equal(ProcessCommand other) =>
      super._equal(other) &&
      executable == other.executable &&
      deepJsonCompare(arguments, other.arguments) &&
      workingDirectory == other.workingDirectory &&
      deepJsonCompare(environmentOverrides, other.environmentOverrides);

  @override
  String get reproductionCommand {
    var env = StringBuffer();
    environmentOverrides.forEach((key, value) =>
        (io.Platform.operatingSystem == 'windows')
            ? env.write('set $key=${escapeCommandLineArgument(value)} & ')
            : env.write('$key=${escapeCommandLineArgument(value)} '));
    var command = [executable, ...nonBatchArguments, ...arguments]
        .map(escapeCommandLineArgument)
        .join(' ');
    if (workingDirectory != null) {
      command = "$command (working directory: $workingDirectory)";
    }
    return "$env$command";
  }

  @override
  bool get outputIsUpToDate => false;

  /// Additional arguments to prepend before [arguments] when running the
  /// process in batch mode.
  List<String> get batchArguments => const [];

  /// Additional arguments to prepend before [arguments] when running the
  /// process in non-batch mode.
  List<String> get nonBatchArguments => const [];
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
      {required bool alwaysCompile,
      String? workingDirectory,
      int index = 0})
      : _alwaysCompile = alwaysCompile,
        super(displayName, executable, arguments, environmentOverrides,
            workingDirectory, index);

  @override
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

  @override
  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
      List<int> stderr, Duration time, bool compilationSkipped,
      [int pid = 0]) {
    if (displayName == 'precompiler' || displayName == 'app_jit') {
      return VMCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, pid);
    } else if (displayName == 'dart2wasm') {
      return Dart2WasmCompilerCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
    }

    return CompilationCommandOutput(
        this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  }

  @override
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

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(outputFile);
    builder.addJson(_alwaysCompile);
    builder.addJson(_bootstrapDependencies);
  }

  @override
  bool _equal(CompilationCommand other) =>
      super._equal(other) &&
      outputFile == other.outputFile &&
      _alwaysCompile == other._alwaysCompile &&
      deepJsonCompare(_bootstrapDependencies, other._bootstrapDependencies);
}

class Dart2jsCompilationCommand extends CompilationCommand {
  final bool useSdk;

  Dart2jsCompilationCommand(
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      {required this.useSdk,
      required bool alwaysCompile,
      String? workingDirectory,
      int index = 0})
      : super("dart2js", outputFile, bootstrapDependencies, executable,
            arguments, environmentOverrides,
            alwaysCompile: alwaysCompile,
            workingDirectory: workingDirectory,
            index: index);

  @override
  Dart2jsCompilationCommand indexedCopy(int index) => Dart2jsCompilationCommand(
      outputFile,
      _bootstrapDependencies,
      executable,
      arguments,
      environmentOverrides,
      useSdk: useSdk,
      alwaysCompile: _alwaysCompile,
      workingDirectory: workingDirectory,
      index: index);

  @override
  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
      List<int> stderr, Duration time, bool compilationSkipped,
      [int? pid = 0]) {
    return Dart2jsCompilerCommandOutput(
        this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
  }

  @override
  List<String> get batchArguments {
    return <String>[
      if (useSdk) ...['compile', 'js'],
      ...super.batchArguments,
    ];
  }

  @override
  List<String> get nonBatchArguments {
    return <String>[
      if (useSdk) ...['compile', 'js'],
      ...super.nonBatchArguments,
    ];
  }

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(useSdk);
  }

  @override
  bool _equal(Dart2jsCompilationCommand other) {
    return super._equal(other) && useSdk == other.useSdk;
  }
}

class DevCompilerCompilationCommand extends CompilationCommand {
  final String compilerPath;

  DevCompilerCompilationCommand(
      String outputFile,
      List<Uri> bootstrapDependencies,
      String executable,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      {required this.compilerPath,
      required bool alwaysCompile,
      String? workingDirectory,
      int index = 0})
      : super("ddc", outputFile, bootstrapDependencies, executable, arguments,
            environmentOverrides,
            alwaysCompile: alwaysCompile,
            workingDirectory: workingDirectory,
            index: index);

  @override
  DevCompilerCompilationCommand indexedCopy(int index) =>
      DevCompilerCompilationCommand(outputFile, _bootstrapDependencies,
          executable, arguments, environmentOverrides,
          compilerPath: compilerPath,
          alwaysCompile: _alwaysCompile,
          workingDirectory: workingDirectory,
          index: index);

  @override
  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
      List<int> stderr, Duration time, bool compilationSkipped,
      [int pid = 0]) {
    return DevCompilerCommandOutput(this, exitCode, timedOut, stdout, stderr,
        time, compilationSkipped, pid);
  }

  @override
  List<String> get batchArguments {
    return <String>[
      compilerPath,
      ...super.batchArguments,
    ];
  }

  @override
  List<String> get nonBatchArguments {
    return <String>[
      compilerPath,
      ...super.nonBatchArguments,
    ];
  }

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(compilerPath);
  }

  @override
  bool _equal(DevCompilerCompilationCommand other) {
    return super._equal(other) && compilerPath == other.compilerPath;
  }
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
      String? workingDirectory,
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

  @override
  FastaCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int? pid = 0]) =>
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
            workingDirectory!, Uri.directory(".").toFilePath());
      }
      return escapeCommandLineArgument(argument);
    }

    var buffer = StringBuffer();
    if (workingDirectory != null && !io.Platform.isWindows) {
      buffer.write("(cd ");
      buffer.write(escapeCommandLineArgument(workingDirectory!));
      buffer.write(" ; ");
    }
    environmentOverrides.forEach((key, value) {
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
      [executable, _compilerLocation.toFilePath(), ...arguments]
          .map(relativizeAndEscape),
      " ",
    );
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
      {required bool alwaysCompile,
      int index = 0})
      : super('vm_compile_to_kernel', outputFile, bootstrapDependencies,
            executable, arguments, environmentOverrides,
            alwaysCompile: alwaysCompile, index: index);

  @override
  VMKernelCompilationCommand indexedCopy(int index) =>
      VMKernelCompilationCommand(outputFile, _bootstrapDependencies, executable,
          arguments, environmentOverrides,
          alwaysCompile: _alwaysCompile, index: index);

  @override
  VMKernelCompilationCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int? pid = 0]) =>
      VMKernelCompilationCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);

  @override
  int get maxNumRetries => 1;
}

/// This is just a Pair(String, Map) class with hashCode and operator ==
class AddFlagsKey {
  final String flags;
  final Map env;
  AddFlagsKey(this.flags, this.env);
  // Just use object identity for environment map
  @override
  bool operator ==(Object other) =>
      other is AddFlagsKey && flags == other.flags && env == other.env;
  @override
  int get hashCode => flags.hashCode ^ env.hashCode;
}

class BrowserTestCommand extends Command {
  Runtime get browser => configuration.runtime;
  final String url;
  final TestConfiguration configuration;

  BrowserTestCommand(this.url, this.configuration, {int index = 0})
      : super._(configuration.runtime.name, index: index);

  @override
  BrowserTestCommand indexedCopy(int index) =>
      BrowserTestCommand(url, configuration, index: index);

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.addJson(browser.name);
    builder.addJson(url);
    builder.add(configuration);
  }

  @override
  bool _equal(BrowserTestCommand other) =>
      super._equal(other) &&
      browser == other.browser &&
      url == other.url &&
      identical(configuration, other.configuration);

  @override
  String get reproductionCommand {
    var parts = [
      io.Platform.resolvedExecutable,
      'pkg/test_runner/bin/launch_browser.dart',
      browser.name,
      url
    ];
    return parts.map(escapeCommandLineArgument).join(' ');
  }

  @override
  int get maxNumRetries => 4;
}

class AnalysisCommand extends ProcessCommand {
  final List<String> commonAnalyzerCliArguments;

  AnalysisCommand(String executable, List<String> arguments,
      this.commonAnalyzerCliArguments, Map<String, String> environmentOverrides,
      {int index = 0})
      : super('dart2analyzer', executable, arguments, environmentOverrides,
            null, index);

  @override
  AnalysisCommand indexedCopy(int index) => AnalysisCommand(
      executable, arguments, commonAnalyzerCliArguments, environmentOverrides,
      index: index);

  @override
  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int? pid = 0]) =>
      AnalysisCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);

  @override
  List<String> get batchArguments => commonAnalyzerCliArguments;

  @override
  List<String> get nonBatchArguments => commonAnalyzerCliArguments;

  @override
  bool _equal(covariant ProcessCommand other) {
    return other is AnalysisCommand &&
        super._equal(other) &&
        deepJsonCompare(
            commonAnalyzerCliArguments, other.commonAnalyzerCliArguments);
  }
}

class CompareAnalyzerCfeCommand extends ProcessCommand {
  CompareAnalyzerCfeCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super('compare_analyzer_cfe', executable, arguments,
            environmentOverrides, null, index);

  @override
  CompareAnalyzerCfeCommand indexedCopy(int index) =>
      CompareAnalyzerCfeCommand(executable, arguments, environmentOverrides,
          index: index);

  @override
  CompareAnalyzerCfeCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int? pid = 0]) =>
      CompareAnalyzerCfeCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
}

class SpecParseCommand extends ProcessCommand {
  SpecParseCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides, {int index = 0})
      : super('spec_parser', executable, arguments, environmentOverrides, null,
            index);

  @override
  SpecParseCommand indexedCopy(int index) =>
      SpecParseCommand(executable, arguments, environmentOverrides,
          index: index);

  @override
  SpecParseCommandOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int? pid = 0]) =>
      SpecParseCommandOutput(
          this, exitCode, timedOut, stdout, stderr, time, compilationSkipped);
}

class VMCommand extends ProcessCommand {
  VMCommand(String executable, List<String> arguments,
      Map<String, String> environmentOverrides,
      {int index = 0})
      : super('vm', executable, arguments, environmentOverrides, null, index);

  @override
  VMCommand indexedCopy(int index) =>
      VMCommand(executable, arguments, environmentOverrides, index: index);

  @override
  CommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);
}

// Run a VM test under RR, and copy the trace if it crashes. Using a helper
// script like the precompiler does not work because the RR traces are large
// and we must diligently erase them for non-crashes even if the test times
// out and would be killed by the harness, so the copying and cleanup logic
// must be in the harness.
class RRCommand extends Command {
  ProcessCommand originalCommand;
  late ProcessCommand wrappedCommand;
  late io.Directory recordingDir;
  late io.Directory savedDir;

  RRCommand(this.originalCommand)
      : super._(originalCommand.displayName, index: originalCommand.index) {
    final suffix = "/rr-trace-${originalCommand.hashCode}";
    recordingDir = io.Directory(io.Directory.systemTemp.path + suffix);
    savedDir = io.Directory("out$suffix");
    final executable = "rr";
    final arguments = <String>[
      "record",
      "--chaos",
      "--output-trace-dir=${recordingDir.path}",
    ];
    arguments.add(originalCommand.executable);
    arguments.addAll(originalCommand.nonBatchArguments);
    arguments.addAll(originalCommand.arguments);
    wrappedCommand = ProcessCommand(
        originalCommand.displayName,
        executable,
        arguments,
        originalCommand.environmentOverrides,
        originalCommand.workingDirectory,
        originalCommand.index);
  }

  @override
  RRCommand indexedCopy(int index) =>
      RRCommand(originalCommand.indexedCopy(index));

  Future<CommandOutput> run(
      int timeout, TestConfiguration configuration) async {
    // rr will fail if the output trace directory already exists. Delete any
    // that might be leftover from interrupting the harness.
    if (await recordingDir.exists()) {
      await recordingDir.delete(recursive: true);
    }
    final output = await RunningProcess(wrappedCommand, timeout,
            configuration: configuration)
        .run();
    if (output.hasCrashed) {
      if (await savedDir.exists()) {
        await savedDir.delete(recursive: true);
      }
      await recordingDir.rename(savedDir.path);
      await io.File("${savedDir.path}/command.txt")
          .writeAsString(wrappedCommand.reproductionCommand);
      await io.File("${savedDir.path}/stdout.txt").writeAsBytes(output.stdout);
      await io.File("${savedDir.path}/stderr.txt").writeAsBytes(output.stderr);
    } else if (await recordingDir.exists()) {
      await recordingDir.delete(recursive: true);
    }

    final compilationSkipped = false;
    switch (displayName) {
      case 'app_jit':
      case 'precompiler':
      case 'run_vm_unittest':
      case 'vm':
        return VMCommandOutput(this, output.exitCode, output.hasTimedOut,
            output.stdout, output.stderr, output.time, output.pid);
      case 'dart2wasm':
        return Dart2WasmCompilerCommandOutput(
            this,
            output.exitCode,
            output.hasTimedOut,
            output.stdout,
            output.stderr,
            output.time,
            compilationSkipped);
      case 'dart2js':
        return Dart2jsCompilerCommandOutput(
            this,
            output.exitCode,
            output.hasTimedOut,
            output.stdout,
            output.stderr,
            output.time,
            compilationSkipped);
      case 'ddc':
        return DevCompilerCommandOutput(
            this,
            output.exitCode,
            output.hasTimedOut,
            output.stdout,
            output.stderr,
            output.time,
            compilationSkipped,
            output.pid);
    }
    throw "Don't know how to interpret output for $displayName";
  }

  @override
  String get reproductionCommand =>
      "${wrappedCommand.reproductionCommand} (rr replay ${savedDir.path})";

  @override
  void _buildHashCode(HashCodeBuilder builder) {
    originalCommand._buildHashCode(builder);
    builder.add(42);
  }

  @override
  bool _equal(RRCommand other) =>
      hashCode == other.hashCode &&
      originalCommand._equal(other.originalCommand);
}

abstract class AdbCommand {
  String get buildPath;
  List<String> get extraLibraries;
}

class AdbPrecompilationCommand extends Command implements AdbCommand {
  @override
  final String buildPath; // Path to the output directory of the build.
  final String processTestFilename;
  final String abstractSocketTestFilename;
  final String precompiledTestDirectory;
  final List<String> arguments;
  final bool useElf;
  @override
  final List<String> extraLibraries;

  AdbPrecompilationCommand(
      this.buildPath,
      this.processTestFilename,
      this.abstractSocketTestFilename,
      this.precompiledTestDirectory,
      this.arguments,
      this.useElf,
      this.extraLibraries,
      {int index = 0})
      : super._("adb_precompilation", index: index);

  @override
  AdbPrecompilationCommand indexedCopy(int index) => AdbPrecompilationCommand(
      buildPath,
      processTestFilename,
      abstractSocketTestFilename,
      precompiledTestDirectory,
      arguments,
      useElf,
      extraLibraries,
      index: index);

  @override
  VMCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);

  @override
  _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(buildPath);
    builder.add(precompiledTestDirectory);
    builder.add(arguments);
    builder.add(useElf);
    extraLibraries.forEach(builder.add);
  }

  @override
  bool _equal(AdbPrecompilationCommand other) =>
      super._equal(other) &&
      buildPath == other.buildPath &&
      useElf == other.useElf &&
      arguments == other.arguments &&
      precompiledTestDirectory == other.precompiledTestDirectory &&
      deepJsonCompare(extraLibraries, other.extraLibraries);

  @override
  String toString() => 'Steps to push precompiled runner and precompiled code '
      'to an attached device. Uses (and requires) adb.';

  @override
  String get reproductionCommand => throw UnimplementedError();
}

class AdbDartkCommand extends Command implements AdbCommand {
  @override
  final String buildPath;
  final String processTestFilename;
  final String abstractSocketTestFilename;
  final String kernelFile;
  final List<String> arguments;
  @override
  final List<String> extraLibraries;

  AdbDartkCommand(
      this.buildPath,
      this.processTestFilename,
      this.abstractSocketTestFilename,
      this.kernelFile,
      this.arguments,
      this.extraLibraries,
      {int index = 0})
      : super._("adb_precompilation", index: index);

  @override
  AdbDartkCommand indexedCopy(int index) => AdbDartkCommand(
      buildPath,
      processTestFilename,
      abstractSocketTestFilename,
      kernelFile,
      arguments,
      extraLibraries,
      index: index);

  @override
  _buildHashCode(HashCodeBuilder builder) {
    super._buildHashCode(builder);
    builder.add(buildPath);
    builder.add(kernelFile);
    builder.add(arguments);
    builder.add(extraLibraries);
  }

  @override
  bool _equal(AdbDartkCommand other) =>
      super._equal(other) &&
      buildPath == other.buildPath &&
      arguments == other.arguments &&
      extraLibraries == other.extraLibraries &&
      kernelFile == other.kernelFile;

  @override
  VMCommandOutput createOutput(int exitCode, bool timedOut, List<int> stdout,
          List<int> stderr, Duration time, bool compilationSkipped,
          [int pid = 0]) =>
      VMCommandOutput(this, exitCode, timedOut, stdout, stderr, time, pid);

  @override
  String toString() => 'Steps to push Dart VM and Dill file '
      'to an attached device. Uses (and requires) adb.';

  @override
  String get reproductionCommand => throw UnimplementedError();
}

class JSCommandLineCommand extends ProcessCommand {
  JSCommandLineCommand(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environmentOverrides = const {}, int index = 0])
      : super(displayName, executable, arguments, environmentOverrides, null,
            index);

  @override
  JSCommandLineCommand indexedCopy(int index) => JSCommandLineCommand(
      displayName, executable, arguments, environmentOverrides, index);

  @override
  JSCommandLineOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int? pid = 0]) =>
      JSCommandLineOutput(this, exitCode, timedOut, stdout, stderr, time);
}

class Dart2WasmCommandLineCommand extends ProcessCommand {
  Dart2WasmCommandLineCommand(
      String displayName, String executable, List<String> arguments,
      [Map<String, String> environmentOverrides = const {}, int index = 0])
      : super(displayName, executable, arguments, environmentOverrides, null,
            index);

  @override
  Dart2WasmCommandLineCommand indexedCopy(int index) =>
      Dart2WasmCommandLineCommand(
          displayName, executable, arguments, environmentOverrides, index);

  @override
  Dart2WasmCommandLineOutput createOutput(
          int exitCode,
          bool timedOut,
          List<int> stdout,
          List<int> stderr,
          Duration time,
          bool compilationSkipped,
          [int? pid = 0]) =>
      Dart2WasmCommandLineOutput(
          this, exitCode, timedOut, stdout, stderr, time);
}

/// [ScriptCommand]s are executed by dart code.
abstract class ScriptCommand extends Command {
  ScriptCommand._(String displayName, {int index = 0})
      : super._(displayName, index: index);

  Future<ScriptCommandOutput> run();
}
