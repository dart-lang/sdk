// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

/// Contains methods used to communicate DartDev results back to the VM.
///
/// Messages are received in runtime/bin/dartdev_isolate.cc.
abstract class VmInteropHandler {
  /// Initializes [VmInteropHandler] to utilize [port] to communicate with the
  /// VM.
  static void initialize(SendPort? port) => _port = port;

  /// Notifies the VM to run [script] with [args] upon DartDev exit.
  ///
  /// If [packageConfigOverride] is given, that is where the packageConfig is found.
  ///
  /// If [markMainIsolateAsSystemIsolate] is given and set to true, the spawned
  /// isolate will run with `--mark-main-isolate-as-system-isolate` enabled.
  ///
  /// If [useExecProcess] is given and set to true, the script is executed by
  /// execing it (On Linux/Mac the exec call is used, on Windows a new child
  /// process is started).
  static void run(
    String script,
    List<String> args, {
    String? packageConfigOverride,
    // TODO(bkonyi): remove once DartDev moves to AOT and this flag can be
    // provided directly to the process spawned by `dart run` and `dart test`.
    //
    // See https://github.com/dart-lang/sdk/issues/53576
    bool markMainIsolateAsSystemIsolate = false,
    bool useExecProcess = false,
  }) {
    List<String> argsList;
    if (useExecProcess && Platform.isWindows) {
      // On Windows if a new process is used to execute the script we
      // need to escape the script path and all the arguments as we
      // construct a single command line string to be passed to the
      // Windows process create call.
      if (script.contains(' ') && !script.contains('"')) {
        // Escape paths that may contain spaces
        script = '"$script"';
      }
      argsList = [
        for (int i = 0; i < args.length; i++) _windowsArgumentEscape(args[i]),
      ];
    } else {
      // Copy the list so it doesn't get GC'd underneath us.
      argsList = args.toList();
    }
    final port = _port;
    if (port == null) return;
    final message = <dynamic>[
      useExecProcess ? _kResultRunExec : _kResultRun,
      script,
      packageConfigOverride,
      markMainIsolateAsSystemIsolate,
      argsList,
    ];
    port.send(message);
  }

  /// Notifies the VM that DartDev has completed running. If provided a
  /// non-zero [exitCode], the VM will terminate with the given exit code.
  static void exit(int? exitCode) {
    final port = _port;
    if (port == null) return;
    final message = <dynamic>[_kResultExit, exitCode];
    port.send(message);
  }

  /// This code is identical to the one in process_patch.dart, please ensure
  /// changes made here are also done in process_patch.dart.
  /// TODO : figure out if this functionality can be abstracted out to a
  ///        common place.
  static String _windowsArgumentEscape(String argument) {
    if (argument.isEmpty) {
      return '""';
    }
    var result = argument;
    if (argument.contains('\t') ||
        argument.contains(' ') ||
        argument.contains('"')) {
      // Produce something that the C runtime on Windows will parse
      // back as this string.

      // Replace any number of '\' followed by '"' with
      // twice as many '\' followed by '\"'.
      var backslash = '\\'.codeUnitAt(0);
      var sb = StringBuffer();
      var nextPos = 0;
      var quotePos = argument.indexOf('"', nextPos);
      while (quotePos != -1) {
        var numBackslash = 0;
        var pos = quotePos - 1;
        while (pos >= 0 && argument.codeUnitAt(pos) == backslash) {
          numBackslash++;
          pos--;
        }
        sb.write(argument.substring(nextPos, quotePos - numBackslash));
        for (var i = 0; i < numBackslash; i++) {
          sb.write(r'\\');
        }
        sb.write(r'\"');
        nextPos = quotePos + 1;
        quotePos = argument.indexOf('"', nextPos);
      }
      sb.write(argument.substring(nextPos, argument.length));
      result = sb.toString();

      // Add '"' at the beginning and end and replace all '\' at
      // the end with two '\'.
      sb = StringBuffer('"');
      sb.write(result);
      nextPos = argument.length - 1;
      while (argument.codeUnitAt(nextPos) == backslash) {
        sb.write('\\');
        nextPos--;
      }
      sb.write('"');
      result = sb.toString();
    }

    return result;
  }

  // Note: keep in sync with runtime/bin/dartdev_isolate.h
  static const int _kResultRun = 1;
  static const int _kResultRunExec = 2;
  static const int _kResultExit = 3;

  static SendPort? _port;
}
