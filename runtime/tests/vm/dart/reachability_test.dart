// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--new_gen_semi_max_size=1

import 'dart:_internal' show VMInternalsForTesting;
import 'dart:developer';
import 'package:expect/expect.dart';

var g_arr = List<List<int>?>.filled(1000, null);
void main() {
  var count = reachabilityBarrier;
  var l_arr = List<List<int>?>.filled(1000, null);
  for (int i = 0; i < 1000; i++) {
    l_arr[i] = List<int>.filled(100, 0);
  }
  for (int j = 0; j < 1000; j++) {
    for (int i = 0; i < 1000; i++) {
      g_arr[i] = l_arr[i];
    }
    for (int i = 0; i < 1000; i++) {
      l_arr[i] = List<int>.filled(100, 0);
    }
  }
  VMInternalsForTesting.collectAllGarbage();
  for (int j = 0; j < 1000; j++) {
    for (int i = 0; i < 1000; i++) {
      g_arr[i] = l_arr[i];
    }
    for (int i = 0; i < 1000; i++) {
      l_arr[i] = List<int>.filled(100, 0);
    }
  }
  VMInternalsForTesting.collectAllGarbage();
  Expect.isTrue(reachabilityBarrier > count);
}
