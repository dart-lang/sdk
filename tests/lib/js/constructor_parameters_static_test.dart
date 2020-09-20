// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  // [web] Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.
  external factory Foo.fooFactory({int? a});
  //                                    ^
  // [web] Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.
}

@JS()
@anonymous
class Bar {
  external Bar({int? a});
  //                 ^
  // [web] Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.

  // Factories of an anonymous class can only contain named parameters.
  external factory Bar.barFactoryPositional(int? a);
  //                                             ^
  // [web] Factory constructors for @anonymous JS interop classes should not contain any positional parameters.
  external factory Bar.barFactoryOptional([int? a]);
  //                                            ^
  // [web] Factory constructors for @anonymous JS interop classes should not contain any positional parameters.
  external factory Bar.barFactoryMixedOptional(int? a, [int? b]);
  //                                                ^
  // [web] Factory constructors for @anonymous JS interop classes should not contain any positional parameters.
  external factory Bar.barFactoryMixedNamed(int? a, {int? b});
  //                                             ^
  // [web] Factory constructors for @anonymous JS interop classes should not contain any positional parameters.

  // Named parameters are okay only for factories of an anonymous class.
  external factory Bar.barFactoryNamed({int? a});
}

@JS()
abstract class Baz {
  external Baz({int? a});
  //                 ^
  // [web] Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.
  external factory Baz.bazFactory({int? a});
  //                                    ^
  // [web] Named parameters for JS interop functions are only allowed in a factory constructor of an @anonymous JS class.
}

main() {}
