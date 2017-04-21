// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test explicit import of dart:core in the source code..

library ImportCorePrefixTest.dart;

import "package:expect/expect.dart";
import "dart:core" as mycore;

class Object {}

class Map {
  Map(this._lat, this._long);

  get isPrimeMeridian => _long == 0;

  var _lat;
  var _long;
}

void main() {
  var test = new mycore.Map<mycore.int, mycore.String>();
  mycore.bool boolval = false;
  mycore.int variable = 10;
  mycore.num value = 10;
  mycore.dynamic d = null;
  mycore.print(new mycore.Object());
  mycore.print(new Object());

  var greenwich = new Map(51, 0);
  var kpao = new Map(37, -122);
  Expect.isTrue(greenwich.isPrimeMeridian);
  Expect.isFalse(kpao.isPrimeMeridian);
}
