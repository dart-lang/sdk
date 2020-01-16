// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  // Stream.take(n) automatically cancels after seeing the n'th value.
  test('cancels at yield', () {
    Completer exits = Completer();
    var list = [];
    f() async* {
      try {
        list.add(0);
        list.add(1);
        yield null;
        list.add(2);
      } finally {
        exits.complete(3);
      }
    }

    // No events must be fired synchronously in response to a listen.
    var subscription = f().listen((v) {
      fail('Received event $v');
    }, onDone: () {
      fail('Received done');
    });
    // No events must be delivered after a cancel.
    subscription.cancel();
    return exits.future.then((v) {
      expect(v, equals(3));
      expect(list, equals([0, 1]));
    });
  });

  test('does cancel eventually', () {
    var exits = Completer();
    var list = [];
    f() async* {
      int i = 0;
      try {
        while (true) yield i++;
      } finally {
        list.add('a');
        exits.complete(i);
      }
    }

    return expectList(f().take(5), [0, 1, 2, 3, 4])
        .then((_) => exits.future)
        .then((v) {
      expect(v, greaterThan(4));
      expect(list, ['a']);
    });
  });

  group('at index', () {
    f() async* {
      try {
        yield await Future.microtask(() => 1);
      } finally {
        try {
          yield await Future.microtask(() => 2);
        } finally {
          yield await Future.microtask(() => 3);
        }
      }
    }

    test('- all, sanity check', () {
      return expectList(f(), [1, 2, 3]);
    });
    test('after end', () {
      return expectList(f().take(4), [1, 2, 3]);
    });
    test('at end', () {
      return expectList(f().take(3), [1, 2, 3]);
    });
    test('before end', () {
      return expectList(f().take(2), [1, 2]);
    });
    test('early', () {
      return expectList(f().take(1), [1]);
    });
    test('at start', () {
      return expectList(f().take(0), []);
    });
  });

  test('regression-fugl/fisk', () {
    var res = [];
    fisk() async* {
      res.add('+fisk');
      try {
        for (int i = 0; i < 2; i++) {
          yield await Future.microtask(() => i);
        }
      } finally {
        res.add('-fisk');
      }
    }

    fugl(int count) async {
      res.add('fisk $count');
      try {
        await for (int i in fisk().take(count)) res.add(i);
      } finally {
        res.add('done');
      }
    }

    return fugl(3)
        .whenComplete(() => fugl(2))
        .whenComplete(() => fugl(1))
        .whenComplete(() {
      expect(res, [
        'fisk 3',
        '+fisk',
        0,
        1,
        '-fisk',
        'done',
        'fisk 2',
        '+fisk',
        0,
        1,
        '-fisk',
        'done',
        'fisk 1',
        '+fisk',
        0,
        '-fisk',
        'done',
      ]);
    });
  });
}
