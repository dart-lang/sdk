// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  test('simple stream', () {
    f(s) async {
      var r = 0;
      await for (var v in s) r += v;
      return r;
    }

    return f(mkStream(5)).then((v) {
      expect(v, equals(10));
    });
  });

  test('simple stream, await', () {
    f(s) async {
      var r = 0;
      await for (var v in s) r += await Future.microtask(() => v);
      return r;
    }

    return f(mkStream(5)).then((v) {
      expect(v, equals(10));
    });
  });

  test('simple stream - take', () {
    f(s) async {
      var r = 0;
      await for (var v in s.take(5)) r += v;
      return r;
    }

    return f(mkStream(10)).then((v) {
      expect(v, equals(10));
    });
  });

  test('simple stream reyield', () {
    f(s) async* {
      var r = 0;
      await for (var v in s) yield r += v;
    }

    return expectList(f(mkStream(5)), [0, 1, 3, 6, 10]);
  });

  test('simple stream, await, reyield', () {
    f(s) async* {
      var r = 0;
      await for (var v in s) yield r += await Future.microtask(() => v);
    }

    return expectList(f(mkStream(5)), [0, 1, 3, 6, 10]);
  });

  test('simple stream - take, reyield', () {
    f(s) async* {
      var r = 0;
      await for (var v in s.take(5)) yield r += v;
    }

    return expectList(f(mkStream(10)), [0, 1, 3, 6, 10]);
  });

  test('nested', () {
    f() async {
      var r = 0;
      await for (var i in mkStream(5)) {
        await for (var j in mkStream(3)) {
          r += i * j;
        }
      }
      return r;
    }

    return f().then((v) {
      expect(v, equals((1 + 2 + 3 + 4) * (1 + 2)));
    });
  });

  test('nested, await', () {
    f() async {
      var r = 0;
      await for (var i in mkStream(5)) {
        await for (var j in mkStream(3)) {
          r += await Future.microtask(() => i * j);
        }
      }
      return r;
    }

    return f().then((v) {
      expect(v, equals((1 + 2 + 3 + 4) * (1 + 2)));
    });
  });

  test('nested, await * 2', () {
    f() async {
      var r = 0;
      await for (var i in mkStream(5)) {
        var ai = await Future.microtask(() => i);
        await for (var j in mkStream(3)) {
          r += await Future.microtask(() => ai * j);
        }
      }
      return r;
    }

    return f().then((v) {
      expect(v, equals((1 + 2 + 3 + 4) * (1 + 2)));
    });
  });

  test('await pauses loop', () {
    var sc;
    var i = 0;
    void send() {
      if (i == 5) {
        sc.close();
      } else {
        sc.add(i++);
      }
    }

    sc = StreamController(onListen: send, onResume: send);
    f(s) async {
      var r = 0;
      await for (var i in s) {
        r += await Future.delayed(ms * 10, () => i);
      }
      return r;
    }

    return f(sc.stream).then((v) {
      expect(v, equals(10));
    });
  });
}
