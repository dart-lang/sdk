// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experiment-new-rti --no-minify

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

class Thingy {}

class GenericThingy<A, B> {
  toString() => 'GenericThingy<$A, $B>';
}

main() {
  var rti1 = rti.instanceType(1);
  Expect.equals('JSInt', rti.testingRtiToString(rti1));

  var rti2 = rti.instanceType('Hello');
  Expect.equals('JSString', rti.testingRtiToString(rti2));

  var rti3 = rti.instanceType(Thingy());
  Expect.equals('Thingy', rti.testingRtiToString(rti3));

  var rti4 = rti.instanceType(GenericThingy<String, int>());
  Expect.equals('GenericThingy<String, int>', rti.testingRtiToString(rti4));
}
