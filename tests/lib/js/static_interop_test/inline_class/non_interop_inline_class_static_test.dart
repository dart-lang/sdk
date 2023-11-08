// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that interop extension types can only work on interop types.

import 'dart:html';
import 'dart:js_interop';
import 'package:js/js.dart' as pkgJs;

// General non-interop types.

@JS()
extension type EObject(Object _) {}
//             ^
// [web] Extension type 'EObject' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'Object'.

extension type EList._(List<JSAny?> _) {
  external EList();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

// dart:js_interop types.

extension type EJSObject(JSObject _) {}

@JS()
extension type EJSString(JSString _) {}

// package:js types.

@pkgJs.JS()
class PkgJs {}

extension type EPkgJs._(PkgJs _) {
  external IPkgJs();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

@pkgJs.JS()
@anonymous
class Anonymous {}

@JS()
extension type EAnonymous._(Anonymous _) {
//             ^
// [web] Extension type 'EAnonymous' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'Anonymous'.
  external EAnonymous();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

@pkgJs.JS()
@staticInterop
class PkgJsStaticInterop {}

extension type EPkgJsStaticInterop(PkgJsStaticInterop _) {}

@JS()
@staticInterop
class StaticInterop {}

extension type EStaticInterop(StaticInterop _) {}

// @Native types.

extension type EWindow(Window _) {}

@JS()
extension type EDocument(Document _) {}

// Extension types.

extension type EExtensionType(EJSObject _) {}

@JS()
extension type EExtensionType2(EExtensionType _) {}
@JS()
extension type ENonInterop._(EObject _) {
//             ^
// [web] Extension type 'ENonInterop' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'EObject'.
  external ENonInterop();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}
