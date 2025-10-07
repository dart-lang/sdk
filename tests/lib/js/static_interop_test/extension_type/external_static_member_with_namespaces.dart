// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS('library-1.library2')
library external_static_member_with_namespaces_test;

import 'dart:js_interop';

@JS()
external void eval(String code);

@JS('library*3.ExternalStatic')
extension type ExternalStatic._(JSObject obj) implements JSObject {
  external ExternalStatic();
  external factory ExternalStatic.factory();
  external ExternalStatic.multipleArgs(double a, String b);
  ExternalStatic.nonExternal() : this.obj = ExternalStatic() as JSObject;

  external static String field;
  @JS('field')
  external static String renamedField;
  @JS('nested-field.foo.field')
  external static String nestedField;
  external static final String finalField;

  external static String get getSet;
  external static set getSet(String val);
  @JS('getSet')
  external static String get renamedGetSet;
  @JS('getSet')
  external static set renamedGetSet(String val);
  @JS('nestedGetSet.1.getSet')
  external static String get nestedGetSet;
  @JS('nestedGetSet.1.getSet')
  external static set nestedGetSet(String val);

  external static String method();
  @JS('method')
  external static String renamedMethod();
  @JS('nested^method.method')
  external static String nestedMethod();
}

@JS('External-Static')
extension type ExternalStaticRenamed._(JSObject obj) implements ExternalStatic {
  external ExternalStaticRenamed();
}
