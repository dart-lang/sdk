// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Example that illustrates how to use the incremental compiler and trigger a
/// hot-reload on the VM after recompiling the application.
///
/// This example resembles the `run` command in flutter-tools. It creates an
/// interactive command-line program that waits for the user to tap a key to
/// trigger a recompile and reload.
///
/// The following instructions assume a linux checkout of the SDK:
///   * Build the SDK
///
/// ```
///    ./tools/build.py -m release
/// ```
///
///   * On one terminal (terminal A), start this script and point it to an
///   example program "foo.dart" and keep the job running. A good example
///   program would do something periodically, so you can see the effect
///   of a hot-reload while the app is running.
///
/// ```
///    out/ReleaseX64/dart pkg/front_end/example/incremental_reload/run.dart foo.dart out.dill
/// ```
///
///   * Trigger an initial compile of the program by hitting the "c" key in
///   terminal A.
///
///   * On another terminal (terminal B), start the program on the VM, with the
///   service-protocol enabled and provide the precompiled platform libraries:
///
/// ```
///    out/ReleaseX64/dart --enable-vm-service --platform=out/ReleaseX64/patched_sdk/platform.dill out.dill
/// ```
///
///   * Modify the orginal program
///
///   * In terminal A, hit the "r" key to trigger a recompile and hot reload.
///
///   * See the changed program in terminal B
library front_end.example.incremental_reload.run;

import 'dart:io';
import 'dart:async';
import 'dart:convert' show ASCII;

import '../../tool/vm/reload.dart';

import 'compiler_with_invalidation.dart';

VmReloader reloader = new VmReloader();
AnsiTerminal terminal = new AnsiTerminal();

main(List<String> args) async {
  if (args.length <= 1) {
    print('usage: dart incremental_compile.dart input.dart out.dill');
    exit(1);
  }

  var compiler = await createIncrementalCompiler(args[0]);
  var outputUri = Uri.base.resolve(args[1]);

  showHeader();
  listenOnKeyPress(compiler, outputUri)
      .whenComplete(() => reloader.disconnect());
}

/// Implements the interactive UI by listening for input keys from the user.
Future listenOnKeyPress(IncrementalCompiler compiler, Uri outputUri) {
  var completer = new Completer();
  terminal.singleCharMode = true;
  StreamSubscription subscription;
  subscription = terminal.onCharInput.listen((String char) async {
    try {
      CompilationResult compilationResult;
      ReloadResult reloadResult;
      switch (char) {
        case 'r':
          compilationResult = await rebuild(compiler, outputUri);
          if (!compilationResult.errorSeen &&
              compilationResult.program != null &&
              compilationResult.program.libraries.isNotEmpty) {
            reloadResult = await reload(outputUri);
          }
          break;
        case 'c':
          compilationResult = await rebuild(compiler, outputUri);
          break;
        case 'l':
          reloadResult = await reload(outputUri);
          break;
        case 'q':
          terminal.singleCharMode = false;
          print('');
          subscription.cancel();
          completer.complete(null);
          break;
        default:
          break;
      }
      if (compilationResult != null || reloadResult != null) {
        reportStats(compilationResult, reloadResult, outputUri);
      }
    } catch (e) {
      terminal.singleCharMode = false;
      subscription.cancel();
      completer.completeError(null);
      rethrow;
    }
  }, onError: (e) {
    terminal.singleCharMode = false;
    subscription.cancel();
    completer.completeError(null);
  });

  return completer.future;
}

/// Request a reload and gather timing metrics.
Future<ReloadResult> reload(outputUri) async {
  var result = new ReloadResult();
  var reloadTimer = new Stopwatch()..start();
  var reloadResult = await reloader.reload(outputUri);
  reloadTimer.stop();
  result.reloadTime = reloadTimer.elapsedMilliseconds;
  result.errorSeen = false;
  result.errorDetails;
  if (!reloadResult['success']) {
    result.errorSeen = true;
    result.errorDetails = reloadResult['details']['notices'].first['message'];
  }
  return result;
}

/// Results from requesting a hot reload.
class ReloadResult {
  /// How long it took to do the hot-reload in the VM.
  int reloadTime = 0;

  /// Whether we saw errors during compilation or reload.
  bool errorSeen = false;

  /// Error message when [errorSeen] is true.
  String errorDetails;
}

/// This script shows stats about each reload on the terminal in a table form.
/// This function prints out the header of such table.
showHeader() {
  print(terminal.bolden('Press a key to trigger a command:'));
  print(terminal.bolden('   r:  incremental compile + reload'));
  print(terminal.bolden('   c:  incremental compile w/o reload'));
  print(terminal.bolden('   l:  reload w/o recompile'));
  print(terminal.bolden('   q:  quit'));
  print(terminal.bolden(
      '#    Files     Files %      ------- Time -------------------------  Binary\n'
      '     Modified  Sent  Total      Check Compile   Reload    Total      Avg   Size  '));
}

/// Whether to show stats as a single line (override metrics on each request)
const bool singleLine = false;

var total = 0;
var iter = 0;
var timeSum = 0;
var lastLine = 0;

/// Show stats about a recompile and reload.
reportStats(CompilationResult compilationResult, ReloadResult reloadResult,
    Uri outputUri) {
  compilationResult ??= new CompilationResult();
  reloadResult ??= new ReloadResult();
  int changed = compilationResult.changed;
  int updated = compilationResult.program?.libraries?.length ?? 0;
  int totalFiles = compilationResult.totalFiles;
  int invalidateTime = compilationResult.invalidateTime;
  int compileTime = compilationResult.compileTime;
  int reloadTime = reloadResult.reloadTime;
  bool errorSeen = compilationResult.errorSeen || reloadResult.errorSeen;
  String errorDetails =
      compilationResult.errorDetails ?? reloadResult.errorDetails;

  var totalTime = invalidateTime + compileTime + reloadTime;
  timeSum += totalTime;
  total++;
  iter++;
  var avgTime = (timeSum / total).truncate();
  var size = new File.fromUri(outputUri).statSync().size;

  var percent = (100 * updated / totalFiles).toStringAsFixed(0);
  var line = '${_padl(iter, 3)}: '
      '${_padl(changed, 8)}  ${_padl(updated, 5)} ${_padl(percent, 4)}%  '
      '${_padl(invalidateTime, 5)} ms '
      '${_padl(compileTime, 5)} ms '
      '${_padl(reloadTime, 5)} ms '
      '${_padl(totalTime, 5)} ms '
      '${_padl(avgTime, 5)} ms '
      '${_padl(size, 5)}b';
  var len = line.length;
  if (singleLine) stdout.write('\r');
  stdout.write((errorSeen) ? terminal.red(line) : terminal.green(line));
  if (!singleLine) stdout.write('\n');
  if (errorSeen) {
    if (!singleLine) errorDetails = '  error: $errorDetails\n';
    len += errorDetails.length;
    stdout.write(errorDetails);
  }
  if (singleLine) {
    var diff = " " * (lastLine - len);
    stdout.write(diff);
  }
  lastLine = len;
}

_padl(x, n) {
  var s = '$x';
  return ' ' * (n - s.length) + s;
}

/// Helper to control an ANSI terminal (adapted from flutter_tools)
class AnsiTerminal {
  static const String _bold = '\u001B[1m';
  static const String _green = '\u001B[32m';
  static const String _red = '\u001B[31m';
  static const String _reset = '\u001B[0m';
  static const String _clear = '\u001B[2J\u001B[H';

  static const int _ENXIO = 6;
  static const int _ENOTTY = 25;
  static const int _ENETRESET = 102;
  static const int _INVALID_HANDLE = 6;

  /// Setting the line mode can throw for some terminals (with "Operation not
  /// supported on socket"), but the error can be safely ignored.
  static const List<int> _lineModeIgnorableErrors = const <int>[
    _ENXIO,
    _ENOTTY,
    _ENETRESET,
    _INVALID_HANDLE,
  ];

  String bolden(String message) => wrap(message, _bold);
  String green(String message) => wrap(message, _green);
  String red(String message) => wrap(message, _red);

  String wrap(String message, String escape) {
    final StringBuffer buffer = new StringBuffer();
    for (String line in message.split('\n'))
      buffer.writeln('$escape$line$_reset');
    final String result = buffer.toString();
    // avoid introducing a new newline to the emboldened text
    return (!message.endsWith('\n') && result.endsWith('\n'))
        ? result.substring(0, result.length - 1)
        : result;
  }

  String clearScreen() => _clear;

  set singleCharMode(bool value) {
    // TODO(goderbauer): instead of trying to set lineMode and then catching
    // [_ENOTTY] or [_INVALID_HANDLE], we should check beforehand if stdin is
    // connected to a terminal or not.
    // (Requires https://github.com/dart-lang/sdk/issues/29083 to be resolved.)
    try {
      // The order of setting lineMode and echoMode is important on Windows.
      if (value) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      } else {
        stdin.lineMode = true;
        stdin.echoMode = true;
      }
    } on StdinException catch (error) {
      if (!_lineModeIgnorableErrors.contains(error.osError?.errorCode)) rethrow;
    }
  }

  /// Return keystrokes from the console.
  ///
  /// Useful when the console is in [singleCharMode].
  Stream<String> get onCharInput => stdin.transform(ASCII.decoder);
}
