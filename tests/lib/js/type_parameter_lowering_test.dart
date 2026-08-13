// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the compilers lower interop calls that use type parameters do not
// pass the type parameter.

@JS()
library type_parameter_lowering_test;

import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS()
external void topLevelMethod<T extends int>(T t);

@JS()
class TypeParam<T extends int> {
  external TypeParam(T t);
  external static void staticMethod<U extends int>(U u);
  external static void staticMethodShadow<T extends int>(T t);
  external void genericMethod<U extends int>(U u);
  external void genericMethodShadow<T extends int>(T t);
}

void main() {
  eval('''
    const checkValue = function(value) {
      if (value != 0) {
        throw new Error(`Expected value to be 0, but got \${value}.`);
      }
    }
    globalThis.topLevelMethod = checkValue;
    globalThis.TypeParam = function (value) {
      checkValue(value);
      this.genericMethod = checkValue;
      this.genericMethodShadow = checkValue;
    }
    globalThis.TypeParam.staticMethod = checkValue;
    globalThis.TypeParam.staticMethodShadow = checkValue;
  ''');
  topLevelMethod(0);
  final typeParam = TypeParam(0);
  TypeParam.staticMethod(0);
  TypeParam.staticMethodShadow(0);
  typeParam.genericMethod(0);
  typeParam.genericMethodShadow(0);
}
