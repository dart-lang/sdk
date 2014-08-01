// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_configuration;

import 'dart:io' show
    Platform;

import 'runtime_configuration.dart' show
    RuntimeConfiguration;

import 'test_runner.dart' show
    Command,
    CommandBuilder,
    CompilationCommand;

import 'test_suite.dart' show
    TestInformation,
    TestUtils;

/// Grouping of a command with its expected result.
class CommandArtifact {
  final List<Command> commands;

  /// Expected result of running [command].
  final String filename;

  /// MIME type of [filename].
  final String mimeType;

  CommandArtifact(this.commands, this.filename, this.mimeType);
}

Uri nativeDirectoryToUri(String nativePath) {
  Uri uri = new Uri.file(nativePath);
  String path = uri.path;
  return (path == '' || path.endsWith('/'))
      ? uri
      : Uri.parse('$uri/');
}

abstract class CompilerConfiguration {
  final bool isDebug;
  final bool isChecked;
  final bool isHostChecked;
  final bool useSdk;

  // TODO(ahe): Remove this constructor and move the switch to
  // test_options.dart.  We probably want to store an instance of
  // [CompilerConfiguration] in [configuration] there.
  factory CompilerConfiguration(Map configuration) {
    String compiler = configuration['compiler'];

    // TODO(ahe): Move these booleans into a struction configuration object
    // which can eventually completely replace the Map-based configuration
    // object.
    bool isDebug = configuration['mode'] == 'debug';
    bool isChecked = configuration['checked'];
    bool isHostChecked = configuration['host_checked'];
    bool useSdk = configuration['use_sdk'];
    bool isCsp = configuration['csp'];

    switch (compiler) {
      case 'dartanalyzer':
        return new AnalyzerCompilerConfiguration(
            'dartanalyzer', isDebug: isDebug, isChecked: isChecked,
            isHostChecked: isHostChecked, useSdk: useSdk);
      case 'dart2analyzer':
        return new DartBasedAnalyzerCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked,
            isHostChecked: isHostChecked, useSdk: useSdk);
      case 'dart2js':
        return new Dart2jsCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked,
            isHostChecked: isHostChecked, useSdk: useSdk, isCsp: isCsp,
            extraDart2jsOptions:
                TestUtils.getExtraOptions(configuration, 'dart2js_options'));
      case 'dart2dart':
        return new Dart2dartCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked,
            isHostChecked: isHostChecked, useSdk: useSdk);
      case 'none':
        return new NoneCompilerConfiguration(
            isDebug: isDebug, isChecked: isChecked,
            isHostChecked: isHostChecked, useSdk: useSdk);
      default:
        throw "Unknown compiler '$compiler'";
    }
  }

  CompilerConfiguration._subclass({
      this.isDebug: false,
      this.isChecked: false,
      this.isHostChecked: false,
      this.useSdk: false});

  /// Return a multiplier used to give tests longer time to run.
  // TODO(ahe): Convert to getter!
  int computeTimeoutMultiplier() {
    return 1;
  }

  // TODO(ahe): It shouldn't be necessary to pass [buildDir] to any of these
  // functions. It is fixed for a given configuration.
  String computeCompilerPath(String buildDir) {
    throw "Unknown compiler for: $runtimeType";
  }

  bool get hasCompiler => true;

  String get executableScriptSuffix => Platform.isWindows ? '.bat' : '';

  // TODO(ahe): Remove this.
  bool get isCsp => false;

  List<Uri> bootstrapDependencies(String buildDir) => const <Uri>[];

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact([], null, null);
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[artifact.filename];
  }
}

/// The "none" compiler.
class NoneCompilerConfiguration extends CompilerConfiguration {
  NoneCompilerConfiguration({
      bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk})
      : super._subclass(
          isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  bool get hasCompiler => false;

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[]
        ..addAll(vmOptions)
        ..addAll(sharedOptions)
        ..addAll(originalArguments);
  }
}

/// Common configuration for dart2js-based tools, such as, dart2js and
/// dart2dart.
class Dart2xCompilerConfiguration extends CompilerConfiguration {
  final String moniker;

  Dart2xCompilerConfiguration(
      this.moniker,
      {bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk})
      : super._subclass(
          isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  String computeCompilerPath(String buildDir) {
    var prefix = 'sdk/bin';
    String suffix = executableScriptSuffix;
    if (isHostChecked) {
      // The script dart2js_developer is not included in the
      // shipped SDK, that is the script is not installed in
      // "$buildDir/dart-sdk/bin/"
      return '$prefix/dart2js_developer$suffix';
    } else {
      if (useSdk) {
        prefix = '$buildDir/dart-sdk/bin';
      }
      return '$prefix/dart2js$suffix';
    }
  }

  CompilationCommand computeCompilationCommand(
      String outputFileName,
      String buildDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    arguments = new List.from(arguments);
    arguments.add('--out=$outputFileName');

    return commandBuilder.getCompilationCommand(
        moniker, outputFileName, !useSdk,
        bootstrapDependencies(buildDir),
        computeCompilerPath(buildDir),
        arguments, environmentOverrides);
  }

  List<Uri> bootstrapDependencies(String buildDir) {
    if (!useSdk) return const <Uri>[];

    Uri absoluteBuildDir = Uri.base.resolveUri(nativeDirectoryToUri(buildDir));
    return [absoluteBuildDir.resolve(
          'dart-sdk/bin/snapshots/dart2js.dart.snapshot')];
  }
}

/// Configuration for dart2js compiler.
class Dart2jsCompilerConfiguration extends Dart2xCompilerConfiguration {
  final bool isCsp;
  final List<String> extraDart2jsOptions;

  Dart2jsCompilerConfiguration({
      bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk,
      bool this.isCsp,
      this.extraDart2jsOptions})
      : super(
          'dart2js',
          isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  int computeTimeoutMultiplier() {
    int multiplier = 1;
    if (isDebug) multiplier *= 4;
    if (isChecked) multiplier *= 2;
    if (isHostChecked) multiplier *= 16;
    return multiplier;
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact(
        <Command>[
            this.computeCompilationCommand(
                '$tempDir/out.js',
                buildDir,
                CommandBuilder.instance,
                []..addAll(arguments)..addAll(extraDart2jsOptions),
                environmentOverrides)],
        '$tempDir/out.js',
        'application/javascript');
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    Uri sdk = useSdk ?
        nativeDirectoryToUri(buildDir).resolve('dart-sdk/') :
        nativeDirectoryToUri(TestUtils.dartDir.toNativePath()).resolve('sdk/');
    Uri preambleDir = sdk.resolve('lib/_internal/lib/preambles/');
    return runtimeConfiguration.dart2jsPreambles(preambleDir)
        ..add(artifact.filename);
  }
}

/// Configuration for dart2dart compiler.
class Dart2dartCompilerConfiguration extends Dart2xCompilerConfiguration {
  Dart2dartCompilerConfiguration({
      bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk})
      : super(
          'dart2dart',
          isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    String outputFileName = '$tempDir/out.dart';
    arguments = new List.from(arguments)..add('--output-type=dart');
    return new CommandArtifact(
        <Command>[
            this.computeCompilationCommand(
                outputFileName,
                buildDir,
                CommandBuilder.instance,
                arguments,
                environmentOverrides)],
        outputFileName,
        'application/dart');
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    // TODO(antonm): support checked.
    return <String>[]
        ..addAll(vmOptions)
        ..add('--ignore-unrecognized-flags')
        ..add(artifact.filename);
  }
}

/// Common configuration for analyzer-based tools, such as, dartanalyzer.
class AnalyzerCompilerConfiguration extends CompilerConfiguration {
  final String moniker;

  AnalyzerCompilerConfiguration(
      this.moniker,
      {bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk})
      : super._subclass(
          isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  int computeTimeoutMultiplier() {
    return 4;
  }

  String computeCompilerPath(String buildDir) {
    String suffix = executableScriptSuffix;
    return 'sdk/bin/dartanalyzer_developer$suffix';
  }

  CommandArtifact computeCompilationArtifact(
      String buildDir,
      String tempDir,
      CommandBuilder commandBuilder,
      List arguments,
      Map<String, String> environmentOverrides) {
    return new CommandArtifact(
        <Command>[
            commandBuilder.getAnalysisCommand(
                moniker, computeCompilerPath(buildDir), arguments,
                environmentOverrides,
                flavor: moniker)],
        null, null); // Since this is not a real compilation, no artifacts are
                     // produced.
  }

  List<String> computeRuntimeArguments(
      RuntimeConfiguration runtimeConfiguration,
      String buildDir,
      TestInformation info,
      List<String> vmOptions,
      List<String> sharedOptions,
      List<String> originalArguments,
      CommandArtifact artifact) {
    return <String>[];
  }
}

class DartBasedAnalyzerCompilerConfiguration
    extends AnalyzerCompilerConfiguration {
  DartBasedAnalyzerCompilerConfiguration({
      bool isDebug,
      bool isChecked,
      bool isHostChecked,
      bool useSdk})
      : super(
          'dart2analyzer', isDebug: isDebug, isChecked: isChecked,
          isHostChecked: isHostChecked, useSdk: useSdk);

  String computeCompilerPath(String buildDir) => 'editor/tools/analyzer';
}
