// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "dart:io";

main() {
  if (Platform.operatingSystem != 'windows') return;
  var tempDir = new Directory('').createTempSync();
  var funkyDir = new Directory("${tempDir.path}/å");
  funkyDir.createSync();
  var funkyFile = new File('${funkyDir.path}/funky.bat');
  funkyFile.writeAsStringSync("""
@echo off
set SCRIPTDIR=%~dp0
%1 %2
      """);
  var options = new Options();
  var dart = options.executable;
  var scriptDir = new Path(options.script).directoryPath;
  var script = scriptDir.append('windows_environment_script.dart');
  Process.run('cmd',
              ['/c', funkyFile.path, dart, script.toNativePath()]).then((p) {
    if (0 != p.exitCode) throw "Exit code not 0";
    tempDir.deleteSync(recursive: true);
  });
}
