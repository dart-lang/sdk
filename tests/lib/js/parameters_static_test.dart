// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks for static errors related to parameters for methods.

@JS()
library js_parameters_static_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class Foo {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
}

@JS()
class Bar {
  external static int singleNamedArg({int? a});
  //                                       ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
  external static int mixedNamedArgs(int a, {int? b});
  //                                              ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
}

external int singleNamedArg({int? a});
//                                ^
// [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
external int mixedNamedArgs(int a, {int? b});
//                                       ^
// [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.

@JS()
@anonymous
class Baz {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
}

@JS()
abstract class Qux {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
}

extension ExtensionFoo on Foo {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.
}

main() {}
