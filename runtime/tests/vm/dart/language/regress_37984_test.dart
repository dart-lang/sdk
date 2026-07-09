// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

main() async {
  await for (var x in func(3)) {
    print(x);
  }
}

Stream<int> func(int i) async* {
  int currentState = 0;
  try {
    print('outer try');
  } finally {
    try {
      print('inner try');
    } finally {
      yield currentState + 1;
    }
    yield currentState + 1;
    print('finally');
  }
}
