// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

void main() {
  test('plain', () {
    f() async* {
      yield 0;
    }

    return expectList(f(), [0]);
  });

  test('if-then-else', () {
    f(b) async* {
      if (b)
        yield 0;
      else
        yield 1;
    }

    return expectList(f(true), [0]).whenComplete(() {
      expectList(f(false), [1]);
    });
  });

  test('block', () {
    f() async* {
      yield 0;
      {
        yield 1;
      }
      yield 2;
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('labeled', () {
    f() async* {
      label1:
      yield 0;
    }

    return expectList(f(), [0]);
  });

  test('two labels on same line', () {
    f() async* {
      // DO NOT RUN dartfmt on this file. The labels should be on the same.
      // line. Originally VM issue #2238.
      label1: label2: yield 0;
    }

    return expectList(f(), [0]);
  });

  test('for-loop', () {
    f() async* {
      for (int i = 0; i < 3; i++) yield i;
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('for-in-loop', () {
    f() async* {
      for (var i in [0, 1, 2]) yield i;
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('await for-in-loop', () {
    f() async* {
      await for (var i in Stream.fromIterable([0, 1, 2])) yield i;
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('while-loop', () {
    f() async* {
      int i = 0;
      while (i < 3) yield i++;
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('do-while-loop', () {
    f() async* {
      int i = 0;
      do yield i++; while (i < 3);
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('try-catch-finally', () {
    f() async* {
      try {
        yield 0;
      } catch (e) {
        yield 1;
      } finally {
        yield 2;
      }
    }

    return expectList(f(), [0, 2]);
  });

  test('try-catch-finally 2', () {
    f() async* {
      try {
        yield throw 0;
      } catch (e) {
        yield 1;
      } finally {
        yield 2;
      }
    }

    return expectList(f(), [1, 2]);
  });

  test('switch-case', () {
    f(v) async* {
      switch (v) {
        case 0:
          yield 0;
          continue label1;
        label1:
        case 1:
          yield 1;
          break;
        default:
          yield 2;
      }
    }

    return expectList(f(0), [0, 1]).whenComplete(() {
      return expectList(f(1), [1]);
    }).whenComplete(() {
      return expectList(f(2), [2]);
    });
  });

  test('dead-code return', () {
    f() async* {
      return;
      yield 1;
    }

    return expectList(f(), []);
  });

  test('dead-code throw', () {
    f() async* {
      try {
        throw 0;
        yield 1;
      } catch (_) {}
    }

    return expectList(f(), []);
  });

  test('dead-code break', () {
    f() async* {
      while (true) {
        break;
        yield 1;
      }
    }

    return expectList(f(), []);
  });

  test('dead-code break 2', () {
    f() async* {
      label:
      {
        break label;
        yield 1;
      }
    }

    return expectList(f(), []);
  });

  test('dead-code continue', () {
    f() async* {
      do {
        continue;
        yield 1;
      } while (false);
    }

    return expectList(f(), []);
  });
}
