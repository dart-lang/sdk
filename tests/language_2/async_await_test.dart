// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_await_test;

import "package:unittest/unittest.dart";
import "dart:async";

main() {
  bool assertionsEnabled = false;
  assert((assertionsEnabled = true));

  group("basic", () {
    test("async w/o await", () {
      f() async {
        return id(42);
      }

      return expect42(f());
    });

    test("async waits", () {
      // Calling an "async" function won't do anything immediately.
      var result = [];
      f() async {
        result.add(1);
        return id(42);
      }

      ;
      var future = f();
      result.add(0);
      return future.whenComplete(() {
        expect(result, equals([0, 1]));
      });
    });

    test("async throws", () {
      f() async {
        throw "err";
        return id(42);
      }

      return throwsErr(f());
    });

    test("await future", () {
      f() async {
        var v = await new Future.value(42);
        return v;
      }

      ;
      return expect42(f());
    });

    test("await value", () {
      f() async {
        var v = await id(42);
        return v;
      }

      ;
      return expect42(f());
    });

    test("await null", () {
      f() async {
        var v = await null;
        expect(v, equals(null));
      }

      ;
      return f();
    });

    test("await await", () {
      f() async {
        return await await new Future.value(42);
      }

      return expect42(f());
    });

    test("await fake value future", () {
      f() async {
        return await new FakeValueFuture(42);
      }

      return expect42(f());
    });

    test("await fake error future", () {
      f() async {
        return await new FakeErrorFuture("err");
      }

      return throwsErr(f());
    });

    test("await value is delayed", () {
      f() async {
        bool x = false;
        scheduleMicrotask(() {
          x = true;
        });
        var y = await true;
        expect(x, equals(y));
      }

      return f();
    });

    test("await throw", () {
      f() async {
        await (throw "err"); // Check grammar: Are parentheses necessary?
        return id(42);
      }

      return throwsErr(f());
    });

    test("throw before await", () {
      f() async {
        var x = throw "err";
        await x; // Check grammar: Are parentheses necessary?
        return id(42);
      }

      return throwsErr(f());
    });

    if (assertionsEnabled) {
      test("assert before await", () {
        f(v) async {
          assert(v == 87);
          return await new Future.microtask(() => 42);
        }

        return f(42).then((_) {
          fail("assert didn't throw");
        }, onError: (e, s) {
          expect(e is AssertionError, isTrue);
        });
      });

      test("assert after await", () {
        f(v) async {
          var x = await new Future.microtask(() => 42);
          assert(v == 87);
          return x;
        }

        return f(42).then((_) {
          fail("assert didn't throw");
        }, onError: (e, s) {
          expect(e is AssertionError, isTrue);
        });
      });
    }

    test("async await error", () {
      f() async {
        await new Future.error("err");
        return id(42);
      }

      return throwsErr(f());
    });

    test("async flattens futures", () {
      f() async {
        return new Future.value(42); // Not awaited.
      }

      ;
      return f().then((v) {
        expect(v, equals(42)); // And not a Future with value 42.
      });
    });

    test("async flattens futures, error", () {
      f() async {
        return new Future.error("err"); // Not awaited.
      }

      ;
      return throwsErr(f());
    });

    test("await for", () {
      f(Stream<int> s) async {
        int i = 0;
        await for (int v in s) {
          i += v;
        }
        return i;
      }

      return f(mkStream()).then((v) {
        expect(v, equals(45)); // 0 + 1 + ... + 9
      });
    });

    test("await for w/ await", () {
      f(Stream<int> s) async {
        int i = 0;
        await for (int v in s) {
          i += await new Future.value(v);
        }
        return i;
      }

      return f(mkStream()).then((v) {
        expect(v, equals(45)); // 0 + 1 + ... + 9
      });
    });

    test("await for empty", () {
      f(Stream<int> s) async {
        int v = 0;
        await for (int i in s) {
          v += i;
        }
        return v;
      }

      var s = (new StreamController<int>()..close()).stream;
      return f(s).then((v) {
        expect(v, equals(0));
      });
    });

    if (assertionsEnabled) {
      test("await for w/ await, asseert", () {
        f(Stream<int> s) async {
          int i = 0;
          await for (int v in s) {
            i += await new Future.microtask(() => v);
            assert(v < 8);
          }
          return i;
        }

        return f(mkStream()).then((v) {
          fail("assert didn't throw");
        }, onError: (e, s) {
          expect(e is AssertionError, isTrue);
        });
      });
    }
  });

  group("for", () {
    test("await in for-loop", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i++) {
          v += await new Future.value(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * id(42)));
      });
    });

    test("await in for-init", () {
      f() async {
        int v = 0;
        for (int i = await new Future.value(42); i >= 0; i -= 10) {
          v += 10;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * 5));
      });
    });

    test("await in for-test", () {
      f() async {
        int v = 0;
        for (int i = 0; i < await new Future.value(42); i += 10) {
          v += 10;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * 5));
      });
    });

    test("await in for-incr", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 100; i += await new Future.value(42)) {
          v += 10;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * 3));
      });
    });

    test("await err in for-loop", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i++) {
          v += await new Future.error("err");
        }
        return v;
      }

      return throwsErr(f());
    });

    test("await err in for-init", () {
      f() async {
        int v = 0;
        for (int i = await new Future.error("err"); i >= 0; i -= 10) {
          v += 10;
        }
        return v;
      }

      return throwsErr(f());
    });

    test("await err in for-test", () {
      f() async {
        int v = 0;
        for (int i = 0; i < await new Future.error("err"); i += 10) {
          v += 10;
        }
        return v;
      }

      return throwsErr(f());
    });

    test("await err in for-incr", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 100; i += await new Future.error("err")) {
          v += 10;
        }
        return v;
      }

      return throwsErr(f());
    });

    test("await in empty for-loop", () {
      f() async {
        int v = 0;
        for (int i = 0; i > 0; i += 1) {
          v += await new Future.value(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(0));
      });
    });

    test("await in empty for-loop 2", () {
      f() async {
        int v = 0;
        for (int i = 0; i > 0; i += await new Future.value(1)) {
          v += 1;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(0));
      });
    });

    test("break before await in for-loop", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i += 1) {
          if (i == 2) break;
          v += await new Future.value(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 2));
      });
    });

    test("break before await in for-loop 2", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i += await new Future.value(1)) {
          if (i == 2) break;
          v += id(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 2));
      });
    });

    test("continue before await", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i += 1) {
          if (i == 2) continue;
          v += await new Future.value(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });

    test("continue after await", () {
      f() async {
        int v = 0;
        for (int i = 0; i < 10; i += 1) {
          var j = await new Future.value(42);
          if (i == 2) continue;
          v += j;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });
  });

  group("while", () {
    test("await in while-loop", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          v += await new Future.value(42);
          i++;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * id(42)));
      });
    });

    test("await in while-test", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < await new Future.value(42)) {
          v += 10;
          i += 10;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * 5));
      });
    });

    test("await err in loop", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          v += await new Future.error("err");
          i++;
        }
        return v;
      }

      return throwsErr(f());
    });

    test("await err in test", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < await new Future.error("err")) {
          v += 10;
          i += 10;
        }
        return v;
      }

      return throwsErr(f());
    });

    test("break before await", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          if (i == 2) break;
          v += await new Future.value(42);
          i += 1;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 2));
      });
    });

    test("break after await", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          v += await new Future.value(42);
          if (i == 2) break;
          i += 1;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 3));
      });
    });

    test("continue before await", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          i += 1;
          if (i == 2) continue;
          v += await new Future.value(42);
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });

    test("continue after await", () {
      f() async {
        int v = 0;
        int i = 0;
        while (i < 10) {
          i += 1;
          int j = await new Future.value(42);
          if (i == 2) continue;
          v += j;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });
  });

  group("do-while", () {
    test("await in loop", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          v += await new Future.value(42);
          i++;
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * id(42)));
      });
    });

    test("await in test", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          v += 10;
          i += 10;
        } while (i < await new Future.value(42));
        return v;
      }

      return f().then((v) {
        expect(v, equals(10 * 5));
      });
    });

    test("await err in loop", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          v += await new Future.error("err");
          i++;
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("await err in test", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          v += 10;
          i += 10;
        } while (i < await new Future.error("err"));
        return v;
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("break before await", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          if (i == 2) break;
          v += await new Future.value(42);
          i += 1;
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 2));
      });
    });

    test("break after await", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          v += await new Future.value(42);
          if (i == 2) break;
          i += 1;
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 3));
      });
    });

    test("continue before await", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          i += 1;
          if (i == 2) continue;
          v += await new Future.value(42);
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });

    test("continue after await", () {
      f() async {
        int v = 0;
        int i = 0;
        do {
          i += 1;
          int j = await new Future.value(42);
          if (i == 2) continue;
          v += j;
        } while (i < 10);
        return v;
      }

      return f().then((v) {
        expect(v, equals(42 * 9));
      });
    });
  });

  group("for-in", () {
    test("await in for-in", () {
      f() async {
        var v = 0;
        for (var fut in [1, 2, 3].map((v) => new Future.value(v))) {
          v += await fut;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(6));
      });
    });

    test("await in for-in iterable", () {
      f() async {
        var v = 0;
        for (var i in await new Future.value([1, 2, 3])) {
          v += i;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(6));
      });
    });

    test("await err in for-in", () {
      f() async {
        var v = 0;
        for (var fut in [1, 2, 3].map(
            (v) => (v != 1) ? new Future.value(v) : new Future.error("err"))) {
          v += await fut;
        }
        return v;
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("await err in for-in iterable", () {
      f() async {
        var v = 0;
        for (var i in await new Future.error("err")) {
          v += i;
        }
        return v;
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("break before await in for-in", () {
      f() async {
        var v = 0;
        for (var fut in [1, 2, 3].map((v) => new Future.value(v))) {
          if (v == 3) break;
          v += await fut;
        }
        return v;
      }

      return f().then((v) {
        expect(v, equals(3));
      });
    });
  });

  group("try-catch", () {
    test("try-no-catch", () {
      f() async {
        try {
          return await id(42);
        } catch (e) {
          return 37;
        }
      }

      return expect42(f());
    });

    test("await in body", () {
      f() async {
        try {
          await new Future.error(42);
        } catch (e) {
          return e;
        }
      }

      return expect42(f());
    });

    test("throw before await in body", () {
      int i = id(0);
      f() async {
        try {
          if (i >= 0) throw id(42);
          return await new Future.value(10);
        } catch (e) {
          return e;
        }
      }

      return expect42(f());
    });

    test("try-catch await in catch", () {
      f() async {
        try {
          throw id(42);
        } catch (e) {
          return await new Future.value(e);
        }
      }

      return expect42(f());
    });

    test("try-catch await error in catch", () {
      f() async {
        try {
          throw id(42);
        } catch (e) {
          await new Future.error("err");
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("try-catch-rethrow", () {
      f() async {
        try {
          await new Future.error("err");
        } catch (e) {
          if (e == id(42)) return;
          rethrow;
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });
  });

  group("try-finally", () {
    test("await in body", () {
      f() async {
        try {
          return await new Future.value(42);
        } finally {
          // Don't do anything.
        }
      }

      return expect42(f());
    });

    test("await in finally", () {
      var x = 0;
      f() async {
        try {
          return id(42);
        } finally {
          x = await new Future.value(37);
        }
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(37));
      });
    });

    test("await err in body", () {
      f() async {
        try {
          return await new Future.error("err");
        } finally {
          // Don't do anything.
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("await err in finally", () {
      f() async {
        try {
          return id(42);
        } finally {
          await new Future.error("err");
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("await err in both", () {
      f() async {
        try {
          await new Future.error("not err");
        } finally {
          await new Future.error("err");
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
      });
    });

    test("await err in body, override in finally", () {
      f() async {
        try {
          return await new Future.error("err");
        } finally {
          return id(42);
        }
      }

      return expect42(f());
    });

    test("await in body, override in finally", () {
      f() async {
        label:
        try {
          return await new Future.value(37);
        } finally {
          break label;
        }
        return id(42);
      }

      return expect42(f());
    });

    test("await, override in finally", () {
      var x = 0;
      f() async {
        label:
        try {
          return 87;
        } finally {
          x = await new Future.value(37);
          break label;
        }
        return id(42);
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(37));
      });
    });

    test("throw in body, await, override in finally 3", () {
      var x = 0;
      f() async {
        label:
        try {
          throw "err";
        } finally {
          x = await new Future.value(37);
          break label;
        }
        return id(42);
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(37));
      });
    });

    test("await err in body, override in finally 2", () {
      f() async {
        label:
        try {
          return await new Future.error("err");
        } finally {
          break label;
        }
        return id(42);
      }

      return expect42(f());
    });

    test("await in body, no-exit in finally", () {
      f() async {
        for (int i = 0; i < 10; i++) {
          try {
            return await i;
          } finally {
            continue;
          }
        }
        return id(42);
      }

      return expect42(f());
    });

    test("no-exit after await in finally", () {
      f() async {
        int i = 0;
        for (; i < 10; i++) {
          try {
            break;
          } finally {
            await new Future.value(42);
            continue;
          }
        }
        return id(i);
      }

      return f().then((v) {
        expect(v, equals(10));
      });
    });

    test("exit after continue, await in finally", () {
      f() async {
        int i = 0;
        for (; i < 10; i++) {
          try {
            continue;
          } finally {
            await new Future.value(42);
            break;
          }
        }
        return id(i);
      }

      return f().then((v) {
        expect(v, equals(0));
      });
    });

    test("no-exit before await in finally 2", () {
      f() async {
        for (int i = 0; i < 10; i++) {
          try {
            return i;
          } finally {
            if (i >= 0) continue;
            await new Future.value(42);
          }
        }
        return id(42);
      }

      return expect42(f());
    });

    test("no-exit after await in finally", () {
      f() async {
        for (int i = 0; i < 10; i++) {
          try {
            return i;
          } finally {
            await new Future.value(42);
            continue;
          }
        }
        return id(42);
      }

      return expect42(f());
    });

    test("nested finallies", () {
      var x = 0;
      f() async {
        try {
          try {
            return 42;
          } finally {
            x = await new Future.value(37);
          }
        } finally {
          x += await new Future.value(37);
        }
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(74));
      });
    });

    test("nested finallies 2", () {
      var x = 0;
      f() async {
        label:
        try {
          try {
            break label;
          } finally {
            x = await new Future.value(37);
          }
        } finally {
          x += await new Future.value(37);
        }
        return 42;
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(74));
      });
    });

    test("nested finallies 3", () {
      var x = 0;
      f() async {
        label:
        try {
          try {
            break label;
          } finally {
            return await new Future.value(42);
          }
        } finally {
          break label;
        }
        return 42;
      }

      return expect42(f());
    });

    test("nested finallies, throw", () {
      var x = 0;
      f() async {
        try {
          try {
            throw "err";
          } finally {
            x = await new Future.value(37);
          }
        } finally {
          x += await new Future.value(37);
        }
      }

      return f().then((v) {
        fail("didn't throw");
      }, onError: (e) {
        expect(e, equals("err"));
        expect(x, equals(2 * 37));
      });
    });
  });

  group("try-catch-finally", () {
    test("await in body", () {
      f() async {
        try {
          return await new Future.value(42);
        } catch (e) {
          throw null;
        } finally {
          if (id(42) == id(10)) return 10;
        }
      }

      return expect42(f());
    });

    test("await in catch, not hit", () {
      f() async {
        try {
          return id(42);
        } catch (e) {
          await new Future.error("err");
        } finally {
          if (id(42) == id(10)) return 10;
        }
      }

      return expect42(f());
    });

    test("await in catch, hit", () {
      f() async {
        try {
          return throw id(42);
        } catch (e) {
          return await new Future.value(e);
        } finally {
          if (id(42) == id(10)) return 10;
        }
      }

      return expect42(f());
    });

    test("await in finally", () {
      var x = 0;
      f() async {
        try {
          return id(42);
        } catch (e) {
          throw null;
        } finally {
          x = await new Future.value(37);
          if (id(42) == id(10)) return 10;
        }
      }

      return f().then((v) {
        expect(v, equals(42));
        expect(x, equals(37));
      });
    });
  });

  group("switch", () {
    test("await in expression", () {
      f(v) async {
        switch (await new Future.value(v)) {
          case 1:
            return 1;
          case 2:
            return 42;
          default:
            return 3;
        }
        return null;
      }

      return expect42(f(2));
    });

    test("await err in expression", () {
      f(v) async {
        switch (await new Future.error("err")) {
          case 1:
            return 1;
          case 2:
            return 42;
          default:
            return 3;
        }
        return null;
      }

      return throwsErr(f(2));
    });

    test("await in case", () {
      f(v) async {
        switch (v) {
          case 1:
            return 1;
          case 2:
            return await new Future.value(42);
          default:
            return 3;
        }
        return null;
      }

      return expect42(f(2));
    });

    test("await err in case", () {
      f(v) async {
        switch (v) {
          case 1:
            return 1;
          case 2:
            return await new Future.error("err");
          default:
            return 3;
        }
        return null;
      }

      return throwsErr(f(2));
    });
    // TODO(jmesserly): restore this when we fix
    // https://github.com/dart-lang/dev_compiler/issues/263
    /*test("continue before await in case", () {
      f(v) async {
        switch (v) {
          label:
          case 1: return 42;
          case 2:
            if (v <= 2) continue label;
            return await new Future.value(10);
          default: return 3;
        }
        return null;
      }
      return expect42(f(2));
    });

    test("continue after await in case", () {
      f(v) async {
        switch (v) {
          label:
          case 1: return 42;
          case 2:
            await new Future.value(10);
            continue label;
          default: return 3;
        }
        return null;
      }
      return expect42(f(2));
    });*/
  });

  group("if", () {
    test("await in test", () {
      f(v) async {
        if (await new Future.value(v)) {
          return 42;
        } else {
          return 37;
        }
      }

      return expect42(f(true));
    });

    test("await err in test", () {
      f(v) async {
        if (await new Future.error("err")) {
          return 42;
        } else {
          return 37;
        }
      }

      return throwsErr(f(true));
    });

    test("await in then", () {
      f(v) async {
        if (v) {
          return await new Future.value(42);
        }
        return 37;
      }

      return expect42(f(true));
    });

    test("await err in then", () {
      f(v) async {
        if (v) {
          return await new Future.error("err");
        }
        return 37;
      }

      return throwsErr(f(true));
    });

    test("await in then with else", () {
      f(v) async {
        if (v) {
          return await new Future.value(42);
        } else {
          return 87;
        }
        return 37;
      }

      return expect42(f(true));
    });

    test("await err in then with else", () {
      f(v) async {
        if (v) {
          return await new Future.error("err");
        } else {
          return 87;
        }
        return 37;
      }

      return throwsErr(f(true));
    });

    test("await in else", () {
      f(v) async {
        if (v) {
          return 37;
        } else {
          return await new Future.value(42);
        }
        return 87;
      }

      return expect42(f(false));
    });

    test("await err in else", () {
      f(v) async {
        if (v) {
          return 37;
        } else {
          return await new Future.error("err");
        }
        return 87;
      }

      return throwsErr(f(false));
    });

    test("await in else-if test", () {
      f(v) async {
        if (v) {
          return 37;
        } else if (!await new Future.value(v)) {
          return 42;
        } else {
          return 37;
        }
        return 87;
      }

      return expect42(f(false));
    });

    test("await in else-if then", () {
      f(v) async {
        if (v) {
          return 37;
        } else if (!v) {
          return await new Future.value(42);
        } else {
          return 37;
        }
        return 87;
      }

      return expect42(f(false));
    });
  });

  group("conditional operator", () {
    test("await in test", () {
      f(v) async {
        return (await new Future.value(v)) ? 42 : 37;
      }

      return expect42(f(true));
    });

    test("await err in test", () {
      f(v) async {
        return (await new Future.error("err")) ? 42 : 37;
      }

      return throwsErr(f(true));
    });

    test("await in then", () {
      f(v) async {
        return v ? (await new Future.value(42)) : 37;
      }

      return expect42(f(true));
    });

    test("await err in then", () {
      f(v) async {
        return v ? (await new Future.error("err")) : 37;
      }

      return throwsErr(f(true));
    });

    test("await in else", () {
      f(v) async {
        return v ? 37 : (await new Future.value(42));
      }

      return expect42(f(false));
    });

    test("await err in else", () {
      f(v) async {
        return v ? 37 : (await new Future.error("err"));
      }

      return throwsErr(f(false));
    });
  });

  group("async declarations", () {
    var f42 = new Future.value(42);

    // Top-level declarations or local declarations in top-level functions.
    test("topMethod", () {
      return expect42(topMethod(f42));
    });

    test("topArrowMethod", () {
      return expect42(topArrowMethod(f42));
    });

    test("topGetter", () {
      return expect42(topGetter);
    });

    test("topArrowGetter", () {
      return expect42(topArrowGetter);
    });

    test("topLocal", () {
      return expect42(topLocal(f42));
    });

    test("topArrowLocal", () {
      return expect42(topArrowLocal(f42));
    });

    test("topExpression", () {
      return expect42(topExpression(f42));
    });

    test("topArrowExpression", () {
      return expect42(topArrowExpression(f42));
    });

    test("topVarExpression", () {
      return expect42(topVarExpression(f42));
    });

    test("topVarArrowExpression", () {
      return expect42(topVarArrowExpression(f42));
    });

    // Static declarations or local declarations in static functions.
    test("staticMethod", () {
      return expect42(Async.staticMethod(f42));
    });

    test("staticArrowMethod", () {
      return expect42(Async.staticArrowMethod(f42));
    });

    test("staticGetter", () {
      return expect42(Async.staticGetter);
    });

    test("staticArrowGetter", () {
      return expect42(Async.staticArrowGetter);
    });

    test("staticLocal", () {
      return expect42(Async.staticLocal(f42));
    });

    test("staticArrowLocal", () {
      return expect42(Async.staticArrowLocal(f42));
    });

    test("staticExpression", () {
      return expect42(Async.staticExpression(f42));
    });

    test("staticArrowExpression", () {
      return expect42(Async.staticArrowExpression(f42));
    });

    test("staticVarExpression", () {
      return expect42(Async.staticVarExpression(f42));
    });

    test("staticVarArrowExpression", () {
      return expect42(Async.staticVarArrowExpression(f42));
    });

    // Instance declarations or local declarations in instance functions.
    var async = new Async();

    test("instanceMethod", () {
      return expect42(async.instanceMethod(f42));
    });

    test("instanceArrowMethod", () {
      return expect42(async.instanceArrowMethod(f42));
    });

    test("instanceGetter", () {
      return expect42(async.instanceGetter);
    });

    test("instanceArrowGetter", () {
      return expect42(async.instanceArrowGetter);
    });

    test("instanceLocal", () {
      return expect42(async.instanceLocal(f42));
    });

    test("instanceArrowLocal", () {
      return expect42(async.instanceArrowLocal(f42));
    });

    test("instanceExpression", () {
      return expect42(async.instanceExpression(f42));
    });

    test("instanceArrowExpression", () {
      return expect42(async.instanceArrowExpression(f42));
    });

    test("instanceVarExpression", () {
      return expect42(async.instanceVarExpression(f42));
    });

    test("instanceVarArrowExpression", () {
      return expect42(async.instanceVarArrowExpression(f42));
    });

    // Local functions in constructor initializer list.
    test("initializerExpression", () {
      var async = new Async.initializer(f42);
      return expect42(async.initValue);
    });

    test("initializerArrowExpression", () {
      var async = new Async.initializerArrow(f42);
      return expect42(async.initValue);
    });

    test("async in async", () {
      return expect42(asyncInAsync(f42));
    });

    test("sync in async", () {
      return expect42(syncInAsync(f42));
    });

    test("async in sync", () {
      return expect42(asyncInSync(f42));
    });

    // Equality and identity.
    // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/265
    skip_test("Identical and equals", () {
      expect(async.instanceMethod, equals(async.instanceMethod));
      expect(Async.staticMethod, same(Async.staticMethod));
      expect(topMethod, same(topMethod));
    });
  });

  group("await expression", () {
    const c42 = 42;
    final v42 = 42;

    test("local variable", () {
      var l42 = 42;
      f() async {
        return await l42;
      }

      return expect42(f());
    });

    test("parameter", () {
      f(p) async {
        return await p;
      }

      return expect42(f(42));
    });

    test("final local variable", () {
      f() async {
        return await v42;
      }

      return expect42(f());
    });

    test("const local variable", () {
      f() async {
        return await c42;
      }

      return expect42(f());
    });

    test("unary prefix operator", () {
      f() async {
        return -await -42;
      }

      return expect42(f());
    });

    test("suffix operator", () {
      f() async {
        var v = [42];
        return await v[0];
      }

      return expect42(f());
    });

    test("unary postfix operator", () {
      f() async {
        var x = 42;
        return await x++;
      }

      return expect42(f());
    });

    test("suffix operator + increment", () {
      f() async {
        var v = [42];
        return await v[0]++;
      }

      return expect42(f());
    });

    test("suffix operator + increment 2", () {
      f() async {
        var v = [42];
        return await v[await 0]++;
      }

      return expect42(f());
    });

    test("unary pre-increment operator", () {
      f() async {
        var x = 41;
        return await ++x;
      }

      return expect42(f());
    });

    // TODO(jmesserly): https://github.com/dart-lang/dev_compiler/issues/265
    skip_test("suffix operator + pre-increment", () {
      f() async {
        var v = [41];
        return await ++v[0];
      }

      return expect42(f());
    });

    test("assignment operator", () {
      f() async {
        var x = 37;
        return await (x = 42);
      }

      return expect42(f());
    });

    test("assignment-op operator", () {
      f() async {
        var x = 37;
        return await (x += 5);
      }

      return expect42(f());
    });

    test("binary operator", () {
      f() async {
        return await (10 + 11) + await (10 + 11);
      }

      return expect42(f());
    });

    test("ternary operator", () {
      f(v) async {
        return await ((v == 10) ? new Future.value(42) : 37);
      }

      return expect42(f(10));
    });

    test("top-level function call", () {
      f() async {
        return await topMethod(42);
      }

      return expect42(f());
    });

    test("static function call", () {
      f() async {
        return await Async.staticMethod(42);
      }

      return expect42(f());
    });

    test("instance function call", () {
      f() async {
        var a = new Async();
        return await a.instanceMethod(42);
      }

      return expect42(f());
    });

    test("top-level function call w/ await", () {
      f() async {
        return await topMethod(await 42);
      }

      return expect42(f());
    });

    test("static function call w/ await", () {
      f() async {
        return await Async.staticMethod(await 42);
      }

      return expect42(f());
    });

    test("instance function call w/ await", () {
      f() async {
        var a = new Async();
        return await a.instanceMethod(await 42);
      }

      return expect42(f());
    });

    test("top-level getter call", () {
      f() async {
        return await topGetter;
      }

      return expect42(f());
    });

    test("static getter call", () {
      f() async {
        return await Async.staticGetter;
      }

      return expect42(f());
    });

    test("top-level getter call", () {
      f() async {
        var a = new Async();
        return await a.instanceGetter;
      }

      return expect42(f());
    });

    if (!assertionsEnabled) return;

    test("inside assert, true", () { //                      //# 03: ok
      f() async { //                                         //# 03: continued
        assert(await new Future.microtask(() => true)); //   //# 03: continued
        return 42; //                                        //# 03: continued
      } //                                                   //# 03: continued
      return expect42(f()); //                               //# 03: continued
    }); //                                                   //# 03: continued

    test("inside assert, false", () { //                     //# 03: continued
      f() async { //                                         //# 03: continued
        assert(await new Future.microtask(() => false)); //  //# 03: continued
        return 42; //                                        //# 03: continued
      } //                                                   //# 03: continued
      return f().then((_) { //                               //# 03: continued
        fail("assert didn't throw"); //                      //# 03: continued
      }, onError: (e, s) { //                                //# 03: continued
        expect(e is AssertionError, isTrue); //              //# 03: continued
      }); //                                                 //# 03: continued
    }); //                                                   //# 03: continued

    test("inside assert, function -> false", () { //         //# 03: continued
      f() async { //                                         //# 03: continued
        assert(await new Future.microtask(() => false)); //  //# 03: continued
        return 42; //                                        //# 03: continued
      } //                                                   //# 03: continued
      return f().then((_) { //                               //# 03: continued
        fail("assert didn't throw"); //                      //# 03: continued
      }, onError: (e, s) { //                                //# 03: continued
        expect(e is AssertionError, isTrue); //              //# 03: continued
      }); //                                                 //# 03: continued
    }); //                                                   //# 03: continued
  });

  group("syntax", () {
    test("async as variable", () {
      // Valid identifiers outside of async function.
      var async = 42;
      expect(async, equals(42));
    });

    test("await as variable", () { //                        //# 02: ok
      // Valid identifiers outside of async function. //     //# 02: continued
      var await = 42; //                                     //# 02: continued
      expect(await, equals(42)); //                          //# 02: continued
    }); //                                                   //# 02: continued

    test("yield as variable", () {
      // Valid identifiers outside of async function.
      var yield = 42;
      expect(yield, equals(42));
    });
  });
}

// Attempt to obfuscates value to avoid too much constant folding.
id(v) {
  try {
    if (v != null) throw v;
  } catch (e) {
    return e;
  }
  return null;
}

// Create a stream for testing "async for-in".
Stream<int> mkStream() {
  StreamController<int> c;
  int i = 0;
  next() {
    c.add(i++);
    if (i == 10) {
      c.close();
    } else {
      scheduleMicrotask(next);
    }
  }

  c = new StreamController(onListen: () {
    scheduleMicrotask(next);
  });
  return c.stream;
}

// Check that future contains the error "err".
Future throwsErr(Future future) {
  return future.then((v) {
    fail("didn't throw");
  }, onError: (e) {
    expect(e, equals("err"));
  });
}

// Check that future contains the value 42.
Future expect42(Future future) {
  return future.then((v) {
    expect(v, equals(42));
  });
}

// Various async declarations.

Future topMethod(f) async {
  return await f;
}

Future topArrowMethod(f) async => await f;

Future get topGetter async {
  return await new Future.value(42);
}

Future get topArrowGetter async => await new Future.value(42);

Future topLocal(f) {
  local() async {
    return await f;
  }

  return local();
}

Future topArrowLocal(f) {
  local() async => await f;
  return local();
}

Future topExpression(f) {
  return () async {
    return await f;
  }();
}

Future topArrowExpression(f) {
  return (() async => await f)();
}

var topVarExpression = (f) async {
  return await f;
};

var topVarArrowExpression = (f) async => await f;

class Async {
  var initValue;
  Async();

  Async.initializer(f)
      : initValue = (() async {
          return await f;
        }());

  Async.initializerArrow(f) : initValue = ((() async => await f)());

  /* static */
  static Future staticMethod(f) async {
    return await f;
  }

  static Future staticArrowMethod(f) async => await f;

  static Future get staticGetter async {
    return await new Future.value(42);
  }

  static Future get staticArrowGetter async => await new Future.value(42);

  static Future staticLocal(f) {
    local() async {
      return await f;
    }

    return local();
  }

  static Future staticArrowLocal(f) {
    local() async => await f;
    return local();
  }

  static Future staticExpression(f) {
    return () async {
      return await f;
    }();
  }

  static Future staticArrowExpression(f) {
    return (() async => await f)();
  }

  static var staticVarExpression = (f) async {
    return await f;
  };

  static var staticVarArrowExpression = (f) async => await f;

  /* instance */
  Future instanceMethod(f) async {
    return await f;
  }

  Future instanceArrowMethod(f) async => await f;

  Future get instanceGetter async {
    return await new Future.value(42);
  }

  Future get instanceArrowGetter async => await new Future.value(42);

  Future instanceLocal(f) {
    local() async {
      return await f;
    }

    return local();
  }

  Future instanceArrowLocal(f) {
    local() async => await f;
    return local();
  }

  Future instanceExpression(f) {
    return () async {
      return await f;
    }();
  }

  Future instanceArrowExpression(f) {
    return (() async => await f)();
  }

  var instanceVarExpression = (f) async {
    return await f;
  };

  var instanceVarArrowExpression = (f) async => await f;
}

Future asyncInAsync(f) async {
  inner(f) async {
    return await f;
  }

  return await inner(f);
}

Future asyncInSync(f) {
  inner(f) async {
    return await f;
  }

  return inner(f);
}

Future syncInAsync(f) async {
  inner(f) {
    return f;
  }

  return await inner(f);
}

/**
 * A non-standard implementation of Future with a value.
 */
class FakeValueFuture implements Future {
  final _value;
  FakeValueFuture(this._value);
  Future/*<S>*/ then/*<S>*/(callback(value), {Function onError}) {
    return new Future/*<S>*/ .microtask(() => callback(_value));
  }

  Future whenComplete(callback()) {
    return new Future.microtask(() {
      callback();
    });
  }

  Future catchError(Function onError, {bool test(error)}) => this;
  Stream asStream() => (new StreamController()
        ..add(_value)
        ..close())
      .stream;
  Future timeout(Duration duration, {onTimeout()}) => this;
}

typedef BinaryFunction(a, b);

/**
 * A non-standard implementation of Future with an error.
 */
class FakeErrorFuture implements Future {
  final _error;
  FakeErrorFuture(this._error);
  Future/*<S>*/ then/*<S>*/(callback(value), {Function onError}) {
    if (onError != null) {
      if (onError is BinaryFunction) {
        return new Future/*<S>*/ .microtask(() => onError(_error, null));
      }
      return new Future/*<S>*/ .microtask(() => onError(_error));
    }
    return new Future/*<S>*/ .error(_error);
  }

  Future whenComplete(callback()) {
    return new Future.microtask(() {
      callback();
    }).then((_) => this);
  }

  Future catchError(Function onError, {bool test(error)}) {
    return new Future.microtask(() {
      if (test != null && !test(_error)) return this;
      if (onError is BinaryFunction) {
        return onError(_error, null);
      }
      return onError(_error);
    });
  }

  Stream asStream() => (new StreamController()
        ..addError(_error)
        ..close())
      .stream;
  Future timeout(Duration duration, {onTimeout()}) => this;
}
