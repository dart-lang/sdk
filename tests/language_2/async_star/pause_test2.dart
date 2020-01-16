// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  test('pauses execution at yield for at least a microtask', () {
    var list = [];
    f() async* {
      list.add(1);
      yield 2;
      list.add(3);
      yield 4;
      list.add(5);
    }

    var done = Completer();
    var sub = f().listen((v) {
      if (v == 2) {
        expect(list, equals([1]));
      } else if (v == 4) {
        expect(list, equals([1, 3]));
      } else {
        fail('Unexpected value $v');
      }
    }, onDone: () {
      expect(list, equals([1, 3, 5]));
      done.complete();
    });
    return done.future;
  });

  test('pause stops execution at yield', () {
    var list = [];
    f() async* {
      list.add(1);
      yield 2;
      list.add(3);
      yield 4;
      list.add(5);
    }

    var done = Completer();
    var sub;
    sub = f().listen((v) {
      if (v == 2) {
        expect(list, equals([1]));
        sub.pause();
        Timer(ms * 300, () {
          expect(list.length, lessThan(3));
          sub.resume();
        });
      } else if (v == 4) {
        expect(list, equals([1, 3]));
      } else {
        fail('Unexpected value $v');
      }
    }, onDone: () {
      expect(list, equals([1, 3, 5]));
      done.complete();
    });
    return done.future;
  });

  test('pause stops execution at yield 2', () {
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
    var done = Completer();
    var sub;
    sub = f().listen((v) {
      expect(v, equals(expected++));
      if (v % 5 == 0) {
        sub.pause(Future.delayed(ms * 300));
      } else if (v == 17) {
        sub.cancel();
        done.complete();
      }
    }, onDone: () {
      fail('Unexpected done!');
    });
    return done.future.whenComplete(() {
      expect(list.length == 18 || list.length == 19, isTrue);
    });
  });
}
