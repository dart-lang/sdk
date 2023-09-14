// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In http://dartbug.com/53078, `v` was erroneously optimized to `true`.

@pragma('dart2js:never-inline')
/*member: issue53078:function() {
  var x, i, v;
  for (x = 3, i = 0; i < 3; ++i) {
    v = x >= 3;
    if (i !== 0 && v)
      throw A.wrapException("Something is wrong");
    x = (v ? 0 : x) + 1;
  }
}*/
void issue53078() {
  const int y = 3;
  int x = y;
  for (int i = 0; i < 3; i++) {
    final v = x >= y;
    if (i != 0 && v) throw 'Something is wrong';
    if (v) {
      x = 0;
    }
    x++;
  }
}

/*member: main:ignore*/
main() {
  issue53078();
}
