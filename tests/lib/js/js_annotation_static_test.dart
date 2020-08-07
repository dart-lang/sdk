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
  // [web] TODO(srujzs): Add error once supported.
  @JS()
  external factory Foo.fooFactory();
  //               ^
  // [web] TODO(srujzs): Add error once supported.
  @JS()
  external int get bar;
  //               ^^^
  // [web] TODO(srujzs): Add error once supported.
  @JS()
  external set bar(int val);
  //           ^^^
  // [web] TODO(srujzs): Add error once supported.
  @JS()
  external int baz();
  //           ^^^
  // [web] TODO(srujzs): Add error once supported.
  @JS()
  external static int bazStatic();
  //                  ^^^^^^^^^
  // [web] TODO(srujzs): Add error once supported.
}

@JS()
external int qux();

main() {}
