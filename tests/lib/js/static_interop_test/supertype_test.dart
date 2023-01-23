// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that interop classes that inherit/implement other classes have the
// appropriate static interop static errors.

@JS()
library supertype_test;

import 'package:js/js.dart';

// Base static interop class.
@JS()
@staticInterop
class Static {}

// Base non-static interop class.
@JS()
class NonStatic {
  external int instanceMethod();
}

@JS()
@staticInterop
class NonStaticMarkedAsStatic {
  external int instanceMethod();
  //           ^
  // [web] JS interop class 'NonStaticMarkedAsStatic' with `@staticInterop` annotation cannot declare instance members.
}

// Static interop classes can inherit other static interop classes in order to
// inherit its extension methods.
@JS()
@staticInterop
class StaticExtendsStatic extends Static {}

// Static interop classes are disallowed from extending non-static interop
// classes.
@JS()
@staticInterop
class StaticExtendsNonStatic extends NonStatic {}
//    ^
// [web] JS interop class 'StaticExtendsNonStatic' has an `@staticInterop` annotation, but has supertype 'NonStatic', which does not.

// Non-static interop classes are disallowed from extending static interop
// classes.
@JS()
class NonStaticExtendsStatic extends Static {}
//    ^
// [web] Class 'NonStaticExtendsStatic' does not have an `@staticInterop` annotation, but has supertype 'Static', which does.

// Static interop classes can implement each other in order to inherit extension
// methods. They cannot implement or be implemented by non-static interop
// classes.
@JS()
@staticInterop
class StaticImplementsStatic implements Static {}

@JS()
class NonStaticImplementsStatic implements Static {}
//    ^
// [web] Class 'NonStaticImplementsStatic' does not have an `@staticInterop` annotation, but has supertype 'Static', which does.

@JS()
class EmptyNonStatic {}

@JS()
@staticInterop
class StaticImplementsNonStatic implements EmptyNonStatic {}
//    ^
// [web] JS interop class 'StaticImplementsNonStatic' has an `@staticInterop` annotation, but has supertype 'EmptyNonStatic', which does not.
