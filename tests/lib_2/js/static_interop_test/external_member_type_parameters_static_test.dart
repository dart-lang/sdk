// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
// [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.

typedef Typedef<T> = T Function();

@JS()
@staticInterop
class JSList<T> {}

@JS()
@staticInterop
class Uninstantiated<W, X extends Instantiated> {
  external factory Uninstantiated(W w);
  //               ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external factory Uninstantiated.named(X x);
}

extension UninstantiatedExtension<T, U extends JSAny, V extends Instantiated>
    on Uninstantiated {
  external T fieldT;
  //         ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external U fieldU;
  external V fieldV;

  T get getTDart => throw UnimplementedError();
  external T get getT;
  //             ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external U get getU;
  external V get getV;

  set setTDart(T t) => throw UnimplementedError();
  external set setT(T t);
  //           ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external set setU(U u);
  external set setV(V v);

  T returnTDart() => throw UnimplementedError();
  external T returnT();
  //         ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external U returnU();
  external V returnV();

  void consumeTDart(T t) => throw UnimplementedError();
  external void consumeT(T t);
  //            ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external void consumeU(U u);
  external void consumeV(V v);

  // Test type parameters in a nested type context.
  JSList<Typedef<T>> get getNestedTDart => throw UnimplementedError();
  // No error as JSList is an interop type.
  external JSList<Typedef<T>> get getNestedT;
  external JSList<Typedef<U>> get getNestedU;
  external JSList<Typedef<V>> get getNestedV;

  // Test type parameters that are declared by the member.
  W returnWDart<W>() => throw UnimplementedError();
  external W returnW<W>();
  //         ^
  // [web] External static interop members can only use type parameters that extend either a static interop type or one of the 'dart:js_interop' types.
  external X returnX<X extends JSArray>();
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

void main() {}
