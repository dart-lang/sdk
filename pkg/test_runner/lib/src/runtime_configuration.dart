// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'command.dart';
import 'compiler_configuration.dart';
import 'configuration.dart';
import 'fuchsia.dart';
import 'repository.dart';
import 'utils.dart';

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
        return DummyRuntimeConfiguration();

      case Runtime.jsshell:
        return JsshellRuntimeConfiguration();

      case Runtime.d8:
        return D8RuntimeConfiguration();

      case Runtime.none:
        return NoneRuntimeConfiguration();

      case Runtime.vm:
        if (configuration.system == System.android) {
          return DartkAdbRuntimeConfiguration();
        } else if (configuration.system == System.fuchsia) {
          return DartkFuchsiaEmulatorRuntimeConfiguration();
        }
        return StandaloneDartRuntimeConfiguration();

      case Runtime.dartPrecompiled:
        if (configuration.system == System.android) {
          return DartPrecompiledAdbRuntimeConfiguration(
            useElf: configuration.useElf,
          );
        } else {
          return DartPrecompiledRuntimeConfiguration(
            useElf: configuration.useElf,
          );
        }
        break;

      case Runtime.selfCheck:
        return SelfCheckRuntimeConfiguration();
    }
    throw "unreachable";
  }

  factory RuntimeConfiguration(TestConfiguration configuration) {
    return _makeInstance(configuration).._configuration = configuration;
  }

  RuntimeConfiguration._subclass();

  int timeoutMultiplier(
      {Mode mode,
      bool isChecked = false,
      bool isReload = false,
      Architecture arch}) {
    return 1;
  }

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    // TODO(ahe): Make this method abstract.
    throw "Unimplemented runtime '$runtimeType'";
  }

  /// The output directory for this suite's configuration.
  String get buildDir => _configuration.buildDirectory;

  List<String> dart2jsPreambles(Uri preambleDir) => [];

  /// Returns the path to the Dart VM executable.
  ///
  /// Controlled by user with the option "--dart".
  String get dartVmBinaryFileName =>
      _configuration.dartPath ?? dartVmExecutableFileName;

  String get dartVmExecutableFileName {
    return _configuration.useSdk
        ? '$buildDir/dart-sdk/bin/dart$executableExtension'
        : '$buildDir/dart$executableExtension';
  }

  String get dartPrecompiledBinaryFileName {
    // Controlled by user with the option "--dart_precompiled".
    var dartExecutable = _configuration.dartPrecompiledPath;

    if (dartExecutable == null || dartExecutable == '') {
      dartExecutable = '$buildDir/dart_precompiled_runtime$executableExtension';
    }

    TestUtils.ensureExists(dartExecutable, _configuration);
    return dartExecutable;
  }

  String get processTestBinaryFileName {
    var processTestExecutable = '$buildDir/process_test$executableExtension';
    TestUtils.ensureExists(processTestExecutable, _configuration);
    return processTestExecutable;
  }

  String get d8FileName {
    var d8Dir = Repository.dir.append('third_party/d8');
    var d8Path =
        d8Dir.append('${Platform.operatingSystem}/d8$executableExtension');
    var d8 = d8Path.toNativePath();
    TestUtils.ensureExists(d8, _configuration);
    return d8;
  }

  String get jsShellFileName {
    var executable = 'jsshell$executableExtension';
    var jsshellDir = Repository.uri.resolve("tools/testing/bin").path;
    var jsshell = '$jsshellDir/$executable';
    TestUtils.ensureExists(jsshell, _configuration);
    return jsshell;
  }
}

/// The 'none' runtime configuration.
class NoneRuntimeConfiguration extends RuntimeConfiguration {
  NoneRuntimeConfiguration() : super._subclass();

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    return <Command>[];
  }
}

class CommandLineJavaScriptRuntime extends RuntimeConfiguration {
  final String moniker;

  CommandLineJavaScriptRuntime(this.moniker) : super._subclass();

  void checkArtifact(CommandArtifact artifact) {
    var type = artifact.mimeType;
    if (type != 'application/javascript') {
      throw "Runtime '$moniker' cannot run files of type '$type'.";
    }
  }
}

/// Chrome/V8-based development shell (d8).
class D8RuntimeConfiguration extends CommandLineJavaScriptRuntime {
  D8RuntimeConfiguration() : super('d8');

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    // TODO(ahe): Avoid duplication of this method between d8 and jsshell.
    checkArtifact(artifact);
    return [
      JSCommandLineCommand(moniker, d8FileName, arguments, environmentOverrides)
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
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    checkArtifact(artifact);
    return [
      JSCommandLineCommand(
          moniker, jsShellFileName, arguments, environmentOverrides)
    ];
  }

  List<String> dart2jsPreambles(Uri preambleDir) {
    return ['-f', preambleDir.resolve('jsshell.js').toFilePath(), '-f'];
  }
}

class QemuConfig {
  static const all = <Architecture, QemuConfig>{
    Architecture.arm:
        QemuConfig('qemu-arm', ['-L', '/usr/arm-linux-gnueabihf/']),
    Architecture.arm64:
        QemuConfig('qemu-aarch64', ['-L', '/usr/aarch64-linux-gnu/']),
  };

  final String executable;
  final List<String> arguments;

  const QemuConfig(this.executable, this.arguments);
}

/// Common runtime configuration for runtimes based on the Dart VM.
class DartVmRuntimeConfiguration extends RuntimeConfiguration {
  DartVmRuntimeConfiguration() : super._subclass();

  int timeoutMultiplier(
      {Mode mode,
      bool isChecked = false,
      bool isReload = false,
      Architecture arch}) {
    var multiplier = 1;

    switch (arch) {
      case Architecture.simarm:
      case Architecture.arm:
      case Architecture.arm_x64:
      case Architecture.arm64:
      case Architecture.simarmv6:
      case Architecture.armv6:
      case Architecture.simarm64:
        multiplier *= 4;
        break;
    }

    if (mode.isDebug) {
      multiplier *= 2;
    }
    if (isReload) {
      multiplier *= 2;
    }
    if (_configuration.sanitizer != Sanitizer.none) {
      multiplier *= 2;
    }
    if (_configuration.rr) {
      multiplier *= 2;
    }
    return multiplier;
  }
}

//// The standalone Dart VM binary, "dart" or "dart.exe".
class StandaloneDartRuntimeConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact.filename;
    var type = artifact.mimeType;
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
    var executable = dartVmBinaryFileName;
    if (type == 'application/kernel-ir-fully-linked') {
      executable = dartVmExecutableFileName;
    }
    if (_configuration.useQemu) {
      final config = QemuConfig.all[_configuration.architecture];
      arguments.insert(0, executable);
      arguments.insertAll(0, config.arguments);
      executable = config.executable;
    }
    var command = VMCommand(executable, arguments, environmentOverrides);
    if (_configuration.rr && !isCrashExpected) {
      return [RRCommand(command)];
    }
    return [command];
  }
}

class DartPrecompiledRuntimeConfiguration extends DartVmRuntimeConfiguration {
  final bool useElf;
  DartPrecompiledRuntimeConfiguration({this.useElf});

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact.filename;
    var type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    var executable = dartPrecompiledBinaryFileName;

    if (_configuration.useQemu) {
      final config = QemuConfig.all[_configuration.architecture];
      arguments.insert(0, executable);
      arguments.insertAll(0, config.arguments);
      executable = config.executable;
    }

    var command = VMCommand(executable, arguments, environmentOverrides);
    if (_configuration.rr && !isCrashExpected) {
      return [RRCommand(command)];
    }
    return [command];
  }
}

class DartkAdbRuntimeConfiguration extends DartVmRuntimeConfiguration {
  static const String deviceDir = '/data/local/tmp/testing';
  static const String deviceTestDir = '/data/local/tmp/testing/test';

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact.filename;
    var type = artifact.mimeType;
    if (script != null && type != 'application/kernel-ir-fully-linked') {
      throw "dart cannot run files of type '$type'.";
    }

    var buildPath = buildDir;
    var processTest = processTestBinaryFileName;
    return [
      AdbDartkCommand(buildPath, processTest, script, arguments, extraLibs)
    ];
  }
}

class DartPrecompiledAdbRuntimeConfiguration
    extends DartVmRuntimeConfiguration {
  static const deviceDir = '/data/local/tmp/precompilation-testing';
  static const deviceTestDir = '/data/local/tmp/precompilation-testing/test';

  final bool useElf;
  DartPrecompiledAdbRuntimeConfiguration({this.useElf});

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact.filename;
    var type = artifact.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dart_precompiled cannot run files of type '$type'.";
    }

    var processTest = processTestBinaryFileName;
    return [
      AdbPrecompilationCommand(
          buildDir, processTest, script, arguments, useElf, extraLibs)
    ];
  }
}

class DartkFuchsiaEmulatorRuntimeConfiguration
    extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact.filename;
    var type = artifact.mimeType;
    if (script != null &&
        type != 'application/dart' &&
        type != 'application/dart-snapshot' &&
        type != 'application/kernel-ir' &&
        type != 'application/kernel-ir-fully-linked') {
      throw "Dart VM cannot run files of type '$type'.";
    }
    var runtimeArgs =
        FuchsiaEmulator.getTestArgs(_configuration.mode.name, arguments);
    if (isCrashExpected) {
      runtimeArgs.insert(0, '--suppress-core-dump');
    }
    runtimeArgs.insert(runtimeArgs.length - 1, '--disable-dart-dev');
    return [
      VMCommand(FuchsiaEmulator.fsshTool, runtimeArgs, environmentOverrides)
    ];
  }
}

class SelfCheckRuntimeConfiguration extends DartVmRuntimeConfiguration {
  final List<String> selfCheckers = <String>[];

  SelfCheckRuntimeConfiguration() {
    searchForSelfCheckers();
  }

  void searchForSelfCheckers() {
    var pkg = Repository.uri.resolve('pkg');
    for (var entry in Directory.fromUri(pkg).listSync(recursive: true)) {
      if (entry is File && entry.path.endsWith('_self_check.dart')) {
        selfCheckers.add(entry.path);
      }
    }
  }

  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var executable = dartVmBinaryFileName;
    return selfCheckers
        .map((String tester) => VMBatchCommand(
            executable, tester, arguments, environmentOverrides,
            checked: _configuration.isChecked))
        .toList();
  }
}

/// Temporary runtime configuration for browser runtimes that haven't been
/// migrated yet.
// TODO(ahe): Remove this class.
class DummyRuntimeConfiguration extends DartVmRuntimeConfiguration {
  List<Command> computeRuntimeCommands(
      CommandArtifact artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    throw "Unimplemented runtime '$runtimeType'";
  }
}
