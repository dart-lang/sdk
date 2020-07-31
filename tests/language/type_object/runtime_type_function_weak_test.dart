// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

/// Test string representations of legacy types accessed from a null safe
/// library.
import "package:expect/expect.dart";

import "runtime_type_function_helper.dart";
import "runtime_type_function_legacy_lib.dart";

main() {
  // Types that do not use class names - these can be checked on dart2js in
  // minified mode.

  check(fn('dynamic', ''), legacyMain); //        Top-level tear-off.
  check(fn('void', ''), Xyzzy.foo); //      Class static member tear-off.
  check(fn('void', 'Object'), new MyList().add); //  Instance tear-off.
  check(fn('int', ''), () => 1); //       closure.

  var s = new Xyzzy().runtimeType.toString();
  if (s.length <= 3) return; // dart2js --minify has minified names.

  Expect.equals('Xyzzy', s, 'runtime type of plain class prints as class name');

  check(fn('void', 'String, dynamic'), check);

  // Class static member tear-offs.
  check(fn('String', 'String, [String, dynamic]'), Xyzzy.opt);
  check(fn('String', 'String', {'a': 'String', 'b': 'dynamic'}), Xyzzy.nam);

  // Instance method tear-offs.
  check(fn('void', 'Object'), new MyList<String>().add);
  check(fn('void', 'Object'), new MyList<int>().add);
  check(fn('void', 'int'), new Xyzzy().intAdd);

  check(fn('String', 'Object'), new G<String, int>().foo);

  // Instance method with function parameter.
  var string2int = fn('int', 'String');
  check(fn('String', 'Object'), new G<String, int>().moo);
  check(fn('String', '$string2int'), new G<String, int>().higherOrder);
}
