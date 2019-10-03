// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() async {
  int f_async() async { return 42; }
  print(await f_async());

  int f_async_star() async* { yield 42; }
  await for (var x in f_async_star() as dynamic) {
    print(x);
  }

  int f_sync_star() sync* { yield 42; }
  for (var x in f_sync_star() as dynamic) {
    print(x);
  }
}
