// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type parameters in external static interop members extend a static
// interop type when using dart:js_interop.

import 'package:js/js.dart';

// We should ignore classes and extensions on classes that use package:js to
// avoid a breaking change.
@JS()
external T pkgJsTopLevel<T>(T t);

@JS()
@staticInterop
class PkgJsStaticInterop<T> {
  external factory PkgJsStaticInterop(T t);
}

extension PkgJsStaticInteropExtension<T> on PkgJsStaticInterop<T> {
  external T getT;
}

@JS()
class PkgJs<T> {
  external PkgJs(T t);
}

extension PkgJsExtension<T> on PkgJs<T> {
  external T getT;
}

void main() {}
