// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@JS()
library disallowed_generative_constructor_static_test;

import 'package:js/js.dart';

@JS()
@staticInterop
class JSClass {
  external JSClass();
  //       ^
  // [web] `@staticInterop` classes should not contain any generative constructors.
  external JSClass.namedConstructor();
  //       ^
  // [web] `@staticInterop` classes should not contain any generative constructors.
}

@JS()
@staticInterop
class SyntheticConstructor {}

void main() {
  SyntheticConstructor();
//^
// [web] Synthetic constructors on `@staticInterop` classes can not be used.
}
