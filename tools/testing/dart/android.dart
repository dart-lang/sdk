// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library android;

import "dart:async";
import "dart:convert" show LineSplitter, UTF8;
import "dart:core";
import "dart:io";

import "path.dart";
import "utils.dart";

Future _executeCommand(String executable,
                       List<String> args,
                       [String stdin = ""]) {
  return _executeCommandRaw(executable, args, stdin).then((results) => null);
}

Future _executeCommandGetOutput(String executable,
                                List<String> args,
                                [String stdin = ""]) {
  return _executeCommandRaw(executable, args, stdin)
      .then((output) => output);
}

/**
 * [_executeCommandRaw] will write [stdin] to the standard input of the created
 * process and will return a tuple (stdout, stderr).
 *
 * If the exit code of the process was nonzero it will complete with an error.
 * If starting the process failed, it will complete with an error as well.
 */
Future _executeCommandRaw(String executable,
                          List<String> args,
                          [String stdin = ""]) {
  Future<String> getOutput(Stream<List<int>> stream) {
    return stream.transform(UTF8.decoder).toList()
        .then((data) => data.join(""));
  }

  DebugLogger.info("Running: '\$ $executable ${args.join(' ')}'");
  return Process.start(executable, args).then((Process process) {
    if (stdin != null && stdin != '') {
      process.stdin.write(stdin);
    }
    process.stdin.close();

    var futures = [getOutput(process.stdout),
                   getOutput(process.stderr),
                   process.exitCode];
    return Future.wait(futures).then((results) {
      bool success = results[2] == 0;
      if (!success) {
        var error = "Running: '\$ $executable ${args.join(' ')}' failed:"
                    "stdout: \n ${results[0]}"
                    "stderr: \n ${results[1]}"
                    "exitCode: \n ${results[2]}";
        throw new Exception(error);
      } else {
        DebugLogger.info("Success: $executable finished");
      }
      return results[0];
    });
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
    var completer = new Completer();
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
  static Future createAvd(String name, String target) {
    var args = ['--silent', 'create', 'avd', '--name', '$name',
                '--target', '$target', '--force', '--abi', 'armeabi-v7a'];
    // We're adding newlines to stdin to simulate <enter>.
    return _executeCommand("android", args, "\n\n\n\n");
  }
}

/**
 * Used for communicating with an emulator or with a real device.
 */
class AdbDevice {
  static const _adbServerStartupTime = const Duration(seconds: 3);
  String _deviceId;

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
  Future waitForBootCompleted() {
    var timeout = const Duration(seconds: 2);
    var completer = new Completer();

    checkUntilBooted() {
      _adbCommandGetOutput(['shell', 'getprop', 'sys.boot_completed'])
          .then((String stdout) {
            stdout = stdout.trim();
            if (stdout == '1') {
              completer.complete();
            } else {
              new Timer(timeout, checkUntilBooted);
            }
          }).catchError((error) {
            new Timer(timeout, checkUntilBooted);
          });
    }
    checkUntilBooted();
    return completer.future;
  }

  /**
   * Put adb in root mode.
   */
  Future adbRoot() {
    var adbRootCompleter = new Completer();
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
    var arguments = ['shell', 'am', 'start', '-W',
                     '-a', intent.action,
                     '-n', "${intent.package}/${intent.activity}"];
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

  Future _adbCommand(List<String> adbArgs) {
    if (_deviceId != null) {
      var extendedAdbArgs = ['-s', _deviceId];
      extendedAdbArgs.addAll(adbArgs);
      adbArgs = extendedAdbArgs;
    }
    return _executeCommand("adb", adbArgs);
  }

  Future<String> _adbCommandGetOutput(List<String> adbArgs) {
    if (_deviceId != null) {
      var extendedAdbArgs = ['-s', _deviceId];
      extendedAdbArgs.addAll(adbArgs);
      adbArgs = extendedAdbArgs;
    }
    return _executeCommandGetOutput("adb", adbArgs);
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
      return _deviceLineRegexp.allMatches(result.stdout)
          .map((Match m) => m.group(1)).toList();
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

