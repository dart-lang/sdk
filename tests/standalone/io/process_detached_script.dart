// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Simple script hanging for testing a detached process.

import 'dart:isolate';

main() {
  new ReceivePort().listen(print);
}
