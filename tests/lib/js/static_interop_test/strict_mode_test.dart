// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library strict_mode_test;

import 'dart:js_interop';
/**/ import 'dart:js';
//   ^
// [web] Library 'dart:js' is forbidden when strict mode is enabled.

/**/ import 'dart:js_util';
//   ^
// [web] Library 'dart:js_util' is forbidden when strict mode is enabled.

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
}

@JS()
inline class Inline {
  final JSObject obj;
  external Inline();
}

@JS()
external void jsFunctionTest(JSFunction foo);

@JS()
external void useStaticInteropClass(JSClass foo);

@JS()
external void useStaticInteropInlineClass(Inline foo);

void main() {
  jsFunctionTest(((double foo) => 4.0.toJS).toJS);
  //                                        ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  jsFunctionTest(((JSNumber foo) => 4.0).toJS);
  //                                     ^
  // [web] JS interop requires JS types when strict mode is enabled, but Type 'double' is not a type or subtype of a type from `dart:js_interop`.

  jsFunctionTest(((((JSNumber foo) => 4.0) as dynamic) as Function).toJS);
  //                                                                ^
  // [web] `Function.toJS` requires a statically known function type, but Type 'Function' is not a function type, e.g., `void Function()`.
}
