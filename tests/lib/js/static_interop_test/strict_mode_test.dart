// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library strict_mode_test;

import 'dart:js_interop';
import 'package:js/js.dart' hide JS;

@JS()
@staticInterop
class JSClass {
  external factory JSClass(List<int> baz);
  //               ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'List<int>' is not a type or subtype of a type from `dart:js_interop`.

  external factory JSClass.other(Object blu);
  //               ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'Object' is not a type or subtype of a type from `dart:js_interop`.

  external static int foo();
  //                  ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'int' is not a type or subtype of a type from `dart:js_interop`.

  external static JSClass foo1(String bar);
  //                      ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'String' is not a type or subtype of a type from `dart:js_interop`.

  external static Function foo2();
  //                       ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'Function' is not a type or subtype of a type from `dart:js_interop`.

  external static JSClass foo3(void Function() bar);
  //                      ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'void Function()' is not a type or subtype of a type from `dart:js_interop`.

  external static double get fooGet;
  //                         ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  external static set fooSet(String bar);
  //                  ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'String' is not a type or subtype of a type from `dart:js_interop`.
}

extension JSClassExtension on JSClass {
  external dynamic extFoo();
  //               ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'dynamic' is not a type or subtype of a type from `dart:js_interop`.

  external JSClass extFoo2(List<Object?> bar);
  //               ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'List<Object?>' is not a type or subtype of a type from `dart:js_interop`.

  external Function extFoo3(JSClass bar);
  //                ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'Function' is not a type or subtype of a type from `dart:js_interop`.

  external JSClass extFoo4(void Function() bar);
  //               ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'void Function()' is not a type or subtype of a type from `dart:js_interop`.

  external double get extFooGet;
  //                  ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  external set extFooSet(String bar);
  //           ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'String' is not a type or subtype of a type from `dart:js_interop`.

  external static int staticExtFoo();
  //                  ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'int' is not a type or subtype of a type from `dart:js_interop`.

  external static JSClass staticExtFoo2(dynamic bar);
  //                      ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'dynamic' is not a type or subtype of a type from `dart:js_interop`.

  external static Function staticExtFoo3();
  //                       ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'Function' is not a type or subtype of a type from `dart:js_interop`.

  external static JSClass staticExtFoo4(void Function() bar);
  //                      ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'void Function()' is not a type or subtype of a type from `dart:js_interop`.

  external static double get staticExtFooGet;
  //                         ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  external static set staticExtFooSet(String bar);
  //                  ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'String' is not a type or subtype of a type from `dart:js_interop`.
}

@JS()
external void jsFunctionTest(JSFunction foo);

void main() {
  jsFunctionTest(((double foo) => 4.0.toJS).toJS);
  //                                        ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  jsFunctionTest(((JSNumber foo) => 4.0).toJS);
  //                                     ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.
}
