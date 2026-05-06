// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_local_variable

int opaqueVal() => int.parse('42');

void callClosure(void Function() func) {
  if (opaqueVal() == 1) func();
}

void foo42() {
  int a = opaqueVal();
  int b = opaqueVal();
  int c = opaqueVal();
  int d = opaqueVal();

  callClosure(() {
    print(a);
    print(b);
    print(d);
  });

  callClosure(() {
    print(b);
    print(c);
  });

  while (true) {
    var e = 50;
    var f = 60;
    var g = 70;

    callClosure(() {
      d += 41;
    });

    callClosure(() {
      e += 51;
      f += 61;
    });

    callClosure(() {
      f += 62;
      g += 72;
    });

    print(d);
    print(e);
    print(f);
    print(g);

    if (opaqueVal() == 1) break;
  }

  for (var i = 0; i < 10; ++i) {
    int h = opaqueVal();

    callClosure(() {
      print(h);
      print(i);
    });

    for (var j = 0; j < 10; ++j) {
      var k = 90;

      callClosure(() {
        j += 2;
        k += 91;
      });

      print(k);
    }
  }
}

void foo43() {
  var a = 10;
  var b = 20;
  var c = 30;
  var d = 40;

  callClosure(() {
    a += 11;
    b += 21;
  });

  callClosure(() {
    a += 12;
    c += 32;
  });

  callClosure(() {
    b += 23;
    c += 33;
  });

  callClosure(() {
    d += 44;
  });
}

// TODO: support instanitation of closures
/*
void foo44<S, T>() {
  callClosure(<U>() {
    callClosure(() {
      print(<T>[]);
      print(U);
    });
  });
}
*/

void foo45() {
  var a = 10;

  callClosure(() {
    a += 11;
  });

  if (opaqueVal() == 1) {
    var b = 20;

    callClosure(() {
      a += 12;
      b += 22;
    });
  }

  if (opaqueVal() == 1) {
    var c = 30;

    callClosure(() {
      a += 13;
      c += 33;
    });
  }
}

void foo46() {
  var a = opaqueVal();
  var b = opaqueVal();

  callClosure(() {
    callClosure(() {
      print(a);
    });
  });

  callClosure(() {
    callClosure(() {
      b += 11;
    });
  });
}

// TODO: support class type parameters via captured receiver
class A /*<T>*/ {
  List<int> aField = [
    for (int i = 0; i < 10; ++i)
      () {
        // print(T);
        print(i);
        i += 2;
        return i;
      }(),
  ];

  A.foo47();
}

void foo48() {
  if (opaqueVal() == 1) {
    var a = 10;

    callClosure(() {
      a += 11;
    });
  }

  if (opaqueVal() == 1) {
    var b = 20;

    callClosure(() {
      b += 22;
    });
  }
}

void foo49() {
  var a = opaqueVal();

  callClosure(() {
    a += 10;
  });

  for (var i = 0; i < 4; i++) {
    callClosure(() {
      a += 20;
      callClosure(() {
        a += 30;
      });
    });
  }
}

void main() {}
