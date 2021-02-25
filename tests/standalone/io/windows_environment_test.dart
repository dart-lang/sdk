// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=windows_environment_script.dart

import 'package:path/path.dart';
import 'package:expect/expect.dart';
import "dart:io";

main() {
  if (Platform.operatingSystem != 'windows') return;
  var tempDir = Directory.systemTemp.createTempSync('dart_windows_environment');
  var funkyDir = new Directory(join(tempDir.path, 'å'));
  funkyDir.createSync();
  var funkyFile = new File(join(funkyDir.path, 'funky.bat'));
  final vmOptions = Platform.executableArguments.join(' ');
  funkyFile.writeAsStringSync("""
@echo off
set SCRIPTDIR=%~dp0
echo %1 $vmOptions %2
%1 $vmOptions %2
      """);
  var dart = Platform.executable;
  var script =
      Platform.script.resolve('windows_environment_script.dart').toFilePath();
  Process.run('cmd', ['/c', funkyFile.path, dart, script]).then((p) {
    print('stdout: ${p.stdout}');
    print('stderr: ${p.stderr}');
    if (0 != p.exitCode) throw "Exit code not 0";
    tempDir.deleteSync(recursive: true);
  });
}
