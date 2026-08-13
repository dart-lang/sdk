// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool topLevelField = true;
var untypedTopLevelField;

class Super {
  int superInstanceField = 0;
  var untypedSuperInstanceField;
}

class C extends Super {
  int instanceField = 0;
  var untypedInstanceField;

  static double staticField = 0.0;

  static var untypedStaticField;

  m() {
    String local;
    var untypedLocal;
    for (local in []) {}
    for (untypedLocal in []) {}
    for (instanceField in []) {}
    for (untypedInstanceField in []) {}
    for (staticField in []) {}
    for (untypedStaticField in []) {}
    for (topLevelField in []) {}
    for (untypedTopLevelField in []) {}
    for (super.superInstanceField in []) {}
    for (super.untypedSuperInstanceField in []) {}
    C c = new C();
    for (c.instanceField in []) {}
    for (c.untypedSuperInstanceField in []) {}
    for (unresolved in []) {}
    for (unresolved.foo in []) {}
    for (c.unresolved in []) {}
    for (main() in []) {}
    for (var x, y in <int>[]) {
      print(x);
      print(y);
    }
    const int constant = 0;
    for (constant in []) {}
  }
}

main() {}
