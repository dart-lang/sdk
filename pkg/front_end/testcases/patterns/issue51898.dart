// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  int d = 1;
  var x = false;
  switch (d) {
    case 1 when x = true:
      print('OK!');
  }
}
