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
  // [web] Type 'List<int>' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external factory JSClass.other(Object blu);
  //               ^
  // [web] Type 'Object' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external static dynamic foo();
  //                      ^
  // [web] Type 'dynamic' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external static Function get fooGet;
  //                           ^
  // [web] Type 'Function' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external static set fooSet(void Function() bar);
  //                  ^
  // [web] Type 'void Function()' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
}

extension JSClassExtension on JSClass {
  external dynamic extFoo();
  //               ^
  // [web] Type 'dynamic' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external JSClass extFoo2(List<Object?> bar);
  //               ^
  // [web] Type 'List<Object?>' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external Function get extFooGet;
  //                    ^
  // [web] Type 'Function' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  external set extFooSet(void Function() bar);
  //           ^
  // [web] Type 'void Function()' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
}

@JS()
extension type ExtensionType(JSObject _) {}

@JS()
external void jsFunctionTest(JSFunction foo);

@JS()
external void useStaticInteropClass(JSClass foo);

@JS()
external void useStaticInteropExtensionType(ExtensionType foo);

void declareTypeParameter<T extends JSAny?>() {}

T declareAndUseTypeParameter<T extends JSAny?>(T t) => t;

T declareAndUseInvalidTypeParameter<T>(T t) => t;

void main() {
  ((double foo) => 4.0.toJS).toJS;

  ((JSNumber foo) => 4.0).toJS;

  ((List foo) => 4.0).toJS;
  //                  ^
  // [web] Type 'List<dynamic>' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  ((JSNumber foo) => () {}).toJS;
  //                        ^
  // [web] Type 'Null Function()' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

  ((((JSNumber foo) => 4.0) as dynamic) as Function).toJS;
  //                                                 ^
  // [web] `Function.toJS` requires a statically known function type, but Type 'Function' is not a precise function type, e.g., `void Function()`.

  void typeParametersTest<T extends JSAny, U extends ExtensionType,
      V extends JSClass, W, Y>() {
    ((T t) => t).toJS;
    ((U u) => u).toJS;
    ((V v) => v).toJS;
    ((W w) => w as Y).toJS;
    //                ^
    // [web] Type 'W' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
    // [web] Type 'Y' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

    declareTypeParameter.toJS;
    //                   ^
    // [web] Functions converted via `toJS` cannot declare type parameters.
    declareAndUseTypeParameter.toJS;
    //                         ^
    // [web] Functions converted via `toJS` cannot declare type parameters.
    declareAndUseInvalidTypeParameter.toJS;
    //                                ^
    // [web] Functions converted via `toJS` cannot declare type parameters.
    // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  }
}
