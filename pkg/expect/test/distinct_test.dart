// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var o1 = new Object();
  var o2 = new Object();
  var o3 = new Object();
  var c1 = new C(0);
  var c2 = new C(0);

  // Successful checks.
  Expect.notIdentical(o1, o2, "msg");

  Expect.equals(c1, c2);
  Expect.notIdentical(c1, c2, "msg");

  Expect.notIdentical([1], [1], "msg");

  Expect.allDistinct([], "msg");
  Expect.allDistinct([o1], "msg");
  Expect.allDistinct([
    o1,
    o2,
    c1,
    c2,
    [1]
  ], "msg");
  Expect.allDistinct(new List.generate(100, (_) => new Object()));

  fails((msg) {
    Expect.notIdentical(o1, o1, msg);
  });

  fails((msg) {
    var list = [1];
    Expect.notIdentical(list, list, msg);
  });

  fails((msg) {
    Expect.allDistinct([o1, o1], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o1, o1, o1], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o1, o2, o3], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o2, o1, o3], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o2, o3, o1], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o2, o2, o3], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o2, o3, o2], msg);
  });
  fails((msg) {
    Expect.allDistinct([o1, o2, o3, o3], msg);
  });
  fails((msg) {
    var list = new List.generate(100, (_) => new Object());
    list.add(list[0]);
    Expect.allDistinct(list, msg);
  });
}

class C {
  final x;
  const C(this.x);
  int get hashCode => x.hashCode;
  bool operator ==(Object other) => other is C && x == other.x;
}

int _ctr = 0;
fails(test(msg)) {
  var msg = "__#${_ctr++}#__"; // "Unique" name.
  try {
    test(msg);
    throw "Did not throw!";
  } on ExpectException catch (e) {
    if (e.message.indexOf(msg) < 0) {
      throw "Failure did not contain message: \"$msg\" not in ${e.message}";
    }
  }
}
