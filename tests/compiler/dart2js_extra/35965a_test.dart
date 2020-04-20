// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for issue 35965.
//
// The combination of generator bodies on mixin methods with super-calls caused
// various kinds of broken generated JavaScript.
//
//  - The generator body name had unescaped '&' symbols from the Kernel
//    synthesized super-mixin-application class.
//  - The super-mixin-application class was missing the generator body because
//    it did not expect injected members.

import 'dart:async';

abstract class II {
  bar();
}

mixin M on II {
  // The parameter type check causes the generator to have a body.
  //
  // The super call causes the body to be on the super mixin application.
  //
  // The super call causes the body to have a name depending on the super mixin
  // application name.
  Future<T> foo<T>(T a) async {
    super.bar();
    return a;
  }

  // The parameter type check causes the generator to have a body.
  //
  // The super call causes 'fred' to be on the super mixin application.
  //
  // The super call causes the closure's call method's generator to have a name
  // depending on the super mixin application name.
  fred<T>() => (T a) async {
        super.bar();
        return a;
      };
}

class BB implements II {
  bar() {
    print('BB.bar');
  }
}

class UU extends BB with M {}

main() async {
  print('hello');
  var uu = UU();

  print(await uu.foo<int>(1));
  print(await uu.foo<String>("one"));

  print(await uu.fred<int>()(1));
  print(await uu.fred<String>()("uno"));
}
