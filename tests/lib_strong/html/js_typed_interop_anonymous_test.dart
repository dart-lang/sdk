// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@anonymous
class Literal {
  external factory Literal({int x, String y, num z});

  external int get x;
  external String get y;
  external num get z;
}

main() {
  test('simple', () {
    var l = new Literal(x: 3, y: "foo");
    expect(l.x, equals(3));
    expect(l.y, equals("foo"));
    expect(l.z, isNull);
  });
}
