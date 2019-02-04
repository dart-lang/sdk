// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'command.dart';
import 'compiler_configuration.dart';
import 'configuration.dart';
import 'repository.dart';
// TODO(ahe): Remove this import, we can precompute all the values required
// from TestSuite once the refactoring is complete.
import 'test_suite.dart';

/// Describes the commands to run a given test case or its compiled output.
///
/// A single runtime configuration object exists per test suite, and is thus
/// shared between multiple test cases, it should not be mutated after
/// construction.
abstract class RuntimeConfiguration {
  TestConfiguration _configuration;

  static RuntimeConfiguration _makeInstance(TestConfiguration configuration) {
    switch (configuration.runtime) {
      case Runtime.chrome:
      case Runtime.chromeOnAndroid:
      case Runtime.firefox:
      case Runtime.ie11:
      case Runtime.ie10:
      case Runtime.ie9:
      case Runtime.safari:
        // TODO(ahe): Replace this with one or more browser runtimes.
        return new DummyRuntimeConfiguration();

      case Runtime.jsshell:
        return new JsshellRuntimeConfiguration();

      case Runtime.d8:
        return new D8RuntimeConfiguration();

      case Runtime.none:
        return new NoneRuntimeConfiguration();

      case Runtime.vm:
        return new StandaloneDartRuntimeConfiguration();

      case Runtime.dartPrecompiled:
        if (configuration.system == System.android) {
          return new DartPrecompiledAdbRuntimeConfiguration(
              useBlobs: configuration.useBlobs);
        } else {
          return new DartPrecompiledRuntimeConfiguration(
              useBlobs: configuration.useBlobs);
        }
        break;

      case Runtime.selfCheck:
        return new SelfCheckRuntimeConfiguration();
    }
    throw "unreachable";
  }

  factory RuntimeConfiguration(TestConfiguration configuration) {
    return _makeInstance(configuration).._configuration = configuration;
  }

  RuntimeConfiguration._subclass();

  int timeoutMultiplier(
      {Mode mode,
      bool isChecked: false,
      bool isReload: false,
      Architecture arch}) {
    return 1;
  }

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    // TODO(ahe): Avoid duplication of this method between d8 and jsshell.
    checkArtifact(artifact);
    return [
      Command.jsCommandLine(
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    checkArtifact(artifact);
    return [
      Command.jsCommandLine(
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

  int timeoutMultiplier(
      {Mode mode,
      bool isChecked: false,
      bool isReload: false,
      Architecture arch}) {
    var multiplier = 1;

    switch (arch) {
      case Architecture.simarm:
      case Architecture.arm:
      case Architecture.arm64:
      case Architecture.simarmv6:
      case Architecture.armv6:
      case Architecture.simarmv5te:
      case Architecture.armv5te:
      case Architecture.simarm64:
      case Architecture.simdbc:
      case Architecture.simdbc64:
        multiplier *= 4;
        break;
    }

    if (_configuration.compiler == Compiler.dartkb) {
      multiplier *= 4;
    }
    if (mode.isDebug) {
      multiplier *= 2;
    }
    if (isReload) {
      multiplier *= 2;
    }
    return multiplier;
  }
}

//// The standalone Dart VM binary, "dart" or "dart.exe".
class StandaloneDartRuntimeConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null &&
        type != 'application/dart' &&
        type != 'application/dart-snapshot' &&
        type != 'application/kernel-ir' &&
        type != 'application/kernel-ir-fully-linked') {
      throw "Dart VM cannot run files of type '$type'.";
    }
    if (isCrashExpected) {
      arguments.insert(0, '--suppress-core-dump');
    }
    String executable = suite.dartVmBinaryFileName;
    if (type == 'application/kernel-ir-fully-linked') {
      executable = suite.dartVmExecutableFileName;
    }
    return [Command.vm(executable, arguments, environmentOverrides)];
  }
}

class DartPrecompiledRuntimeConfiguration extends DartVmRuntimeConfiguration {
  final bool useBlobs;
  DartPrecompiledRuntimeConfiguration({bool useBlobs}) : useBlobs = useBlobs;

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    return [
      Command.vm(
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    String script = artifact.filename;
    String type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    String precompiledRunner = suite.dartPrecompiledBinaryFileName;
    String processTest = suite.processTestBinaryFileName;
    return [
      Command.adbPrecompiled(
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
    Uri pkg = Repository.uri.resolve('pkg');
    for (var entry in new Directory.fromUri(pkg).listSync(recursive: true)) {
      if (entry is File && entry.path.endsWith('_self_check.dart')) {
        selfCheckers.add(entry.path);
      }
    }
  }

  List<Command> computeRuntimeCommands(
      TestSuite suite,
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    String executable = suite.dartVmBinaryFileName;
    return selfCheckers
        .map((String tester) => Command.vmBatch(
            executable, tester, arguments, environmentOverrides,
            checked: suite.configuration.isChecked))
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      bool isCrashExpected) {
    throw "Unimplemented runtime '$runtimeType'";
  }
}
