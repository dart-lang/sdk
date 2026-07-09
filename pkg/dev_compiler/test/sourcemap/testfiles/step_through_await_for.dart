// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() async {
  /* bl */
  /*sl:1 */ print('About to loop!');
  await for (var /*s:4*/ i in /*s:3*/ foobar()) {
    print(i);
  }
  print('Done!');
}

Stream<int> foobar() /*sl:2*/ async* {
  // The testing framework should not step into the 'real body' at all.
  /*nb*/
  yield 1;
  /*nb*/
  yield 2;
}
