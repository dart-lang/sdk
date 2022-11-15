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

@JSExport()
class Dart {
  int _unused = 0;
}

void main() {
  createStaticInteropMock<StaticInterop, Dart>(Dart());
  createStaticInteropMock<Dart, StaticInterop>(StaticInterop());
//^
// [web] Type argument 'Dart' needs to be a `@staticInterop` type.
// [web] Type argument 'StaticInterop' needs to be a non-JS interop type.
  createStaticInteropMock<Dart, Js>(Js());
//^
// [web] Type argument 'Dart' needs to be a `@staticInterop` type.
// [web] Type argument 'Js' needs to be a non-JS interop type.
  createStaticInteropMock<Dart, Anonymous>(Anonymous());
//^
// [web] Type argument 'Anonymous' needs to be a non-JS interop type.
// [web] Type argument 'Dart' needs to be a `@staticInterop` type.
  createStaticInteropMock<StaticInterop, void Function()>(() {});
//^
// [web] Type argument 'void Function()' needs to be an interface type.
  createStaticInteropMock(Dart());
//^
// [web] Type argument 'Object' needs to be a `@staticInterop` type.
}
