// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@JS()
library external_extension_member_type_parameters_static_test;

import 'package:js/js.dart';

@JS()
@staticInterop
class Uninstantiated {}

typedef TypedefT<T> = T Function();

extension E1<T> on Uninstantiated {
  // Test simple type parameters.
  external T get getT;
  // [error column 18]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external set setT(T t);
  // [error column 16]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external T returnT();
  // [error column 14]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeT(T t);
  // [error column 17]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.

  // Test type parameters in a nested type context.
  external void Function(T) get getNestedT;
  // [error column 33]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external set setNestedT(TypedefT<T> nestedT);
  // [error column 16]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external List<Map<T, T>> returnNestedT();
  // [error column 28]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeNestedT(Set<TypedefT<T>> nestedT);
  // [error column 17]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.

  // Test type parameters that are declared by the member.
  external U returnU<U>();
  // [error column 14]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
  external void consumeU<U>(U u);
  // [error column 17]
  // [web] `@staticInterop` classes cannot have external extension members with type parameters.
}

@JS()
@staticInterop
class Instantiated {}

extension E2 on Instantiated {
  // Test generic types where there all the type parameters are instantiated.
  external List<int> get getList;
  external set setList(List<int> list);
  external List<int> returnList();
  external void consumeList(List<int> list);
}

void main() {}
