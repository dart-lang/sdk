// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var x = 3;
  if (x == x) {
    print('good');
  } else {
    throw "x != x with x == 3";
  }
  dynamic y = x;
  if (true) {
    y = 10;
  }
  if (x == y) throw "3 == 10";
  if (y == true) throw "10 == true";
  if (y == "str") throw "3 == 'str'";
  if (true == 'str') throw "true == 'str'";
  if (true) y = false;
  if (y == false) {
    print('good');
  } else {
    throw "false != false";
  }
}
