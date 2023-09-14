// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that external extension members with the 'static' keyword on JS interop
// and @Native types are disallowed.

library static_external_extension_members_static_test;

import 'dart:html';
import 'dart:js_interop';

import 'package:js/js.dart' as pkgJs;

@pkgJs.JS()
class JSClass {}

extension on JSClass {
  external static JSNumber field;
  //                       ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static final JSNumber finalField;
  //                             ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static JSNumber get getSet;
  //                           ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static set getSet(JSNumber _);
  //                  ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static void method();
  //                   ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
}

@pkgJs.JS()
@pkgJs.anonymous
class Anonymous {}

extension on Anonymous {
  external static JSNumber field;
  //                       ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static final JSNumber finalField;
  //                             ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static JSNumber get getSet;
  //                           ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static set getSet(JSNumber _);
  //                  ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static void method();
  //                   ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
}

@JS()
@staticInterop
class StaticInterop {}

extension on StaticInterop {
  external static JSNumber field;
  //                       ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static final JSNumber finalField;
  //                             ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static JSNumber get getSet;
  //                           ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static set getSet(JSNumber _);
  //                  ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static void method();
  //                   ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
}

@JS()
extension type ExtensionType(JSObject _) {}

extension on ExtensionType {
  external static JSNumber field;
  //                       ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static final JSNumber finalField;
  //                             ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static JSNumber get getSet;
  //                           ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static set getSet(JSNumber _);
  //                  ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static void method();
  //                   ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
}

extension on Window {
  external static JSNumber field;
  //                       ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static final JSNumber finalField;
  //                             ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static JSNumber get getSet;
  //                           ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static set getSet(JSNumber _);
  //                  ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
  external static void method();
  //                   ^
  // [web] External extension members with the keyword 'static' on JS interop and @Native types are disallowed.
}
