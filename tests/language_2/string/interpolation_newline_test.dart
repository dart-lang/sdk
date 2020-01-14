// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of newlines in interpolated strings.

main() {
  String expected = '[[{{}: {}}]]';
  String a = "${ [ "${ [ '${ { '${ { } }' : { } } }' ] }" ] }";
  String b = "${ [ "${ [ '${ { '${
      { } }' : { } } }' ] }" ] }";
  String c = "${ [ "${ [ '${ { '${
      {
      } }' : {
      } } }' ] }" ] }";
  if (expected != a) throw 'expecteda: $expected != $a';
  if (a != b) throw 'ab: $a != $b';
  if (b != c) throw 'bc: $b != $c';
  print('$a$b$c');
}
