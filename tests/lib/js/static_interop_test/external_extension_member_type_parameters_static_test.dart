// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library external_extension_member_type_parameters_static_test;

import 'package:js/js.dart';

@JS()
@staticInterop
class Uninstantiated {}

typedef TypedefT<T> = T Function();

extension E1<T> on Uninstantiated {
  // Test simple type parameters.
  external T fieldT;
  //         ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external T get getT;
  //             ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external set setT(T t);
  //           ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external T returnT();
  //         ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeT(T t);
  //            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.

  // Test type parameters in a nested type context.
  external List<T> fieldNestedT;
  //               ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void Function(T) get getNestedT;
  //                            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external set setNestedT(TypedefT<T> nestedT);
  //           ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external List<Map<T, T>> returnNestedT();
  //                       ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeNestedT(Set<TypedefT<T>> nestedT);
  //            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.

  // Test type parameters that are declared by the member.
  external U returnU<U>();
  //         ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeU<U>(U u);
  //            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
}

@JS()
@staticInterop
class Instantiated {}

extension E2 on Instantiated {
  // Test generic types where there all the type parameters are instantiated.
  external List<int> fieldList;
  external List<int> get getList;
  external set setList(List<int> list);
  external List<int> returnList();
  external void consumeList(List<int> list);
}

// Extension members that don't declare or use type parameters should not be
// affected by whether their extension declares a type parameter.
@JS()
@staticInterop
class ExtensionWithTypeParams {}

extension E3<T> on ExtensionWithTypeParams {
  external void noTypeParams();
  external void declareTypeParam<U>(U u);
  //            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void useTypeParam(T t);
  //            ^
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
}

void main() {}
