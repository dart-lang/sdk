// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  List<String> whereWasI = [];
  int outer = 1;
  int inner = 0;
  switch (outer) {
    case 0:
      whereWasI.add("outer 0");
      break;
    case 1:
      () {
        switch (inner) {
          case 0:
            whereWasI.add("inner 0");
            continue fallThrough;
          fallThrough:
          case 1:
            whereWasI.add("inner 1");
        }
      }();
  }

  if (whereWasI.length != 2 ||
      whereWasI[0] != "inner 0" ||
      whereWasI[1] != "inner 1") {
    throw "Unexpected path.";
  }

  print(whereWasI);
}
