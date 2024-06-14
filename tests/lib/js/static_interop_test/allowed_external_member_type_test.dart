// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library allowed_external_member_type_test;

import 'dart:js_interop';

import 'package:js/js.dart' as pkgJs;

@pkgJs.JS()
class PkgJS {}

@pkgJs.JS()
@pkgJs.anonymous
class Anonymous {}

// Test `@staticInterop`, interop extension type, and top-level external
// members.

@JS()
@staticInterop
class StaticInterop {
  external factory StaticInterop(_);
  //               ^
  // [web] External JS interop member contains invalid types in its function signature: 'StaticInterop Function(*dynamic*)'.

  external static dynamic method();
  //                      ^
  // [web] External JS interop member contains invalid types in its function signature: '*dynamic* Function()'.

  external static Object field;
  //                     ^
  // [web] External JS interop member contains an invalid type: 'Object'.

  external static Function get getter;
  //                           ^
  // [web] External JS interop member contains an invalid type: 'Function'.

  external static set setter(void Function() _);
  //                  ^
  // [web] External JS interop member contains an invalid type: 'void Function()'.
}

extension JSClassExtension on StaticInterop {
  external void method(List _);
  //            ^
  // [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*)'.

  external List<Object?> field;
  //                     ^
  // [web] External JS interop member contains an invalid type: 'List<Object?>'.

  external PkgJS get getter;
  //                 ^
  // [web] External JS interop member contains an invalid type: 'PkgJS'.

  external set setter(Anonymous _);
  //           ^
  // [web] External JS interop member contains an invalid type: 'Anonymous'.
  external Future operator [](List _);
  //                       ^
  // [web] External JS interop member contains invalid types in its function signature: '*Future<dynamic>* Function(*List<dynamic>*)'.
  external void operator []=(List _, Future __);
  //                     ^
  // [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, *Future<dynamic>*)'.
}

@JS()
@staticInterop
@anonymous
class AnonymousStaticInterop {
  external factory AnonymousStaticInterop({Future a});
  //               ^
  // [web] External JS interop member contains invalid types in its function signature: 'AnonymousStaticInterop Function({*a: Future<dynamic>*})'.
}

@JS()
extension type ExtensionType._(JSObject _) {
  external ExtensionType(Map _);
  //       ^
  // [web] External JS interop member contains invalid types in its function signature: 'ExtensionType Function(*Map<dynamic, dynamic>*)'.
  external ExtensionType.constructor({Future a});
  //       ^
  // [web] External JS interop member contains invalid types in its function signature: 'ExtensionType Function({*a: Future<dynamic>*})'.
  external factory ExtensionType.factory(_);
  //               ^
  // [web] External JS interop member contains invalid types in its function signature: 'ExtensionType Function(*dynamic*)'.

  external static dynamic staticMethod();
  //                      ^
  // [web] External JS interop member contains invalid types in its function signature: '*dynamic* Function()'.

  external static Object? staticField;
  //                      ^
  // [web] External JS interop member contains an invalid type: 'Object?'.

  external static Function get staticGetter;
  //                           ^
  // [web] External JS interop member contains an invalid type: 'Function'.

  external static set staticSetter(void Function() _);
  //                  ^
  // [web] External JS interop member contains an invalid type: 'void Function()'.
  external void method(List _);
  //            ^
  // [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*)'.

  external List<Object?> field;
  //                     ^
  // [web] External JS interop member contains an invalid type: 'List<Object?>'.

  external PkgJS get getter;
  //                 ^
  // [web] External JS interop member contains an invalid type: 'PkgJS'.

  external set setter(Anonymous _);
  //           ^
  // [web] External JS interop member contains an invalid type: 'Anonymous'.
  external Future operator [](List _);
  //                       ^
  // [web] External JS interop member contains invalid types in its function signature: '*Future<dynamic>* Function(*List<dynamic>*)'.
  external void operator []=(List _, Future __);
  //                     ^
  // [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, *Future<dynamic>*)'.
}

extension ExtensionTypeExtension on ExtensionType {
  external void extensionMethod(List _);
  //            ^
  // [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*)'.

  external List<Object?> extensionField;
  //                     ^
  // [web] External JS interop member contains an invalid type: 'List<Object?>'.

  external PkgJS get extensionGetter;
  //                 ^
  // [web] External JS interop member contains an invalid type: 'PkgJS'.

  external set extensionSetter(Anonymous _);
  //           ^
  // [web] External JS interop member contains an invalid type: 'Anonymous'.
}

@JS()
external void method(List _);
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*)'.

@JS()
external List<Object?> field;
//                     ^
// [web] External JS interop member contains an invalid type: 'List<Object?>'.

@JS()
external PkgJS get getter;
//                 ^
// [web] External JS interop member contains an invalid type: 'PkgJS'.

@JS()
external set setter(Anonymous _);
//           ^
// [web] External JS interop member contains an invalid type: 'Anonymous'.

@JS()
external void optionalParameters(List _, [Anonymous __]);
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, *Anonymous*)'.

// While users can't use both positional and named parameters, make sure that
// the error around invalid types is still accurate.
@JS()
external void positionalAndNamedParameters(List _, {Anonymous a});
//            ^
// [web] External JS interop member contains invalid types in its function signature: 'void Function(*List<dynamic>*, {*a: Anonymous*})'.
//                                                            ^
// [web] Named parameters for JS interop functions are only allowed in object literal constructors or @anonymous factories.

// Allowed types.

@JS()
external JSString jsTypeMethod(JSFunction _);

@JS()
external StaticInterop staticInteropTypeMethod(StaticInterop _);

@JS()
external ExtensionType interopExtensionTypeMethod(ExtensionType _);

@JS()
external void primitivesMethod(num a, int b, double c, bool d, String e);

void functionToJSTest<T extends JSAny, U extends ExtensionType,
    V extends StaticInterop, W, Y>() {
  // Test `toJS` conversions of functions.
  ((double _) => 4.0.toJS).toJS;

  ((JSArray _) => '').toJS;

  () {}.toJS;

  (_) {}.toJS;
  //     ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: 'Null Function(*dynamic*)'.

  ((List _) => 4.0).toJS;
  //                ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: 'double Function(*List<dynamic>*)'.

  ((JSNumber _) => () {}).toJS;
  //                      ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: '*Null Function()* Function(JSNumber)'.

  ((((JSNumber _) => 4.0) as dynamic) as Function).toJS;
  //                                               ^
  // [web] `Function.toJS` requires a statically known function type, but Type 'Function' is not a precise function type, e.g., `void Function()`.

  ((T t) => t).toJS;
  ((U u) => u).toJS;
  ((V v) => v).toJS;
  ((W w) => w as Y).toJS;
  //                ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: '*Y* Function(*W*)'.

  void declareTypeParameter<T extends JSAny?>() {}

  T declareAndUseTypeParameter<T extends JSAny?>(T t) => t;

  T declareAndUseInvalidTypeParameter<T>(T t) => t;

  declareTypeParameter.toJS;
  //                   ^
  // [web] Functions converted via `toJS` cannot declare type parameters.
  declareAndUseTypeParameter.toJS;
  //                         ^
  // [web] Functions converted via `toJS` cannot declare type parameters.
  declareAndUseInvalidTypeParameter.toJS;
  //                                ^
  // [web] Function converted via 'toJS' contains invalid types in its function signature: '*T* Function(*T*)'.
  // [web] Functions converted via `toJS` cannot declare type parameters.

  (({JSNumber? n}) => n).toJS;
  //                     ^
  // [web] Functions converted via `toJS` cannot declare named parameters.
  ((JSString _, {int n = 0}) => n).toJS;
  //                               ^
  // [web] Functions converted via `toJS` cannot declare named parameters.
  (({int n = 0, JSArray? a}) => n).toJS;
  //                               ^
  // [web] Functions converted via `toJS` cannot declare named parameters.
}

void main() {}
