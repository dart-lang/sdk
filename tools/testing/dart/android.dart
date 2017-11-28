// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library android;

import "dart:async";
import "dart:convert" show LineSplitter, UTF8;
import "dart:core";
import "dart:collection";
import "dart:io";

import "path.dart";
import "utils.dart";

class AdbCommandResult {
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final bool timedOut;

  AdbCommandResult(
      this.command, this.stdout, this.stderr, this.exitCode, this.timedOut);

  void throwIfFailed() {
    if (exitCode != 0) {
      var error = "Running: $command failed:"
          "stdout:\n  ${stdout.trim()}\n"
          "stderr:\n  ${stderr.trim()}\n"
          "exitCode: $exitCode\n"
          "timedOut: $timedOut";
      throw new Exception(error);
    }
  }
}

/**
 * [_executeCommand] will write [stdin] to the standard input of the created
 * process and will return a tuple (stdout, stderr).
 *
 * If the exit code of the process was nonzero it will complete with an error.
 * If starting the process failed, it will complete with an error as well.
 */
Future<AdbCommandResult> _executeCommand(String executable, List<String> args,
    {String stdin, Duration timeout}) {
  Future<String> getOutput(Stream<List<int>> stream) {
    return stream
        .transform(UTF8.decoder)
        .toList()
        .then((data) => data.join(""));
  }

  return Process.start(executable, args).then((Process process) async {
    if (stdin != null && stdin != '') {
      process.stdin.write(stdin);
      await process.stdin.flush();
    }
    process.stdin.close();

    Timer timer;
    bool timedOut = false;
    if (timeout != null) {
      timer = new Timer(timeout, () {
        timedOut = true;
        process.kill(ProcessSignal.SIGTERM);
        timer = null;
      });
    }

    var results = await Future.wait([
      getOutput(process.stdout),
      getOutput(process.stderr),
      process.exitCode
    ]);
    if (timer != null) timer.cancel();

    String command = "$executable ${args.join(' ')}";
    return new AdbCommandResult(command, results[0] as String,
        results[1] as String, results[2] as int, timedOut);
  });
}

/**
 * Helper class to loop through all adb ports.
 *
 * The ports come in pairs:
 *  - even number: console connection
 *  - odd number: adb connection
 * Note that this code doesn't check if the ports are used.
 */
class AdbServerPortPool {
  static int MIN_PORT = 5554;
  static int MAX_PORT = 5584;

  static int _nextPort = MIN_PORT;

  static int next() {
    var port = _nextPort;
    if (port > MAX_PORT) {
      throw new Exception("All ports are used.");
    }
    _nextPort += 2;
    return port;
  }
}

/**
 * Represents the interface to the emulator.
 * New emulators can be launched by calling the static [launchNewEmulator]
 * method.
 */
class AndroidEmulator {
  int _port;
  Process _emulatorProcess;
  AdbDevice _adbDevice;

  int get port => _port;

  AdbDevice get adbDevice => _adbDevice;

  static Future<AndroidEmulator> launchNewEmulator(String avdName) {
    var portNumber = AdbServerPortPool.next();
    var args = ['-avd', '$avdName', '-port', "$portNumber" /*, '-gpu', 'on'*/];
    return Process.start("emulator64-arm", args).then((Process process) {
      var adbDevice = new AdbDevice('emulator-$portNumber');
      return new AndroidEmulator._private(portNumber, adbDevice, process);
    });
  }

  AndroidEmulator._private(this._port, this._adbDevice, this._emulatorProcess) {
    Stream<String> getLines(Stream s) {
      return s.transform(UTF8.decoder).transform(new LineSplitter());
    }

    getLines(_emulatorProcess.stdout).listen((line) {
      log("stdout: ${line.trim()}");
    });
    getLines(_emulatorProcess.stderr).listen((line) {
      log("stderr: ${line.trim()}");
    });
    _emulatorProcess.exitCode.then((exitCode) {
      log("emulator exited with exitCode: $exitCode.");
    });
  }

  Future<bool> kill() {
    var completer = new Completer<bool>();
    if (_emulatorProcess.kill()) {
      _emulatorProcess.exitCode.then((exitCode) {
        // TODO: Should we use exitCode to do something clever?
        completer.complete(true);
      });
    } else {
      log("Sending kill signal to emulator process failed");
      completer.complete(false);
    }
    return completer.future;
  }

  void log(String msg) {
    DebugLogger.info("AndroidEmulator(${_adbDevice.deviceId}): $msg");
  }
}

/**
 * Helper class to create avd device configurations.
 */
class AndroidHelper {
  static Future createAvd(String name, String target) async {
    var args = [
      '--silent',
      'create',
      'avd',
      '--name',
      '$name',
      '--target',
      '$target',
      '--force',
      '--abi',
      'armeabi-v7a'
    ];
    // We're adding newlines to stdin to simulate <enter>.
    var result = await _executeCommand("android", args, stdin: "\n\n\n\n");
    result.throwIfFailed();
  }
}

/**
 * Used for communicating with an emulator or with a real device.
 */
class AdbDevice {
  static const _adbServerStartupTime = const Duration(seconds: 3);
  String _deviceId;
  Map<String, String> _cachedData = new Map<String, String>();

  String get deviceId => _deviceId;

  AdbDevice(this._deviceId);

  /**
   * Blocks execution until the device is online
   */
  Future waitForDevice() {
    return _adbCommand(['wait-for-device']);
  }

  /**
   * Polls the 'sys.boot_completed' property. Returns as soon as the property is
   * 1.
   */
  Future<Null> waitForBootCompleted() async {
    while (true) {
      try {
        AdbCommandResult result =
            await _adbCommand(['shell', 'getprop', 'sys.boot_completed']);
        if (result.stdout.trim() == '1') return;
      } catch (_) {}
      await new Future<Null>.delayed(const Duration(seconds: 2));
    }
  }

  /**
   * Put adb in root mode.
   */
  Future<bool> adbRoot() {
    var adbRootCompleter = new Completer<bool>();
    _adbCommand(['root']).then((_) {
      // TODO: Figure out a way to wait until the adb daemon was restarted in
      // 'root mode' on the device.
      new Timer(_adbServerStartupTime, () => adbRootCompleter.complete(true));
    }).catchError((error) => adbRootCompleter.completeError(error));
    return adbRootCompleter.future;
  }

  /**
   * Download data form the device.
   */
  Future pullData(Path remote, Path local) {
    return _adbCommand(['pull', '$remote', '$local']);
  }

  /**
   * Upload data to the device.
   */
  Future pushData(Path local, Path remote) {
    return _adbCommand(['push', '$local', '$remote']);
  }

  /**
   * Upload data to the device, unless [local] is the same as the most recently
   * used source for [remote].
   */
  Future<AdbCommandResult> pushCachedData(String local, String remote) {
    if (_cachedData[remote] == local) {
      return new Future.value(
          new AdbCommandResult("Skipped cached push", "", "", 0, false));
    }
    _cachedData[remote] = local;
    return _adbCommand(['push', local, remote]);
  }

  /**
   * Change permission of directory recursively.
   */
  Future chmod(String mode, Path directory) {
    var arguments = ['shell', 'chmod', '-R', mode, '$directory'];
    return _adbCommand(arguments);
  }

  /**
   * Install an application on the device.
   */
  Future installApk(Path filename) {
    return _adbCommand(
        ['install', '-i', 'com.google.android.feedback', '-r', '$filename']);
  }

  /**
   * Start the given intent on the device.
   */
  Future startActivity(Intent intent) {
    var arguments = [
      'shell',
      'am',
      'start',
      '-W',
      '-a',
      intent.action,
      '-n',
      "${intent.package}/${intent.activity}"
    ];
    if (intent.dataUri != null) {
      arguments.addAll(['-d', intent.dataUri]);
    }
    return _adbCommand(arguments);
  }

  /**
   * Force to stop everything associated with [package].
   */
  Future forceStop(String package) {
    var arguments = ['shell', 'am', 'force-stop', package];
    return _adbCommand(arguments);
  }

  /**
   * Set system property name to value.
   */
  Future setProp(String name, String value) {
    return _adbCommand(['shell', 'setprop', name, value]);
  }

  /**
   * Kill all background processes.
   */
  Future killAll() {
    var arguments = ['shell', 'am', 'kill-all'];
    return _adbCommand(arguments);
  }

  Future<AdbCommandResult> runAdbCommand(List<String> adbArgs,
      {Duration timeout}) {
    return _executeCommand("adb", _deviceSpecificArgs(adbArgs),
        timeout: timeout);
  }

  Future<AdbCommandResult> runAdbShellCommand(List<String> shellArgs,
      {Duration timeout}) async {
    const MARKER = 'AdbShellExitCode: ';

    // The exitcode of 'adb shell ...' can be 0 even though the command failed
    // with a non-zero exit code. We therefore explicitly print it to stdout and
    // search for it.

    var args = ['shell', "${shellArgs.join(' ')} ; echo $MARKER \$?"];
    AdbCommandResult result = await _executeCommand(
        "adb", _deviceSpecificArgs(args),
        timeout: timeout);
    int exitCode = result.exitCode;
    var lines = result.stdout
        .split('\n')
        .where((line) => line.trim().length > 0)
        .toList();
    if (lines.length > 0) {
      int index = lines.last.indexOf(MARKER);
      if (index >= 0) {
        exitCode =
            int.parse(lines.last.substring(index + MARKER.length).trim());
        if (exitCode > 128 && exitCode <= 128 + 31) {
          // Return negative exit codes for signals 1..31 (128+N for signal N)
          exitCode = 128 - exitCode;
        }
      } else {
        // In case of timeouts, for example, we won't get the exitcode marker.
        // TODO(mkroghj): Some times tests fail with the assert below. To better
        // investigate, write out debug info.
        DebugLogger.info("======= THIS IS DEBUG INFORMATION =======");
        DebugLogger.info("arguments: $args");
        DebugLogger.info("exitCode: ${result.exitCode}");
        DebugLogger.info("timedOut: ${result.timedOut}");
        DebugLogger.info("---- std out ----");
        DebugLogger.info(result.stdout);
        DebugLogger.info("---- std out end ----");
        DebugLogger.info("---- std error  ----");
        DebugLogger.info(result.stderr);
        DebugLogger.info("---- std error end ----");
        DebugLogger.info("======= THIS IS NO LONGER DEBUG INFORMATION =======");
        assert(result.exitCode != 0);
      }
    }
    return new AdbCommandResult(result.command, result.stdout, result.stderr,
        exitCode, result.timedOut);
  }

  Future<AdbCommandResult> _adbCommand(List<String> adbArgs) async {
    var result = await _executeCommand("adb", _deviceSpecificArgs(adbArgs));
    result.throwIfFailed();
    return result;
  }

  List<String> _deviceSpecificArgs(List<String> adbArgs) {
    if (_deviceId != null) {
      var extendedAdbArgs = ['-s', _deviceId];
      extendedAdbArgs.addAll(adbArgs);
      adbArgs = extendedAdbArgs;
    }
    return adbArgs;
  }
}

/**
 * Helper to list all adb devices available.
 */
class AdbHelper {
  static RegExp _deviceLineRegexp =
      new RegExp(r'^([a-zA-Z0-9_-]+)[ \t]+device$', multiLine: true);

  static Future<List<String>> listDevices() {
    return Process.run('adb', ['devices']).then((ProcessResult result) {
      if (result.exitCode != 0) {
        throw new Exception("Could not list devices [stdout: ${result.stdout},"
            "stderr: ${result.stderr}]");
      }
      return _deviceLineRegexp
          .allMatches(result.stdout as String)
          .map((Match m) => m.group(1))
          .toList();
    });
  }
}

/**
 * Represents an android intent.
 */
class Intent {
  String action;
  String package;
  String activity;
  String dataUri;

  Intent(this.action, this.package, this.activity, [this.dataUri]);
}

/**
 * Discovers all available devices and supports acquire/release.
 */
class AdbDevicePool {
  final Queue<AdbDevice> _idleDevices = new Queue<AdbDevice>();
  final Queue<Completer> _waiter = new Queue<Completer>();

  AdbDevicePool(List<AdbDevice> idleDevices) {
    _idleDevices.addAll(idleDevices);
  }

  static Future<AdbDevicePool> create() async {
    var names = await AdbHelper.listDevices();
    var devices = names.map((id) => new AdbDevice(id)).toList();
    if (devices.length == 0) {
      throw new Exception('No android devices found. '
          'Please make sure "adb devices" shows your device!');
    }
    print("Found ${devices.length} Android devices.");
    return new AdbDevicePool(devices);
  }

  Future<AdbDevice> acquireDevice() async {
    if (_idleDevices.length > 0) {
      return _idleDevices.removeFirst();
    } else {
      var completer = new Completer<AdbDevice>();
      _waiter.add(completer);
      return completer.future;
    }
  }

  void releaseDevice(AdbDevice device) {
    if (_waiter.length > 0) {
      Completer completer = _waiter.removeFirst();
      completer.complete(device);
    } else {
      _idleDevices.add(device);
    }
  }
}
