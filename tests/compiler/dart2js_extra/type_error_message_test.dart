// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C<T, S> {}

bool inCheckedMode() {
  try {
    int i = 'hest';
  } catch (e) {
    return true;
  }
  return false;
}

main() {
  if (inCheckedMode()) {
    bool caught = false;
    try {
      C<String, String> x = new C<C<int, String>, String>();
    } catch (e) {
      String expected = 'C<C<int, String>, String>';
      Expect.isTrue(e.toString().contains(expected),
                    'Expected "$expected" in the message');
      caught = true;
    }
    Expect.isTrue(caught);
  }
}
