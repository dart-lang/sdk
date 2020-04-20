// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  List test = ["f", "5", "s", "6"];
  int length = test.length;
  for (int i = 0; i < length;) {
    var action = test[i++];
    switch (action) {
      case "f":
      case "s":
        action = test[i - 1];
        int value = int.parse(test[i++]);
        if (action == "f") {
          Expect.equals(5, value);
        } else {
          Expect.equals(6, value);
        }
        break;
    }
  }
}
