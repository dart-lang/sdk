// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  throws(() {
    if (val(10) == 10 && guard(42)) {
      print('cast on conditions catches non-bools');
    }
  });
  throws(() {
    var r = (10,);
    if (r case (10,) when guard(42)) {
      print('missing cast on conditions allows this code to execute');
    }
  });
}

int val(int x) => x;
dynamic guard(dynamic x) => x;

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception';
}
