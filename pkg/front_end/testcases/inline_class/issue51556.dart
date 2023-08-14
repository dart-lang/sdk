// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class JSAny {
  final Object value;
  JSAny(this.value);
}

inline class JSObject implements JSAny {
  final Object value;
  JSObject(this.value);
}

inline class JSArray implements JSObject {
  final List<JSAny?> value;
  JSArray(this.value);
}

inline class JSExportedDartObject implements JSObject {
  final Object value;
  JSExportedDartObject(this.value);
}

inline class JSNumber implements JSAny {
  final double value;
  JSNumber(this.value);
}

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
