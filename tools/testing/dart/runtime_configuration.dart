// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library runtime_configuration;

import 'dart:io' show Directory, File;

import 'compiler_configuration.dart' show CommandArtifact;

// TODO(ahe): Remove this import, we can precompute all the values required
// from TestSuite once the refactoring is complete.
import 'test_suite.dart' show TestSuite, TestUtils;

import 'test_runner.dart' show Command, CommandBuilder;

/// Describes the commands to run a given test case or its compiled output.
///
/// A single runtime configuration object exists per test suite, and is thus
/// shared between multiple test cases, it should not be mutated after
/// construction.
//
// TODO(ahe): I expect this class will become abstract very soon.
class RuntimeConfiguration {
  // TODO(ahe): Remove this constructor and move the switch to
  // test_options.dart.  We probably want to store an instance of
  // [RuntimeConfiguration] in [configuration] there.
  factory RuntimeConfiguration(Map<String, dynamic> configuration) {
    String runtime = configuration['runtime'];
    bool useBlobs = configuration['use_blobs'];

    switch (runtime) {
      case 'ContentShellOnAndroid':
      case 'DartiumOnAndroid':
      case 'chrome':
      case 'chromeOnAndroid':
      case 'dartium':
      case 'ff':
      case 'firefox':
      case 'ie11':
      case 'ie10':
      case 'ie9':
      case 'opera':
      case 'safari':
      case 'safarimobilesim':
        // TODO(ahe): Replace this with one or more browser runtimes.
        return new DummyRuntimeConfiguration();

      case 'jsshell':
        return new JsshellRuntimeConfiguration();

      case 'd8':
        return new D8RuntimeConfiguration();

      case 'none':
        return new NoneRuntimeConfiguration();

      case 'vm':
        return new StandaloneDartRuntimeConfiguration();

      case 'flutter':
        return new StandaloneFlutterEngineConfiguration();

      case 'dart_precompiled':
        if (configuration['system'] == 'android') {
          return new DartPrecompiledAdbRuntimeConfiguration(useBlobs: useBlobs);
        }
        return new DartPrecompiledRuntimeConfiguration(useBlobs: useBlobs);

      case 'drt':
        return new DrtRuntimeConfiguration();

      case 'self_check':
        return new SelfCheckRuntimeConfiguration();

      default:
        throw "Unknown runtime '$runtime'";
    }
  }

  RuntimeConfiguration._subclass();

  int computeTimeoutMultiplier(
      {String mode, bool isChecked: false, bool isReload: false, String arch}) {
    return 1;
  }

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    // TODO(ahe): Make this method abstract.
    throw "Unimplemented runtime '$runtimeType'";
  }

  List<String> dart2jsPreambles(Uri preambleDir) => [];

  bool get shouldSkipNegativeTests => false;
}

/// The 'none' runtime configuration.
class NoneRuntimeConfiguration extends RuntimeConfiguration {
  NoneRuntimeConfiguration() : super._subclass();

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    return <Command>[];
  }
}

class CommandLineJavaScriptRuntime extends RuntimeConfiguration {
  final String moniker;

  CommandLineJavaScriptRuntime(this.moniker) : super._subclass();

  void checkArtifact(CommandArtifact artifact) {
    String type = artifact.mimeType;
    if (type != 'application/javascript') {
      throw "Runtime '$moniker' cannot run files of type '$type'.";
    }
  }
}

/// Chrome/V8-based development shell (d8).
class D8RuntimeConfiguration extends CommandLineJavaScriptRuntime {
  D8RuntimeConfiguration() : super('d8');

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    // TODO(ahe): Avoid duplication of this method between d8 and jsshell.
    checkArtifact(artifact);
    return <Command>[
      commandBuilder.getJSCommandlineCommand(
          moniker, suite.d8FileName, arguments, environmentOverrides)
    ];
  }

  List<String> dart2jsPreambles(Uri preambleDir) {
    return [preambleDir.resolve('d8.js').toFilePath()];
  }
}

/// Firefox/SpiderMonkey-based development shell (jsshell).
class JsshellRuntimeConfiguration extends CommandLineJavaScriptRuntime {
  JsshellRuntimeConfiguration() : super('jsshell');

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    checkArtifact(artifact);
    return <Command>[
      commandBuilder.getJSCommandlineCommand(
          moniker, suite.jsShellFileName, arguments, environmentOverrides)
    ];
  }

  List<String> dart2jsPreambles(Uri preambleDir) {
    return ['-f', preambleDir.resolve('jsshell.js').toFilePath(), '-f'];
  }
}

/// Common runtime configuration for runtimes based on the Dart VM.
class DartVmRuntimeConfiguration extends RuntimeConfiguration {
  DartVmRuntimeConfiguration() : super._subclass();

  int computeTimeoutMultiplier(
      {String mode, bool isChecked: false, bool isReload: false, String arch}) {
    int multiplier = 1;
    switch (arch) {
      case 'simarm':
      case 'arm':
      case 'simarmv6':
      case 'armv6':
      case ' simarmv5te':
      case 'armv5te':
      case 'simmips':
      case 'mips':
      case 'simarm64':
      case 'simdbc':
      case 'simdbc64':
        multiplier *= 4;
        break;
    }
    if (mode == 'debug') {
      multiplier *= 2;
      if (isReload) {
        multiplier *= 2;
      }
    }
    return multiplier;
  }
}

/// Runtime configuration for Content Shell.  We previously used a similar
/// program named Dump Render Tree, hence the name.
class DrtRuntimeConfiguration extends DartVmRuntimeConfiguration {
  int computeTimeoutMultiplier(
      {String mode, bool isChecked: false, bool isReload: false, String arch}) {
    return 4 // Allow additional time for browser testing to run.
        // TODO(ahe): We might need to distinguish between DRT for running
        // JavaScript and Dart code.  I'm not convinced the inherited timeout
        // multiplier is relevant for JavaScript.
        *
        super.computeTimeoutMultiplier(
            mode: mode, isChecked: isChecked, isReload: isReload);
  }
}

/// The standalone Dart VM binary, "dart" or "dart.exe".
class StandaloneDartRuntimeConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null &&
        type != 'application/dart' &&
        type != 'application/dart-snapshot') {
      throw "Dart VM cannot run files of type '$type'.";
    }
    String executable = suite.dartVmBinaryFileName;
    return <Command>[
      commandBuilder.getVmCommand(executable, arguments, environmentOverrides)
    ];
  }
}

/// The flutter engine binary, "sky_shell".
class StandaloneFlutterEngineConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null &&
        type != 'application/dart' &&
        type != 'application/dart-snapshot') {
      throw "Flutter Engine cannot run files of type '$type'.";
    }
    String executable = suite.flutterEngineBinaryFileName;
    var args = <String>['--non-interactive']..addAll(arguments);
    return <Command>[
      commandBuilder.getVmCommand(executable, args, environmentOverrides)
    ];
  }
}

class DartPrecompiledRuntimeConfiguration extends DartVmRuntimeConfiguration {
  final bool useBlobs;
  DartPrecompiledRuntimeConfiguration({bool useBlobs}) : useBlobs = useBlobs;

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    return <Command>[
      commandBuilder.getVmCommand(
          suite.dartPrecompiledBinaryFileName, arguments, environmentOverrides)
    ];
  }
}

class DartPrecompiledAdbRuntimeConfiguration
    extends DartVmRuntimeConfiguration {
  static const String DeviceDir = '/data/local/tmp/precompilation-testing';
  static const String DeviceTestDir =
      '/data/local/tmp/precompilation-testing/test';

  final bool useBlobs;
  DartPrecompiledAdbRuntimeConfiguration({bool useBlobs}) : useBlobs = useBlobs;

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    String precompiledRunner = suite.dartPrecompiledBinaryFileName;
    String processTest = suite.processTestBinaryFileName;
    return <Command>[
      commandBuilder.getAdbPrecompiledCommand(
          precompiledRunner, processTest, script, arguments, useBlobs)
    ];
  }
}

class SelfCheckRuntimeConfiguration extends DartVmRuntimeConfiguration {
  final List<String> selfCheckers = <String>[];

  SelfCheckRuntimeConfiguration() {
    searchForSelfCheckers();
  }

  void searchForSelfCheckers() {
    Uri pkg = TestUtils.dartDirUri.resolve('pkg');
    for (var entry in new Directory.fromUri(pkg).listSync(recursive: true)) {
      if (entry is File && entry.path.endsWith('_self_check.dart')) {
        selfCheckers.add(entry.path);
      }
    }
  }

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    String executable = suite.dartVmBinaryFileName;
    return selfCheckers
        .map((String tester) => commandBuilder.getVmBatchCommand(
            executable, tester, arguments, environmentOverrides,
            checked: suite.configuration['checked']))
        .toList();
  }

  @override
  bool get shouldSkipNegativeTests => true;
}

/// Temporary runtime configuration for browser runtimes that haven't been
/// migrated yet.
// TODO(ahe): Remove this class.
class DummyRuntimeConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandBuilder commandBuilder,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides) {
    throw "Unimplemented runtime '$runtimeType'";
  }
}
