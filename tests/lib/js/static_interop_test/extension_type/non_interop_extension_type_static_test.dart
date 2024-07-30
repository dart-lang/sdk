// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that interop extension types can only work on interop types and external
// extension members can't be added to non-interop extension types.

import 'dart:html';
import 'dart:js_interop';
import 'dart:typed_data';

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

extension on EObject {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
}

// dart:js_interop types.

extension type EJSObject(JSObject _) {}

@JS()
extension type EJSString(JSString _) {}

extension on EJSObject {
  external int field;
}

// package:js types.

@pkgJs.JS()
class PkgJs {}

extension type EPkgJs._(PkgJs _) {
  external IPkgJs();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

extension on EPkgJs {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
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

extension on EAnonymous {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
}

@pkgJs.JS()
@staticInterop
class PkgJsStaticInterop {}

extension type EPkgJsStaticInterop(PkgJsStaticInterop _) {}

extension on EPkgJsStaticInterop {
  external int field;
}

@JS()
@staticInterop
class StaticInterop {}

extension type EStaticInterop(StaticInterop _) {}

extension on EStaticInterop {
  external int field;
}

// @Native types.

extension type EWindow(Window _) {}

@JS()
extension type EDocument(Document _) {}

extension type EUint8List._(Uint8List _) {
  external EUint8List();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

@JS()
extension type EUint32List(Uint32List _) {}
//             ^
// [web] Extension type 'EUint32List' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'Uint32List'.

extension on EWindow {
  external int field;
}

extension on EUint8List {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
}

// Extension types.

extension type EExtensionType(EJSObject _) {}

@JS()
extension type EExtensionType2(EExtensionType _) {}

extension on EExtensionType {
  external int field;
}

@JS()
extension type ENonInterop._(EObject _) {
//             ^
// [web] Extension type 'ENonInterop' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'EObject'.
  external ENonInterop();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

extension on ENonInterop {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
}

extension type EExternalDartReference._(ExternalDartReference<Object> _) {
  external EExternalDartReference();
  //       ^
  // [web] Extension type member is marked 'external', but the representation type of its extension type is not a valid JS interop type.
}

@JS()
extension type EExternalDartReference2._(ExternalDartReference<Object> _) {}
//             ^
// [web] Extension type 'EExternalDartReference2' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'ExternalDartReference<Object>'.

extension on EExternalDartReference {
  external int field;
  //           ^
  // [web] JS interop type or @Native type from an SDK web library required for 'external' extension members.
}
