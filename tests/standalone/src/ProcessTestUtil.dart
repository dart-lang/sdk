// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getProcessTestFileName() {
  var os = new Platform().operatingSystem();

  var outDir = '';
  if (os == 'linux') {
    outDir = 'out';
  } else if (os == 'macos') {
    outDir = 'xcodebuild';
  }

  var names = ['$outDir/Release_ia32/process_test',
               '$outDir/Debug_ia32/process_test'];

  for (var name in names) {
    if (new File(name).existsSync()) {
      return name;
    }
  }

  Expect.fail('Could not find the process_test program.');
}
