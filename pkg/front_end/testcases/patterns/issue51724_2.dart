// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final int value;
  String log = "";
  C(this.value);

  void clearLog() {
    log = "";
  }

  dynamic operator >(num other) {
    log += "C($value)>$other;";
    return this.value - other;
  }
}

String test1(C c) {
  switch (c) {
    case > 1:
      return "1";
    default:
      return "no match";
  }
}

main() {
  C c1 = C(0);
  C c2 = C(2);
  throws(() {
    test1(c1);
  });
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception';
}
