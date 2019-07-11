// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main(List<String> args) {
  var x = args.length;
  switch (x) {
    case 3:
      x = 4;
    case 5:
      break;
    case 6:
    case 7:
      if (args[0] == '') {
        break;
      } else {
        return;
      }
    case 4:
  }
}
