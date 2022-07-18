// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library supertype_transform_test;

import 'dart:html';

import 'package:js/js.dart';

@JS()
@staticInterop
class JSClass {}

class Base<T> {
  T castValue(Object o) => o as T;
}

class Derived extends Base<JSClass> {}

void main() {
  // Without erasure of types in supertypes, `T` is `JSClass` instead of
  // `JavaScriptObject`. This will trigger a type failure in `castValue` with a
  // `dart:html` object.
  Derived().castValue(window);
}
