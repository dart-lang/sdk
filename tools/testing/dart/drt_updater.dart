// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("drt_updater");

#import("dart:io");
#import("dart:builtin");

class _DartiumUpdater {
  String name;
  String script;
  String option;

  bool isActive = false;
  bool updated = false;
  List onUpdated;

  Process _updatingProcess;

  _DartiumUpdater(this.name, this.script, [this.option = null]);

  void update() {
    if (!isActive) {
      isActive = true;
      print('Updating $name.');
      onUpdated = [() {updated = true;} ];
      _updatingProcess = Process.start('python', _getUpdateCommand);
      _updatingProcess.onExit = _onUpdatedHandler;
      _updatingProcess.onError = (error) {
        print("Error starting $script process: $error");
        _onUpdatedHandler(-1);  // Continue anyway.
      };
    }
  }

  List<String> get _getUpdateCommand() {
    String scriptPath = new Options().script.replaceAll('\\', '/');
    String toolsDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
    List<String> command = ['$toolsDir/$script'];
    if (null !== option) {
      command.add(option);
    }
    return command;
  }

  void _onUpdatedHandler(int exit_code) {
    print('$name updated ($exit_code)');
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
                                                   'get_drt.py');
    }
    return _dumpRenderTreeUpdater;
  } else if (runtime == 'dartium' && configuration['dartium'] == '') {
    // Download the default Dartium from Google Storage.
    if (_dartiumUpdater === null) {
      _dartiumUpdater = new _DartiumUpdater('Dartium Chrome', 'get_drt.py',
                                            '--dartium');
    }
    return _dartiumUpdater;
  } else {
    return null;
  }
}
