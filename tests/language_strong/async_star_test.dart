// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_start_test;

import "package:unittest/unittest.dart";
import "dart:async";

main() {
  group("basic", () {
    test("empty", () {
      f() async* {}
      return f().toList().then((v) {
        expect(v, equals([]));
      });
    });

    test("single", () {
      f() async* {
        yield 42;
      }

      return f().toList().then((v) {
        expect(v, equals([42]));
      });
    });

    test("call delays", () {
      var list = [];
      f() async* {
        list.add(1);
        yield 2;
      }

      // TODO(jmesserly): use tear off. For now this is a workaround for:
      // https://github.com/dart-lang/dev_compiler/issues/269
      var res = f().forEach((x) => list.add(x));
      list.add(0);
      return res.whenComplete(() {
        expect(list, equals([0, 1, 2]));
      });
    });

    test("throws", () {
      f() async* {
        yield 1;
        throw 2;
      }

      var completer = new Completer();
      var list = [];
      // TODO(jmesserly): use tear off. For now this is a workaround for:
      // https://github.com/dart-lang/dev_compiler/issues/269
      f().listen((x) => list.add(x),
          onError: (v) => list.add("$v"), onDone: completer.complete);
      return completer.future.whenComplete(() {
        expect(list, equals([1, "2"]));
      });
    });

    test("multiple", () {
      f() async* {
        for (int i = 0; i < 10; i++) {
          yield i;
        }
      }

      return expectList(f(), new List.generate(10, id));
    });

    test("allows await", () {
      f() async* {
        var x = await new Future.value(42);
        yield x;
        x = await new Future.value(42);
      }

      return expectList(f(), [42]);
    });

    test("allows await in loop", () {
      f() async* {
        for (int i = 0; i < 10; i++) {
          yield await i;
        }
      }

      return expectList(f(), new List.generate(10, id));
    });

    test("allows yield*", () {
      f() async* {
        yield* new Stream.fromIterable([1, 2, 3]);
      }

      return expectList(f(), [1, 2, 3]);
    });

    test("allows yield* of async*", () {
      f(n) async* {
        yield n;
        if (n == 0) return;
        yield* f(n - 1);
        yield n;
      }

      return expectList(f(3), [3, 2, 1, 0, 1, 2, 3]);
    });

    test("Cannot yield* non-stream", () {
      f(s) async* {
        yield* s;
      }

      return f(42).transform(getErrors).single.then((v) {
        // Not implementing Stream.
        expect(v is Error, isTrue);
      });
    });

    test("Cannot yield* non-stream", () {
      f(s) async* {
        yield* s;
      }

      return f(new NotAStream()).transform(getErrors).single.then((v) {
        // Not implementing Stream.
        expect(v is Error, isTrue);
      });
    });
  });

  group("yield statement context", () {
    test("plain", () {
      f() async* {
        yield 0;
      }

      return expectList(f(), [0]);
    });

    test("if-then-else", () {
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

    test("block", () {
      f() async* {
        yield 0;
        {
          yield 1;
        }
        yield 2;
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("labeled", () {
      f() async* {
        label1:
        yield 0;
      }

      return expectList(f(), [0]);
    });

    // VM issue 2238
    test("labeled 2", () { //         //# 01: ok
      f() async* { //                 //# 01: continued
        label1: label2: yield 0; //   //# 01: continued
      } //                            //# 01: continued
      return expectList(f(), [0]); // //# 01: continued
    }); //                            //# 01: continued

    test("for-loop", () {
      f() async* {
        for (int i = 0; i < 3; i++) yield i;
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("for-in-loop", () {
      f() async* {
        for (var i in [0, 1, 2]) yield i;
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("await for-in-loop", () {
      f() async* {
        await for (var i in new Stream.fromIterable([0, 1, 2])) yield i;
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("while-loop", () {
      f() async* {
        int i = 0;
        while (i < 3) yield i++;
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("do-while-loop", () {
      f() async* {
        int i = 0;
        do yield i++; while (i < 3);
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("try-catch-finally", () {
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

    test("try-catch-finally 2", () {
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

    // TODO(jmesserly): restore this when we fix
    // https://github.com/dart-lang/dev_compiler/issues/263
    /*test("switch-case", () {
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
    });*/

    test("dead-code return", () {
      f() async* {
        return;
        yield 1;
      }

      return expectList(f(), []);
    });

    test("dead-code throw", () {
      f() async* {
        try {
          throw 0;
          yield 1;
        } catch (_) {}
      }

      return expectList(f(), []);
    });

    test("dead-code break", () {
      f() async* {
        while (true) {
          break;
          yield 1;
        }
      }

      return expectList(f(), []);
    });

    test("dead-code break 2", () {
      f() async* {
        label:
        {
          break label;
          yield 1;
        }
      }

      return expectList(f(), []);
    });

    test("dead-code continue", () {
      f() async* {
        do {
          continue;
          yield 1;
        } while (false);
      }

      return expectList(f(), []);
    });
  });

  group("yield expressions", () {
    test("local variable", () {
      f() async* {
        var x = 42;
        yield x;
      }

      return expectList(f(), [42]);
    });

    test("constant variable", () {
      f() async* {
        const x = 42;
        yield x;
      }

      return expectList(f(), [42]);
    });

    test("function call", () {
      g() => 42;
      f() async* {
        yield g();
      }

      return expectList(f(), [42]);
    });

    test("unary operator", () {
      f() async* {
        var x = -42;
        yield -x;
      }

      return expectList(f(), [42]);
    });

    test("binary operator", () {
      f() async* {
        var x = 21;
        yield x + x;
      }

      return expectList(f(), [42]);
    });

    test("ternary operator", () {
      f() async* {
        var x = 21;
        yield x == 21 ? x + x : x;
      }

      return expectList(f(), [42]);
    });

    test("suffix post-increment", () {
      f() async* {
        var x = 42;
        yield x++;
      }

      return expectList(f(), [42]);
    });

    test("suffix pre-increment", () {
      f() async* {
        var x = 41;
        yield ++x;
      }

      return expectList(f(), [42]);
    });

    test("assignment", () {
      f() async* {
        var x = 37;
        yield x = 42;
      }

      return expectList(f(), [42]);
    });

    test("assignment op", () {
      f() async* {
        var x = 41;
        yield x += 1;
      }

      return expectList(f(), [42]);
    });

    test("await", () {
      f() async* {
        yield await new Future.value(42);
      }

      return expectList(f(), [42]);
    });

    test("index operator", () {
      f() async* {
        var x = [42];
        yield x[0];
      }

      return expectList(f(), [42]);
    });

    test("function expression block", () {
      var o = new Object();
      f() async* {
        yield () {
          return o;
        };
      }

      return f().first.then((v) {
        expect(v(), same(o));
      });
    });

    test("function expression arrow", () {
      var o = new Object();
      f() async* {
        yield () => o;
      }

      return f().first.then((v) {
        expect(v(), same(o));
      });
    });

    test("function expression block async", () {
      var o = new Object();
      f() async* {
        yield () async {
          return o;
        };
      }

      return f().first.then((v) => v()).then((v) {
        expect(v, same(o));
      });
    });

    test("function expression arrow async", () {
      var o = new Object();
      f() async* {
        yield () async => o;
      }

      return f().first.then((v) => v()).then((v) {
        expect(v, same(o));
      });
    });

    test("function expression block async*", () {
      var o = new Object();
      f() async* {
        yield () async* {
          yield o;
        };
      }

      return f().first.then((v) => v().first).then((v) {
        expect(v, same(o));
      });
    });
  });

  group("loops", () {
    test("simple yield", () {
      f() async* {
        for (int i = 0; i < 3; i++) {
          yield i;
        }
      }

      return expectList(f(), [0, 1, 2]);
    });

    test("yield in double loop", () {
      f() async* {
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 2; j++) {
            yield i * 2 + j;
          }
        }
      }

      return expectList(f(), [0, 1, 2, 3, 4, 5]);
    });

    test("yield in try body", () {
      var list = [];
      f() async* {
        for (int i = 0; i < 3; i++) {
          try {
            yield i;
          } finally {
            list.add("$i");
          }
        }
      }

      return expectList(f(), [0, 1, 2]).whenComplete(() {
        expect(list, equals(["0", "1", "2"]));
      });
    });

    test("yield in catch", () {
      var list = [];
      f() async* {
        for (int i = 0; i < 3; i++) {
          try {
            throw i;
          } catch (e) {
            yield e;
          } finally {
            list.add("$i");
          }
        }
      }

      return expectList(f(), [0, 1, 2]).whenComplete(() {
        expect(list, equals(["0", "1", "2"]));
      });
    });

    test("yield in finally", () {
      var list = [];
      f() async* {
        for (int i = 0; i < 3; i++) {
          try {
            throw i;
          } finally {
            yield i;
            list.add("$i");
            continue;
          }
        }
      }

      return expectList(f(), [0, 1, 2]).whenComplete(() {
        expect(list, equals(["0", "1", "2"]));
      });
    });

    test("keep yielding after cancel", () {
      f() async* {
        for (int i = 0; i < 10; i++) {
          try {
            yield i;
          } finally {
            continue;
          }
        }
      }

      return expectList(f().take(3), [0, 1, 2]);
    });
  });

  group("canceling", () {
    // Stream.take(n) automatically cancels after seeing the n'th value.

    test("cancels at yield", () {
      Completer exits = new Completer();
      var list = [];
      f() async* {
        try {
          list.add(0);
          yield list.add(1);
          list.add(2);
        } finally {
          exits.complete(3);
        }
      }

      // No events must be fired synchronously in response to a listen.
      var subscription = f().listen((v) {
        fail("Received event $v");
      }, onDone: () {
        fail("Received done");
      });
      // No events must be delivered after a cancel.
      subscription.cancel();
      return exits.future.then((v) {
        expect(v, equals(3));
        expect(list, equals([0, 1]));
      });
    });

    test("does cancel eventually", () {
      var exits = new Completer();
      var list = [];
      f() async* {
        int i = 0;
        try {
          while (true) yield i++;
        } finally {
          list.add("a");
          exits.complete(i);
        }
      }

      return expectList(f().take(5), [0, 1, 2, 3, 4])
          .then((_) => exits.future)
          .then((v) {
        expect(v, greaterThan(4));
        expect(list, ["a"]);
      });
    });

    group("at index", () {
      f() async* {
        try {
          yield await new Future.microtask(() => 1);
        } finally {
          try {
            yield await new Future.microtask(() => 2);
          } finally {
            yield await new Future.microtask(() => 3);
          }
        }
      }

      test("- all, sanity check", () {
        return expectList(f(), [1, 2, 3]);
      });
      test("after end", () {
        return expectList(f().take(4), [1, 2, 3]);
      });
      test("at end", () {
        return expectList(f().take(3), [1, 2, 3]);
      });
      test("before end", () {
        return expectList(f().take(2), [1, 2]);
      });
      test("early", () {
        return expectList(f().take(1), [1]);
      });
      test("at start", () {
        return expectList(f().take(0), []);
      });
    });

    // Crashes dart2js.
    // test("regression-fugl/fisk", () {
    //   var res = [];
    //   fisk() async* {
    //     res.add("+fisk");
    //     try {
    //       for (int i = 0; i < 2; i++) {
    //         yield await new Future.microtask(() => i);
    //       }
    //     } finally {
    //       res.add("-fisk");
    //     }
    //   }

    //   fugl(int count) async {
    //     res.add("fisk $count");
    //     try {
    //       await for(int i in fisk().take(count)) res.add(i);
    //     } finally {
    //       res.add("done");
    //     }
    //   }

    //   return fugl(3).whenComplete(() => fugl(2))
    //                 .whenComplete(() => fugl(1))
    //                 .whenComplete(() {
    //     expect(res, ["fisk 3", "+fisk", 0, 1, "-fisk", "done",
    //                  "fisk 2", "+fisk", 0, 1, "-fisk", "done",
    //                  "fisk 1", "+fisk", 0, "done", "-fisk", ]);
    //   });
    // });
  });

  group("pausing", () {
    test("pauses execution at yield for at least a microtask", () {
      var list = [];
      f() async* {
        list.add(1);
        yield 2;
        list.add(3);
        yield 4;
        list.add(5);
      }

      var done = new Completer();
      var sub = f().listen((v) {
        if (v == 2) {
          expect(list, equals([1]));
        } else if (v == 4) {
          expect(list, equals([1, 3]));
        } else {
          fail("Unexpected value $v");
        }
      }, onDone: () {
        expect(list, equals([1, 3, 5]));
        done.complete();
      });
      return done.future;
    });

    test("pause stops execution at yield", () {
      var list = [];
      f() async* {
        list.add(1);
        yield 2;
        list.add(3);
        yield 4;
        list.add(5);
      }

      var done = new Completer();
      var sub;
      sub = f().listen((v) {
        if (v == 2) {
          expect(list, equals([1]));
          sub.pause();
          new Timer(MS * 300, () {
            expect(list.length, lessThan(3));
            sub.resume();
          });
        } else if (v == 4) {
          expect(list, equals([1, 3]));
        } else {
          fail("Unexpected value $v");
        }
      }, onDone: () {
        expect(list, equals([1, 3, 5]));
        done.complete();
      });
      return done.future;
    });

    test("pause stops execution at yield 2", () {
      var list = [];
      f() async* {
        int i = 0;
        while (true) {
          yield i;
          list.add(i);
          i++;
        }
      }

      int expected = 0;
      var done = new Completer();
      var sub;
      sub = f().listen((v) {
        expect(v, equals(expected++));
        if (v % 5 == 0) {
          sub.pause(new Future.delayed(MS * 300));
        } else if (v == 17) {
          sub.cancel();
          done.complete();
        }
      }, onDone: () {
        fail("Unexpected done!");
      });
      return done.future.whenComplete(() {
        expect(list.length == 18 || list.length == 19, isTrue);
      });
    });

    test("canceling while paused at yield", () { //                 //# 02: ok
      var list = []; //                                             //# 02: continued
      var sync = new Sync(); //                                     //# 02: continued
      f() async* { //                                               //# 02: continued
        list.add("*1"); //                                          //# 02: continued
        yield 1; //                                                 //# 02: continued
        await sync.wait(); //                                       //# 02: continued
        sync.release(); //                                          //# 02: continued
        list.add("*2"); //                                          //# 02: continued
        yield 2; //                                                 //# 02: continued
        list.add("*3"); //                                          //# 02: continued
      }; //                                                         //# 02: continued
      var stream = f(); //                                          //# 02: continued
    // TODO(jmesserly): added workaround for:
    // https://github.com/dart-lang/dev_compiler/issues/269
      var sub = stream.listen((x) => list.add(x)); //                         //# 02: continued
      return sync.wait().whenComplete(() { //                       //# 02: continued
        expect(list, equals(["*1", 1])); //                         //# 02: continued
        sub.pause(); //                                             //# 02: continued
        return sync.wait(); //                                      //# 02: continued
      }).whenComplete(() { //                                       //# 02: continued
        expect(list, equals(["*1", 1, "*2"])); //                   //# 02: continued
        sub.cancel(); //                                            //# 02: continued
        return new Future.delayed(MS * 200, () { //                 //# 02: continued
          // Should not have yielded 2 or added *3 while paused. // //# 02: continued
          expect(list, equals(["*1", 1, "*2"])); //                 //# 02: continued
        }); //                                                      //# 02: continued
      }); //                                                        //# 02: continued
    }); //                                                          //# 02: continued
  });

  group("await for", () {
    mkStream(int n) async* {
      for (int i = 0; i < n; i++) yield i;
    }

    test("simple stream", () {
      f(s) async {
        var r = 0;
        await for (var v in s) r += v;
        return r;
      }

      return f(mkStream(5)).then((v) {
        expect(v, equals(10));
      });
    });

    test("simple stream, await", () {
      f(s) async {
        var r = 0;
        await for (var v in s) r += await new Future.microtask(() => v);
        return r;
      }

      return f(mkStream(5)).then((v) {
        expect(v, equals(10));
      });
    });

    test("simple stream - take", () { //          //# 03: ok
      f(s) async { //                             //# 03: continued
        var r = 0; //                             //# 03: continued
        await for(var v in s.take(5)) r += v; //  //# 03: continued
        return r; //                              //# 03: continued
      } //                                        //# 03: continued
      return f(mkStream(10)).then((v) { //        //# 03: continued
        expect(v, equals(10)); //                 //# 03: continued
      }); //                                      //# 03: continued
    }); //                                        //# 03: continued

    test("simple stream reyield", () {
      f(s) async* {
        var r = 0;
        await for (var v in s) yield r += v;
      }

      return expectList(f(mkStream(5)), [0, 1, 3, 6, 10]);
    });

    test("simple stream, await, reyield", () {
      f(s) async* {
        var r = 0;
        await for (var v in s) yield r += await new Future.microtask(() => v);
      }

      return expectList(f(mkStream(5)), [0, 1, 3, 6, 10]);
    });

    test("simple stream - take, reyield", () { //               //# 04: ok
      f(s) async* { //                                          //# 04: continued
        var r = 0; //                                           //# 04: continued
        await for(var v in s.take(5)) yield r += v; //          //# 04: continued
      } //                                                      //# 04: continued
      return expectList(f(mkStream(10)), [0, 1, 3, 6, 10]); //  //# 04: continued
    }); //                                                      //# 04: continued

    test("nested", () {
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

    test("nested, await", () {
      f() async {
        var r = 0;
        await for (var i in mkStream(5)) {
          await for (var j in mkStream(3)) {
            r += await new Future.microtask(() => i * j);
          }
        }
        return r;
      }

      return f().then((v) {
        expect(v, equals((1 + 2 + 3 + 4) * (1 + 2)));
      });
    });

    test("nested, await * 2", () {
      f() async {
        var r = 0;
        await for (var i in mkStream(5)) {
          var ai = await new Future.microtask(() => i);
          await for (var j in mkStream(3)) {
            r += await new Future.microtask(() => ai * j);
          }
        }
        return r;
      }

      return f().then((v) {
        expect(v, equals((1 + 2 + 3 + 4) * (1 + 2)));
      });
    });

    test("await pauses loop", () { //                                  //# 05: ok
      var sc; //                                                       //# 05: continued
      var i = 0; //                                                    //# 05: continued
      void send() { //                                                 //# 05: continued
        if (i == 5) { //                                               //# 05: continued
          sc.close(); //                                               //# 05: continued
        } else { //                                                    //# 05: continued
          sc.add(i++); //                                              //# 05: continued
        } //                                                           //# 05: continued
      } //                                                             //# 05: continued
      sc = new StreamController(onListen: send, onResume: send); //    //# 05: continued
      f(s) async { //                                                  //# 05: continued
        var r = 0; //                                                  //# 05: continued
        await for (var i in s) { //                                    //# 05: continued
          r += await new Future.delayed(MS * 10, () => i); //          //# 05: continued
        } //                                                           //# 05: continued
        return r; //                                                   //# 05: continued
      } //                                                             //# 05: continued
      return f(sc.stream).then((v) { //                                //# 05: continued
        expect(v, equals(10)); //                                      //# 05: continued
      }); //                                                           //# 05: continued
    }); //                                                             //# 05: continued
  });
}

// Obscuring identity function.
id(x) {
  try {
    if (x != null) throw x;
  } catch (e) {
    return e;
  }
  return null;
}

expectList(stream, list) {
  return stream.toList().then((v) {
    expect(v, equals(list));
  });
}

const MS = const Duration(milliseconds: 1);

var getErrors = new StreamTransformer.fromHandlers(handleData: (data, sink) {
  fail("Unexpected value");
}, handleError: (e, s, sink) {
  sink.add(e);
}, handleDone: (sink) {
  sink.close();
});

class NotAStream {
  listen(oData, {onError, onDone, cancelOnError}) {
    fail("Not implementing Stream.");
  }
}

/**
 * Allows two asynchronous executions to synchronize.
 *
 * Calling [wait] and waiting for the returned future to complete will
 * wait for the other executions to call [wait] again. At that point,
 * the waiting execution is allowed to continue (the returned future completes),
 * and the more resent call to [wait] is now the waiting execution.
 */
class Sync {
  Completer _completer = null;
  // Release whoever is currently waiting and start waiting yourself.
  Future wait([v]) {
    if (_completer != null) _completer.complete(v);
    _completer = new Completer();
    return _completer.future;
  }

  // Release whoever is currently waiting.
  void release([v]) {
    if (_completer != null) {
      _completer.complete(v);
      _completer = null;
    }
  }
}
