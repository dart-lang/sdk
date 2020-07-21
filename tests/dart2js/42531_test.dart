// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for badly named generator body.

Future<void> goo(Future Function() f) async {
  Expect.equals(102, (await f()).keys.single);
  Expect.equals(104, (await f()).keys.single);
}

Future<T> identity<T>(T x) async => x;

extension Gloop<T> on Map<T, List<T>> {
  // An async method using a 'complex' generator type `Map<T, List<T>>`.  This
  // requires a separated entry and body, which requires a name, and the name
  // must be legal JavaScript.
  Future<Map<T, List<T>>> foo(int x) async {
    var result = await identity({(x += this.length) as T: <T>[]});
    return result;
  }

  Future<int> bar(int x) async {
    // An async closure using a 'complex' generator type `Map<T, Set<T>>`.  This
    // requires a separated entry and body, which requires a name, and the name
    // must be legal JavaScript.
    await goo(() async => {(x += this.length) as T: <T>{}});
    return x;
  }
}

main() async {
  // Test method.
  Map<int, List<int>> o1 = {1: [], 2: []};
  var o2 = await o1.foo(100);
  var o3 = await o2.foo(100);
  Expect.equals('{102: []}', '$o2');
  Expect.equals('{101: []}', '$o3');

  // Test closure.
  Map<int, List<int>> o = {1: [], 2: []};
  int x = await o.bar(100);
  Expect.equals(104, x);
}
