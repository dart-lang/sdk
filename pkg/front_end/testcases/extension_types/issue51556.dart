// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type JSAny(Object value) {}

extension type JSObject(Object value) implements JSAny {}

extension type JSArray(List<JSAny?> value) implements JSObject {}

extension type JSExportedDartObject(Object value) implements JSObject {}

extension type JSNumber(double value) implements JSAny {}

extension ObjectToJSExportedDartObject on Object {
  JSExportedDartObject get toJS => JSExportedDartObject(this);
}

extension ListToJSArray on List<JSAny?> {
  JSArray get toJS => JSArray(this);
}

extension DoubleToJSNumber on double {
  JSNumber get toJS => JSNumber(this);
}

void main() {
  JSArray arr = [1.0.toJS, 'foo'.toJS].toJS;
}
