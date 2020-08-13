// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srujzs): Fix this test once web static error testing is supported.

// Tests static errors for incorrect JS annotations.

@JS()
library js_annotation_static_test;

import 'package:js/js.dart';

class Foo {
  //  ^^^
  // [web] TODO(srujzs): Test context once supported.
  @JS()
  external Foo(int bar);
  //       ^
  // [web] Member has a JS interop annotation but the enclosing class does not.
  @JS()
  external factory Foo.fooFactory();
  //               ^
  // [web] Member has a JS interop annotation but the enclosing class does not.
  @JS()
  external int get bar;
  //               ^^^
  // [web] Member has a JS interop annotation but the enclosing class does not.
  @JS()
  external set bar(int val);
  //           ^^^
  // [web] Member has a JS interop annotation but the enclosing class does not.
  @JS()
  external int baz();
  //           ^^^
  // [web] Member has a JS interop annotation but the enclosing class does not.
  @JS()
  external static int bazStatic();
  //                  ^^^^^^^^^
  // [web] Member has a JS interop annotation but the enclosing class does not.
}

@JS()
external int qux();

main() {}
