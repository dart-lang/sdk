// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks its type arguments.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
class Js {
  external Js();
}

@JS()
@anonymous
class Anonymous {
  external factory Anonymous();
}

@JS()
@staticInterop
class StaticInterop {
  external factory StaticInterop();
}

class Dart {}

void main() {
  createStaticInteropMock<StaticInterop, Dart>(Dart());
  createStaticInteropMock<Dart, StaticInterop>(StaticInterop());
//^
// [web] First type argument 'Dart' is not a `@staticInterop` type.
// [web] Second type argument 'StaticInterop' is not a Dart interface type.
  createStaticInteropMock<Dart, Js>(Js());
//^
// [web] First type argument 'Dart' is not a `@staticInterop` type.
// [web] Second type argument 'Js' is not a Dart interface type.
  createStaticInteropMock<Dart, Anonymous>(Anonymous());
//^
// [web] First type argument 'Dart' is not a `@staticInterop` type.
// [web] Second type argument 'Anonymous' is not a Dart interface type.
  createStaticInteropMock<StaticInterop, void Function()>(() {});
//^
// [web] Second type argument 'void Function()' is not a Dart interface type.
  createStaticInteropMock(Dart());
//^
// [web] First type argument 'dynamic' is not a `@staticInterop` type.
}
