// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'utils.dart';

Future _contentShellFuture;

/// Runs "tools/get_archive.py" to download and install Content Shell.
Future updateContentShell(String drtPath) {
  if (_contentShellFuture == null) {
    _contentShellFuture =
        new _RuntimeUpdater('Content Shell', 'tools/get_archive.py', 'drt')
            .update();
  }

  return _contentShellFuture;
}

class _RuntimeUpdater {
  String _name;
  String _script;
  String _option;

  _RuntimeUpdater(this._name, this._script, [this._option]);

  Future update() async {
    try {
      print('Updating $_name...');

      var arguments = [TestUtils.dartDirUri.resolve(_script).toFilePath()];

      if (_option != null) arguments.add(_option);

      var result = await Process.run('python', arguments);
      if (result.exitCode == 0) {
        print('Updated $_name.');
      } else {
        print('Failed to update $_name (exit code ${result.exitCode}):');
        print(result.stdout);
        print(result.stderr);
        exit(1);
      }
    } catch (error) {
      print("Error starting $_script process: $error");
      exit(1);
    }
  }
}
