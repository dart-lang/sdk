// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

main() {
  var scriptDir = Platform.environment['SCRIPTDIR'];
  if (!scriptDir.contains('å')) throw "scriptDir not containing character å";
  scriptDir = Platform.environment['ScriptDir'];
  if (!scriptDir.contains('å')) throw "scriptDir not containing character å";
  var str = new File('$scriptDir/funky.bat').readAsStringSync();
  if (!str.contains('%~dp0')) throw "str not containing dp0";
}
