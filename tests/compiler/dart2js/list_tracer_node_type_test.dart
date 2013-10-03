// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST1 = r"""
main() {
  var a = [42, null];
  return a[0] + 42;
}
""";

const String TEST2 = r"""
main() {
  var a = new List();
  a.add(42);
  a.add(null);
  return a[0] + 42;
}
""";

const String TEST3 = r"""
main() {
  var a = new List(42);
  a[0] = 42;
  return a[0] + 42;
}
""";

const String TEST4 = r"""
main() {
  var a = new List.filled(42, null);
  a[0] = 42;
  return 42 + a[0];
}
""";

// Test that the backend knows the element type of a const list.
const String TEST5 = r"""
var b = 4;
main() {
  var a = const [1, 2, 3];
  return 42 + a[b];
}
""";

// Test that the backend knows the element type of a const static.
const String TEST6 = r"""
const a = const [1, 2, 3];
var b = 4;
main() {
  return 42 + a[b];
}
""";

String generateTest(String call) {
  return """
main() {
  var a = [42];
  return a.$call + 42;
}
""";
}


main() {
  asyncTest(() => compileAll(TEST1).then((generated) {
    Expect.isTrue(generated.contains('if (typeof t1'));
  }));

  asyncTest(() => compileAll(TEST2).then((generated) {
    Expect.isTrue(generated.contains('if (typeof t1'));
  }));

  asyncTest(() => compileAll(TEST3).then((generated) {
    Expect.isTrue(generated.contains('if (typeof t1'));
  }));

  asyncTest(() => compileAll(TEST4).then((generated) {
    Expect.isTrue(generated.contains('if (typeof t1'));
  }));

  asyncTest(() => compileAll(TEST5).then((generated) {
    Expect.isFalse(generated.contains('iae'));
  }));

  asyncTest(() => compileAll(TEST6).then((generated) {
    Expect.isFalse(generated.contains('iae'));
  }));

  var selectors = const <String>[
    'first',
    'last',
    'single',
    'singleWhere',
    'elementAt',
    'removeAt',
    'removeLast'
  ];
  selectors.map((name) => generateTest('$name()')).forEach((String test) {
    asyncTest(() => compileAll(test).then((generated) {
      Expect.isFalse(generated.contains('if (typeof t1'));
      Expect.isFalse(generated.contains('if (t1 == null)'));
    }));
  });

}
