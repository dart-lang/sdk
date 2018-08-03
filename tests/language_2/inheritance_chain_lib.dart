// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "inheritance_chain_test.dart";

class B extends C {
  get id => "B";
  get length => 2;
}

class D extends Z {
  get id => "D";
  get length => 4;
}

class W {
  get id => "W";
  get length => -4;
}

class Y extends X {
  get id => "Y";
  get length => -2;
}
