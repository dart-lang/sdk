// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

void main() {
  final List<int> codeUnits = [];
  final jsString = "hello".toJS.toDart;
  if (jsString == "hello") {
    for (int i = 0; i < 5; i += 1) {
      codeUnits.add(jsString.codeUnitAt(i));
    }
  }
  Expect.listEquals(codeUnits, [104, 101, 108, 108, 111]);
}
