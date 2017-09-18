// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

int main() {
  var a = [1, 2, 3][2];
  switch (a) {
    case 0.0: //           //# 01: compile-time error
      print("illegal"); // //# 01: continued
    case 1:
      print("OK");
  }
}
