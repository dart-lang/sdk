// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(srujzs): Fix this test once web static error testing is supported.

// Checks for static errors related to parameters for methods.

@JS()
library js_parameters_static_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
class Foo {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] TODO(srujzs): Add error once supported.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] TODO(srujzs): Add error once supported.
}

@JS()
class Bar {
  external static int singleNamedArg({int? a});
  //                                       ^
  // [web] TODO(srujzs): Add error once supported.
  external static int mixedNamedArgs(int a, {int? b});
  //                                              ^
  // [web] TODO(srujzs): Add error once supported.
}

external int singleNamedArg({int? a});
//                                ^
// [web] TODO(srujzs): Add error once supported.
external int mixedNamedArgs(int a, {int? b});
//                                       ^
// [web] TODO(srujzs): Add error once supported.

@JS()
@anonymous
class Baz {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] TODO(srujzs): Add error once supported.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] TODO(srujzs): Add error once supported.
}

@JS()
abstract class Qux {
  external int singleNamedArg({int? a});
  //                                ^
  // [web] TODO(srujzs): Add error once supported.
  external int mixedNamedArgs(int a, {int? b});
  //                                       ^
  // [web] TODO(srujzs): Add error once supported.
}

main() {}
