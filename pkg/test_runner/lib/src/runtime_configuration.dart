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
  late TestConfiguration _configuration;

  static RuntimeConfiguration _makeInstance(TestConfiguration configuration) {
    switch (configuration.runtime) {
      case Runtime.chrome:
      case Runtime.chromeOnAndroid:
      case Runtime.firefox:
      case Runtime.safari:
        // TODO(ahe): Replace this with one or more browser runtimes.
        return DummyRuntimeConfiguration();

      case Runtime.jsc:
        return JSCRuntimeConfiguration(configuration.compiler);

      case Runtime.jsshell:
        return JsshellRuntimeConfiguration(configuration.compiler);

      case Runtime.d8:
        return D8RuntimeConfiguration(configuration.compiler);

      case Runtime.none:
        return NoneRuntimeConfiguration();

      case Runtime.vm:
        if (configuration.system == System.android) {
          return DartkAdbRuntimeConfiguration();
        } else if (configuration.system == System.fuchsia) {
          return DartkFuchsiaEmulatorRuntimeConfiguration(false);
        }
        return StandaloneDartRuntimeConfiguration();

      case Runtime.dartPrecompiled:
        if (configuration.system == System.android) {
          return DartPrecompiledAdbRuntimeConfiguration(
            configuration.genSnapshotFormat == GenSnapshotFormat.elf,
          );
        } else if (configuration.system == System.fuchsia) {
          return DartkFuchsiaEmulatorRuntimeConfiguration(true);
        }
        return DartPrecompiledRuntimeConfiguration(
          configuration.genSnapshotFormat == GenSnapshotFormat.elf,
        );

      default:
        throw "unreachable";
    }
  }

  factory RuntimeConfiguration(TestConfiguration configuration) {
    return _makeInstance(configuration).._configuration = configuration;
  }

  RuntimeConfiguration._subclass();

  int timeoutMultiplier(
      {required Mode mode,
      bool isChecked = false,
      bool isReload = false,
      required Architecture arch,
      required System system}) {
    return 1;
  }

  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
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
    // Controlled by user with the option "--dart-precompiled".
    var dartExecutable = _configuration.dartPrecompiledPath;

    if (dartExecutable == null || dartExecutable == '') {
      var dir = buildDir;

      // gen_snapshot can run with different word sizes, but the simulators
      // cannot.
      dir = dir.replaceAll("SIMARM_X64", "SIMARM");

      dartExecutable = '$dir/dartaotruntime$executableExtension';
    }

    TestUtils.ensureExists(dartExecutable, _configuration);
    return dartExecutable;
  }

  String get processTestBinaryFileName {
    var processTestExecutable = '$buildDir/process_test$executableExtension';
    TestUtils.ensureExists(processTestExecutable, _configuration);
    return processTestExecutable;
  }

  String get abstractSocketTestBinaryFileName {
    var abstractSocketTestExecutable =
        '$buildDir/abstract_socket_test$executableExtension';
    TestUtils.ensureExists(abstractSocketTestExecutable, _configuration);
    return abstractSocketTestExecutable;
  }

  String get d8FileName {
    var d8Dir = Repository.dir.append('third_party/d8');
    var d8Path = d8Dir.append(
        '${Platform.operatingSystem}/${Architecture.host}/d8$executableExtension');
    var d8 = d8Path.toNativePath();
    TestUtils.ensureExists(d8, _configuration);
    return d8;
  }

  String get jscFileName {
    final jscPath =
        Repository.dir.append('third_party/jsc/jsc$executableExtension');
    final jsc = jscPath.toNativePath();
    TestUtils.ensureExists(jsc, _configuration);
    return jsc;
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

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
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
    if (type != 'application/javascript' && type != 'application/wasm') {
      throw "Runtime '$moniker' cannot run files of type '$type'.";
    }
  }
}

/// Chrome/V8-based development shell (d8).
class D8RuntimeConfiguration extends CommandLineJavaScriptRuntime {
  final Compiler compiler;

  D8RuntimeConfiguration(this.compiler) : super('d8');

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    // TODO(ahe): Avoid duplication of this method between d8 and jsshell.
    checkArtifact(artifact!);
    if (compiler == Compiler.dart2wasm) {
      return [
        Dart2WasmCommandLineCommand(
            moniker,
            'pkg/dart2wasm/tool/run_benchmark',
            // Default stack trace limit in V8 is 10, which hides some of the
            // stack frames we check in stack trace tests.
            ['--d8', '--shell-option=--stack-trace-limit=20', ...arguments],
            environmentOverrides)
      ];
    } else {
      return [
        JSCommandLineCommand(
            moniker, d8FileName, arguments, environmentOverrides)
      ];
    }
  }

  @override
  List<String> dart2jsPreambles(Uri preambleDir) {
    return [
      preambleDir.resolve('seal_native_object.js').toFilePath(),
      preambleDir.resolve('d8.js').toFilePath()
    ];
  }
}

/// Safari/WebKit/JavaScriptCore-based development shell (jsc).
class JSCRuntimeConfiguration extends CommandLineJavaScriptRuntime {
  final Compiler compiler;

  JSCRuntimeConfiguration(this.compiler) : super('jsc');

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    checkArtifact(artifact!);
    if (compiler != Compiler.dart2wasm) {
      throw 'No test runner setup for jsc + dart2js yet';
    }
    return [
      Dart2WasmCommandLineCommand(moniker, 'pkg/dart2wasm/tool/run_benchmark',
          ['--jsc', ...arguments], environmentOverrides)
    ];
  }
}

/// Firefox/SpiderMonkey-based development shell (jsshell).
class JsshellRuntimeConfiguration extends CommandLineJavaScriptRuntime {
  final Compiler compiler;

  JsshellRuntimeConfiguration(this.compiler) : super('jsshell');

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    checkArtifact(artifact!);
    if (compiler == Compiler.dart2wasm) {
      return [
        Dart2WasmCommandLineCommand(moniker, 'pkg/dart2wasm/tool/run_benchmark',
            ['--jsshell', ...arguments], environmentOverrides)
      ];
    } else {
      return [
        JSCommandLineCommand(
            moniker, jsShellFileName, arguments, environmentOverrides)
      ];
    }
  }

  @override
  List<String> dart2jsPreambles(Uri preambleDir) {
    return [
      '-f',
      preambleDir.resolve('seal_native_object.js').toFilePath(),
      '-f',
      preambleDir.resolve('jsshell.js').toFilePath(),
      '-f'
    ];
  }
}

enum QemuConfig {
  ia32._('qemu-i386', '/usr/lib/i386-linux-gnu/'),
  x64._('qemu-x86_64', '/usr/lib/x86_64-linux-gnu/'),
  arm._('qemu-arm', '/usr/arm-linux-gnueabihf/'),
  arm64._('qemu-aarch64', '/usr/aarch64-linux-gnu/'),
  riscv32._('qemu-riscv32', '/usr/riscv32-linux-gnu/'),
  riscv64._('qemu-riscv64', '/usr/riscv64-linux-gnu/');

  static const all = <Architecture, QemuConfig>{
    Architecture.ia32: QemuConfig.ia32,
    Architecture.x64: QemuConfig.x64,
    Architecture.x64c: QemuConfig.x64,
    Architecture.arm: QemuConfig.arm,
    Architecture.arm64: QemuConfig.arm64,
    Architecture.simarm64_arm64: QemuConfig.arm64,
    Architecture.arm64c: QemuConfig.arm64,
    Architecture.riscv32: QemuConfig.riscv32,
    Architecture.riscv64: QemuConfig.riscv64,
  };

  final String executable;
  final String elfInterpreterPrefix;

  const QemuConfig._(this.executable, this.elfInterpreterPrefix);

  @override
  String toString() => executable;
}

/// Common runtime configuration for runtimes based on the Dart VM.
class DartVmRuntimeConfiguration extends RuntimeConfiguration {
  DartVmRuntimeConfiguration() : super._subclass();

  @override
  int timeoutMultiplier(
      {required Mode mode,
      bool isChecked = false,
      bool isReload = false,
      required Architecture arch,
      required System system}) {
    var multiplier = 1;

    switch (arch) {
      case Architecture.simarm:
      case Architecture.simarm64:
      case Architecture.simarm64c:
      case Architecture.simriscv32:
      case Architecture.simriscv64:
        multiplier *= 4;
        break;
      default:
        break;
    }

    if (_configuration.useQemu) {
      multiplier *= 2;
    }
    if (system == System.fuchsia && arch == Architecture.arm64) {
      multiplier *= 4; // Full system QEMU.
    }

    // Configurations where `kernel-service` doesn't run from AppJIT snapshot
    // will make tests run very slow due to the `kernel-service` code slowly
    // warming up the JIT. This is especially noticable in `debug` mode.
    if (arch == Architecture.ia32) {
      multiplier *= 2;
    }
    if ((arch == Architecture.x64 && system == System.mac) ||
        (arch == Architecture.arm64 && system == System.win)) {
      multiplier *= 2; // Slower machines.
    }

    if (mode.isDebug) {
      multiplier *= 2;
    }
    if (isReload) {
      multiplier *= 2;
    }
    switch (_configuration.sanitizer) {
      case Sanitizer.none:
      case Sanitizer.lsan:
      case Sanitizer.ubsan:
        multiplier *= 1;
        break;
      case Sanitizer.hwasan:
      case Sanitizer.asan:
      case Sanitizer.msan:
        multiplier *= 2;
        break;
      case Sanitizer.tsan:
        multiplier *= 6;
        break;
    }
    if (_configuration.rr) {
      multiplier *= 2;
    }
    return multiplier;
  }
}

//// The standalone Dart VM binary, "dart" or "dart.exe".
class StandaloneDartRuntimeConfiguration extends DartVmRuntimeConfiguration {
  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact?.filename;
    var type = artifact?.mimeType;
    if (script != null &&
        type != 'application/dart' &&
        type != 'application/dart-snapshot' &&
        type != 'application/kernel-ir' &&
        type != 'application/kernel-ir-fully-linked' &&
        type != 'application/dart-bytecode') {
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
      final config = QemuConfig.all[_configuration.architecture]!;
      arguments.insert(0, executable);
      executable = config.executable;
      if (environmentOverrides['QEMU_LD_PREFIX'] == null) {
        environmentOverrides['QEMU_LD_PREFIX'] = config.elfInterpreterPrefix;
      }
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
  DartPrecompiledRuntimeConfiguration(this.useElf);

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact?.filename;
    var type = artifact?.mimeType;
    if (script != null &&
        type != 'application/dart-precompiled' &&
        type != 'application/dart-bytecode') {
      throw "dartaotruntime cannot run files of type '$type'.";
    }

    var executable = dartPrecompiledBinaryFileName;

    if (_configuration.useQemu) {
      final config = QemuConfig.all[_configuration.architecture]!;
      arguments.insert(0, executable);
      executable = config.executable;
      if (environmentOverrides['QEMU_LD_PREFIX'] == null) {
        environmentOverrides['QEMU_LD_PREFIX'] = config.elfInterpreterPrefix;
      }
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

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact?.filename;
    var type = artifact?.mimeType;
    if (script != null && type != 'application/kernel-ir-fully-linked') {
      throw "dart cannot run files of type '$type'.";
    }

    var buildPath = buildDir;
    var processTest = processTestBinaryFileName;
    var abstractSocketTest = abstractSocketTestBinaryFileName;
    return [
      AdbDartkCommand(buildPath, processTest, abstractSocketTest, script!,
          arguments, extraLibs)
    ];
  }
}

class DartPrecompiledAdbRuntimeConfiguration
    extends DartVmRuntimeConfiguration {
  static const deviceDir = '/data/local/tmp/precompilation-testing';
  static const deviceTestDir = '/data/local/tmp/precompilation-testing/test';

  final bool useElf;
  DartPrecompiledAdbRuntimeConfiguration(this.useElf);

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact?.filename;
    var type = artifact?.mimeType;
    if (script != null && type != 'application/dart-precompiled') {
      throw "dartaotruntime cannot run files of type '$type'.";
    }

    var processTest = processTestBinaryFileName;
    var abstractSocketTest = abstractSocketTestBinaryFileName;
    return [
      AdbPrecompilationCommand(buildDir, processTest, abstractSocketTest,
          script!, arguments, useElf, extraLibs)
    ];
  }
}

class DartkFuchsiaEmulatorRuntimeConfiguration
    extends DartVmRuntimeConfiguration {
  final bool aot;
  DartkFuchsiaEmulatorRuntimeConfiguration(this.aot);

  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    var script = artifact?.filename;
    var type = artifact?.mimeType;
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

    // Rewrite paths on the host to paths in the Fuchsia package.
    arguments = arguments
        .map((argument) =>
            argument.replaceAll(Directory.current.path, "pkg/data"))
        .toList();

    var component = "dartvm_test_component.cm";
    if (aot) {
      component = "dartaotruntime_test_component.cm";
      arguments[arguments.length - 1] =
          arguments[arguments.length - 1].replaceAll(".dart", ".dart.elf");
    }

    arguments.insert(arguments.length - 1, '--disable-dart-dev');
    return [
      FuchsiaEmulator.instance().getTestCommand(
          _configuration.buildDirectory,
          _configuration.mode.name,
          _configuration.architecture.name,
          component,
          arguments,
          environmentOverrides)
    ];
  }
}

/// Temporary runtime configuration for browser runtimes that haven't been
/// migrated yet.
// TODO(ahe): Remove this class.
class DummyRuntimeConfiguration extends DartVmRuntimeConfiguration {
  @override
  List<Command> computeRuntimeCommands(
      CommandArtifact? artifact,
      List<String> arguments,
      Map<String, String> environmentOverrides,
      List<String> extraLibs,
      bool isCrashExpected) {
    throw "Unimplemented runtime '$runtimeType'";
  }
}
