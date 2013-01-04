// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

main() {
  var scriptDir = Platform.environment['SCRIPTDIR'];
  Expect.isTrue(scriptDir.contains('å'));
  scriptDir = Platform.environment['ScriptDir'];
  Expect.isTrue(scriptDir.contains('å'));
  var str = new File('$scriptDir/funky.bat').readAsStringSync();
  Expect.isTrue(str.contains('%~dp0'));
}
