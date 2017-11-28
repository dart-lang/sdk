// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Prefix17Test.dart;

import "library12.dart" as lib12;

class LocalClass {
  static int static_fld;
}

void main() {
  LocalClass.static_fld = 42;
  var lc1 = new lib12.Library12(5);
  lib12.Library12 lc2 = new lib12.Library12(10);
  lib12.Library12 lc2m = new lib12.Library12.other(10, 2);
  lib12.Library12.static_fld = 43;
  //print("${LocalClass.static_fld}, ${lc1.fld}, ${lc2.fld}, ${lc2m.fld}, ${lib12.Library12.static_fld}");
}
