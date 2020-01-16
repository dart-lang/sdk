// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  test('canceling while paused at yield', () {
    var list = [];
    var sync = Sync();
    f() async* {
      list.add('*1');
      yield 1;
      await sync.wait();
      sync.release();
      list.add('*2');
      yield 2;
      list.add('*3');
    }

    var stream = f();
    // TODO(jmesserly): added workaround for:
    // https://github.com/dart-lang/dev_compiler/issues/269
    var sub = stream.listen((x) => list.add(x));
    return sync.wait().whenComplete(() {
      expect(list, equals(['*1', 1]));
      sub.pause();
      return sync.wait();
    }).whenComplete(() {
      expect(list, equals(['*1', 1, '*2']));
      sub.cancel();
      return Future.delayed(ms * 200, () {
        // Should not have yielded 2 or added *3 while paused.
        expect(list, equals(['*1', 1, '*2']));
      });
    });
  });
}
