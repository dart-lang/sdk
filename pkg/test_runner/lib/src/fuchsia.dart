// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'repository.dart';
import 'utils.dart';

class FuchsiaEmulator {
  static final Uri toolsDir =
      Repository.uri.resolve('third_party/fuchsia/sdk/linux/bin/');
  static final String femuTool = toolsDir.resolve('femu.sh').toFilePath();
  static final String fserveTool = toolsDir.resolve('fserve.sh').toFilePath();
  static final String fpubTool = toolsDir.resolve('fpublish.sh').toFilePath();
  static final String fsshTool = toolsDir.resolve('fssh.sh').toFilePath();
  static final RegExp emulatorReadyPattern =
      RegExp(r'Using unique host name (.+)\.local\.');
  static final RegExp emulatorPidPattern =
      RegExp(r'([0-9]+) .* qemu-system-x86');
  static final String serverReadyPattern = '[pm serve] serving';

  static FuchsiaEmulator _inst;

  Process _emu;
  Process _server;
  String _deviceName;

  static Future<void> publishPackage(String buildDir, String mode) async {
    if (_inst == null) {
      _inst = FuchsiaEmulator();
      await _inst._start();
    }
    await _inst._publishPackage(buildDir, mode);
  }

  static void stop() {
    _inst?._stop();
  }

  static List<String> getTestArgs(String mode, List<String> arguments) {
    return _inst._getSshArgs(
        mode,
        arguments.map((arg) =>
            arg.replaceAll(Repository.uri.toFilePath(), '/pkg/data/')));
  }

  Future<void> _start() async {
    // Start the emulator.
    DebugLogger.info('Starting Fuchsia emulator');
    _emu = await Process.start(
        'xvfb-run', [femuTool, '--image', 'qemu-x64', '-N', '--headless']);

    // Wait until the emulator is ready and has a valid device name.
    var deviceNameFuture = Completer<String>();
    var emuStdout = StringBuffer();
    var emuStderr = StringBuffer();
    _emu.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (String line) {
      if (!deviceNameFuture.isCompleted) {
        emuStdout.write(line);
        emuStdout.write('\n');
        var match = emulatorReadyPattern.firstMatch(line);
        if (match != null) {
          deviceNameFuture.complete(match.group(1));
        }
      }
    }, onDone: () {
      if (!deviceNameFuture.isCompleted) {
        deviceNameFuture.completeError(
            'Fuchsia emulator terminated unexpectedly.\n\n' +
                _formatOutputs(emuStdout.toString(), emuStderr.toString()));
      }
      _stop();
    });
    _emu.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      if (!deviceNameFuture.isCompleted) {
        emuStderr.write(line);
        emuStderr.write('\n');
      }
    });
    _deviceName = await deviceNameFuture.future;
    DebugLogger.info('Fuchsia emulator ready: $_deviceName');

    // Start the server.
    DebugLogger.info('Starting Fuchsia package server');
    _server = await Process.start(fserveTool, [
      '--bucket',
      'fuchsia-sdk',
      '--image',
      'qemu-x64',
      '--device-name',
      _deviceName
    ]);

    // Wait until the server is ready to serve packages.
    var serverReadyFuture = Completer<String>();
    var serverStdout = StringBuffer();
    var serverStderr = StringBuffer();
    _server.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      if (!serverReadyFuture.isCompleted) {
        serverStdout.write(line);
        serverStdout.write('\n');
        if (line.contains(serverReadyPattern)) {
          serverReadyFuture.complete();
        }
      }
    }, onDone: () {
      if (!serverReadyFuture.isCompleted) {
        serverReadyFuture.completeError(
            'Fuchsia package server terminated unexpectedly.\n\n' +
                _formatOutputs(
                    serverStdout.toString(), serverStderr.toString()));
      }
      _stop();
    });
    _server.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      if (!serverReadyFuture.isCompleted) {
        serverStderr.write(line);
        serverStderr.write('\n');
      }
    });
    await serverReadyFuture.future;
    DebugLogger.info('Fuchsia package server ready');
  }

  List<String> _getSshArgs(String mode, Iterable<String> args) {
    var sshArgs = [
      '--device-name',
      _deviceName,
      'run',
      'fuchsia-pkg://fuchsia.com/dart_test_$mode#meta/dart.cmx'
    ];
    return sshArgs..addAll(args);
  }

  Future<void> _publishPackage(String buildDir, String mode) async {
    var packageFile = '$buildDir/gen/dart_test_$mode/dart_test_$mode.far';
    if (!File(packageFile).existsSync()) {
      throw 'File $packageFile does not exist. Please build fuchsia_test_package.';
    }
    DebugLogger.info('Publishing package: $packageFile');
    var result = await Process.run(fpubTool, [packageFile]);
    if (result.exitCode != 0) {
      _stop();
      throw _formatFailedResult('Publishing package', result);
    }

    // Verify that the publication was successful by running hello_test.dart.
    // This also forces the emulator to download the published package from the
    // server, rather than waiting until the first tests are run. It can take a
    // minute or two to transfer, and we don't want to eat into the timeout
    // timer of the first tests.
    DebugLogger.info('Verifying publication');
    result = await Process.run(fsshTool,
        _getSshArgs(mode, ['/pkg/data/pkg/testing/test/hello_test.dart']));
    if (result.exitCode != 0 || result.stdout != 'Hello, World!\n') {
      _stop();
      throw _formatFailedResult('Verifying publication', result);
    }
    DebugLogger.info('Publication successful');
  }

  void _stop() {
    if (_emu != null) {
      DebugLogger.info('Stopping Fuchsia emulator');
      _emu.kill(ProcessSignal.sigint);
      _emu = null;

      // Killing femu.sh seems to leave the underlying emulator running. So
      // manually find the process and terminate it by PID.
      var result = Process.runSync('ps', []);
      var emuPid = int.tryParse(
          emulatorPidPattern.firstMatch(result.stdout as String)?.group(1) ??
              "");
      if (result.exitCode != 0 || emuPid == null) {
        DebugLogger.info(
            _formatFailedResult('Searching for emulator process', result));
      } else {
        Process.killPid(emuPid);
        DebugLogger.info('Fuchsia emulator stopped');
      }
    }

    if (_server != null) {
      DebugLogger.info('Stopping Fuchsia package server');
      _server.kill();
      _server = null;

      // fserve.sh starts a package manager process in the background. We need
      // to manually kill this process, using fserve.sh again.
      var result = Process.runSync(fserveTool, ['--kill']);
      if (result.exitCode != 0) {
        DebugLogger.info(
            _formatFailedResult('Killing package manager', result));
      } else {
        DebugLogger.info('Fuchsia package server stopped');
      }
    }
  }

  String _formatOutputs(String stdout, String stderr) {
    var output = "";
    if (stdout.isNotEmpty) output += "=== STDOUT ===\n$stdout\n";
    if (stderr.isNotEmpty) output += "=== STDERR ===\n$stderr\n";
    return output;
  }

  String _formatFailedResult(String name, ProcessResult result) {
    return '$name failed with exit code: ${result.exitCode}\n\n' +
        _formatOutputs(result.stdout as String, result.stderr as String);
  }
}
