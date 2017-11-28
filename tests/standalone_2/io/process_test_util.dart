// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library process_test_util;

import "dart:io";

String getPlatformExecutableExtension() {
  var os = Platform.operatingSystem;
  if (os == 'windows') return '.exe';
  return ''; // Linux and Mac OS.
}

String getProcessTestFileName() {
  var extension = getPlatformExecutableExtension();
  var executable = Platform.executable;
  var dirIndex = executable.lastIndexOf('dart');
  var buffer = new StringBuffer(executable.substring(0, dirIndex));
  buffer.write('process_test$extension');
  return buffer.toString();
}
