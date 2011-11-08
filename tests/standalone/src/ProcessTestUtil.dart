// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getProcessTestFileName() {
  var names = ['out/Release_ia32/process_test',
               'out/Debug_ia32/process_test',
               'xcodebuild/Release_ia32/process_test',
               'xcodebuild/Debug_ia32/process_test',
               'Release_ia32/process_test.exe',
               'Debug_ia32/process_test.exe'];
  for (var name in names) {
    if (new File(name).existsSync()) {
      return name;
    }
  }
  Expect.fail('Could not find the process_test program.');
}
