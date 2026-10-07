// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dap/dap.dart';
import 'package:path/path.dart' as path;

import '../logging.dart';
import 'dart.dart';

/// A mixin providing some utility functions for locating/working with
/// package_config.json files.
mixin PackageConfigUtils {
  /// Find the `package_config.json` file for the program being launched.
  ///
  /// It is no longer necessary to call this method as the package config file
  /// is no longer used. URI lookups are done via the VM Service.
  @Deprecated('No longer necessary, URI lookups are done via VM Service')
  File? findPackageConfigFile(String possibleRoot) {
    // TODO(dantup): Remove this method after Flutter DA is updated not to use
    // it.
    return null;
  }
}

/// A mixin for tracking additional PIDs that can be shut down at the end of a
/// debug session.
mixin PidTracker {
  /// Process IDs to terminate during shutdown.
  ///
  /// This may be populated with pids from the VM Service to ensure we clean up
  /// properly where signals may not be passed through the shell to the
  /// underlying VM process.
  /// https://github.com/Dart-Code/Dart-Code/issues/907
  final pidsToTerminate = <int>{};

  /// Terminates all processes with the PIDs registered in [pidsToTerminate].
  void terminatePids(ProcessSignal signal) {
    // TODO(dantup): In Dart-Code DAP, we first try again with sigint and wait
    // for a few seconds before sending sigkill.
    for (final pid in pidsToTerminate) {
      // Skip any negative pids. On Linux, kill -1 means kill everything that
      // you can. See https://github.com/dart-lang/sdk/issues/55209 for details.
      if (pid >= 0) {
        Process.killPid(pid, signal);
      }
    }
  }
}

/// A mixin providing some utility functions for adapters that run tests and
/// provides some basic test reporting since otherwise nothing is printed when
/// using the JSON test reporter.
mixin TestAdapter on ColorUtils {
  static const _passSymbol = '✓';
  static const _failSymbol = '✖';
  static const _skippedSymbol = '!';

  /// Test names by testID.
  ///
  /// Stored in testStart so that they can be looked up in testDone.
  final Map<int, String> _testNames = {};

  void sendEvent(EventBody body, {String? eventType});
  void sendOutput(
    String category,
    String message, {
    int? variablesReference,
    @Deprecated(
      'parseStackFrames has no effect, stack frames are always parsed',
    )
    bool? parseStackFrames,
  });

  void sendTestEvents(Object testNotification) {
    // Send the JSON package as a raw notification so the client can interpret
    // the results (for example to populate a test tree).
    sendEvent(
      RawEventBody(testNotification),
      eventType: 'dart.testNotification',
    );

    // Additionally, send a textual output so that the user also has visible
    // output in the Debug Console.
    if (testNotification is Map<String, Object?>) {
      sendTestTextOutput(testNotification);
    }
  }

  int _testPassCount = 0, _testSkipCount = 0, _testFailCount = 0;
  int _lastTimeMs = 0;

  /// Sends textual output for tests, including pass/fail and test output.
  ///
  /// This is sent so that clients that do not handle the package:test JSON
  /// events still get some useful textual output in their Debug Consoles.
  void sendTestTextOutput(Map<String, Object?> testNotification) {
    _lastTimeMs = testNotification['time'] as int? ?? _lastTimeMs;
    switch (testNotification['type']) {
      case 'testStart':
        // When a test starts, capture its name by ID so we can get it back when
        // testDone comes.
        final test = testNotification['test'] as Map<String, Object?>?;
        if (test != null) {
          final testID = test['id'] as int?;
          final testName = test['name'] as String?;
          if (testID != null && testName != null) {
            _testNames[testID] = testName;
          }
        }

      case 'testDone':
        // Print the status of completed tests with a tick/cross.
        if (testNotification['hidden'] == true) {
          break;
        }
        final testID = testNotification['testID'] as int?;
        if (testID != null) {
          final testName = _testNames[testID];
          if (testName != null) {
            String symbol;
            if (testNotification['skipped'] == true) {
              symbol = yellow(_skippedSymbol);
              _testSkipCount++;
            } else if (testNotification['result'] == 'success') {
              symbol = green(_passSymbol);
              _testPassCount++;
            } else {
              symbol = red(_failSymbol);
              _testFailCount++;
            }
            sendOutput('console', _addSummary('$symbol $testName\n'));
          }
        }

      case 'print':
        final message = testNotification['message'] as String?;
        final messageType = testNotification['messageType'] as String?;

        // Don't send output for print messages that are skip reasons as a
        // result of running with `solo: true` / @soloTest because for suites
        // with many tests, this will bury the useful information in the debug
        // console between lots of repeated skip messages.
        //
        // The JSON messages will have still been forwarded, so the tests can
        // still show up as skipped in the UI, etc.
        const soloSkipMessage = 'Skip: does not have "solo"';
        if (messageType == 'skip' && message == soloSkipMessage) {
          break;
        }

        if (message != null) {
          sendOutput('stdout', '${message.trimRight()}\n');
        }

      case 'error':
        final error = testNotification['error'] as String?;
        final stack = testNotification['stackTrace'] as String?;
        if (error != null) {
          sendOutput('stderr', '${error.trimRight()}\n');
        }
        if (stack != null) {
          sendOutput('stderr', '${stack.trimRight()}\n');
        }

      // When done, send a summary.
      case 'done':
        if (_testSkipCount > 0) {
          final skipSummary = _testSkipCount == 1
              ? '$_testSkipCount skipped test.'
              : '$_testSkipCount skipped tests.';
          _sendTestOutputLine(yellow(skipSummary));
        }
        if (_testFailCount > 0) {
          _sendTestOutputLine(red('Some tests failed.'));
        } else if (_testSkipCount > 0) {
          _sendTestOutputLine('All other tests passed!');
        } else {
          _sendTestOutputLine('All tests passed!');
        }
    }
  }

  /// Sends a line of output with the test summary prefix, followed by a
  /// newline.
  void _sendTestOutputLine(String message) {
    sendOutput('console', _addSummary('$message\n'));
  }

  /// Adds a test summary to the start of [message] in the format matching the
  /// default `pkg:test` output:
  ///
  ///     mm:ss +a ~b -c: message
  ///
  /// Pass and skip counts (`~b -c`) are skipped if zero.
  String _addSummary(String message) {
    final output = StringBuffer();
    output
      ..write(_lastTimeString)
      ..write(' ')
      ..write(green('+$_testPassCount'));
    if (_testSkipCount > 0) {
      output
        ..write(' ')
        ..write(yellow('~$_testSkipCount'));
    }
    if (_testFailCount > 0) {
      output
        ..write(' ')
        ..write(red('-$_testFailCount'));
    }
    output.write(': $message');
    return output.toString();
  }

  /// Returns a representation of the last event time as `MM:SS`.
  String get _lastTimeString {
    final duration = Duration(milliseconds: _lastTimeMs);
    return "${duration.inMinutes.toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

/// A mixin providing some utility functions for working with vm-service-info
/// files such as ensuring a temp folder exists to create them in, and waiting
/// for the file to become valid parsable JSON.
mixin VmServiceInfoFileUtils on FileUtils {
  /// Creates a temp folder for the VM to write the service-info-file into and
  /// returns the [File] to use.
  File generateVmServiceInfoFile() {
    // Using tmpDir.createTemporary() is flakey on Windows+Linux (at least
    // on GitHub Actions) complaining the file does not exist when creating a
    // watcher. Creating/watching a folder and writing the file into it seems
    // to be reliable.
    final serviceInfoFilePath = path.join(
      normalizePath(
        Directory.systemTemp.createTempSync('dart-vm-service').path,
      ),
      'vm.json',
    );

    return File(serviceInfoFilePath);
  }

  /// Waits for [vmServiceInfoFile] to exist and become valid before returning
  /// the VM Service URI contained within.
  Future<Uri> waitForVmServiceInfoFile(Logger? logger, File vmServiceInfoFile) {
    final completer = Completer<Uri>();

    void tryParseServiceInfoFile(FileSystemEvent event) {
      final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
      if (uri != null && !completer.isCompleted) {
        _vmServiceInfoFileWatcher?.cancel();
        completer.complete(uri);
      }
    }

    _vmServiceInfoFileWatcher = vmServiceInfoFile.parent
        .watch()
        .where((event) => event.path == vmServiceInfoFile.path)
        .listen(
          tryParseServiceInfoFile,
          onError: (Object e) =>
              logger?.call('Ignoring exception from watcher: $e'),
        );

    // After setting up the watcher, also check if the file already exists to
    // ensure we don't miss it if it was created right before we set the
    // watched up.
    final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
    if (uri != null && !completer.isCompleted) {
      _vmServiceInfoFileWatcher?.cancel();
      completer.complete(uri);
    }

    return completer.future;
  }

  /// The watcher subscription that is monitoring for a VM Service file.
  ///
  /// Created in [waitForVmServiceInfoFile] and cancelled in
  /// [stopWaitingForVmServiceInfoFile].
  StreamSubscription<FileSystemEvent>? _vmServiceInfoFileWatcher;

  /// Stops watching for VM Service Info files that may have been started by
  /// [waitForVmServiceInfoFile].
  ///
  /// This should be called during shutdown in case the VM Service info file
  /// was never created.
  void stopWaitingForVmServiceInfoFile() {
    _vmServiceInfoFileWatcher?.cancel();
  }

  /// Attempts to read VM Service info from a watcher event.
  ///
  /// If successful, returns the URI. Otherwise, returns null.
  Uri? _readVmServiceInfoFile(Logger? logger, File file) {
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      if (json case {'uri': final String uri}) {
        return Uri.parse(uri);
      }
      return null;
    } catch (e) {
      // It's possible we tried to read the file before it was completely
      // written so ignore and try again on the next event.
      logger?.call('Ignoring error parsing vm-service-info file: $e');
      return null;
    }
  }
}

mixin ColorUtils {
  DartCommonLaunchAttachRequestArguments get args;

  /// Wraps [input] in ANSI escape and reset codes for [code], if supported.
  String _wrapWithAnsiCode(String input, int code) {
    return args.allowAnsiColorOutput ?? false
        ? '\u001B[${code}m$input\u001B[0m'
        : input;
  }

  /// Dims [input] when the client supports ANSI-colored output.
  String dim(String input) => _wrapWithAnsiCode(input, 2);

  /// Colors [input] red when the client supports ANSI-colored output.
  String red(String input) => _wrapWithAnsiCode(input, 31);

  /// Colors [input] green when the client supports ANSI-colored output.
  String green(String input) => _wrapWithAnsiCode(input, 32);

  /// Colors [input] yellow when the client supports ANSI-colored output.
  String yellow(String input) => _wrapWithAnsiCode(input, 33);
}

mixin FileUtils {
  /// Normalizes [filePath] to avoid issues with different casing of drive
  /// letters on Windows.
  ///
  /// Some clients like VS Code do their own normalization and may provide drive
  /// letters case different in some requests (such as breakpoints) to drive
  /// letters computed elsewhere (such in `Platform.resolvedExecutable`). When
  /// these do not match, breakpoints may not be hit.
  ///
  /// This is the case for the whole path, but drive letters are most commonly
  /// mismatched due to VS Code's explicit normalization.
  ///
  /// https://github.com/dart-lang/sdk/issues/32222
  String normalizePath(String filePath) {
    if (!Platform.isWindows || filePath.isEmpty || path.isRelative(filePath)) {
      return filePath;
    }
    return filePath.substring(0, 1).toUpperCase() + filePath.substring(1);
  }

  /// Normalizes a [Uri] via [normalizePath].
  Uri normalizeUri(Uri uri) {
    if (uri.isScheme('file')) {
      final filePath = uri.toFilePath();
      final normalizedPath = normalizePath(filePath);
      return Uri.file(normalizedPath);
    } else {
      return uri;
    }
  }
}
