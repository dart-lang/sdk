// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that interop inline classes can only work on interop types.

import 'dart:html';
import 'dart:js_interop';
import 'package:js/js.dart' as pkgJs;

// General non-interop types.

@JS()
inline class IObject {
//           ^
// [web] Inline class 'IObject' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'InterfaceType(Object)'.
  final Object obj;
  external IObject();
  //       ^
  // [web] Inline class member is marked 'external', but the representation type of its inline class is not a valid JS interop type.
}

inline class IList {
  final List<JSAny?> obj;
  external IList();
  //       ^
  // [web] Inline class member is marked 'external', but the representation type of its inline class is not a valid JS interop type.
}

// dart:js_interop types.

inline class IJSObject {
  final JSObject obj;
  external IJSObject();
}

@JS()
inline class IJSString {
  final JSString obj;
  external IJSString();
}

// package:js types.

@pkgJs.JS()
class PkgJs {}

inline class IPkgJs {
  final PkgJs obj;
  external IPkgJs();
  //       ^
  // [web] Inline class member is marked 'external', but the representation type of its inline class is not a valid JS interop type.
}

@pkgJs.JS()
@anonymous
class Anonymous {}

@JS()
inline class IAnonymous {
//           ^
// [web] Inline class 'IAnonymous' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'InterfaceType(Anonymous)'.
  final Anonymous obj;
  external IAnonymous();
  //       ^
  // [web] Inline class member is marked 'external', but the representation type of its inline class is not a valid JS interop type.
}

@pkgJs.JS()
@staticInterop
class PkgJsStaticInterop {}

inline class IPkgJsStaticInterop {
  final PkgJsStaticInterop obj;
  external IPkgJsStaticInterop();
}

@JS()
@staticInterop
class StaticInterop {}

inline class IStaticInterop {
  final StaticInterop obj;
  external IStaticInterop();
}

// @Native types.

inline class IWindow {
  final Window obj;
  external IWindow();
}

@JS()
inline class IDocument {
  final Document obj;
  external IDocument();
}

// Inline types.

inline class IInlineInterop {
  final IJSObject obj;
  external IInlineInterop();
}

@JS()
inline class IInlineInterop2 {
  final IInlineInterop obj;
  external IInlineInterop2();
}

@JS()
inline class IInlineNonInterop {
//           ^
// [web] Inline class 'IInlineNonInterop' is marked with a '@JS' annotation, but its representation type is not a valid JS interop type: 'InlineType(IObject)'.
  final IObject obj;
  external IInlineNonInterop();
  //       ^
  // [web] Inline class member is marked 'external', but the representation type of its inline class is not a valid JS interop type.
}
