// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';

import '../logging.dart';

/// A mixin providing some utility functions for locating/working with
/// package_config.json files.
mixin PackageConfigUtils {
  /// Find the `package_config.json` file for the program being launched.
  ///
  /// TODO(dantup): Remove this once
  ///   https://github.com/dart-lang/sdk/issues/45530 is done as it will not be
  ///   necessary.
  File? findPackageConfigFile(String possibleRoot) {
    File? packageConfig;
    while (true) {
      packageConfig =
          File(path.join(possibleRoot, '.dart_tool', 'package_config.json'));

      // If this packageconfig exists, use it.
      if (packageConfig.existsSync()) {
        break;
      }

      final parent = path.dirname(possibleRoot);

      // If we can't go up anymore, the search failed.
      if (parent == possibleRoot) {
        packageConfig = null;
        break;
      }

      possibleRoot = parent;
    }

    return packageConfig;
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
    pidsToTerminate.forEach(
      (pid) => Process.killPid(pid, signal),
    );
  }
}

/// A mixin providing some utility functions for working with vm-service-info
/// files such as ensuring a temp folder exists to create them in, and waiting
/// for the file to become valid parsable JSON.
mixin VmServiceInfoFileUtils {
  /// Creates a temp folder for the VM to write the service-info-file into and
  /// returns the [File] to use.
  File generateVmServiceInfoFile() {
    // Using tmpDir.createTempory() is flakey on Windows+Linux (at least
    // on GitHub Actions) complaining the file does not exist when creating a
    // watcher. Creating/watching a folder and writing the file into it seems
    // to be reliable.
    final serviceInfoFilePath = path.join(
      Directory.systemTemp.createTempSync('dart-vm-service').path,
      'vm.json',
    );

    return File(serviceInfoFilePath);
  }

  /// Waits for [vmServiceInfoFile] to exist and become valid before returning
  /// the VM Service URI contained within.
  Future<Uri> waitForVmServiceInfoFile(
    Logger? logger,
    File vmServiceInfoFile,
  ) async {
    final completer = Completer<Uri>();
    late final StreamSubscription<FileSystemEvent> vmServiceInfoFileWatcher;

    Uri? tryParseServiceInfoFile(FileSystemEvent event) {
      final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
      if (uri != null && !completer.isCompleted) {
        vmServiceInfoFileWatcher.cancel();
        completer.complete(uri);
      }
    }

    vmServiceInfoFileWatcher = vmServiceInfoFile.parent
        .watch(events: FileSystemEvent.all)
        .where((event) => event.path == vmServiceInfoFile.path)
        .listen(
          tryParseServiceInfoFile,
          onError: (e) => logger?.call('Ignoring exception from watcher: $e'),
        );

    // After setting up the watcher, also check if the file already exists to
    // ensure we don't miss it if it was created right before we set the
    // watched up.
    final uri = _readVmServiceInfoFile(logger, vmServiceInfoFile);
    if (uri != null && !completer.isCompleted) {
      unawaited(vmServiceInfoFileWatcher.cancel());
      completer.complete(uri);
    }

    return completer.future;
  }

  /// Attempts to read VM Service info from a watcher event.
  ///
  /// If successful, returns the URI. Otherwise, returns null.
  Uri? _readVmServiceInfoFile(Logger? logger, File file) {
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      return Uri.parse(json['uri']);
    } catch (e) {
      // It's possible we tried to read the file before it was completely
      // written so ignore and try again on the next event.
      logger?.call('Ignoring error parsing vm-service-info file: $e');
    }
  }
}
