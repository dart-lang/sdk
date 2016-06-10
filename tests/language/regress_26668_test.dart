// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests that the VM does not crash on weird corner cases of class Math.

import 'dart:async';

main() async {
  var myClass = new CustomClass<int>();
  await myClass.processData();
}

class CustomClass<T> {
  Future<T> processData() async {
    return 0;
  }
}

