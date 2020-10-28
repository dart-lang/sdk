// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Normally the CFE recognizes files in ..._2 directories and automatically
// opts those libraries out of NNBD.  Though this file will be copied to the
// build directory, which will cause the CFE no longer to automatically opt it
// out of NNBD, so we do that explicitly here.
// @dart=2.9

// Script used by the file_lock_test.dart test.

import "dart:io";

main(List<String> args) {
  File file = new File(args[0]);
  int start = null;
  int end = null;
  var mode = FileLock.exclusive;
  if (args[1] == 'SHARED') {
    mode = FileLock.shared;
  }
  if (args[2] != 'null') {
    start = int.parse(args[2]);
  }
  if (args[3] != 'null') {
    end = int.parse(args[3]);
  }
  var raf = file.openSync(mode: FileMode.write);
  try {
    raf.lockSync(mode, start, end);
    print('LOCK SUCCEEDED');
  } catch (e) {
    print('LOCK FAILED');
  } finally {
    raf.closeSync();
  }
}
