// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("drt_updater");

#import("dart:io");

#import("test_suite.dart");

class _DartiumUpdater {
  String name;
  String script;
  String option;

  bool isActive = false;
  bool updated = false;
  List onUpdated;

  Future<ProcessResult> _updatingProcess;

  _DartiumUpdater(this.name, this.script, [this.option = null]);

  void update() {
    if (!isActive) {
      isActive = true;
      print('Updating $name.');
      onUpdated = [() {updated = true;} ];
      _updatingProcess = Process.run('python', _getUpdateCommand);
      _updatingProcess.handleException((e) {
        print("Error starting $script process: $e");
        return false;
      });
      _updatingProcess.then(_onUpdatedHandler);
    }
  }

  List<String> get _getUpdateCommand {
    Path testScriptPath = new Path.fromNative(TestUtils.testScriptPath);
    Path updateScriptPath = testScriptPath.directoryPath.append(script);
    List<String> command = [updateScriptPath.toNativePath()];
    if (null !== option) {
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
    for (var callback in onUpdated ) callback();
  }
}

_DartiumUpdater _dumpRenderTreeUpdater;
_DartiumUpdater _dartiumUpdater;

_DartiumUpdater runtimeUpdater(Map configuration) {
  String runtime = configuration['runtime'];
  if (runtime == 'drt' && configuration['drt'] == '') {
    // Download the default DumpRenderTree from Google Storage.
    if (_dumpRenderTreeUpdater === null) {
      _dumpRenderTreeUpdater = new _DartiumUpdater('DumpRenderTree',
                                                   'get_archive.py', 'drt');
    }
    return _dumpRenderTreeUpdater;
  } else if (runtime == 'dartium' && configuration['dartium'] == '') {
    // Download the default Dartium from Google Storage.
    if (_dartiumUpdater === null) {
      _dartiumUpdater = new _DartiumUpdater('Dartium Chrome', 'get_archive.py',
                                            'dartium');
    }
    return _dartiumUpdater;
  } else {
    return null;
  }
}
