// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart';
import 'package:expect/expect.dart';
import "dart:io";

main() {
  if (Platform.operatingSystem != 'windows') return;
  var tempDir = Directory.systemTemp.createTempSync('dart_windows_environment');
  var funkyDir = new Directory(join(tempDir.path, 'å'));
  funkyDir.createSync();
  var funkyFile = new File(join(funkyDir.path, 'funky.bat'));
  funkyFile.writeAsStringSync("""
@echo off
set SCRIPTDIR=%~dp0
%1 %2
      """);
  var dart = Platform.executable;
  var script =
      Platform.script.resolve('windows_environment_script.dart').toFilePath();
  Process.run('cmd', ['/c', funkyFile.path, dart, script]).then((p) {
    if (0 != p.exitCode) throw "Exit code not 0";
    tempDir.deleteSync(recursive: true);
  });
}
