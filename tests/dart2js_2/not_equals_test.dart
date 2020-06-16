// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

void main() {
  var x = 3;
  if (x != x) {
    throw "x != x with x == 3";
  } else {
    print('good');
  }
  var y = x;
  if (x != y) throw "3 != 3";

  var z = 4;
  if (x != z) {
    print('good');
  } else {
    throw 'x == z';
  }
}
