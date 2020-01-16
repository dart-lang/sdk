// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  test('local variable', () {
    f() async* {
      var x = 42;
      yield x;
    }

    return expectList(f(), [42]);
  });

  test('constant variable', () {
    f() async* {
      const x = 42;
      yield x;
    }

    return expectList(f(), [42]);
  });

  test('function call', () {
    g() => 42;
    f() async* {
      yield g();
    }

    return expectList(f(), [42]);
  });

  test('unary operator', () {
    f() async* {
      var x = -42;
      yield -x;
    }

    return expectList(f(), [42]);
  });

  test('binary operator', () {
    f() async* {
      var x = 21;
      yield x + x;
    }

    return expectList(f(), [42]);
  });

  test('ternary operator', () {
    f() async* {
      var x = 21;
      yield x == 21 ? x + x : x;
    }

    return expectList(f(), [42]);
  });

  test('suffix post-increment', () {
    f() async* {
      var x = 42;
      yield x++;
    }

    return expectList(f(), [42]);
  });

  test('suffix pre-increment', () {
    f() async* {
      var x = 41;
      yield ++x;
    }

    return expectList(f(), [42]);
  });

  test('assignment', () {
    f() async* {
      var x = 37;
      yield x = 42;
    }

    return expectList(f(), [42]);
  });

  test('assignment op', () {
    f() async* {
      var x = 41;
      yield x += 1;
    }

    return expectList(f(), [42]);
  });

  test('await', () {
    f() async* {
      yield await Future.value(42);
    }

    return expectList(f(), [42]);
  });

  test('index operator', () {
    f() async* {
      var x = [42];
      yield x[0];
    }

    return expectList(f(), [42]);
  });

  test('function expression block', () {
    var o = Object();
    f() async* {
      yield () {
        return o;
      };
    }

    return f().first.then((v) {
      expect(v(), same(o));
    });
  });

  test('function expression arrow', () {
    var o = Object();
    f() async* {
      yield () => o;
    }

    return f().first.then((v) {
      expect(v(), same(o));
    });
  });

  test('function expression block async', () {
    var o = Object();
    f() async* {
      yield () async {
        return o;
      };
    }

    return f().first.then((v) => v()).then((v) {
      expect(v, same(o));
    });
  });

  test('function expression arrow async', () {
    var o = Object();
    f() async* {
      yield () async => o;
    }

    return f().first.then((v) => v()).then((v) {
      expect(v, same(o));
    });
  });

  test('function expression block async*', () {
    var o = Object();
    f() async* {
      yield () async* {
        yield o;
      };
    }

    return f().first.then((v) => v().first).then((v) {
      expect(v, same(o));
    });
  });
}
