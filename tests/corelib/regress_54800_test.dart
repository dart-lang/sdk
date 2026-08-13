// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final match = RegExp(r' ([0-9]+) ').allMatches('  1234   ').single;
  print(match[1]!.runtimeType);
  Expect.equals(0x1234, int.parse(match[1]!, radix: 16));
}
