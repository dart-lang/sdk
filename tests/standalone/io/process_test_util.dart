// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getPlatformExecutableExtension() {
  var os = Platform.operatingSystem;
  if (os == 'windows') return '.exe';
  return '';  // Linux and Mac OS.
}

String getProcessTestFileName() {
  var extension = getPlatformExecutableExtension();
  var executable = new Options().executable;
  var dirIndex = executable.lastIndexOf('dart$extension');
  var buffer = new StringBuffer(executable.substring(0, dirIndex));
  buffer.add('process_test$extension');
  return buffer.toString();
}
