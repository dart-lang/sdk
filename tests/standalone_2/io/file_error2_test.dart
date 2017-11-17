// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in file I/O.
//
// Customize ASAN options for this test with 'allocator_may_return_null=1' as
// it tries to allocate a large memory buffer.
// Environment=ASAN_OPTIONS=handle_segv=0:detect_stack_use_after_return=1:allocator_may_return_null=1

import "dart:io";

import "file_error_test.dart" show createTestFile;
import "package:expect/expect.dart";

testReadSyncBigInt() {
  createTestFile((file, done) {
    var bigint = 9223372036854775807;
    var openedFile = file.openSync();
    Expect.throws(
        () => openedFile.readSync(bigint), (e) => e is FileSystemException);
    openedFile.closeSync();
    done();
  });
}

main() {
  testReadSyncBigInt();
}
