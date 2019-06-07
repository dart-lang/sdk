// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
