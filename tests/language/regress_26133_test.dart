// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } on TypeError {
    return true;
  }
}

var x = 'a';

Future<int> foo() async {
  return x;
}

main() {
  foo().then((_) {
    Expect.isFalse(isCheckedMode());
  }, onError: (e) {
    Expect.isTrue(isCheckedMode() && (e is TypeError));
  });
}
