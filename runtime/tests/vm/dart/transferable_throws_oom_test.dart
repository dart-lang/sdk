// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Customize ASAN options for this test with 'allocator_may_return_null=1' as
// it tries to allocate a large memory buffer.
// Environment=ASAN_OPTIONS=handle_segv=0:detect_stack_use_after_return=1:allocator_may_return_null=1
// Environment=LSAN_OPTIONS=handle_segv=0:detect_stack_use_after_return=1:allocator_may_return_null=1
// Environment=MSAN_OPTIONS=handle_segv=0:detect_stack_use_after_return=1:allocator_may_return_null=1
// Environment=TSAN_OPTIONS=handle_segv=0:detect_stack_use_after_return=1:allocator_may_return_null=1

// Test that ensures correct exception when running out of memory for
// really large transferable.

import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';

import "package:expect/expect.dart";

main() {
  // Attempt to create total 1tb uint8list which should fail on 32 and 64-bit
  // platforms.
  final bytes100MB = Uint8List(100 * 1024 * 1024);
  final total1TB = List<Uint8List>.filled(10000, bytes100MB);
  // Try to make a 1 TB transferable.
  Expect.throws(() => TransferableTypedData.fromList(total1TB));
}
