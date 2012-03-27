// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("drt_updater");

#import("dart:io");
#import("dart:builtin");

class DumpRenderTreeUpdater {
  static bool isActive = false;
  static bool updated = false;
  static List onUpdated;

  static Process _updatingProcess;

  static void update() {
    if (!isActive) {
      isActive = true;
      print('Updating DumpRenderTree.');
      onUpdated = [() {updated = true;} ];
      _updatingProcess = new Process.start('python', [_getDrtPath]);
      _updatingProcess.onExit = _onUpdatedHandler;
      _updatingProcess.onError = (error) {
        print("Error starting get_drt.py process: $error");
        _onUpdatedHandler(-1);  // Continue anyway.
      };
    }
  }

  static String get _getDrtPath() {
    String scriptPath = new Options().script.replaceAll('\\', '/');
    String toolsDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
    return '$toolsDir/get_drt.py';
  }

  static void _onUpdatedHandler(int exit_code) {
    print('DumpRenderTree updated ($exit_code)');
    for (var callback in onUpdated ) callback();
  }
}
