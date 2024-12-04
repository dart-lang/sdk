// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that if a new exception is thrown and handled within an exception
// handler, the inner exception should not clobber the outer exception.

import 'package:expect/expect.dart';

Future<void> something(int v) async {
  await Future.delayed(Duration(milliseconds: 10));
  throw StateError('error $v');
}

Stream<int> _readLoop() async* {
  try {
    while (true) {
      yield 1;
      await something(0);
    }
  } catch (e) {
    throw StateError('converted');
  } finally {
    try {
      await something(1);
    } catch (e) {
      Expect.isTrue('$e'.contains('error 1'));
    }
  }
}

void main() async {
  try {
    await for (var _ in _readLoop()) {}
  } catch (e) {
    Expect.isTrue('$e'.contains('converted'));
  }
}
