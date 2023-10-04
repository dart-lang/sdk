// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

@JS()
library strict_mode_test;

import 'dart:js_interop';
import 'dart:js';
import 'dart:js_util';

@JS()
@staticInterop
class JSClass {
  external factory JSClass(List<int> baz);
  //               ^
  // [web] Type 'List<int>' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external factory JSClass.other(Object blu);
  //               ^
  // [web] Type 'Object' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external static dynamic foo();
  //                      ^
  // [web] Type 'dynamic' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external static Function get fooGet;
  //                           ^
  // [web] Type 'Function' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external static set fooSet(void Function() bar);
  //                  ^
  // [web] Type 'void Function()' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.
}

extension JSClassExtension on JSClass {
  external dynamic extFoo();
  //               ^
  // [web] Type 'dynamic' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external JSClass extFoo2(List<Object?> bar);
  //               ^
  // [web] Type 'List<Object?>' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external Function get extFooGet;
  //                    ^
  // [web] Type 'Function' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  external set extFooSet(void Function() bar);
  //           ^
  // [web] Type 'void Function()' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.
}

@JS()
extension type ExtensionType(JSObject _) {}

@JS()
external void jsFunctionTest(JSFunction foo);

@JS()
external void useStaticInteropClass(JSClass foo);

@JS()
external void useStaticInteropExtensionType(ExtensionType foo);

void main() {
  jsFunctionTest(((double foo) => 4.0.toJS).toJS);

  jsFunctionTest(((JSNumber foo) => 4.0).toJS);

  jsFunctionTest(((List foo) => 4.0).toJS);
  //                                 ^
  // [web] Type 'List<dynamic>' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  jsFunctionTest(((JSNumber foo) => () {}).toJS);
  //                                       ^
  // [web] Type 'Null Function()' is not a valid type for external `dart:js_interop` APIs. The only valid types are: @staticInterop types, JS types from `dart:js_interop`, void, bool, num, double, int, String, and any extension type that erases to one of these types.

  jsFunctionTest(((((JSNumber foo) => 4.0) as dynamic) as Function).toJS);
  //                                                                ^
  // [web] `Function.toJS` requires a statically known function type, but Type 'Function' is not a function type, e.g., `void Function()`.
}