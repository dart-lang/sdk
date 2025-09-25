// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

Future<int> make(int x) => (new Future(() => x));

test() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(list);
  Future<String> results2 = results.then(
    (List<int> list) => list.fold(
      '',
      (x, y) => /*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/
          x /*error:UNDEFINED_OPERATOR*/ + y.toString(),
    ),
  );

  Future<String> results3 = results.then(
    (List<int> list) => list.fold(
      '',
      /*info:INFERRED_TYPE_CLOSURE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ (
        String x,
        y,
      ) => x + y.toString(),
    ),
  );

  Future<String> results4 = results.then(
    (List<int> list) => list.fold<String>('', (x, y) => x + y.toString()),
  );
}

main() {}
