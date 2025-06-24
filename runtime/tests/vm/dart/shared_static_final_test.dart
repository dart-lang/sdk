// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--experimental-shared-data
//
import 'package:expect/expect.dart';

@pragma('vm:shared')
final int foo = 42;

main() {
  Expect.equals(42, foo);
}
