// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library constants_test;

import 'dart:html';

import 'package:js/js.dart';

@JS()
@staticInterop
class JSClass {}

class Container<T> {
  const Container();

  void accept(T t) {}
}

void main() {
  // Without erasure of types in constants, `T` above should be `JSClass`
  // instead of `JavaScriptObject`. This will trigger a type failure when we
  // call `accept` with a `dart:html` object.
  const container = Container<JSClass>();
  container.accept(window as JSClass);
}
