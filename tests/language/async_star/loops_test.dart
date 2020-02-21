// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_minitest.dart';

import 'utils.dart';

main() {
  test('simple yield', () {
    f() async* {
      for (int i = 0; i < 3; i++) {
        yield i;
      }
    }

    return expectList(f(), [0, 1, 2]);
  });

  test('yield in double loop', () {
    f() async* {
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 2; j++) {
          yield i * 2 + j;
        }
      }
    }

    return expectList(f(), [0, 1, 2, 3, 4, 5]);
  });

  test('yield in try body', () {
    var list = [];
    f() async* {
      for (int i = 0; i < 3; i++) {
        try {
          yield i;
        } finally {
          list.add('$i');
        }
      }
    }

    return expectList(f(), [0, 1, 2]).whenComplete(() {
      expect(list, equals(['0', '1', '2']));
    });
  });

  test('yield in catch', () {
    var list = [];
    f() async* {
      for (int i = 0; i < 3; i++) {
        try {
          throw i;
        } catch (e) {
          yield e;
        } finally {
          list.add('$i');
        }
      }
    }

    return expectList(f(), [0, 1, 2]).whenComplete(() {
      expect(list, equals(['0', '1', '2']));
    });
  });

  test('yield in finally', () {
    var list = [];
    f() async* {
      for (int i = 0; i < 3; i++) {
        try {
          throw i;
        } finally {
          yield i;
          list.add('$i');
          continue;
        }
      }
    }

    return expectList(f(), [0, 1, 2]).whenComplete(() {
      expect(list, equals(['0', '1', '2']));
    });
  });

  test('keep yielding after cancel', () {
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
}
