// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() async {
  /* bl */
  /*sl:1 */ print('About to loop!');
  await for (var /*s:3*/ /*s:5*/ i in foobar /*sl:2*/ ()) {
    /*s:4*/ /*s:6*/ /*nbb:6:7*/ print(i);
  }
  /*s:7*/ /*nbb:7:8*/ print('Done!');
  /*nbb:0:7*/
  /*s:8*/
}

Stream<int> foobar() async* {
  // The testing framework should not step into the 'real body' at all.
  /*nb*/
  yield 1;
  /*nb*/
  yield 2;
}
