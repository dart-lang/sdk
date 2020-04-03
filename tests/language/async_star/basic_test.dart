// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

class NotAStream {
  listen(oData, {onError, onDone, cancelOnError}) {
    fail('Not implementing Stream.');
  }
}

StreamTransformer getErrors =
    StreamTransformer.fromHandlers(handleData: (data, sink) {
  fail('Unexpected value');
}, handleError: (e, s, sink) {
  sink.add(e);
}, handleDone: (sink) {
  sink.close();
});

// Obscuring identity function.
id(x) {
  try {
    if (x != null) throw x;
  } catch (e) {
    return e;
  }
  return null;
}

main() {
  test('empty', () {
    f() async* {}
    return f().toList().then((v) {
      expect(v, equals([]));
    });
  });

  test('single', () {
    f() async* {
      yield 42;
    }

    return f().toList().then((v) {
      expect(v, equals([42]));
    });
  });

  test('call delays', () {
    var list = [];
    f() async* {
      list.add(1);
      yield 2;
    }

    var res = f().forEach(list.add);
    list.add(0);
    return res.whenComplete(() {
      expect(list, equals([0, 1, 2]));
    });
  });

  test('throws', () {
    f() async* {
      yield 1;
      throw 2;
    }

    var completer = Completer();
    var list = [];
    f().listen(list.add,
        onError: (v) => list.add('$v'), onDone: completer.complete);
    return completer.future.whenComplete(() {
      expect(list, equals([1, '2']));
    });
  });

  test('multiple', () {
    f() async* {
      for (int i = 0; i < 10; i++) {
        yield i;
      }
    }

    return expectList(f(), List.generate(10, id));
  });

  test('allows await', () {
    f() async* {
      var x = await Future.value(42);
      yield x;
      x = await Future.value(42);
    }

    return expectList(f(), [42]);
  });

  test('allows await in loop', () {
    f() async* {
      for (int i = 0; i < 10; i++) {
        yield await i;
      }
    }

    return expectList(f(), List.generate(10, id));
  });

  test('allows yield*', () {
    f() async* {
      yield* Stream.fromIterable([1, 2, 3]);
    }

    return expectList(f(), [1, 2, 3]);
  });

  test('allows yield* of async*', () {
    f(n) async* {
      yield n;
      if (n == 0) return;
      yield* f(n - 1);
      yield n;
    }

    return expectList(f(3), [3, 2, 1, 0, 1, 2, 3]);
  });

  test('Cannot yield* non-stream', () {
    f(dynamic s) async* {
      yield* s;
    }

    return f(42).transform(getErrors).single.then((v) {
      // Not implementing Stream.
      expect(v is Error, isTrue);
    });
  });

  test('Cannot yield* non-stream 2', () {
    f(dynamic s) async* {
      yield* s;
    }

    return f(NotAStream()).transform(getErrors).single.then((v) {
      // Not implementing Stream.
      expect(v is Error, isTrue);
    });
  });
}
