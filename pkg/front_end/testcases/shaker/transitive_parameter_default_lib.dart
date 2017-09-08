// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'transitive_parameter_default_lib2.dart';

topLevelFunction1(p1, [p2, p3 = const A1()]) {}

topLevelFunction2(p1, {p2, p3: const A2()}) {}

topLevelFunction3(p1, {p2, p3: const A3()}) {}

class C1 {
  C1([p = const A4()]);
}

class C2 {
  C2({p: const A5()});
}

class C3 {
  C3({p: const A6()});
}
