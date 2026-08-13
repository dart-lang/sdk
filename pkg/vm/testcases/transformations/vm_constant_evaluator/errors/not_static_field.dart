// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that annotating a non-static field fails.

import 'dart:io';

class A {
  @pragma("vm:platform-const")
  final String os = Platform.operatingSystem;
}

void main() => null;
