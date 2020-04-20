// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

isCheckedMode() {
  try {
    dynamic i = 1;
    String s = i;
    return false;
  } on TypeError {
    return true;
  }
}

dynamic x = 'a';

Future<int> foo() async {
  return x;
}

Future<int> bar() async => x;

main() {
  foo().then((_) {
    Expect.isFalse(isCheckedMode());
  }, onError: (e) {
    Expect.isTrue(isCheckedMode() && (e is TypeError));
  });
  bar().then((_) {
    Expect.isFalse(isCheckedMode());
  }, onError: (e) {
    Expect.isTrue(isCheckedMode() && (e is TypeError));
  });
}
