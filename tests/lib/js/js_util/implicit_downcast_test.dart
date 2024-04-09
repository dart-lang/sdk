// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests implicit downcasts in js_util.

@JS()
library js_util_implicit_downcast_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
class Foo {
  external Foo(num a);

  external num get a;
  external void set a(_);
  external num bar();
}

bool isComplianceMode() {
  var stuff = [1, 'string'];
  var a = stuff[0];
  // Detect whether we are using --omit-implicit-checks.
  try {
    String s = a as dynamic;
    return false;
  } catch (e) {
    // Ignore.
  }
  return true;
}

main() {
  eval(r"""
    function Foo(a) {
      this.a = a;
    }

    Foo.prototype.bar = function() {
      return this.a;
    }
    """);

  if (isComplianceMode()) {
    complianceModeTest();
  } else {
    omitImplicitChecksTest();
  }
}

complianceModeTest() {
  var f = Foo(42);
  expect(js_util.getProperty<int>(f, 'a'), equals(42));
  expect(() => js_util.getProperty<List>(f, 'a'), throws);

  f.a = 5;
  expect(js_util.callMethod<int>(f, 'bar', []), equals(5));
  expect(() => js_util.callMethod<List>(f, 'bar', []), throws);

  // Check optimized lowering of callMethod.
  expect(() => js_util.callMethod<List>(f, 'bar', [1]), throws);
  expect(() => js_util.callMethod<List>(f, 'bar', [1, 2]), throws);
  expect(() => js_util.callMethod<List>(f, 'bar', [1, 2, 3]), throws);
  expect(() => js_util.callMethod<List>(f, 'bar', [1, 2, 3, 4]), throws);
  expect(() => js_util.callMethod<List>(f, 'bar', [1, 2, 3, 4, 5]), throws);

  var f2 = Foo(7);
  var fConstructor = js_util.getProperty(f, 'constructor');
  expect(js_util.callConstructor<Foo>(fConstructor, [7]).a, equals(7));
  expect(() => js_util.callConstructor<List>(fConstructor, [7]), throws);

  // Check optimized lowering of callConstructor.
  expect(() => js_util.callConstructor<List>(fConstructor, null), throws);
  expect(() => js_util.callConstructor<List>(fConstructor, []), throws);
  expect(() => js_util.callConstructor<List>(fConstructor, [1, 2]), throws);
  expect(() => js_util.callConstructor<List>(fConstructor, [1, 2, 3]), throws);
  expect(
      () => js_util.callConstructor<List>(fConstructor, [1, 2, 3, 4]), throws);
  expect(() => js_util.callConstructor<List>(fConstructor, [1, 2, 3, 4, 5]),
      throws);
}

omitImplicitChecksTest() {
  var f = Foo(42);
  expect(js_util.getProperty<int>(f, 'a'), equals(42));
  expect(js_util.getProperty<List>(f, 'a'), equals(42));

  f.a = 5;
  expect(js_util.callMethod<int>(f, 'bar', []), equals(5));
  expect(js_util.callMethod<List>(f, 'bar', []), equals(5));

  // Check optimized lowering of callMethod.
  expect(js_util.callMethod<List>(f, 'bar', [1]), equals(5));
  expect(js_util.callMethod<List>(f, 'bar', [1, 2]), equals(5));
  expect(js_util.callMethod<List>(f, 'bar', [1, 2, 3]), equals(5));
  expect(js_util.callMethod<List>(f, 'bar', [1, 2, 3, 4]), equals(5));
  expect(js_util.callMethod<List>(f, 'bar', [1, 2, 3, 4, 5]), equals(5));

  var fConstructor = js_util.getProperty(f, 'constructor');
  expect(js_util.callConstructor<Foo>(fConstructor, [7]).a, equals(7));
  expect(
      (js_util.callConstructor<List>(fConstructor, [7]) as Foo).a, equals(7));

  // Check optimized lowering of callConstructor.
  expect((js_util.callConstructor<List>(fConstructor, null) as Foo).a,
      equals(null));
  expect(
      (js_util.callConstructor<List>(fConstructor, []) as Foo).a, equals(null));
  expect((js_util.callConstructor<List>(fConstructor, [1, 2]) as Foo).a,
      equals(1));
  expect((js_util.callConstructor<List>(fConstructor, [1, 2, 3]) as Foo).a,
      equals(1));
  expect((js_util.callConstructor<List>(fConstructor, [1, 2, 3, 4]) as Foo).a,
      equals(1));
  expect(
      (js_util.callConstructor<List>(fConstructor, [1, 2, 3, 4, 5]) as Foo).a,
      equals(1));
}
