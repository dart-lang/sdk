// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous_test;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@anonymous
class Literal {
  external factory Literal({int x, String y, num z});

  external set x(int v);
  external int get x;
  external String get y;
  external num get z;
}

class MockLiteral implements Literal {
  int _v = 0;
  set x(int v) {
    _v = v;
  }

  int get x => _v;
  String get y => "";
  num get z => 1;
}

main() {
  test('simple', () {
    var l = new Literal(x: 3, y: "foo");
    expect(l.x, equals(3));
    expect(l.y, equals("foo"));
    expect(l.z, isNull);
  });

  test('mock', () {
    Literal l = new MockLiteral();
    expect(l.x, equals(0));
    l.x = 3;
    expect(l.x, equals(3));
    expect(l.y, equals(""));
    expect(l.z, equals(1));
  });

  // Test that instance checks behave appropriately.
  test('Instance checks: implements', () {
    Object l = new Literal(x: 3, y: "foo");
    Object m = new MockLiteral();
    expect(m is Literal, isTrue);
    expect(m is MockLiteral, isTrue);
    expect(l is Literal, isTrue);
    expect(l is MockLiteral, isFalse);
  });

  // Test that casts behave appropriately.
  test('Casts: implements', () {
    Object l = new Literal(x: 3, y: "foo");
    Object m = new MockLiteral();
    expect(m as Literal, equals(m));
    expect(m as MockLiteral, equals(m));
    expect(l as Literal, equals(l));
    expect(() => l as MockLiteral, throws);
  });
}
