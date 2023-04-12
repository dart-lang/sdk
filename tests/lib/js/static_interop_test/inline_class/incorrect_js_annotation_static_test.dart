// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

// Test that the right `@JS` annotation is used based on context.

// TODO(srujzs): This only tests classes and top-levels, but not members inside
// the classes or in extensions yet.

import 'dart:js_interop' as jsi;

import 'package:js/js.dart' as pkgJs;

@jsi.JS()
external jsi.JSVoid jsiTopLevel();

@pkgJs.JS()
external jsi.JSVoid pkgJsTopLevel();

@jsi.JS()
inline class JsiInlineClass {}

@pkgJs.JS()
inline class PkgJsInlineClass {}
//           ^
// [web] Inline classes should use the '@JS' annotation from 'dart:js_interop' and not from 'package:js'.

@jsi.JS()
class JsiClass {}
//    ^
// [web] The '@JS' annotation from 'dart:js_interop' can only be used for static interop, either through inline classes or '@staticInterop'.

@pkgJs.JS()
class PkgJsClass {}

@jsi.JS()
@jsi.anonymous
class JsiAnonymousClass {}
//    ^
// [web] The '@JS' annotation from 'dart:js_interop' can only be used for static interop, either through inline classes or '@staticInterop'.

@pkgJs.JS()
@pkgJs.anonymous
class PkgJsAnonymousClass {}

@jsi.JS()
@jsi.staticInterop
class JsiStaticInteropClass {}

@pkgJs.JS()
@pkgJs.staticInterop
class PkgJsStaticInteropClass {}

@jsi.JS()
@jsi.staticInterop
@jsi.anonymous
class JsiStaticInteropAnonymousClass {}

@pkgJs.JS()
@pkgJs.staticInterop
@pkgJs.anonymous
class PkgJsStaticInteropAnonymousClass {}
