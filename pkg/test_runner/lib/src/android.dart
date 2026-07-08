// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "dart:async";
import "dart:collection";
import "dart:convert" show LineSplitter, utf8;
import "dart:core";
import "dart:io";
import "dart:math" as math;

import "path.dart";
import "utils.dart";

class AdbCommandResult {
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final bool timedOut;

  AdbCommandResult(
    this.command,
    this.stdout,
    this.stderr,
    this.exitCode,
    this.timedOut,
  );

  void throwIfFailed() {
    if (exitCode != 0) {
      var error =
          "Running: $command failed:"
          "stdout:\n  ${stdout.trim()}\n"
          "stderr:\n  ${stderr.trim()}\n"
          "exitCode: $exitCode\n"
          "timedOut: $timedOut";
      throw Exception(error);
    }
  }
}

/// [_executeCommand] will write [stdin] to the standard input of the created
/// process and will return a tuple (stdout, stderr).
///
/// If the exit code of the process was nonzero it will complete with an error.
/// If starting the process failed, it will complete with an error as well.
Future<AdbCommandResult> _executeCommand(
  String executable,
  List<String> args, {
  String? stdin,
  Duration? timeout,
}) {
  Future<String> getOutput(Stream<List<int>> stream) {
    return stream
        .transform(utf8.decoder)
        .toList()
        .then((data) => data.join(""));
  }

  return Process.start(executable, args).then((Process process) async {
    if (stdin != null && stdin != '') {
      process.stdin.write(stdin);
      await process.stdin.flush();
    }
    process.stdin.close();

    Timer? timer;
    var timedOut = false;
    if (timeout != null) {
      timer = Timer(timeout, () {
        timedOut = true;
        process.kill(ProcessSignal.sigterm);
        timer = null;
      });
    }

    var results = await Future.wait([
      getOutput(process.stdout),
      getOutput(process.stderr),
      process.exitCode,
    ]);
    timer?.cancel();

    var command = "$executable ${args.join(' ')}";
    return AdbCommandResult(
      command,
      results[0] as String,
      results[1] as String,
      results[2] as int,
      timedOut,
    );
  });
}

/// Helper class to loop through all adb ports.
///
/// The ports come in pairs:
///  - even number: console connection
///  - odd number: adb connection
/// Note that this code doesn't check if the ports are used.
class AdbServerPortPool {
  static const _minPort = 5554;
  static const _maxPort = 5584;

  static int _nextPort = _minPort;

  static int next() {
    var port = _nextPort;
    if (port > _maxPort) throw Exception("All ports are used.");

    _nextPort += 2;
    return port;
  }
}

/// Used for communicating with an emulator or with a real device.
class AdbDevice {
  static const _adbServerStartupTime = Duration(seconds: 3);
  static int _count = 0;

  final String deviceId;
  final String deviceDir;
  final Map<String, String> _cachedData = {};

  factory AdbDevice(String deviceId) => AdbDevice.withSlice(deviceId, _count++);
  AdbDevice.withSlice(this.deviceId, int slice)
    : deviceDir = "/data/local/tmp/testing$slice";

  /// Blocks execution until the device is online.
  Future waitForDevice() {
    return _adbCommand(['wait-for-device']);
  }

  /// Polls the 'sys.boot_completed' property. Returns as soon as the property
  /// is 1.
  Future<void> waitForBootCompleted() async {
    while (true) {
      try {
        var result = await _adbCommand([
          'shell',
          'getprop',
          'sys.boot_completed',
        ]);
        if (result.stdout.trim() == '1') return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  /// Put adb in root mode.
  Future<bool> adbRoot() {
    var adbRootCompleter = Completer<bool>();
    _adbCommand(['root'])
        .then((_) {
          // TODO: Figure out a way to wait until the adb daemon was restarted in
          // 'root mode' on the device.
          Timer(_adbServerStartupTime, () => adbRootCompleter.complete(true));
        })
        .catchError((Object error) {
          adbRootCompleter.completeError(error);
        });
    return adbRootCompleter.future;
  }

  /// Download data from the device.
  Future pullData(Path remote, Path local) {
    return _adbCommand(['pull', '$remote', '$local']);
  }

  /// Upload data to the device.
  Future pushData(Path local, Path remote) {
    return _adbCommand(['push', '$local', '$remote']);
  }

  /// Upload data to the device, unless [local] is the same as the most recently
  /// used source for [remote].
  Future<AdbCommandResult> pushCachedData(String local, String remote) {
    if (_cachedData[remote] == local) {
      return Future.value(
        AdbCommandResult("Skipped cached push", "", "", 0, false),
      );
    }
    _cachedData[remote] = local;
    return _adbCommand(['push', local, remote]);
  }

  /// Change permission of directory recursively.
  Future chmod(String mode, Path directory) {
    var arguments = ['shell', 'chmod', '-R', mode, '$directory'];
    return _adbCommand(arguments);
  }

  /// Install an application on the device.
  Future installApk(Path filename) {
    return _adbCommand([
      'install',
      '-i',
      'com.google.android.feedback',
      '-r',
      '$filename',
    ]);
  }

  /// Start the given intent on the device.
  Future startActivity(Intent intent) {
    return _adbCommand([
      'shell',
      'am',
      'start',
      '-W',
      '-a',
      intent.action,
      '-n',
      "${intent.package}/${intent.activity}",
      if (intent.dataUri != null) ...['-d', intent.dataUri!],
    ]);
  }

  /// Force to stop everything associated with [package].
  Future forceStop(String package) {
    return _adbCommand(['shell', 'am', 'force-stop', package]);
  }

  /// Set system property name to value.
  Future setProp(String name, String value) {
    return _adbCommand(['shell', 'setprop', name, value]);
  }

  /// Kill all background processes.
  Future killAll() {
    return _adbCommand(['shell', 'am', 'kill-all']);
  }

  Future<AdbCommandResult> runAdbCommand(
    List<String> adbArgs, {
    Duration? timeout,
  }) {
    return _executeCommand(
      "adb",
      _deviceSpecificArgs(adbArgs),
      timeout: timeout,
    );
  }

  Future<AdbCommandResult> runAdbShellCommand(
    List<String> shellArgs, {
    Duration? timeout,
  }) async {
    const marker = 'AdbShellExitCode: ';

    // The exitcode of 'adb shell ...' can be 0 even though the command failed
    // with a non-zero exit code. We therefore explicitly print it to stdout and
    // search for it.

    var args = ['shell', "${shellArgs.join(' ')} ; echo $marker \$?"];
    var result = await _executeCommand(
      "adb",
      _deviceSpecificArgs(args),
      timeout: timeout,
    );
    var exitCode = result.exitCode;
    var lines = result.stdout
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isNotEmpty) {
      var index = lines.last.indexOf(marker);
      if (index >= 0) {
        exitCode = int.parse(
          lines.last.substring(index + marker.length).trim(),
        );
        if (exitCode > 128 && exitCode <= 128 + 31) {
          // Return negative exit codes for signals 1..31 (128+N for signal N).
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
    return AdbCommandResult(
      result.command,
      result.stdout,
      result.stderr,
      exitCode,
      result.timedOut,
    );
  }

  Future<AdbCommandResult> _adbCommand(List<String> adbArgs) async {
    var result = await _executeCommand("adb", _deviceSpecificArgs(adbArgs));
    result.throwIfFailed();
    return result;
  }

  List<String> _deviceSpecificArgs(List<String> adbArgs) {
    return ['-s', deviceId, ...adbArgs];
  }
}

/// Helper to list all adb devices available.
class AdbHelper {
  static final RegExp _deviceLineRegexp = RegExp(
    r'^([a-zA-Z0-9:_.\-]+)[ \t]+device$',
    multiLine: true,
  );

  static final RegExp _fastbootDeviceLineRegexp = RegExp(
    r'^([a-zA-Z0-9:_.\-]+)[ \t]+fastboot$',
    multiLine: true,
  );

  static Future<List<String>> listDevices() {
    return Process.run('adb', ['devices']).then((ProcessResult result) {
      if (result.exitCode != 0) {
        throw Exception(
          "Could not list devices [stdout: ${result.stdout},"
          "stderr: ${result.stderr}]",
        );
      }
      return _deviceLineRegexp
          .allMatches(result.stdout as String)
          .map((Match m) => m[1]!)
          .toList();
    });
  }

  static Future<List<String>> listFastbootDevices() async {
    final result = await Process.run('fastboot', ['devices']);
    if (result.exitCode != 0) {
      throw Exception(
        "Could not list fastboot devices [stdout: ${result.stdout},"
        "stderr: ${result.stderr}]",
      );
    }
    return _fastbootDeviceLineRegexp
        .allMatches(result.stdout as String)
        .map((Match m) => m[1]!)
        .toList();
  }

  static Future<void> rebootFastbootDevices() async {
    final result = await Process.run('fastboot', ['reboot']);
    if (result.exitCode != 0) {
      throw Exception(
        "Could not list fastboot devices [stdout: ${result.stdout},"
        "stderr: ${result.stderr}]",
      );
    }
  }
}

/// Represents an android intent.
class Intent {
  String action;
  String package;
  String activity;
  String? dataUri;

  Intent(this.action, this.package, this.activity, [this.dataUri]);
}

class AndroidEmulators {
  static final _processes = <Process>[];

  static void _forward(Process process, String label) {
    const LineSplitter()
        .bind(utf8.decoder.bind(process.stdout))
        .listen((d) => print("[$label] $d"));
    const LineSplitter()
        .bind(utf8.decoder.bind(process.stderr))
        .listen((d) => print("[$label] $d"));
  }

  static final _environment = {
    "ANDROID_HOME": Uri.base
        .resolve("third_party/android_tools/sdk")
        .toFilePath(),
    "JAVA_HOME": Uri.base.resolve("third_party/openjdk").toFilePath(),
  };

  static Future start() {
    return _start;
  }

  static final _start = _startOnce();
  static Future _startOnce() async {
    const sdkmanager =
        "./third_party/android_tools/sdk/cmdline-tools/latest/bin/sdkmanager";

    var p = await Process.start(
      sdkmanager,
      ["--install", "emulator"],
      environment: _environment,
      mode: ProcessStartMode.inheritStdio,
    );
    var e = await p.exitCode;
    if (e != 0) {
      throw "install emulator failed: $e";
    }

    p = await Process.start(
      sdkmanager,
      ["--install", "system-images;android-30;default;x86_64"],
      environment: _environment,
      mode: ProcessStartMode.inheritStdio,
    );
    e = await p.exitCode;
    if (e != 0) {
      throw "install image failed: $e";
    }

    final numEmulators = 1;
    // Maybe Platform.numberOfProcessors ~/ 6, but unexplained crashes.
    final starts = <Future>[];
    for (var i = 0; i < numEmulators; i++) {
      final port = "${5555 + i * 2}"; // adb's prefered port range.
      starts.add(startEmulator(port));
    }
    return Future.wait(starts);
  }

  static Future startEmulator(String port) async {
    const avdmanager =
        "./third_party/android_tools/sdk/cmdline-tools/latest/bin/avdmanager";
    const emulator = "./third_party/android_tools/sdk/emulator/emulator";
    const adb = "./third_party/android_tools/sdk/platform-tools/adb";

    var p = await Process.start(avdmanager, [
      "create",
      "avd",
      "--force",
      "--name",
      "test-$port",
      "--package",
      "system-images;android-30;default;x86_64",
    ], environment: _environment);
    _forward(p, "avdmanager create");
    p.stdin.writeln("no"); // Create custom hardware profile?
    p.stdin.close();
    var e = await p.exitCode;
    if (e != 0) {
      throw "create avd failed: $e";
    }

    final deviceId = "emulator-$port";
    final stopwatch = Stopwatch();
    stopwatch.start();
    p = await Process.start(
      emulator,
      [
        "-port",
        port,
        "-avd",
        "test-$port",
        "-read-only",
        "-accel",
        "on", // Get an error if kvm isn't available.
        "-no-window",
        "-no-snapshot",
        "-no-audio",
        "-no-boot-anim",
        "-no-metrics",
        "-cores",
        "6", // Seems ignored. nproc reports 6 regardless of value here.
        "-memory",
        "8192", // Limited to 1.5-8G.
      ],
      environment: _environment,
      mode: ProcessStartMode.inheritStdio,
    );
    _processes.add(p);

    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(seconds: 20));
      var p = await Process.run(adb, [
        "-s",
        deviceId,
        "shell",
        "getprop",
        "sys.boot_completed",
      ]);
      if (p.stdout.trim() == "1") {
        print("$deviceId ready after ${stopwatch.elapsed}");
        return "okay";
      }
      print("still waiting for $deviceId to boot after ${stopwatch.elapsed}");
    }

    throw "timed out waiting for $deviceId to boot after ${stopwatch.elapsed}";
  }

  static Future stop() async {
    while (_processes.isNotEmpty) {
      _processes.removeLast().kill();
    }
  }
}

/// Discovers all available devices and supports acquire/release.
class AdbDevicePool {
  final Queue<AdbDevice> _idleDevices = Queue();
  final Queue<Completer<AdbDevice>> _waiter = Queue();

  AdbDevicePool(List<AdbDevice> idleDevices) {
    _idleDevices.addAll(idleDevices);
  }

  static Future<AdbDevicePool> create() async {
    var names = await AdbHelper.listDevices();
    var devices = names.map(AdbDevice.new).toList();
    if (devices.isEmpty) {
      var fastbootDevices = await AdbHelper.listFastbootDevices();
      if (fastbootDevices.isNotEmpty) {
        print('Connected device $fastbootDevices found in fastboot mode...');
        AdbHelper.rebootFastbootDevices();

        final sw = Stopwatch()..start();
        const waitForDeviceToRebootInSeconds = 60;
        while (sw.elapsed.inSeconds < waitForDeviceToRebootInSeconds) {
          print('Waiting for device to comeback after fastboot reboot...\n');
          names = await AdbHelper.listDevices();
          if (names.isNotEmpty) {
            devices = names.map(AdbDevice.new).toList();
            break;
          }
          await Future.delayed(const Duration(seconds: 5));
        }
      }
      if (devices.isEmpty) {
        throw Exception(
          'No android devices found. '
          'Please make sure "adb devices" shows your device!',
        );
      }
    }
    print("Found ${devices.length} Android devices.");
    var splitDevices = await _splitDevices(devices);
    print("Using as ${splitDevices.length} Android devices.");
    return AdbDevicePool(splitDevices);
  }

  static Future<List<AdbDevice>> _splitDevices(List<AdbDevice> devices) async {
    var splitDevices = <AdbDevice>[];
    for (var d in devices) {
      var result = await Process.run("adb", [
        "-s",
        d.deviceId,
        "shell",
        "df",
        "/data/local/tmp",
      ]);
      int disk;
      try {
        // Sample input that is being parsed below:
        //
        // Filesystem       1K-blocks      Used Available Use% Mounted on
        // /dev/block/dm-64 114786388 110709944   3945372  97% /data/user/0
        disk =
            int.parse(
              result.stdout
                      .split('\n')[1]
                      .split(' ')
                      .where((String v) => v.isNotEmpty)
                      .toList()[3]
                      .trim()
                  as String,
            ) *
            512;
      } catch (_) {
        print(result.stdout);
        rethrow;
      }
      result = await Process.run("adb", [
        "-s",
        d.deviceId,
        "shell",
        "cat",
        "/proc/meminfo",
      ]);
      int mem;
      try {
        mem =
            int.parse(
              RegExp(
                    r"^MemTotal:\s*(\d+)\s*kB",
                    multiLine: true,
                  ).firstMatch(result.stdout as String)![1]
                  as String,
            ) *
            1024;
      } catch (_) {
        print(result.stdout);
        rethrow;
      }
      result = await Process.run("adb", ["-s", d.deviceId, "shell", "nproc"]);
      int harts;
      try {
        harts = int.parse(result.stdout.trim() as String);
      } catch (e) {
        print(e);
        print(result.stdout);
        print(result.stderr);
        harts = 1;
      }
      print("${d.deviceId} harts=$harts mem=$mem free_disk=$disk");
      var splitCount = harts;
      const kb = 1024;
      const mb = 1024 * kb;
      const gb = 1024 * mb;
      splitCount = math.min(splitCount, mem ~/ gb);
      splitCount = math.min(splitCount, disk ~/ (256 * mb));
      splitCount = math.max(splitCount, 1);
      for (var i = 0; i < splitCount; i++) {
        splitDevices.add(AdbDevice.withSlice(d.deviceId, i));
      }
    }
    return splitDevices;
  }

  Future<AdbDevice> acquireDevice() async {
    if (_idleDevices.isNotEmpty) {
      return _idleDevices.removeFirst();
    } else {
      var completer = Completer<AdbDevice>();
      _waiter.add(completer);
      return completer.future;
    }
  }

  void releaseDevice(AdbDevice device) {
    if (_waiter.isNotEmpty) {
      var completer = _waiter.removeFirst();
      completer.complete(device);
    } else {
      _idleDevices.add(device);
    }
  }
}
