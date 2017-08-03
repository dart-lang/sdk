// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int i = 0;
  while (true) {
    try {
      if (i == 5) {
        break;
      }
    } catch (e, _) {} finally {
      print('Finally with i=$i');
    }
    print(i);
    i++;
  }
}
