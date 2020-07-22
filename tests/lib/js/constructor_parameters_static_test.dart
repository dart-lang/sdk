// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srujzs): Fix this test once web static error testing is supported.

// Checks for static errors related to parameters for constructors and
// factories.

@JS()
library js_constructor_parameters_static_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class Foo {
  external Foo({int? a});
  //                 ^
  // [web] TODO(srujzs): Add error once supported.
  external factory Foo.fooFactory({int? a});
  //                                ^
  // [web] TODO(srujzs): Add error once supported.
}

@JS()
@anonymous
class Bar {
  external Bar({int? a});
  //                 ^
  // [web] TODO(srujzs): Add error once supported.

  // Named parameters are okay only for factories of an anonymous class.
  external factory Bar.barFactory({int? a});
}

@JS()
abstract class Baz {
  external Baz({int? a});
  //                 ^
  // [web] TODO(srujzs): Add error once supported.
  external factory Baz.bazFactory({int? a});
  //                                ^
  // [web] TODO(srujzs): Add error once supported.
}

main() {}
