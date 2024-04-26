// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var o1 = Object();
  var o2 = Object();
  var o3 = Object();
  var c1 = C(0);
  var c2 = C(0);

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
  Expect.allDistinct(List.generate(100, (_) => Object()));

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
    var list = List.generate(100, (_) => Object());
    list.add(list[0]);
    Expect.allDistinct(list, msg);
  });

  Expect.identical(o1, o1);
  Expect.allIdentical([]);
  Expect.allIdentical([o1]);
  Expect.allIdentical([o1, o1]);
  Expect.allIdentical([o1, o1, o1]);
  fails((msg) {
    Expect.identical(o1, o2, msg);
  });
  fails((msg) {
    Expect.allIdentical([o1, o2], msg);
  });
  fails((msg) {
    Expect.allIdentical([o1, o1, o2], msg);
  });
}

class C {
  final Object x;
  const C(this.x);
  @override
  int get hashCode => x.hashCode;
  @override
  bool operator ==(Object other) => other is C && x == other.x;
}

int _ctr = 0;

void fails(void Function(String msg) test) {
  var msg = "__#${_ctr++}#__"; // "Unique" name.
  try {
    test(msg);
    throw "Did not throw!";
  } on ExpectException catch (e) {
    if (!e.message.contains(msg)) {
      throw "Failure did not contain message: \"$msg\" not in ${e.message}";
    }
  }
}
