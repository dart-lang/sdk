// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the error message for a failing subtype test includes type
// arguments.

import 'package:expect/expect.dart';

class C<T, S> {}

bool inComplianceMode() {
  try {
    int i = ('hest' as dynamic);
  } catch (e) {
    return true;
  }
  return false;
}

main() {
  if (inComplianceMode()) {
    bool caught = false;
    try {
      C<String, String> x = (new C<C<int, String>, String>()) as dynamic;
    } catch (e) {
      String nameOfC = (C).toString();
      if (nameOfC.contains('<')) {
        nameOfC = nameOfC.substring(0, nameOfC.indexOf('<'));
      }
      String nameOfInt = (int).toString();
      String nameOfString = (String).toString();
      String expected =
          "'$nameOfC<$nameOfC<$nameOfInt, $nameOfString>, $nameOfString>'";
      Expect.isTrue(e.toString().contains(expected),
          'Expected "$expected" in the message: $e');
      print(e);
      caught = true;
    }
    Expect.isTrue(caught);
  }
}
