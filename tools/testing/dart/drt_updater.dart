// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(antonm): rename to something like test_runner_updater.

library drt_updater;

import "dart:async";
import "dart:io";

import "test_suite.dart";

typedef void Action();

class _DartiumUpdater {
  String name;
  String script;
  String option;

  bool isActive = false;
  bool updated = false;
  List<Action> onUpdated;

  Future<ProcessResult> _updatingProcess;

  _DartiumUpdater(this.name, this.script, [this.option = null]);

  void update() {
    if (!isActive) {
      isActive = true;
      print('Updating $name.');
      onUpdated = [
        () {
          updated = true;
        }
      ];
      _updatingProcess = Process.run('python', _getUpdateCommand);
      _updatingProcess.then(_onUpdatedHandler).catchError((e) {
        print("Error starting $script process: $e");
        // TODO(floitsch): should we print the stacktrace?
        return false;
      });
    }
  }

  List<String> get _getUpdateCommand {
    Uri updateScript = TestUtils.dartDirUri.resolve(script);
    List<String> command = [updateScript.toFilePath()];
    if (null != option) {
      command.add(option);
    }
    return command;
  }

  void _onUpdatedHandler(ProcessResult result) {
    if (result.exitCode == 0) {
      print('$name updated');
    } else {
      print('Failure updating $name');
      print('  Exit code: ${result.exitCode}');
      print(result.stdout);
      print(result.stderr);
      exit(1);
    }
    for (var callback in onUpdated) callback();
  }
}

_DartiumUpdater _contentShellUpdater;
_DartiumUpdater _dartiumUpdater;

_DartiumUpdater runtimeUpdater(Map configuration) {
  String runtime = configuration['runtime'];
  if (runtime == 'drt' && configuration['drt'] == '') {
    // Download the default content shell from Google Storage.
    if (_contentShellUpdater == null) {
      _contentShellUpdater =
          new _DartiumUpdater('Content Shell', 'tools/get_archive.py', 'drt');
    }
    return _contentShellUpdater;
  } else if (runtime == 'dartium' && configuration['dartium'] == '') {
    // Download the default Dartium from Google Storage.
    if (_dartiumUpdater == null) {
      _dartiumUpdater = new _DartiumUpdater(
          'Dartium Chrome', 'tools/get_archive.py', 'dartium');
    }
    return _dartiumUpdater;
  } else {
    return null;
  }
}
