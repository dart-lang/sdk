// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/22987.
// Ensure that functions whose signature only differs in optionality of
// parameters are reflected correctly.

library optional_parameter_test;

@MirrorsUsed(targets: 'optional_parameter_test')
import "dart:mirrors";
import 'package:expect/expect.dart';

class A {
  foo(int x) => x;
}

class B {
  foo([int x]) => x + 1;
}

main() {
  var x = {};
  x["A"] = reflect(new A());
  x["B"] = reflect(new B());

  Expect.equals(1, x["A"].invoke(#foo, [1]).reflectee);
  Expect.equals(2, x["B"].invoke(#foo, [1]).reflectee);
}
