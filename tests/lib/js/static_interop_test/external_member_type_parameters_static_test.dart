// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that type parameters in external static interop members extend a static
// interop type when using dart:js_interop.

library external_member_type_parameters_static_test;

import 'dart:js_interop';
import 'package:js/js.dart' as pkgJs;

@JS()
external T validTopLevel<T extends JSObject>(T t);

@JS()
external T invalidTopLevel<T>(T t);
//         ^
// [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.

typedef Typedef<T> = T Function();

extension type JSList<T>._(JSAny? _) {}

@JS()
@staticInterop
class Uninstantiated<W, X extends Instantiated?> {
  external factory Uninstantiated(W w);
  //               ^
  // [web] Type 'W' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external factory Uninstantiated.named(X x);
}

extension UninstantiatedExtension<T, U extends JSAny?, V extends Instantiated>
    on Uninstantiated {
  external T fieldT;
  //         ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U fieldU;
  external V fieldV;

  T get getTDart => throw UnimplementedError();
  external T get getT;
  //             ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U get getU;
  external V get getV;

  set setTDart(T t) => throw UnimplementedError();
  external set setT(T t);
  //           ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external set setU(U u);
  external set setV(V v);

  T returnTDart() => throw UnimplementedError();
  external T returnT();
  //         ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U returnU();
  external V returnV();

  void consumeTDart(T t) => throw UnimplementedError();
  external void consumeT(T t);
  //            ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external void consumeU(U u);
  external void consumeV(V v);

  // Test type parameters in a nested type context.
  JSList<Typedef<T>> get getNestedTDart => throw UnimplementedError();
  // No error as JSList is an interop extension type.
  external JSList<Typedef<T>> get getNestedT;
  external JSList<Typedef<U>> get getNestedU;
  external JSList<Typedef<V>> get getNestedV;

  // Test type parameters that are declared by the member.
  W returnWDart<W>() => throw UnimplementedError();
  external W returnW<W>();
  //         ^
  // [web] Type 'W' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external X returnX<X extends JSArray>();
}

extension type UninstantiatedExtensionType<T, U extends JSAny?,
    V extends InstantiatedExtensionType>._(JSObject _) {
  external UninstantiatedExtensionType(T t);
  //       ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external factory UninstantiatedExtensionType.fact(U u);

  // Test simple type parameters.
  external T fieldT;
  //         ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U fieldU;
  external V fieldV;

  T get getTDart => throw UnimplementedError();
  external T get getT;
  //             ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U get getU;
  external V get getV;

  set setTDart(T t) => throw UnimplementedError();
  external set setT(T t);
  //           ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external set setU(U u);
  external set setV(V v);

  T returnTDart() => throw UnimplementedError();
  external T returnT();
  //         ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U returnU();
  external V returnV();

  void consumeTDart(T t) => throw UnimplementedError();
  external void consumeT(T t);
  //            ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external void consumeU(U u);
  external void consumeV(V v);

  // Test type parameters in a nested type context.
  JSList<Typedef<T>> get getNestedTDart => throw UnimplementedError();
  // No error as JSList is an interop extension type.
  external JSList<Typedef<T>> get getNestedT;
  external JSList<Typedef<U>> get getNestedU;
  external JSList<Typedef<V>> get getNestedV;

  // Test type parameters that are declared by the member.
  W returnWDart<W>() => throw UnimplementedError();
  external W returnW<W>();
  //         ^
  // [web] Type 'W' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external X returnX<X extends JSArray>();
}

extension UninstantiatedExtensionTypeExtension<T, U extends JSAny?,
    V extends InstantiatedExtensionType> on UninstantiatedExtensionType<T, U, V> {
  external T get extensionGetT;
  //             ^
  // [web] Type 'T' is not a valid type in the signature of `dart:js_interop` external APIs or APIs converted via `toJS`. The only valid types are: JS types from `dart:js_interop`, @staticInterop types, void, bool, num, double, int, String, extension types that erases to one of these types, or a type parameter that is bound to a static interop type.
  external U get extensionGetU;
  external V get extensionGetV;
}

// We should ignore classes and extensions on classes that use package:js to
// avoid a breaking change.
@pkgJs.JS()
external T pkgJsTopLevel<T>(T t);

@pkgJs.JS()
@staticInterop
class PkgJsStaticInterop<T> {
  external factory PkgJsStaticInterop(T t);
}

extension PkgJsStaticInteropExtension<T> on PkgJsStaticInterop<T> {
  external T getT;
}

@pkgJs.JS()
class PkgJs<T> {
  external PkgJs(T t);
}

extension PkgJsExtension<T> on PkgJs<T> {
  external T getT;
}

// Test generic types where all the type parameters are instantiated.
@JS()
@staticInterop
class Instantiated {
  external factory Instantiated(JSList<JSNumber> list);
}

extension InstantiatedExtension on Instantiated {
  external JSList<int> fieldList;
  external JSList<int> get getList;
  external set setList(JSList<int> list);
  external JSList<int> returnList();
  external void consumeList(JSList<int> list);
}

extension type InstantiatedExtensionType._(JSObject _) {
  // Test generic types where all the type parameters are instantiated.
  external InstantiatedExtensionType(JSList<int> list);
  external JSList<int> fieldList;
  external JSList<int> get getList;
  external set setList(JSList<int> list);
  external JSList<int> returnList();
  external void consumeList(JSList<int> list);
}

void main() {}
